# frozen_string_literal: true

require_relative "../test_helper"

class RecordableDeclarationsTest < ActiveSupport::TestCase
  ACCESS_RECORDABLE_TYPE = [ "RecordingStudio", "Access" ].join("::")

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

  def test_accessible_capability_owns_access_recordable_hierarchy
    RecordingStudio.validate_recordable_declarations!

    declaration = RecordingStudio.recordable_declaration_for(ACCESS_RECORDABLE_TYPE)

    assert declaration
    assert_not declaration.root?
    assert_empty RecordingStudio.declared_allowed_parent_types_for(ACCESS_RECORDABLE_TYPE)
    assert_includes RecordingStudio.capability_child_recordables_for(:accessible), ACCESS_RECORDABLE_TYPE
    assert_equal %w[Workspace], RecordingStudio.capability_allowed_parent_types_for(ACCESS_RECORDABLE_TYPE)
    assert_equal(
      { "recording_studio_accessible" => %w[Workspace] },
      RecordingStudio.recordable_parent_allowances_for(ACCESS_RECORDABLE_TYPE)
    )
  end

  def test_accessible_capability_allows_access_children_only_under_enabled_roots
    _, root = create_workspace_root
    folder = root.record(RecordingStudioFolder, parent_recording: root) { |record| record.name = "Folder" }

    assert RecordingStudio.parent_allowed?(child_type: ACCESS_RECORDABLE_TYPE, parent_recording: root)
    assert_not RecordingStudio.parent_allowed?(child_type: ACCESS_RECORDABLE_TYPE, parent_recording: folder)
  end

  def test_grant_access_uses_accessible_public_api
    _, root = create_workspace_root
    actor = create_user

    access_recording = grant_root_access(root: root, actor: actor, role: :admin)

    assert_equal root, access_recording.parent_recording
    assert RecordingStudioAccessible.authorized?(actor: actor, recording: root, role: :edit)
  end

  def test_workspace_roots_are_created_through_core_root_controls
    workspace, root = create_workspace_root

    assert_equal workspace, root.recordable
    assert RecordingStudio.root_recording?(root)
  end
end
