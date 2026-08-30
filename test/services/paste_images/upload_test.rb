require "test_helper"

class PasteImages::UploadTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:regular)
  end

  def sample(fixture = "sample.png", type = "image/png", filename: nil)
    Rack::Test::UploadedFile.new(file_fixture(fixture), type, original_filename: filename || fixture)
  end

  def upload(file = sample)
    PasteImages::Upload.call(user: @user, file: file)
  end

  test "stores under the downcased username" do
    @user.update!(username: "MixedCase")

    assert_match %r{\Apaste-images/mixedcase/}, upload.blob.key
  end

  test "rejects a missing file" do
    result = PasteImages::Upload.call(user: @user, file: nil)

    assert_not result.ok?
    assert_equal :bad_request, result.status
  end

  test "rejects a string masquerading as a file" do
    result = PasteImages::Upload.call(user: @user, file: "not-a-file")

    assert_not result.ok?
    assert_equal :bad_request, result.status
  end

  test "refuses once the user is over quota" do
    stub_const(PasteImages::Upload, :USER_QUOTA, 1) do
      result = upload

      assert_not result.ok?
      assert_equal :content_too_large, result.status
    end
  end

  test "keeps a readable filename without letting it reach the key" do
    blob = upload(sample(filename: "My Screenshot!!.png")).blob

    assert_equal "My Screenshot.png", blob.filename.to_s
    assert_not_includes blob.key, "Screenshot"
  end

  test "renaming the user leaves existing keys alone" do
    blob = upload.blob
    key = blob.key

    @user.update!(username: "renamed")

    assert_equal key, blob.reload.key
    assert_match %r{\Apaste-images/regular/}, key
  end

  test "anonymizing the user purges their paste images" do
    upload
    assert_equal 1, @user.reload.paste_images.count

    perform_enqueued_jobs do
      Users::Anonymize.call(user: @user)
    end

    assert_equal 0, @user.reload.paste_images.count
  end
end
