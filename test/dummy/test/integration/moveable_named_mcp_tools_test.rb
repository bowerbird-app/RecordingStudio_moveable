# frozen_string_literal: true

require_relative "../test_helper"

class MoveableNamedMcpToolsTest < ActionDispatch::IntegrationTest
  def setup
    super

    clear_api_records!
    @owner = create_user
    @workspace, @root = create_workspace_root(actor: @owner)
    grant_root_access(root: @root, actor: @owner, role: :admin)
    @source = @root.record(RecordingStudioFolder, actor: @owner, parent_recording: @root) do |folder|
      folder.name = "MCP source"
    end
    @destination = @root.record(RecordingStudioFolder, actor: @owner, parent_recording: @root) do |folder|
      folder.name = "MCP destination"
    end
    @page = @root.record(RecordingStudioPage, actor: @owner, parent_recording: @source) do |page|
      page.title = "MCP page"
    end
    @edit_token = issue_access_token(role: :edit)
    @view_token = issue_access_token(role: :view)
  end

  def teardown
    clear_api_records!
  end

  test "named move is listed and capability_action is not" do
    listed = rpc(@edit_token, "tools/list")
    tools = listed.dig("result", "tools")
    flunk listed.to_json if tools.nil?

    by_name = tools.to_h { |tool| [tool.fetch("name"), tool] }

    assert by_name.key?("move"), by_name.keys.sort.inspect
    refute by_name.key?("capability_action")

    move = by_name.fetch("move")
    properties = move.fetch("inputSchema").fetch("properties")

    %w[id type destination_id parent_id new_parent_id].each do |field|
      assert properties.key?(field), field
    end
    assert_includes move.fetch("description"), "destination_id"
    assert_includes move.fetch("description"), "allow_cross_root"
    refute_match(/\bedit\b|\bview\b|\bAdmin\b/, move.fetch("description"))
  end

  test "move through the named tool relocates the record for an editor" do
    moved = rpc(@edit_token, "tools/call", name: "move", arguments: move_arguments)

    refute moved.dig("result", "isError"), moved.to_json
    assert_equal @destination.id, @page.reload.parent_recording_id
    assert_equal @destination.id, payload(moved).fetch("parent_id")
  end

  test "move through the named tool leaves the record when the token cannot edit" do
    original_parent_id = @page.parent_recording_id
    denied = rpc(@view_token, "tools/call", name: "move", arguments: move_arguments)

    assert denied.dig("result", "isError"), denied.to_json
    refute_includes denied.dig("result", "content", 0, "text").to_s, "Unknown type"
    assert_equal original_parent_id, @page.reload.parent_recording_id
  end

  private

  def move_arguments
    {
      type: "RecordingStudioPage",
      id: @page.id,
      destination_id: @destination.id
    }
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

  def payload(body)
    structured = body.dig("result", "structuredContent")
    return structured if structured.is_a?(Hash) && structured["id"]

    JSON.parse(body.dig("result", "content", 0, "text").to_s)
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
end
