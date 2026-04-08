# frozen_string_literal: true

require_relative "../test_helper"

class SidebarIndexesTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = create_user(email: "sidebar@example.com")
    sign_in @user
  end

  def test_sidebar_links_render_remaining_navigation
    get root_path

    assert_response :success
    assert_not_includes response.body, "Recordings"
    assert_not_includes response.body, "Folder Recordables"
    assert_not_includes response.body, "Pages Recordables"
    assert_includes response.body, "Events"
    assert_includes response.body, "Moveable Docs"
    assert_includes response.body, "Destinations"
    assert_includes response.body, "Setup"
    assert_includes response.body, "Methods"
    assert_includes response.body, "Redirects"

    get events_path
    assert_response :success
    assert_includes response.body, "Events"
    assert_includes response.body, "created"

    get moveable_docs_path
    assert_response :success
    assert_includes response.body, "Moveable Docs"
    assert_includes response.body, "Where an item can move"
    assert_includes response.body, "How access is checked"
    assert_includes response.body, "RecordingStudio::Capabilities::Moveable.to"
    assert_includes response.body, "uses built-in access checks"
    assert_includes response.body, "on the destination recording"
    assert_includes response.body, "No self or descendants"

    get access_docs_path
    assert_response :success
    assert_includes response.body, "Destinations"
    assert_includes response.body, "Where something can be moved in your app"
    assert_includes response.body, "RecordingStudio::Capabilities::Moveable.to"
    assert_includes response.body, "&quot;Workspace&quot;, &quot;RecordingStudioFolder&quot;"
    assert_includes response.body, "Same root only"
    assert_includes response.body, "No self or descendants"

    get setup_docs_path
    assert_response :success
    assert_includes response.body, "Setup"
    assert_includes response.body, "How to mark a recordable model as moveable in your app"
    assert_includes response.body, "include RecordingStudio::Capabilities::Moveable.to"
    assert_includes response.body, "class RecordingStudioPage &lt; ApplicationRecord"
    assert_includes response.body, "class RecordingStudioFolder &lt; ApplicationRecord"

    get methods_docs_path
    assert_response :success
    assert_includes response.body, "Methods"
    assert_includes response.body, "Reference links and helper methods you can use to launch and support the move flow"
    assert_includes response.body, "recording_studio_moveable.move_recording_path(recording_id: recording.id)"
    assert_includes response.body, "recording_studio_moveable_modal_template"
    assert_includes response.body, "move_recording_modal_path"
    assert_includes response.body, 'link_to &quot;Move&quot;, recording_studio_moveable.move_recording_path(recording_id: recording.id)'

    get redirects_docs_path
    assert_response :success
    assert_includes response.body, "Redirects"
    assert_includes response.body, "How move redirects work in this demo"
    assert_includes response.body, "default_redirect_mode = :moved_record"
    assert_includes response.body, "previous_page"
    assert_includes response.body, "destination"
  end
end