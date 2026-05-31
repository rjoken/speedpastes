class ReportsController < ApplicationController
  def new
    @shortcode = params[:shortcode].to_s
  end

  def create
    shortcode = params[:shortcode].to_s.strip
    details = params[:details].to_s.strip
    reply_to = params[:reply_to].to_s.strip

    if shortcode.blank? || details.blank?
      redirect_back fallback_location: root_path, alert: "Paste and details are required to submit a report."
      return
    end

    ReportMailer.report(shortcode: shortcode, details: details, reply_to: reply_to).deliver_now
    redirect_to root_path, notice: "Your report has been submitted. Thank you."
  rescue => e
    redirect_back fallback_location: root_path, alert: "Failed to send report: #{e.message}"
  end
end
