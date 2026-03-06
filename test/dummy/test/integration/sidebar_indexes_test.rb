# frozen_string_literal: true

require_relative "../test_helper"

class SidebarIndexesTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = create_user(email: "sidebar@example.com")
    sign_in @user
  end

  def test_sidebar_links_render_all_observability_indexes
    get root_path

    assert_response :success
    assert_includes response.body, "Recordings"
    assert_includes response.body, "Folder Recordables"
    assert_includes response.body, "Pages Recordables"
    assert_includes response.body, "Events"

    get recordings_path
    assert_response :success
    assert_includes response.body, "Recordings"
    assert_includes response.body, "Songwriting"
    assert_includes response.body, "RecordingStudioFolder"

    get folder_recordables_path
    assert_response :success
    assert_includes response.body, "Folder Recordables"
    assert_includes response.body, "Songwriting"

    get page_recordables_path
    assert_response :success
    assert_includes response.body, "Pages Recordables"
    assert_includes response.body, "Lyric Draft"

    get events_path
    assert_response :success
    assert_includes response.body, "Events"
    assert_includes response.body, "created"
  end
end