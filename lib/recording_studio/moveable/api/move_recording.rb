# frozen_string_literal: true

module RecordingStudio
  module Moveable
    module Api
      class MoveRecording
        MOVE_CONFLICT_MESSAGES = [
          "Cannot move a recording under itself",
          "Cannot move a recording under its descendant",
          "Destination must belong to this root recording"
        ].freeze

        def self.call(context)
          new(context).call
        end

        def initialize(context)
          @context = context
        end

        def call
          destination = find_destination!
          ensure_move_supported!

          authorize_move!(destination)
          move!(destination)
        end

        private

        attr_reader :context

        def authorize_move!(destination)
          context.access_grant.authorize!(recording: context.recording, role: :edit)
          context.access_grant.authorize!(recording: destination, role: :edit)
        end

        def move!(destination)
          perform_move!(destination)
        rescue RecordingStudio::AccessDenied => e
          raise RecordingStudioApi::AuthorizationError, e.message
        rescue RecordingStudio::InvalidParent, RecordingStudio::CapabilityDisabled => e
          raise domain_move_error(e)
        rescue ArgumentError => e
          raise unless known_move_conflict?(e)

          raise invalid_move_input_error(e)
        end

        def perform_move!(destination)
          context.recording.move_to!(
            new_parent: destination,
            actor: context.api_client,
            metadata: move_metadata
          )
          context.recording.reload
        end

        def find_destination!
          destination_id = destination_id_from_params
          raise RecordingStudioApi::UnsupportedActionError, "parent_id is required for move" if destination_id.blank?

          destination = context.access_grant.accessible_recordings.find_by(id: destination_id)
          return destination if destination

          raise RecordingStudioApi::NotFoundError, "Destination recording was not found in this API scope"
        end

        def destination_id_from_params
          %i[parent_id destination_id new_parent_id].filter_map do |key|
            parameter_value(key).presence
          end.first
        end

        def parameter_value(key)
          return unless context.params.respond_to?(:[])

          context.params[key].presence || context.params[key.to_s]
        end

        def ensure_move_supported!
          return if context.recording.respond_to?(:move_to!)

          raise RecordingStudioApi::UnsupportedActionError,
                "Move is not supported for #{context.recording.recordable_type}"
        end

        def move_metadata
          {
            api_action: "move",
            api_client_id: context.api_client.id,
            api_credential_id: context.credential.id
          }
        end

        def known_move_conflict?(error)
          MOVE_CONFLICT_MESSAGES.include?(error.message)
        end

        def invalid_move_input_error(error)
          RecordingStudioApi::InvalidActionInputError.new(error.message, details: [error.message])
        end

        def domain_move_error(error)
          return invalid_move_input_error(error) if error.is_a?(RecordingStudio::InvalidParent)

          RecordingStudioApi::UnsupportedActionError.new(error.message)
        end
      end
    end
  end
end
