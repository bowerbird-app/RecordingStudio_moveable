# frozen_string_literal: true

require_relative "../test_helper"

class RootRecordingCreationTest < ActiveSupport::TestCase
  def test_root_recording_for_does_not_create_a_root
    workspace = Workspace.create!(name: "Lookup only")

    assert_nil RecordingStudio.root_recording_for(workspace)
    assert_equal 0, RecordingStudio::Recording.where(recordable: workspace).count
  end

  def test_create_root_recording_requires_an_actor_and_returns_the_same_root
    actor = create_user
    workspace = Workspace.create!(name: "Created root")

    error = assert_raises(RecordingStudio::ActorRequired) do
      RecordingStudio.create_root_recording!(workspace)
    end
    assert_match(/actor is required/, error.message)
    assert_nil RecordingStudio.root_recording_for(workspace)

    root = RecordingStudio.create_root_recording!(workspace, actor: actor)

    assert_equal root.id, RecordingStudio.root_recording_for(workspace).id
    created = root.events.find_by!(action: "created")
    assert_equal actor, created.actor
    assert_equal root.id, created.root_recording_id

    again = RecordingStudio.create_root_recording!(workspace, actor: create_user(email: "second-root@example.com"))

    assert_equal root.id, again.id
    assert_equal 1, root.events.where(action: "created").count
  end

  def test_dummy_authorize_write_allows_the_write
    assert_respond_to RecordingStudio.configuration.authorize_write, :call
    assert RecordingStudio.configuration.authorize_write.call(action: "created", recording: nil, actor: nil)
    assert_equal false, RecordingStudio.configuration.allow_unauthorized_writes
  end

  def test_move_still_uses_lock_for_move_return_values
    actor = create_user
    _, source_root = create_workspace_root(actor: actor)
    _, destination_root = create_workspace_root(actor: actor)
    grant_root_access(root: source_root, actor: actor, role: :admin)
    grant_root_access(root: destination_root, actor: actor, role: :admin)
    page = source_root.record(RecordingStudioPage, actor: actor, parent_recording: source_root) { |record| record.title = "Locked page" }
    destination = destination_root.record(RecordingStudioFolder, actor: actor, parent_recording: destination_root) do |folder|
      folder.name = "Locked destination"
    end
    seen = nil
    original = RecordingStudio.method(:lock_for_move!)
    locker = lambda do |recording, to_parent:, to_root:|
      locks = original.call(recording, to_parent: to_parent, to_root: to_root)
      seen = locks.keys
      locks
    end

    RecordingStudio.stub(:lock_for_move!, locker) do
      page.move_to!(new_parent: destination, actor: actor)
    end

    assert_equal %i[recording to_parent to_root source_root descendant_ids], seen
    assert_equal destination.id, page.reload.parent_recording_id
    assert_equal destination_root.id, page.root_recording_id
    assert_equal destination_root.id, page.events.find_by!(action: "moved").root_recording_id
  end
end
