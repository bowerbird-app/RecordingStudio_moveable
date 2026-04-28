# frozen_string_literal: true

require "recording_studio_accessible"

dummy_access_authorizer = lambda do |recording:, actor:, **|
  next false if actor.blank? || recording.blank?

  root_recording = recording.root_recording || recording
  root_access_recordings = RecordingStudioAccessible::DirectAccessQuery.access_recordings_for(root_recording)
  next true if root_access_recordings.none?

  RecordingStudioAccessible::DirectAccessQuery.access_recordings_for_actor(recording: root_recording, actor: actor)
                           .any? { |access_recording| access_recording.recordable.role.to_sym == :admin }
end

RecordingStudioAccessible.configure do |config|
  config.access_management_authorizer = dummy_access_authorizer
  config.mounted_page_authorizer = dummy_access_authorizer
end
