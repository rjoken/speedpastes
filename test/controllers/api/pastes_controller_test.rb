require "test_helper"

class Api::PastesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:regular)
    @collaborator = users(:other)
    @admin = users(:admin)

    @open = pastes(:open)
    @unlisted = @owner.pastes.create!(body: "secret", visibility: :unlisted, collaborators: [ @collaborator.id ])
  end

  # GET /api/pastes/:shortcode

  test "shows an open paste with its full body" do
    @open.update!(tags: [ "ruby" ], collaborators: [ @collaborator.id ])

    get api_paste_path(@open.shortcode), headers: read_headers(@collaborator)

    assert_response :success
    paste = response.parsed_body
    assert_equal "abc123", paste["shortcode"]
    assert_equal "This is an open paste.", paste["body"]
    assert_equal "regular", paste["author"]
    assert_equal [ "ruby" ], paste["tags"]
    assert_equal [ { "id" => @collaborator.id, "username" => "other" } ], paste["collaborators"]
    assert_equal "http://www.example.com/abc123", paste["url"]
    assert_equal "http://www.example.com/raw/abc123", paste["raw_url"]
  end

  test "reading does not increment views" do
    assert_no_changes -> { @open.reload.views } do
      get api_paste_path(@open.shortcode), headers: read_headers(@collaborator)
    end
  end

  test "views are hidden from others when the author hides view counts" do
    @open.update!(views: 7)
    @owner.update!(show_view_count: false)

    get api_paste_path(@open.shortcode), headers: read_headers(@collaborator)
    assert_equal 0, response.parsed_body["views"]

    get api_paste_path(@open.shortcode), headers: read_headers(@owner)
    assert_equal 7, response.parsed_body["views"]
  end

  test "unlisted paste is visible to its owner and collaborators" do
    [ @owner, @collaborator ].each do |user|
      get api_paste_path(@unlisted.shortcode), headers: read_headers(user)

      assert_response :success, user.username
    end
  end

  test "unlisted paste is 404 for everyone else, including admins" do
    stranger = User.create!(email: "stranger@speedpastes.org", username: "stranger", password: "password")

    [ stranger, @admin ].each do |user|
      get api_paste_path(@unlisted.shortcode), headers: read_headers(user)

      assert_response :not_found, user.username
    end
  end

  test "paste by a deactivated author is 404" do
    paste = users(:deactivated).pastes.create!(body: "hidden")

    get api_paste_path(paste.shortcode), headers: read_headers(@owner)

    assert_response :not_found
  end

  test "reading requires pastes:read" do
    get api_paste_path(@open.shortcode), headers: api_headers(@owner, "scratchpad:read")

    assert_response :forbidden
  end

  # GET /api/pastes

  test "lists only open pastes by default" do
    get api_pastes_path, params: { user: @owner.username }, headers: read_headers(@owner)

    assert_response :success
    assert_equal [ @open.shortcode ], shortcodes
  end

  test "unlisted=true adds unlisted pastes the requester owns or collaborates on" do
    stranger_paste = @admin.pastes.create!(body: "admin's own", visibility: :unlisted)

    get api_pastes_path, params: { unlisted: true }, headers: read_headers(@collaborator)

    assert_includes shortcodes, @unlisted.shortcode
    assert_includes shortcodes, @open.shortcode
    assert_not_includes shortcodes, stranger_paste.shortcode
  end

  test "unlisted=true does not give admins other users' unlisted pastes" do
    get api_pastes_path, params: { unlisted: true }, headers: read_headers(@admin)

    assert_not_includes shortcodes, @unlisted.shortcode
  end

  test "excludes pastes by deactivated authors" do
    paste = users(:deactivated).pastes.create!(body: "hidden")

    get api_pastes_path, headers: read_headers(@owner)

    assert_not_includes shortcodes, paste.shortcode
  end

  test "tag filtering defaults to OR and supports AND" do
    ruby = @collaborator.pastes.create!(body: "1", tags: [ "ruby" ])
    rust = @collaborator.pastes.create!(body: "2", tags: [ "rust" ])
    both = @collaborator.pastes.create!(body: "3", tags: [ "ruby", "rust" ])
    query = { user: @collaborator.username, tags: "Ruby, rust" }

    get api_pastes_path, params: query, headers: read_headers(@owner)
    assert_equal [ ruby, rust, both ].map(&:shortcode).sort, shortcodes.sort

    get api_pastes_path, params: query.merge(tag_filtering: "and"), headers: read_headers(@owner)
    assert_equal [ both.shortcode ], shortcodes
  end

  test "invalid query params are 400" do
    [ { unlisted: "maybe" }, { tag_filtering: "xor", tags: "a" }, { per_page: 101 }, { per_page: 0 } ].each do |query|
      get api_pastes_path, params: query, headers: read_headers(@owner)

      assert_response :bad_request, query.inspect
    end
  end

  test "unknown user filter is 404" do
    get api_pastes_path, params: { user: "nobody" }, headers: read_headers(@owner)

    assert_response :not_found
  end

  # Pagination

  test "page defaults to 1" do
    expected = create_pastes_to_paginate

    get_page

    assert_page 1, expected.first(2)
  end

  test "returns the requested page when in range" do
    expected = create_pastes_to_paginate

    get_page page: 2

    assert_page 2, expected[2, 2]
  end

  test "unparseable or below-range pages become page 1" do
    expected = create_pastes_to_paginate

    [ "", "abc", "0", "-4" ].each do |page|
      get_page page: page

      assert_page 1, expected.first(2), "page=#{page.inspect}"
    end
  end

  test "pages past the end become the last page" do
    expected = create_pastes_to_paginate

    [ "4", "99999999999999999999" ].each do |page|
      get_page page: page

      assert_page 3, expected.last(1), "page=#{page.inspect}"
    end
  end

  test "no results is page 1 of 1" do
    get_page page: 3

    assert_response :success
    assert_equal 1, response.parsed_body["page"]
    assert_equal 1, response.parsed_body["pages"]
    assert_equal 0, response.parsed_body["count"]
    assert_empty response.parsed_body["pastes"]
  end

  # POST /api/pastes

  test "creates a single paste and returns an object" do
    assert_difference -> { @owner.pastes.count }, 1 do
      post api_pastes_path, params: { body: "hello world from the api", tags: "Ruby, rust" }.to_json, headers: write_headers(@owner)
    end

    assert_response :created
    paste = response.parsed_body
    assert_equal "hello world from the api", paste["title"]
    assert_equal [ "ruby", "rust" ], paste["tags"]
    assert_equal "open", paste["visibility"]
    assert_equal "plain", paste["render_type"]
  end

  test "creates a batch and returns an array" do
    assert_difference -> { @owner.pastes.count }, 2 do
      post api_pastes_path, params: [ { body: "one" }, { body: "two", visibility: "unlisted" } ].to_json, headers: write_headers(@owner)
    end

    assert_response :created
    assert_equal [ "open", "unlisted" ], response.parsed_body.map { |paste| paste["visibility"] }
  end

  test "a batch is all-or-nothing" do
    assert_no_difference -> { Paste.count } do
      post api_pastes_path, params: [ { body: "fine" }, { body: "bad", visibility: "secret" } ].to_json, headers: write_headers(@owner)
    end

    assert_response :unprocessable_entity
    assert_equal 1, response.parsed_body["details"].first["index"]
  end

  test "invalid enum value is 422" do
    post api_pastes_path, params: { body: "x", render_type: "html" }.to_json, headers: write_headers(@owner)

    assert_response :unprocessable_entity
    assert response.parsed_body["details"]["render_type"].present?
  end

  test "malformed create requests are 400" do
    [
      {},
      { title: "no body" },
      { body: "x", tilte: "typo" },
      { body: 5 },
      { body: "x", hide_frontpage: "true" },
      { body: "x", collaborators: [ "3" ] },
      [],
      [ "not an object" ],
      Array.new(26) { { body: "x" } }
    ].each do |payload|
      assert_no_difference -> { Paste.count } do
        post api_pastes_path, params: payload.to_json, headers: write_headers(@owner)
      end

      assert_response :bad_request, payload.to_json.truncate(60)
    end
  end

  test "collaborators drop self, unknown and inactive users" do
    ids = [ @owner.id, @collaborator.id, users(:deactivated).id, 999_999 ]

    post api_pastes_path, params: { body: "x", collaborators: ids }.to_json, headers: write_headers(@owner)

    assert_equal [ { "id" => @collaborator.id, "username" => "other" } ], response.parsed_body["collaborators"]
  end

  test "creating requires pastes:write" do
    post api_pastes_path, params: { body: "x" }.to_json, headers: json_headers(read_headers(@owner))

    assert_response :forbidden
  end

  # PATCH /api/pastes/:shortcode

  test "owner can update without sending the body" do
    patch api_paste_path(@open.shortcode), params: { title: "Renamed" }.to_json, headers: write_headers(@owner)

    assert_response :success
    assert_equal "Renamed", @open.reload.title
    assert_equal "This is an open paste.", @open.body
    assert_not_nil @open.edited_at
  end

  test "collaborator can update" do
    patch api_paste_path(@unlisted.shortcode), params: { body: "edited" }.to_json, headers: write_headers(@collaborator)

    assert_response :success
    assert_equal "edited", @unlisted.reload.body
  end

  test "only the owner can change collaborators" do
    patch api_paste_path(@unlisted.shortcode), params: { collaborators: [] }.to_json, headers: write_headers(@collaborator)

    assert_response :forbidden
    assert_equal [ @collaborator.id ], @unlisted.reload.collaborators
  end

  test "non-member updating an open paste is 403" do
    patch api_paste_path(@open.shortcode), params: { title: "x" }.to_json, headers: write_headers(@collaborator)

    assert_response :forbidden
  end

  test "admin can update another user's open paste" do
    patch api_paste_path(@open.shortcode), params: { title: "Moderated" }.to_json, headers: write_headers(@admin)

    assert_response :success
  end

  test "admin updating an unlisted paste they are not part of is 404" do
    patch api_paste_path(@unlisted.shortcode), params: { title: "x" }.to_json, headers: write_headers(@admin)

    assert_response :not_found
  end

  test "empty update is 400" do
    patch api_paste_path(@open.shortcode), params: {}.to_json, headers: write_headers(@owner)

    assert_response :bad_request
  end

  test "blanking the body is 422" do
    patch api_paste_path(@open.shortcode), params: { body: "" }.to_json, headers: write_headers(@owner)

    assert_response :unprocessable_entity
  end

  # DELETE /api/pastes/:shortcode

  test "owner can delete" do
    delete api_paste_path(@open.shortcode), headers: write_headers(@owner)

    assert_response :no_content
    assert_not Paste.exists?(@open.id)
  end

  test "collaborator cannot delete" do
    delete api_paste_path(@unlisted.shortcode), headers: write_headers(@collaborator)

    assert_response :forbidden
    assert Paste.exists?(@unlisted.id)
  end

  test "admin can delete another user's open paste" do
    delete api_paste_path(@open.shortcode), headers: write_headers(@admin)

    assert_response :no_content
  end

  test "admin deleting an unlisted paste they are not part of is 404" do
    delete api_paste_path(@unlisted.shortcode), headers: write_headers(@admin)

    assert_response :not_found
    assert Paste.exists?(@unlisted.id)
  end

  test "deleting requires pastes:write" do
    delete api_paste_path(@open.shortcode), headers: read_headers(@owner)

    assert_response :forbidden
  end

  private

  def read_headers(user)
    api_headers(user, "pastes:read")
  end

  def write_headers(user)
    json_headers(api_headers(user, "pastes:write"))
  end

  def shortcodes
    response.parsed_body["pastes"].map { |paste| paste["shortcode"] }
  end

  # 5 pastes for a user with none, newest first to match the index order
  def create_pastes_to_paginate
    5.times.map { |i| @collaborator.pastes.create!(body: "paste #{i}", created_at: i.minutes.ago).shortcode }
  end

  def get_page(**query)
    get api_pastes_path, params: { user: @collaborator.username, per_page: 2, **query }, headers: read_headers(@owner)
  end

  def assert_page(page, expected, message = nil)
    assert_response :success, message
    assert_equal page, response.parsed_body["page"], message
    assert_equal 3, response.parsed_body["pages"], message
    assert_equal 5, response.parsed_body["count"], message
    assert_equal expected, shortcodes, message
  end
end
