# frozen_string_literal: true

require_relative "../test_helper"

class AccessibleGrantTest < ActiveSupport::TestCase
  def test_first_admin_grant_uses_bootstrap_and_stores_a_string_role
    _, root = create_workspace_root
    actor = create_user

    access_recording = grant_root_access(root: root, actor: actor, role: :admin)

    assert_equal "admin", access_recording.recordable.role
    assert_equal :admin, RecordingStudioAccessible.role_for(actor: actor, recording: root).to_sym
    assert RecordingStudioAccessible.authorized?(actor: actor, recording: root, role: :edit)
  end

  def test_later_grants_use_grant_access_and_keep_string_roles
    _, root = create_workspace_root
    owner = create_user
    editor = create_user
    grant_root_access(root: root, actor: owner, role: :admin)

    result = RecordingStudioAccessible.grant_access(
      recording: root,
      actor: editor,
      role: :edit,
      manager_actor: owner
    )
    raise result.error if result.failure?

    assert_equal "edit", result.value.recordable.role
    assert_equal :edit, RecordingStudioAccessible.role_for(actor: editor, recording: root).to_sym
    assert RecordingStudioAccessible.authorized?(actor: editor, recording: root, role: :view)
    refute RecordingStudioAccessible.authorized?(actor: editor, recording: root, role: :admin)
  end
end
