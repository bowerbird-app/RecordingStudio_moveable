# frozen_string_literal: true

module RecordingStudio
  module Moveable
    module Access
      class << self
        def allowed?(actor:, recording:, role:)
          access_check.allowed?(actor: actor, recording: recording, role: role)
        end

        private

        def access_check
          require "recording_studio_accessible"

          return RecordingStudio::Services::AccessCheck if defined?(RecordingStudio::Services::AccessCheck)

          raise LoadError, "RecordingStudio::Services::AccessCheck is unavailable"
        rescue LoadError => e
          raise LoadError, <<~MESSAGE.squish
            RecordingStudio Moveable built-in authorization requires the recording_studio_accessible gem.
            Add `gem "recording_studio_accessible"` to your Gemfile or set
            `RecordingStudio::Moveable.configure { |config| config.use_builtin_access = false }`.
            Original error: #{e.message}
          MESSAGE
        end
      end
    end
  end
end
