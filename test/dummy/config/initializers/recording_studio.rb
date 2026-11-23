# frozen_string_literal: true

RecordingStudio.configure do |config|
  # Registered delegated_type recordables (strings or classes)
  config.recordable_types = [
    "Workspace",
    "RecordingStudioFolder",
    "RecordingStudioPage",
    "RecordingStudioArchiveBox",
    # Oauth loads Site Settings, which loads Attachable. Those types must be
    # registered or the dummy refuses to boot.
    "RecordingStudioAttachable::Attachment",
    "RecordingStudioSiteSettings::SiteSetting"
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

  # The dummy allows every write. Callers still pass an actor.
  config.authorize_write = lambda { |**|
    true
  }

  # Workspace roots are API access points so the dummy can provision API clients.
  config.enable_capability(:api_access_point, on: "Workspace")
end

RecordingStudioAccessible::Compatibility.load_missing_constants!(Rails.application)
RecordingStudioAccessible::Compatibility.ensure_recordable_types_registered!
