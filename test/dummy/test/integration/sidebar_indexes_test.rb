# frozen_string_literal: true

require_relative "../test_helper"

class SidebarIndexesTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = create_user(email: "sidebar@example.com")
    bootstrap_demo_for(@user)
    sign_in @user
  end

  def test_sidebar_links_render_remaining_navigation
    get root_path

    assert_response :success
    assert_not_includes response.body, "Recordings"
    assert_not_includes response.body, "Folder Recordables"
    assert_not_includes response.body, "Pages Recordables"
    assert_includes response.body, "Events"
    assert_includes response.body, "Data"
    assert_includes response.body, "Recordables"
    assert_not_includes response.body, "Moveable Docs"
    assert_includes response.body, "Destinations"
    assert_includes response.body, "Setup"
    assert_includes response.body, "Methods"
    assert_includes response.body, "Redirects"
    assert_includes response.body, "API action"

    get events_path
    assert_response :success
    assert_includes response.body, "Events"
    assert_includes response.body, "created"

    get data_path
    assert_response :success
    assert_includes response.body, "Data"
    assert_includes response.body, "Workspaces"
    assert_includes response.body, "Access"
    assert_includes response.body, "Folders"
    assert_includes response.body, "Parent"
    assert_includes response.body, "Pages"
    assert_includes response.body, "Mix Prep"
    assert_includes response.body, "Users"
    assert_includes response.body, "Archive Boxes"
    assert_includes response.body, "Studio Workspace"
    assert_includes response.body, "Client Workspace"
    assert_includes response.body, "Restricted Workspace"
    assert_includes response.body, "Songwriting"
    assert_includes response.body, "Lyric Draft"
    assert_includes response.body, "sidebar@example.com"
    assert_includes response.body, "No users"
    assert_includes response.body, "Archive Box A"

    get recordables_path
    assert_response :success
    assert_includes response.body, "Recordables"
    assert_includes response.body, "Workspace"
    assert_includes response.body, "Folder"
    assert_includes response.body, "Page"
    assert_includes response.body, "Archive box"

    get access_docs_path
    assert_response :success
    assert_includes response.body, "Destinations"
    assert_includes response.body, "Where something can be moved in your app"
    assert_includes response.body, "RecordingStudio::Capabilities::Moveable.enabled"
    assert_includes response.body, "allow_cross_root: true"
    assert_includes response.body, "Same root by default"
    assert_includes response.body, "No self or descendants"

    get setup_docs_path
    assert_response :success
    assert_includes response.body, "Setup"
    assert_includes response.body, "How to mark a recordable model as moveable in your app"
    assert_includes response.body, "include RecordingStudio::Capabilities::Moveable.enabled"
    assert_includes response.body, "class RecordingStudioPage &lt; ApplicationRecord"
    assert_includes response.body, "class RecordingStudioFolder &lt; ApplicationRecord"

    get methods_docs_path
    assert_response :success
    assert_includes response.body, "Methods"
    assert_includes response.body, "Reference links and helper methods you can use to launch and support the move flow"
    assert_includes response.body, "recording_studio_moveable.move_recording_path(recording_id: recording.id)"
    assert_includes response.body, "recording_studio_moveable_modal_template"
    assert_includes response.body, "move_recording_modal_path"
    assert_includes response.body, "link_to &quot;Move&quot;, recording_studio_moveable.move_recording_path(recording_id: recording.id)"

    get redirects_docs_path
    assert_response :success
    assert_includes response.body, "Redirects"
    assert_includes response.body, "How move redirects work in this demo"
    assert_includes response.body, "default_redirect_mode = :moved_record"
    assert_includes response.body, "previous_page"
    assert_includes response.body, "destination"

    get api_docs_path
    assert_response :success
    assert_includes response.body, "API action"
    assert_includes response.body, "Enable the action"
    assert_includes response.body, "include RecordingStudio::Capabilities::Moveable.enabled"
    assert_includes response.body, "api.use :moveable"
    assert_includes response.body, "capability_actions: %i[move]"
    assert_includes response.body, "Choose the API surface"
    assert_includes response.body, "Public and named APIs have separate action"
    assert_includes response.body, "Request requirements"
    assert_includes response.body, "A successful move returns the reloaded recording"
    assert_includes response.body, "/actions/move"
    assert_includes response.body, "API docs"
    assert_includes response.body, "/recording_studio_api/docs/scalar"
    assert_includes response.body, 'data-turbo="false"'
    assert_match(/API action.*API docs.*Enable the action/m, response.body)
    assert_match(/button-primary-background-color.*API docs/m, response.body)
    assert_includes response.body, "RecordingStudioApi capability-backed action contract"

    get moveable_api_scalar_docs_version_path(version: "v1")
    assert_response :success
    assert_includes response.body, "Interactive API explorer"
    assert_includes response.body, 'id="scalar-api-reference"'
    assert_includes response.body, "recording_studio_api/scalar-1.64.0"
    assert_includes response.body, moveable_api_scalar_docs_openapi_path(version: "v1")

    get moveable_api_scalar_docs_openapi_path(version: "v1")
    assert_response :success
    openapi_paths = JSON.parse(response.body).fetch("paths")
    folder_move = openapi_paths.fetch(
      "/recording_studio_api/api/v1/recording_studio_folders/{id}/actions/move"
    ).fetch("post")
    page_move = openapi_paths.fetch(
      "/recording_studio_api/api/v1/recording_studio_pages/{id}/actions/move"
    ).fetch("post")
    assert_equal ["Recording Studio Folder"], folder_move.fetch("tags")
    assert_equal ["Recording Studio Page"], page_move.fetch("tags")
    request_properties = page_move.dig("requestBody", "content", "application/json", "schema", "properties")
    assert_equal %w[destination_id new_parent_id parent_id], request_properties.keys.sort
    refute_includes request_properties, "api_key"
    refute_includes request_properties, "api_version"
    refute_includes openapi_paths.values.flat_map(&:values).flat_map { |operation| operation.fetch("tags", []) },
                    "Moveable"

    get "/docs/moveable"
    assert_response :not_found
  end
end
