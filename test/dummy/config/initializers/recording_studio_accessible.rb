# frozen_string_literal: true

require "recording_studio_accessible"

dummy_access_authorizer = lambda do |recording:, actor:, **|
  next false if actor.blank? || recording.blank?

  root_recording = recording.root_recording || recording
  root_access_recordings = RecordingStudioAccessible.access_recordings_for(root_recording)
  next true if root_access_recordings.none?

  RecordingStudioAccessible.access_recordings_for_actor(recording: root_recording, actor: actor)
                           .any? { |access_recording| access_recording.recordable.role.to_sym == :admin }
end

RecordingStudioAccessible.configure do |config|
  # Accessible 0.5+ fails closed for new grants unless actor types are allowlisted.
  config.access_actor_types = ["User"]

  config.access_management_authorizer = dummy_access_authorizer
  config.mounted_page_authorizer = dummy_access_authorizer
end
