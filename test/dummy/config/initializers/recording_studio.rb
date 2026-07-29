# frozen_string_literal: true

RecordingStudio.configure do |config|
  # Registered delegated_type recordables (strings or classes)
  config.recordable_types = [
    "Workspace",
    "RecordingStudioFolder",
    "RecordingStudioPage",
    "RecordingStudioArchiveBox",
    "RecordingStudioApi::AdminApi"
  ]

  # Actor resolver for events when no actor is explicitly supplied
  config.actor = -> { Current.actor }

  # Emit ActiveSupport::Notifications events
  config.event_notifications_enabled = true

  # Idempotency behavior for log_event!
  config.idempotency_mode = :return_existing # or :raise

  # Recordable duplication strategy for revisions
  config.recordable_dup_strategy = :dup

  # Move behavior in this app comes from recording_studio_moveable addon capability
  # includes on the relevant recordable models.
end

RecordingStudioAccessible::Compatibility.load_missing_constants!(Rails.application)
RecordingStudioAccessible::Compatibility.ensure_recordable_types_registered!
