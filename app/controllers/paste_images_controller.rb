class PasteImagesController < ApplicationController
  # The Disk service used in dev and test needs url_options to build blob.url
  include ActiveStorage::SetCurrent

  before_action :require_login_json!
  before_action :require_activated_json!

  rate_limit to: 20, within: 1.minute,
    by: -> { current_user&.id || request.remote_ip },
    with: -> { render json: { error: "Rate limit exceeded" },
    status: :too_many_requests },
    only: :create

  def create
    result = PasteImages::Upload.call(user: current_user, file: params[:file])

    if result.ok?
      render json: {
        url: PasteImages::Url.for(result.blob, request: request),
        filename: result.blob.filename.to_s,
        content_type: result.blob.content_type,
        byte_size: result.blob.byte_size,
        signed_id: result.blob.signed_id
      }, status: :created
    else
      render json: { error: result.error }, status: result.status
    end
  end

  private

  # These deliberately do not reuse require_login!/require_activated!: those redirect,
  # and fetch() follows the redirect and hands the JS a login page with a 200.
  def require_login_json!
    return if signed_in?

    render json: { error: "You must be logged in to upload images" }, status: :unauthorized
  end

  def require_activated_json!
    return if activated_user?(current_user)

    render json: { error: "Your account is not eligible to upload images" }, status: :forbidden
  end
end
