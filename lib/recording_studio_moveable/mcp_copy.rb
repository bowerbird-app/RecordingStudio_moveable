# frozen_string_literal: true

require "recording_studio/moveable/api/move_tool_copy"

module RecordingStudioMoveable
  module McpCopy
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
      "destination_id" => { description: ApiCopy::DESTINATION_ID_DESCRIPTION },
      "parent_id" => { description: ApiCopy::PARENT_ID_DESCRIPTION },
      "new_parent_id" => { description: ApiCopy::NEW_PARENT_ID_DESCRIPTION }
    }.freeze

    OUTPUT = ApiCopy::MOVE_OPENAPI.dig(:responses, "200", :description).freeze

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
