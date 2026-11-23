# frozen_string_literal: true

module RecordingStudio
  module Moveable
    module Api
      module OpenapiCopy
        SUMMARY = "Move a record"
        PATH_ID =
          "Path id of the record to move. It names the record in the URL. It is not the new parent."
        DESTINATION_ID =
          "Recording id of the new parent. Put it in the request body. parent_id and new_parent_id are aliases."
        PARENT_ID =
          "Alias of destination_id. Recording id of the new parent. When present, the action reads this " \
          "field before destination_id."
        NEW_PARENT_ID =
          "Alias of destination_id. Recording id of the new parent. The action reads this field only when " \
          "destination_id and parent_id are blank."
        DESCRIPTION =
          "Places the record under a different parent. Call it with POST on the record's move action. " \
          "The record keeps its content. Its children stay under it. The path id is the record to move. " \
          "The body carries destination_id, the new parent's recording id. parent_id and new_parent_id " \
          "are aliases of destination_id. Send one of the three. If the body includes more than one, the " \
          "action reads parent_id, then destination_id, then new_parent_id. The destination must already " \
          "exist. Its type must be an allowed parent type for this record. It must be in the same root " \
          "unless this recordable opts into allow_cross_root. The destination cannot be the record itself " \
          "or a descendant. On success the record's parent_id is the destination's recording id. The " \
          "response body matches show for this type and includes id, type, parent_id, root_id, " \
          "created_at, updated_at, and this type's own fields. A destination the caller cannot find " \
          "returns 404. A refused move returns 403. A destination that is the record itself, a descendant, " \
          "a disallowed parent type, or another root without allow_cross_root returns 422. A missing " \
          "destination id also returns 422. If the tree changes while the move is locking, the action " \
          "returns 409. Retry that request."
        RESPONSE_OK =
          "The record now sits under the destination. The body matches show for this type and includes " \
          "id, type, parent_id, root_id, created_at, updated_at, and this type's own fields. parent_id " \
          "is the new parent."
        RESPONSE_FORBIDDEN = "The move was refused."
        RESPONSE_NOT_FOUND = "The destination recording was not found for this caller."
        RESPONSE_CONFLICT = "The tree changed while the move was locking. Retry the request."
        RESPONSE_INVALID = "The move is invalid, or the destination id is missing."
        DOCUMENT = {
          summary: SUMMARY,
          description: DESCRIPTION,
          parameters: [
            {
              name: "id",
              in: "path",
              required: true,
              description: PATH_ID,
              schema: { type: "string" }
            }
          ],
          responses: {
            "200" => { description: RESPONSE_OK },
            "403" => { description: RESPONSE_FORBIDDEN },
            "404" => { description: RESPONSE_NOT_FOUND },
            "409" => { description: RESPONSE_CONFLICT },
            "422" => { description: RESPONSE_INVALID }
          }
        }.freeze
      end

      PATH_ID_DESCRIPTION = OpenapiCopy::PATH_ID
      DESTINATION_ID_DESCRIPTION = OpenapiCopy::DESTINATION_ID
      PARENT_ID_DESCRIPTION = OpenapiCopy::PARENT_ID
      NEW_PARENT_ID_DESCRIPTION = OpenapiCopy::NEW_PARENT_ID
      MOVE_DESCRIPTION = OpenapiCopy::DESCRIPTION
      MOVE_OPENAPI = OpenapiCopy::DOCUMENT
    end
  end
end
