# frozen_string_literal: true

require_relative "../test_helper"

class RecordableDeclarationsTest < ActiveSupport::TestCase
  def test_configured_recordables_declare_core_hierarchy
    RecordingStudio.validate_recordable_declarations!

    assert RecordingStudio.recordable_declaration_defined?("Workspace")
    assert RecordingStudio.recordable_declaration_defined?("RecordingStudioFolder")
    assert RecordingStudio.recordable_declaration_defined?("RecordingStudioPage")
    assert RecordingStudio.recordable_declaration_defined?("RecordingStudioArchiveBox")
  end

  def test_dummy_hierarchy_matches_core_declarations
    assert RecordingStudio.root_allowed?("Workspace")
    assert_not RecordingStudio.root_allowed?("RecordingStudioFolder")
    assert_not RecordingStudio.root_allowed?("RecordingStudioPage")
    assert_not RecordingStudio.root_allowed?("RecordingStudioArchiveBox")

    assert_equal %w[Workspace RecordingStudioFolder], RecordingStudio.allowed_parent_types_for("RecordingStudioFolder")
    assert_equal %w[Workspace RecordingStudioFolder], RecordingStudio.allowed_parent_types_for("RecordingStudioPage")
    assert_equal %w[Workspace], RecordingStudio.allowed_parent_types_for("RecordingStudioArchiveBox")
  end

  def test_workspace_roots_are_created_through_core_root_controls
    workspace, root = create_workspace_root

    assert_equal workspace, root.recordable
    assert RecordingStudio.root_recording?(root)
  end
end
