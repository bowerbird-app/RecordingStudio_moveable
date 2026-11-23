# frozen_string_literal: true

require "test_helper"

class McpCopyTest < Minitest::Test
  FORBIDDEN = [
    "RecordingStudio::", "Access", "Accessible", "edit", "view", "permission", "role", "Admin"
  ].freeze

  def test_presskit_public_type_is_move_presskit
    assert_equal "move_presskit", RecordingStudioMoveable::McpCopy.tool_name_for("PressKit")
    assert_equal "move_presskit", RecordingStudioMoveable::McpCopy.tool_name_for("RecordingStudio::PressKit")
    assert_equal "move_page", RecordingStudioMoveable::McpCopy.tool_name_for("RecordingStudioPage")
    assert_equal "move_folder", RecordingStudioMoveable::McpCopy.tool_name_for("RecordingStudioFolder")
  end

  def test_tool_names_skip_a_shared_move_tool_when_no_type_is_movable
    assert_empty RecordingStudioMoveable::McpCopy.tool_names
    refute_includes RecordingStudioMoveable::McpCopy.tool_names, "move"
  end

  def test_register_is_a_no_op_when_mcp_is_not_loaded
    refute defined?(RecordingStudioMcp)

    assert_nil RecordingStudioMoveable::McpCopy.register!
  end

  def test_description_states_move_prerequisites_without_a_role
    description = RecordingStudioMoveable::McpCopy.description_for("PressKit")

    assert_includes description, "PressKit"
    assert_includes description, "destination_id"
    assert_includes description, "parent_id"
    assert_includes description, "new_parent_id"
    assert_includes description, "allowed parent type"
    assert_includes description, "same root"
    assert_includes description, "allow_cross_root"
    assert_includes description, "itself"
    assert_includes description, "descendant"
    assert_includes description, "must already exist"
    FORBIDDEN.each { |phrase| refute_includes description, phrase }
  end

  def test_inputs_reuse_the_move_field_descriptions
    inputs = RecordingStudioMoveable::McpCopy::INPUT
    copy = RecordingStudio::Moveable::Api

    assert_equal copy::PATH_ID_DESCRIPTION, inputs.fetch("id").fetch(:description)
    assert_equal copy::DESTINATION_ID_DESCRIPTION, inputs.fetch("destination_id").fetch(:description)
    assert_equal copy::PARENT_ID_DESCRIPTION, inputs.fetch("parent_id").fetch(:description)
    assert_equal copy::NEW_PARENT_ID_DESCRIPTION, inputs.fetch("new_parent_id").fetch(:description)
    assert_equal copy::MOVE_OPENAPI.dig(:responses, "200", :description), RecordingStudioMoveable::McpCopy::OUTPUT
  end

  def test_registration_does_not_enable_movable_or_depend_on_mcp
    root = File.expand_path("..", __dir__)
    gemspec = File.read(File.join(root, "recording_studio_moveable.gemspec"))
    api = File.read(File.join(root, "lib/recording_studio/moveable/api.rb"))
    engine = File.read(File.join(root, "lib/recording_studio_moveable/engine.rb"))
    copy = File.read(File.join(root, "lib/recording_studio_moveable/mcp_copy.rb"))

    refute_includes gemspec, "recording_studio_mcp"
    refute_includes api, 'require "recording_studio_mcp"'
    refute_includes copy, "enable_capability"
    refute_includes copy, 'name: "move"'
    assert_includes api, "RecordingStudioMoveable::McpCopy.register!"
    assert_includes engine, 'initializer "recording_studio_moveable.mcp"'
    assert_includes engine, "config.to_prepare { RecordingStudioMoveable::McpCopy.register! }"
  end
end
