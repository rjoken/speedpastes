require "test_helper"

class PasteEditorMarkupTest < ActionDispatch::IntegrationTest
  test "paste form wires up image-paste, scratchpad does not" do
    sign_in_as users(:regular)

    get new_paste_path
    assert_response :success
    assert_select "[data-controller='linenumbers-editor image-paste']"
    assert_select "[data-image-paste-url-value='/pastes/images']"
    assert_select "[data-image-paste-target='input']"
    assert_select "[data-image-paste-target='status']"
    assert_match "paste-&gt;image-paste#onPaste", response.body
    assert_match "drop-&gt;image-paste#onDrop", response.body

    get scratchpad_path
    assert_response :success
    assert_select "[data-controller='linenumbers-editor']"
    assert_select "[data-image-paste-target]", false
    assert_no_match(/image-paste/, response.body)
  end
end
