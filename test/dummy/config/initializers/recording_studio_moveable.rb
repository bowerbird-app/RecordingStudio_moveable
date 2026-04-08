# frozen_string_literal: true

RecordingStudio::Moveable.configure do |config|
  # Keep the demo app behavior explicit instead of relying on gem defaults.
  config.default_redirect_mode = :previous_page
  config.default_redirect_path = "/"
end