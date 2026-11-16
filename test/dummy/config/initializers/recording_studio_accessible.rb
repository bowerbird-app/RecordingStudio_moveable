# frozen_string_literal: true

require "recording_studio_accessible"

RecordingStudioAccessible.configure do |config|
  # Accessible 0.5+ fails closed for new grants unless actor types are allowlisted.
  config.access_actor_types = ["User"]

  # Mounted Accessible pages allow an admin on the Studio Workspace root.
  config.admin_root_resolver = lambda do
    workspace = Workspace.find_by(name: "Studio Workspace")
    next unless workspace

    RecordingStudio.root_recording_for(workspace)
  end
end
