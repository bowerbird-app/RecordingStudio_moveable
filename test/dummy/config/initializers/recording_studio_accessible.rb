# frozen_string_literal: true

require "recording_studio_accessible"

RecordingStudioAccessible.configure do |config|
  # Accessible 0.5+ fails closed for new grants unless actor types are allowlisted.
  config.access_actor_types = ["User"]
end

