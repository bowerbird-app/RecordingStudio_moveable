# frozen_string_literal: true

require "recording_studio/moveable/api/move_tool_copy"

module RecordingStudioMoveable
  module McpCopy
    TOOL_NAME = "move"
    ACTION = :move
    ApiCopy = RecordingStudio::Moveable::Api

    DESCRIPTION =
      "Move this record under a different parent so it sits somewhere else in the tree. The record " \
      "keeps its content. Its children stay under it. Pass id for the record to move. Take that id " \
      "from list or show. Pass destination_id, the new parent's recording id. parent_id and " \
      "new_parent_id are aliases of destination_id. Send one of the three. If you send more than one, " \
      "the tool uses parent_id, then destination_id, then new_parent_id. The destination must already " \
      "exist. Its type must be an allowed parent type for this record. It must be in the same root " \
      "unless this recordable opts into allow_cross_root. The destination cannot be the record itself " \
      "or a descendant. The result matches show for this type. It includes id, type, parent_id, " \
      "root_id, created_at, updated_at, and this type's own fields. parent_id in the result is the " \
      "destination's recording id."

    INPUT = {
      "id" => { description: ApiCopy::PATH_ID_DESCRIPTION },
      "type" => { description: "Record type for the record to move. Use the type from list or show." },
      "parent_id" => { description: ApiCopy::PARENT_ID_DESCRIPTION }
    }.freeze

    OUTPUT = ApiCopy::MOVE_OPENAPI.dig(:responses, "200", :description).freeze

    module_function

    def tool_names
      [TOOL_NAME]
    end

    def register!
      return unless defined?(::RecordingStudioMcp)
      return unless ::RecordingStudioMcp.respond_to?(:register_tool)

      ::RecordingStudioMcp.register_tool(
        name: TOOL_NAME,
        action: ACTION,
        title: "Move",
        description: DESCRIPTION,
        input: INPUT,
        output: OUTPUT
      )
    end
  end
end
