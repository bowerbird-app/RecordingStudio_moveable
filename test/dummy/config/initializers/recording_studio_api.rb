# frozen_string_literal: true

# The dummy provisions public API clients without an Admin API ACL.
RecordingStudioApi.configure do |config|
  config.api_management_authorization_required = false
end

RecordingStudioApi.register_recordable_type_api(
  "RecordingStudioPage",
  capability_actions: %i[move]
)

RecordingStudioApi.register_recordable_type_api(
  "RecordingStudioFolder",
  capability_actions: %i[move]
)

# API controllers inherit ActionController::API. The API engine applies controller
# extensions only to ActionController::Base descendants, so the move conflict rescue
# never lands. Load the controller and apply the extension Moveable already registered.
Rails.application.config.to_prepare do
  controller = RecordingStudioApi::ApiController
  RecordingStudioApi::Engine.apply_controller_extensions(controller)
end
