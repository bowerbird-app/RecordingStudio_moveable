# frozen_string_literal: true

RecordingStudioMoveable.configure do |config|
  config.full_page_layout = "recording_studio/default_layout"
end

RecordingStudio::Moveable.configure do |config|
  # Keep the demo app behavior explicit instead of relying on gem defaults.
  config.default_redirect_mode = :previous_page
  config.default_redirect_path = "/"
end
