# frozen_string_literal: true

module RecordingStudio
  module Moveable
    module Api
      PATH_ID_DESCRIPTION =
        "Recording id of the record to move. Take it from that record's id on a list or show result. " \
        "This is not the new parent."
      DESTINATION_ID_DESCRIPTION =
        "Recording id of the new parent. Send this field. Take the id from the destination record on a " \
        "list or show result. parent_id and new_parent_id are aliases."
      PARENT_ID_DESCRIPTION =
        "Alias of destination_id. Recording id of the new parent. If this is present, the action uses it " \
        "before destination_id."
      NEW_PARENT_ID_DESCRIPTION =
        "Alias of destination_id. Recording id of the new parent. The action uses it only when " \
        "destination_id and parent_id are blank."
      MOVE_DESCRIPTION =
        "Move this record under a different parent. Use it when the record should sit somewhere else in " \
        "the tree. The record keeps its content. Its children stay under it. The path id is the record " \
        "to move. Take that id from the record's id on a list or show result. Pass the new parent's " \
        "recording id as destination_id. Take that id from the destination record's id. parent_id and " \
        "new_parent_id are aliases of destination_id. Send one of the three. If you send more than one, " \
        "the action uses parent_id first, then destination_id, then new_parent_id. You need edit access " \
        "on the record and on the destination. Both records must be visible in this API access. The " \
        "destination type must be an allowed parent type for this record. The destination must be in the " \
        "same root unless this recordable opts into allow_cross_root. The action rejects a destination " \
        "that is the record itself or a descendant. It returns the same resource JSON as show for this " \
        "type. That JSON includes id, type, parent_id, root_id, created_at, updated_at, and this type's " \
        "own fields. parent_id in the response is the destination's recording id. A destination this " \
        "access cannot see returns 404. Missing edit access returns 403. A destination that is the " \
        "record itself, a descendant, a disallowed parent type, or another root without allow_cross_root " \
        "returns 422. A missing destination id also returns 422. If the tree changes while the move " \
        "is locking, the action returns 409. Retry that move."
      MOVE_OPENAPI = {
        summary: "Move",
        description: MOVE_DESCRIPTION,
        parameters: [
          {
            name: "id",
            in: "path",
            required: true,
            description: PATH_ID_DESCRIPTION,
            schema: { type: "string" }
          }
        ],
        responses: {
          "200" => {
            description: "Moved record as the same resource JSON as show. Includes id, type, parent_id, " \
                         "root_id, created_at, updated_at, and this type's own fields. parent_id is the " \
                         "new parent."
          },
          "403" => { description: "Edit access is missing on the record or the destination." },
          "404" => { description: "The destination recording is not in this API access." },
          "409" => { description: "The tree changed while the move was locking. Retry the move." },
          "422" => { description: "The move is invalid, or the destination id is missing." }
        }
      }.freeze
    end
  end
end
