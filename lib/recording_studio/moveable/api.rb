# frozen_string_literal: true

require "recording_studio/moveable/api/move_recording"

module RecordingStudio
  module Moveable
    module Api
      ACTION_VERSION = "1.0.0"

      class << self
        def register_capability_action!
          return unless recording_studio_api_available?
          return if RecordingStudioApi.capability_action(:move)

          RecordingStudioApi.register_capability_action(:move, **capability_action_options)
        end

        private

        def capability_action_options
          action_metadata.merge(
            handler: MoveRecording,
            serializer: RecordingStudioApi::Serializers::ResourceRecordingSerializer,
            input_contract: move_input_contract,
            openapi: move_openapi
          )
        end

        def action_metadata
          {
            capability: :movable,
            version: ACTION_VERSION,
            version_notes: ["Moveable-owned move action"],
            http_verb: :post,
            scope: :member,
            required_role: :edit
          }
        end

        def recording_studio_api_available?
          defined?(RecordingStudioApi) &&
            RecordingStudioApi.respond_to?(:capability_action) &&
            RecordingStudioApi.respond_to?(:register_capability_action) &&
            defined?(RecordingStudioApi::Serializers::ResourceRecordingSerializer)
        end

        def move_input_contract
          {
            reject_unknown: true,
            fields: {
              parent_id: { type: :string, allow_blank: false },
              destination_id: { type: :string, allow_blank: false },
              new_parent_id: { type: :string, allow_blank: false }
            }
          }
        end

        def move_openapi
          {
            summary: "Move",
            description: "Moves the recording below an accessible destination recording.",
            responses: {
              "200" => { description: "Recording moved successfully." },
              "403" => { description: "API access is not authorized to move this recording." },
              "422" => { description: "Move request is invalid." }
            }
          }
        end
      end
    end
  end
end
