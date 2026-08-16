# frozen_string_literal: true

require_relative "../test_helper"

class MoveableApiActionsTest < ActionDispatch::IntegrationTest
  def setup
    super
    clear_api_records!

    @user = create_user(email: "move-api@example.com")
    @workspace, @root = create_workspace_root
    grant_root_access(root: @root, actor: @user, role: :admin)

    @source_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) do |folder|
      folder.name = "Move source"
    end
    @target_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) do |folder|
      folder.name = "Move target"
    end
    @child_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @source_folder) do |folder|
      folder.name = "Move child"
    end
    @page = @root.record(RecordingStudioPage, actor: @user, parent_recording: @source_folder) do |page|
      page.title = "Move page"
    end
    @archive_box = @root.record(RecordingStudioArchiveBox, actor: @user, parent_recording: @root) do |archive_box|
      archive_box.name = "Archive destination"
    end
    @headers = { "Authorization" => "Bearer " + issue_access_token }
  end

  def teardown
    clear_api_records!
  end

  def test_move_endpoint_moves_recording_and_returns_serialized_result
    post move_action_path(@page), params: { parent_id: @target_folder.id }, headers: @headers

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal @page.id, payload.fetch("id")
    assert_equal @target_folder.id, payload.fetch("parent_id")
    assert_equal "Move page", payload.fetch("title")
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end

  def test_move_endpoint_rejects_unknown_input_and_preserves_parent
    original_parent_id = @page.parent_recording_id

    post move_action_path(@page),
         params: { parent_id: @target_folder.id, unapproved: "value" },
         headers: @headers

    assert_response :unprocessable_entity
    error = JSON.parse(response.body).fetch("error")
    assert_equal "invalid_input", error.fetch("code")
    assert_equal "Invalid input for action move", error.fetch("message")
    assert_includes error.fetch("details"), "Unknown parameters: unapproved"
    assert_equal original_parent_id, @page.reload.parent_recording_id
  end

  def test_move_endpoint_returns_422_for_self_and_preserves_parent
    original_parent_id = @source_folder.parent_recording_id

    post move_action_path(@source_folder), params: { parent_id: @source_folder.id }, headers: @headers

    assert_response :unprocessable_entity
    error = JSON.parse(response.body).fetch("error")
    assert_equal "invalid_input", error.fetch("code")
    assert_equal "Cannot move a recording under itself", error.fetch("message")
    assert_equal ["Cannot move a recording under itself"], error.fetch("details")
    assert_equal original_parent_id, @source_folder.reload.parent_recording_id
  end

  def test_move_endpoint_returns_422_for_descendant_and_preserves_parent
    original_parent_id = @source_folder.parent_recording_id

    post move_action_path(@source_folder), params: { parent_id: @child_folder.id }, headers: @headers

    assert_response :unprocessable_entity
    assert_equal "Cannot move a recording under its descendant",
                 JSON.parse(response.body).dig("error", "message")
    assert_equal original_parent_id, @source_folder.reload.parent_recording_id
  end

  def test_move_endpoint_returns_422_for_invalid_parent_and_preserves_parent
    original_parent_id = @page.parent_recording_id

    post move_action_path(@page), params: { parent_id: @archive_box.id }, headers: @headers

    assert_response :unprocessable_entity
    assert_match(/cannot be recorded under/, JSON.parse(response.body).dig("error", "message"))
    assert_equal original_parent_id, @page.reload.parent_recording_id
  end

  def test_move_endpoint_returns_403_for_move_policy_denial_and_preserves_parent
    original_parent_id = @source_folder.parent_recording_id
    RecordingStudio::Moveable.configure do |config|
      config.use_builtin_access = false
      config.authorization_hook = ->(**) { false }
    end

    post move_action_path(@source_folder), params: { parent_id: @target_folder.id }, headers: @headers

    assert_response :forbidden
    error = JSON.parse(response.body).fetch("error")
    assert_equal "forbidden", error.fetch("code")
    assert_equal "Move authorization hook denied this move", error.fetch("message")
    assert_equal original_parent_id, @source_folder.reload.parent_recording_id
  end

  private

  def issue_access_token
    provision_result = RecordingStudioApi::Services::ProvisionApiClient.call(
      access_point_recording: @root,
      manager_actor: @user,
      role: :edit,
      name: "Move API integration test"
    )
    raise provision_result.error unless provision_result.success?

    payload = provision_result.value
    token_result = RecordingStudioApi::Services::IssueOauthAccessToken.call(
      grant_type: "client_credentials",
      client_id: payload.fetch(:credential).oauth_client_id,
      client_secret: payload.fetch(:token)
    )
    raise token_result.error unless token_result.success?

    token_result.value.fetch(:access_token)
  end

  def move_action_path(recording)
    resource = RecordingStudioApi.resource_name_for(recording.recordable_type)
    "/recording_studio_api/api/v1/#{resource}/#{recording.id}/actions/move"
  end

  def clear_api_records!
    RecordingStudioApi::ApiAccessToken.delete_all
    RecordingStudioApi::ApiCredential.delete_all
    RecordingStudioApi::ApiClient.delete_all
  end
end
