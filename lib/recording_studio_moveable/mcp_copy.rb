# frozen_string_literal: true

module RecordingStudioMoveable
  module McpCopy
    ACTION = :move

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

    ID_DESCRIPTION =
      "Recording id of the record to move. Take it from that record's id on a list or show result. " \
      "This is not the new parent."
    DESTINATION_ID_DESCRIPTION =
      "Recording id of the new parent. Send this field. Take the id from the destination record on a " \
      "list or show result. parent_id and new_parent_id are aliases."
    PARENT_ID_DESCRIPTION =
      "Alias of destination_id. Recording id of the new parent. If this is present, the tool uses it " \
      "before destination_id."
    NEW_PARENT_ID_DESCRIPTION =
      "Alias of destination_id. Recording id of the new parent. The tool uses it only when " \
      "destination_id and parent_id are blank."
    INPUT = {
      "id" => { description: ID_DESCRIPTION },
      "destination_id" => { description: DESTINATION_ID_DESCRIPTION },
      "parent_id" => { description: PARENT_ID_DESCRIPTION },
      "new_parent_id" => { description: NEW_PARENT_ID_DESCRIPTION }
    }.freeze

    OUTPUT =
      "Moved record as the same result as show. Includes id, type, parent_id, root_id, created_at, " \
      "updated_at, and this type's own fields. parent_id is the new parent."

    module_function

    def tool_names
      return [] unless defined?(::RecordingStudioMcp)

      movable_types.map { |type_name| ::RecordingStudioMcp::ToolName.call(type_name, ACTION) }
    end

    def register!
      return unless defined?(::RecordingStudioMcp)
      return unless ::RecordingStudioMcp.respond_to?(:register_tool)

      movable_types.each { |type_name| register_type_tool(type_name) }
      nil
    end

    def register_type_tool(type_name)
      ::RecordingStudioMcp.register_tool(
        name: ::RecordingStudioMcp::ToolName.call(type_name, ACTION),
        type: type_name.to_s,
        action: ACTION,
        title: "Move",
        description: description_for,
        input: INPUT,
        output: OUTPUT
      )
    end

    def description_for
      "Move this record. #{DESCRIPTION}"
    end

    def movable_types
      RecordingStudio.configuration.enabled_recordable_types_for(:movable)
    end
  end
end
