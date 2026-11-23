# frozen_string_literal: true

return unless defined?(RecordingStudioMcp)

RecordingStudioMcp.configure do |config|
  config.mcp_mount_path = "/recording_studio_mcp"
  config.oauth_protected_resource_path = "/.well-known/oauth-protected-resource/recording_studio_mcp"
  config.oauth_engine_mount_path = "/recording_studio_oauth"
end

%w[RecordingStudioPage RecordingStudioFolder].each do |type|
  RecordingStudioMcp.register_type(
    type: type,
    description: "A #{type.demodulize.downcase} in the tree. Pass its public type name when you move it."
  )
end

Rails.application.config.to_prepare do
  RecordingStudioMcp.register_server(:public, api: :public) do
    include_tools(:list, :show, *RecordingStudioMoveable::McpCopy.tool_names)
  end
end
