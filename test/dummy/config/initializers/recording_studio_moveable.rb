# frozen_string_literal: true

RecordingStudioMoveable.configure do |config|
  # nil follows RecordingStudio.configuration.layout, then recording_studio/default_layout.
  config.layout = nil
end

RecordingStudio::Moveable.configure do |config|
  # Keep the demo app behavior explicit instead of relying on gem defaults.
  config.default_redirect_mode = :previous_page
  config.default_redirect_path = "/"
end
