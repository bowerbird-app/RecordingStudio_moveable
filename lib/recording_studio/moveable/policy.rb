# frozen_string_literal: true

module RecordingStudio
  module Moveable
    class Policy
      attr_reader :actor, :source, :impersonator, :metadata

      def initialize(actor:, source:, impersonator: nil, metadata: {})
        @actor = actor
        @source = source
        @impersonator = impersonator
        @metadata = metadata
      end

      def source_visible?
        source_editable?
      end

      def source_editable?
        return custom_allowed?(destination: source) unless built_in_access?

        decision = hook_decision(destination: source)
        return decision unless decision.nil?

        editable_recording?(source)
      end

      def destination_visible?(destination:)
        destination_selectable?(destination: destination)
      end

      def destination_selectable?(destination:)
        return custom_allowed?(destination: destination) unless built_in_access?

        decision = hook_decision(destination: destination)
        return decision unless decision.nil?

        editable_recording?(source) && editable_recording?(destination)
      end

      def filter_visible_destinations(destinations:)
        Array(destinations).select do |destination|
          destination_visible?(destination: destination)
        end
      end

      def authorize_move!(destination:)
        unless built_in_access?
          return true if custom_allowed?(destination: destination)

          raise RecordingStudio::AccessDenied, RecordingStudioMoveable::Copy.t("errors.hook_denied")
        end

        decision = hook_decision(destination: destination)
        return true if decision == true
        raise RecordingStudio::AccessDenied, RecordingStudioMoveable::Copy.t("errors.hook_denied") if decision == false

        built_in_move_allowed!(destination: destination)
      end

      private

      def built_in_move_allowed!(destination:)
        assert_edit_access!(
          recording: source,
          message: RecordingStudioMoveable::Copy.t("errors.source_edit_denied")
        )
        assert_edit_access!(
          recording: destination,
          message: RecordingStudioMoveable::Copy.t("errors.destination_edit_denied")
        )
      end

      def assert_edit_access!(recording:, message:)
        return if editable_recording?(recording)

        raise RecordingStudio::AccessDenied, message
      end

      def editable_recording?(recording)
        RecordingStudio::Moveable::Access.allowed?(actor: actor, recording: recording, role: :edit)
      end

      def built_in_access?
        RecordingStudio::Moveable.configuration.use_builtin_access
      end

      def custom_allowed?(destination:)
        RecordingStudio::Moveable.configuration.authorize_move?(
          actor: actor,
          source: source,
          destination: destination,
          impersonator: impersonator,
          metadata: metadata
        )
      end

      def hook_decision(destination:)
        return nil unless RecordingStudio::Moveable.configuration.authorization_hook_set?

        result = custom_allowed?(destination: destination)
        return true if result == true
        return false if result == false

        nil
      end
    end
  end
end
