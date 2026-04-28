# frozen_string_literal: true

module RecordingStudio
  module Moveable
    module Access
      ROLE_ORDER = {
        "view" => 0,
        "edit" => 1,
        "admin" => 2
      }.freeze

      class << self
        def allowed?(actor:, recording:, role:)
          require_accessible!

          resolved_role = role_for(actor: actor, recording: recording)
          role_satisfies_requirement?(role: resolved_role, minimum_role: role)
        end

        private

        def require_accessible!
          require "recording_studio_accessible"
        rescue LoadError => e
          raise LoadError, <<~MESSAGE.squish
            RecordingStudio Moveable built-in authorization requires the recording_studio_accessible gem.
            Add `gem "recording_studio_accessible"` to your Gemfile or set
            `RecordingStudio::Moveable.configure { |config| config.use_builtin_access = false }`.
            Original error: #{e.message}
          MESSAGE
        end

        def role_for(actor:, recording:)
          return nil unless actor && recording

          path_recordings = access_path_for(recording)
          roles_by_parent_id = load_roles_by_parent_id(actor: actor, recordings: path_recordings)

          path_recordings.filter_map do |path_recording|
            roles_by_parent_id[path_recording.id]
          end.first
        end

        def access_path_for(recording)
          path_recordings = []
          current = recording

          while current
            path_recordings << current
            current = current.parent_recording
          end

          path_recordings.compact.uniq
        end

        def load_roles_by_parent_id(actor:, recordings:)
          return {} if actor.blank? || recordings.blank?

          RecordingStudioAccessible::DirectAccessQuery.access_recordings_for_actor_in(
            recordings: recordings,
            actor: actor
          ).each_with_object({}) do |access_recording, roles|
            parent_id = access_recording.parent_recording_id
            roles[parent_id] ||= access_recording.recordable&.role
          end
        end

        def role_satisfies_requirement?(role:, minimum_role:)
          role_value = ROLE_ORDER[role&.to_s]
          minimum_value = ROLE_ORDER[minimum_role&.to_s]

          role_value.present? && minimum_value.present? && role_value >= minimum_value
        end
      end
    end
  end
end
