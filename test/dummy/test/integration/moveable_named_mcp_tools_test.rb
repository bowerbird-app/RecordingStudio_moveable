# frozen_string_literal: true

require_relative "../test_helper"

class MoveableNamedMcpToolsTest < ActionDispatch::IntegrationTest
  def setup
    super

    clear_api_records!
    @owner = create_user
    @workspace, @root = create_workspace_root(actor: @owner)
    grant_root_access(root: @root, actor: @owner, role: :admin)
    _, @other_root = create_workspace_root(actor: @owner)
    grant_root_access(root: @other_root, actor: @owner, role: :admin)
    @source = @root.record(RecordingStudioFolder, actor: @owner, parent_recording: @root) do |folder|
      folder.name = "MCP source"
    end
    @destination = @root.record(RecordingStudioFolder, actor: @owner, parent_recording: @root) do |folder|
      folder.name = "MCP destination"
    end
    @child = @root.record(RecordingStudioFolder, actor: @owner, parent_recording: @source) do |folder|
      folder.name = "MCP child"
    end
    @other_folder = @other_root.record(RecordingStudioFolder, actor: @owner, parent_recording: @other_root) do |folder|
      folder.name = "MCP other root"
    end
    @page = @root.record(RecordingStudioPage, actor: @owner, parent_recording: @source) do |page|
      page.title = "MCP page"
    end
    @archive = @root.record(RecordingStudioArchiveBox, actor: @owner, parent_recording: @root) do |box|
      box.name = "MCP archive"
    end
    @edit_token = issue_access_token(role: :edit)
    @view_token = issue_access_token(role: :view)
  end

  def teardown
    RecordingStudio::Moveable.reset_configuration!
    restore_dummy_moveable_capabilities!
    clear_api_records!
  end

  test "enabled types get move tools and a disabled type does not" do
    names = listed_tool_names

    assert_equal "move_press_kit", RecordingStudioMcp::ToolName.call("PressKit", :move)
    assert_includes names, move_tool("RecordingStudioPage")
    assert_includes names, move_tool("RecordingStudioFolder")
    refute_includes names, "move"
    refute_includes names, move_tool("Workspace")
    refute_includes names, move_tool("RecordingStudioArchiveBox")
    refute_includes names, "capability_action"

    page = listed_tools.fetch(move_tool("RecordingStudioPage"))
    properties = page.fetch("inputSchema").fetch("properties")
    %w[id destination_id parent_id new_parent_id].each do |field|
      assert properties.key?(field), field
    end
    assert_includes page.fetch("description"), "destination_id"
    assert_includes page.fetch("description"), "allow_cross_root"
    refute_match(/\bedit\b|\bview\b|\bAdmin\b/, page.fetch("description"))
  end

  test "an editor moves a page and a view token does not" do
    moved = call_move(move_tool("RecordingStudioPage"), @page, @destination, token: @edit_token)

    refute moved.dig("result", "isError"), moved.to_json
    assert_equal @destination.id, @page.reload.parent_recording_id

    fresh = @root.record(RecordingStudioPage, actor: @owner, parent_recording: @source) do |page|
      page.title = "MCP view page"
    end
    original_parent_id = fresh.parent_recording_id
    denied = call_move(move_tool("RecordingStudioPage"), fresh, @destination, token: @view_token)

    assert denied.dig("result", "isError"), denied.to_json
    assert_equal original_parent_id, fresh.reload.parent_recording_id
  end

  test "the custom authorization hook allows and denies the move" do
    RecordingStudio::Moveable.configure do |config|
      config.use_builtin_access = false
      config.authorization_hook = ->(**) { true }
    end
    allowed = call_move(move_tool("RecordingStudioPage"), @page, @destination, token: @edit_token)

    refute allowed.dig("result", "isError"), allowed.to_json
    assert_equal @destination.id, @page.reload.parent_recording_id

    RecordingStudio::Moveable.configure do |config|
      config.use_builtin_access = false
      config.authorization_hook = ->(**) { false }
    end
    parked = @root.record(RecordingStudioPage, actor: @owner, parent_recording: @source) do |page|
      page.title = "MCP hook page"
    end
    original_parent_id = parked.parent_recording_id
    denied = call_move(move_tool("RecordingStudioPage"), parked, @destination, token: @edit_token)

    assert denied.dig("result", "isError"), denied.to_json
    assert_equal original_parent_id, parked.reload.parent_recording_id
  end

  test "cross-root move follows the actor's grants and allow_cross_root" do
    hidden = call_move(move_tool("RecordingStudioFolder"), @source, @other_folder, token: @edit_token)

    assert hidden.dig("result", "isError"), hidden.to_json
    assert_equal @root.id, @source.reload.parent_recording_id

    outsider = create_user
    granted = RecordingStudioAccessible.grant_access(
      recording: @root,
      actor: outsider,
      role: :edit,
      manager_actor: @owner
    )
    raise granted.error if granted.failure?
    parked = @root.record(RecordingStudioFolder, actor: @owner, parent_recording: @root) do |folder|
      folder.name = "MCP parked"
    end
    parked_parent_id = parked.parent_recording_id

    assert_raises(RecordingStudio::AccessDenied) do
      parked.move_to!(new_parent: @other_folder, actor: outsider)
    end
    assert_equal parked_parent_id, parked.reload.parent_recording_id

    assert RecordingStudioAccessible.authorized?(actor: @owner, recording: @source, role: :edit)
    assert RecordingStudioAccessible.authorized?(actor: @owner, recording: @other_folder, role: :edit)
    @source.move_to!(new_parent: @other_folder, actor: @owner)

    assert_equal @other_folder.id, @source.reload.parent_recording_id
    @source.move_to!(new_parent: @root, actor: @owner)
    disable_cross_root_for(RecordingStudioFolder)
    original_parent_id = @source.reload.parent_recording_id

    error = assert_raises(ArgumentError) do
      @source.move_to!(new_parent: @other_folder, actor: @owner)
    end

    assert_match(/root/, error.message)
    assert_equal original_parent_id, @source.reload.parent_recording_id
  end

  test "self, descendant, and a disallowed parent stay put" do
    assert_rejected move_tool("RecordingStudioFolder"), @source, @source
    assert_rejected move_tool("RecordingStudioFolder"), @source, @child
    assert_rejected move_tool("RecordingStudioPage"), @page, @archive
  end

  private

  def assert_rejected(tool_name, recording, destination)
    original_parent_id = recording.parent_recording_id
    result = call_move(tool_name, recording, destination, token: @edit_token)

    assert result.dig("result", "isError"), result.to_json
    refute_includes result.dig("result", "content", 0, "text").to_s, "Unknown tool"
    assert_equal original_parent_id, recording.reload.parent_recording_id
  end

  def call_move(tool_name, recording, destination, token:)
    rpc(
      token,
      "tools/call",
      name: tool_name,
      arguments: { id: recording.id, destination_id: destination.id }
    )
  end

  def listed_tool_names
    listed_tools.keys
  end

  def listed_tools
    listed = rpc(@edit_token, "tools/list")
    tools = listed.dig("result", "tools")
    flunk listed.to_json if tools.nil?

    tools.to_h { |tool| [tool.fetch("name"), tool] }
  end

  def rpc(token, method, **params)
    post "/recording_studio_mcp",
         params: { jsonrpc: "2.0", id: SecureRandom.random_number(1_000), method: method, params: params }.to_json,
         headers: {
           "Content-Type" => "application/json",
           "Accept" => "application/json",
           "Authorization" => "Bearer #{token}"
         }
    assert_response :success, response.body
    JSON.parse(response.body)
  end

  def issue_access_token(role:)
    provision_result = RecordingStudioApi::Services::ProvisionApiClient.call(
      access_point_recording: @root,
      manager_actor: @owner,
      role: role,
      name: "Move MCP #{role} #{SecureRandom.hex(4)}"
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

  def clear_api_records!
    RecordingStudioApi::ApiAccessToken.delete_all
    RecordingStudioApi::ApiCredential.delete_all
    RecordingStudioApi::ApiClient.delete_all
  end

  def disable_cross_root_for(recordable_type)
    RecordingStudio.set_capability_options(:movable, on: recordable_type.name, allow_cross_root: false)
  end

  def move_tool(type_name)
    RecordingStudioMcp::ToolName.call(type_name, :move)
  end
end
