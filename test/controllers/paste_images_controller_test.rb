require "test_helper"

class PasteImagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
  end

  def upload(fixture: "sample.png", type: "image/png", filename: nil, param: :file)
    file = Rack::Test::UploadedFile.new(
      file_fixture(fixture),
      type,
      original_filename: filename || fixture
    )
    post images_pastes_path, params: { param => file }
  end

  def last_blob
    @user.reload.paste_images.blobs.last
  end

  test "rejects anonymous uploads" do
    assert_no_difference "ActiveStorage::Blob.count" do
      upload
    end

    assert_response :unauthorized
    assert_equal "You must be logged in to upload images", response.parsed_body["error"]
  end

  test "rejects deactivated users" do
    sign_in_as users(:deactivated)

    assert_no_difference "ActiveStorage::Blob.count" do
      upload
    end

    assert_response :forbidden
  end

  test "uploads a png and returns its url" do
    sign_in_as @user

    assert_difference "ActiveStorage::Blob.count", 1 do
      upload
    end

    assert_response :created
    body = response.parsed_body
    assert_equal "image/png", body["content_type"]
    assert_equal "sample.png", body["filename"]
    assert_equal last_blob.byte_size, body["byte_size"]
    assert body["url"].present?
    assert_equal 1, @user.reload.paste_images.count
  end

  test "stores the blob under the username with a random basename" do
    sign_in_as @user
    upload

    assert_match %r{\Apaste-images/regular/[0-9a-f-]{36}\.png\z}, last_blob.key
  end

  test "keeps the original filename out of the storage key" do
    sign_in_as @user
    upload(filename: "../../etc/passwd.png")

    assert_match %r{\Apaste-images/regular/[0-9a-f-]{36}\.png\z}, last_blob.key
    assert_not_includes last_blob.key, "passwd"
  end

  # The Disk service used here cannot show what Spaces will return, so assert the
  # config that makes production URLs permanent rather than presigned.
  test "the digitalocean service is public so urls never expire" do
    config = YAML.load(ERB.new(Rails.root.join("config/storage.yml").read).result, aliases: true)
    assert config.dig("digitalocean", "public"), "digitalocean service must set public: true"
  end

  test "returns an absolute url" do
    sign_in_as @user
    upload

    assert_match %r{\Ahttps?://}, response.parsed_body["url"]
  end

  test "rejects a non-image declaring an image content type" do
    sign_in_as @user

    assert_no_difference "ActiveStorage::Blob.count" do
      upload(fixture: "not_an_image.png", type: "image/png")
    end

    assert_response :unsupported_media_type
  end

  test "accepts gif and webp" do
    sign_in_as @user

    upload(fixture: "sample.gif", type: "image/gif")
    assert_response :created
    assert_equal "image/gif", response.parsed_body["content_type"]

    upload(fixture: "sample.webp", type: "image/webp")
    assert_response :created
    assert_equal "image/webp", response.parsed_body["content_type"]
  end

  test "rejects a missing file param" do
    sign_in_as @user

    assert_no_difference "ActiveStorage::Blob.count" do
      post images_pastes_path
    end

    assert_response :bad_request
  end

  test "rejects a file over the size limit" do
    sign_in_as @user
    oversized = Rack::Test::UploadedFile.new(
      StringIO.new("\x89PNG\r\n\x1a\n" + "0" * PasteImages::Upload::MAX_BYTES),
      "image/png",
      original_filename: "big.png"
    )

    assert_no_difference "ActiveStorage::Blob.count" do
      post images_pastes_path, params: { file: oversized }
    end

    assert_response :content_too_large
  end
end
