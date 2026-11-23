# frozen_string_literal: true

require "test_helper"

class McpCopyTest < Minitest::Test
  FORBIDDEN = [
    "RecordingStudio::", "Access", "Accessible", "edit", "view", "permission", "role", "Admin"
  ].freeze

  def test_tool_names_are_empty_until_mcp_is_loaded
    refute defined?(RecordingStudioMcp)

    assert_empty RecordingStudioMoveable::McpCopy.tool_names
    refute_includes RecordingStudioMoveable::McpCopy.tool_names, "move"
  end

  def test_register_is_a_no_op_when_mcp_is_not_loaded
    refute defined?(RecordingStudioMcp)
    before = RecordingStudio.configuration.enabled_recordable_types_for(:movable)

    assert_nil RecordingStudioMoveable::McpCopy.register!
    assert_equal before, RecordingStudio.configuration.enabled_recordable_types_for(:movable)
  end

  def test_description_states_move_prerequisites_without_a_role
    description = RecordingStudioMoveable::McpCopy::DESCRIPTION
    assert_equal 1, description.scan("Move this record").size

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

  def test_mcp_copy_is_separate_from_the_api_copy
    inputs = RecordingStudioMoveable::McpCopy::INPUT
    copy = RecordingStudio::Moveable::Api::OpenapiCopy

    assert_equal :move, RecordingStudioMoveable::McpCopy::ACTION
    assert_equal %w[destination_id id new_parent_id parent_id], inputs.keys.sort
    refute_equal copy::DESCRIPTION, RecordingStudioMoveable::McpCopy::DESCRIPTION
    refute_equal copy::PATH_ID, inputs.fetch("id").fetch(:description)
    refute_equal copy::DESTINATION_ID, inputs.fetch("destination_id").fetch(:description)
    refute_equal copy::PARENT_ID, inputs.fetch("parent_id").fetch(:description)
    refute_equal copy::NEW_PARENT_ID, inputs.fetch("new_parent_id").fetch(:description)
    refute_equal copy::DOCUMENT.dig(:responses, "200", :description), RecordingStudioMoveable::McpCopy::OUTPUT
    refute_includes copy::DESCRIPTION, "list or show"
    assert_includes RecordingStudioMoveable::McpCopy::DESCRIPTION, "list or show"
    assert_equal "Move a record", copy::SUMMARY
    assert_includes copy::DESCRIPTION, "POST"
    %w[200 403 404 409 422].each do |status|
      refute_empty copy::DOCUMENT.dig(:responses, status, :description)
    end
  end

  def test_the_published_gem_does_not_depend_on_mcp
    spec = Gem.loaded_specs.fetch("recording_studio_moveable")

    refute(spec.dependencies.any? { |dependency| dependency.name == "recording_studio_mcp" })
    assert_nil RecordingStudioMoveable::McpCopy.register!
  end
end
