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
      movable_type_names.map { |type_name| tool_name_for(type_name) }
    end

    def tool_name_for(type_name)
      "move_#{tool_token(public_type_name(type_name))}"
    end

    def register!
      return unless defined?(::RecordingStudioMcp)
      return unless ::RecordingStudioMcp.respond_to?(:register_tool)

      movable_type_names.each { |type_name| register_type_tool(type_name) }
      nil
    end

    def register_type_tool(type_name)
      public_name = public_type_name(type_name)
      ::RecordingStudioMcp.register_tool(
        name: tool_name_for(type_name),
        type: type_name.to_s,
        action: ACTION,
        title: "Move #{public_name}",
        description: description_for(public_name),
        input: INPUT,
        output: OUTPUT
      )
    end

    def description_for(public_name)
      "Move this #{public_name} record. #{DESCRIPTION}"
    end

    def public_type_name(type_name)
      strip_namespace(api_public_name(type_name).presence || type_name)
    end

    def strip_namespace(type_name)
      demodulized = type_name.to_s.demodulize
      stripped = demodulized.sub(/\ARecordingStudio/, "")
      stripped.presence || demodulized
    end

    def tool_token(public_name)
      public_name.to_s.demodulize.gsub(/[^A-Za-z0-9]/, "").downcase
    end

    def movable_type_names
      return [] unless defined?(RecordingStudio)
      return [] unless RecordingStudio.respond_to?(:capability_enabled?)
      return [] unless RecordingStudio.respond_to?(:configuration)

      names = Array(RecordingStudio.configuration.recordable_types).filter_map { |type| recordable_type_name(type) }
      names.select { |type_name| RecordingStudio.capability_enabled?(:movable, for: type_name) }
    end

    def recordable_type_name(type)
      return type.name if type.respond_to?(:name) && !type.is_a?(String)

      type.to_s
    end

    def api_public_name(type_name)
      return unless defined?(::RecordingStudioApi)
      return unless ::RecordingStudioApi.respond_to?(:recordable_registration_for)

      ::RecordingStudioApi.recordable_registration_for(type_name.to_s)&.public_name
    end
  end
end
