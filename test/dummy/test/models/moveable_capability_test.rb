# frozen_string_literal: true

require_relative "../test_helper"

class MoveableCapabilityTest < ActiveSupport::TestCase
  def setup
    super

    _, @root = create_workspace_root
    @actor = create_user
    grant_root_access(root: @root, actor: @actor, role: :admin)

    @source_folder = @root.record(RecordingStudioFolder, actor: @actor, parent_recording: @root) { |f| f.name = "Source" }
    @target_folder = @root.record(RecordingStudioFolder, actor: @actor, parent_recording: @root) { |f| f.name = "Target" }
    @child_folder = @root.record(RecordingStudioFolder, actor: @actor, parent_recording: @source_folder) { |f| f.name = "Child" }
    @page = @root.record(RecordingStudioPage, actor: @actor, parent_recording: @source_folder) { |p| p.title = "Page" }
    @archive_box = @root.record(RecordingStudioArchiveBox, actor: @actor, parent_recording: @root) { |a| a.name = "Archive" }
  end

  def test_installing_the_gem_does_not_enable_movable_until_included
    refute RecordingStudio.capability_enabled?(:movable, for: Workspace)
    refute RecordingStudio.capability_enabled?(:movable, for: RecordingStudioArchiveBox)
    assert RecordingStudio.capability_enabled?(:movable, for: RecordingStudioFolder)
    assert RecordingStudio.capability_enabled?(:movable, for: RecordingStudioPage)
  end

  def test_move_to_allows_configured_destination_and_logs_metadata
    @page.move_to!(new_parent: @target_folder, actor: @actor, metadata: { "reason" => "reorg" })

    assert_equal @target_folder.id, @page.reload.parent_recording_id
    event = @page.events.first
    assert_equal "moved", event.action
    assert_equal @source_folder.id, event.metadata["from_parent_id"]
    assert_equal @target_folder.id, event.metadata["to_parent_id"]
    assert_equal "reorg", event.metadata["reason"]
  end

  def test_move_to_blocks_disallowed_destination_type
    error = assert_raises(RecordingStudio::InvalidParent) do
      @page.move_to!(new_parent: @archive_box, actor: @actor)
    end

    assert_match(/RecordingStudioPage cannot be recorded under RecordingStudioArchiveBox/, error.message)
  end

  def test_move_to_blocks_cross_root_moves
    disable_cross_root_for(RecordingStudioPage)

    _, other_root = create_workspace_root
    other_parent = other_root.record(RecordingStudioFolder, actor: @actor, parent_recording: other_root) { |f| f.name = "Other" }

    error = assert_raises(ArgumentError) do
      @page.move_to!(new_parent: other_parent, actor: @actor)
    end

    assert_match(/must belong to this root recording/, error.message)
  end

  def test_move_to_can_transfer_a_subtree_across_roots_when_enabled
    enable_cross_root_for(RecordingStudioFolder)

    _, other_root = create_workspace_root
    grant_root_access(root: other_root, actor: @actor, role: :admin)
    other_parent = other_root.record(RecordingStudioFolder, actor: @actor, parent_recording: other_root) { |f| f.name = "Other" }

    @source_folder.move_to!(new_parent: other_parent, actor: @actor, metadata: { "reason" => "workspace transfer" })

    assert_equal other_parent.id, @source_folder.reload.parent_recording_id
    assert_equal other_root.id, @source_folder.root_recording_id
    assert_equal other_root.id, @child_folder.reload.root_recording_id
    assert_equal other_root.id, @page.reload.root_recording_id

    event = @source_folder.events.find_by!(action: "moved")
    assert_equal @root.id, event.metadata["from_root_id"]
    assert_equal other_root.id, event.metadata["to_root_id"]
    assert_equal "workspace transfer", event.metadata["reason"]
    assert_equal other_root.id, event.root_recording_id
    [@child_folder, @page].each do |descendant|
      descendant.events.each do |descendant_event|
        assert_equal other_root.id, descendant_event.root_recording_id
      end
    end
  end

  def test_move_to_retries_a_transient_move_conflict
    calls = 0
    original = RecordingStudio.method(:lock_for_move!)
    locker = lambda do |recording, to_parent:, to_root:|
      calls += 1
      raise RecordingStudio::MoveConflict, "retry" if calls < 3

      original.call(recording, to_parent: to_parent, to_root: to_root)
    end

    RecordingStudio.stub(:lock_for_move!, locker) do
      @page.move_to!(new_parent: @target_folder, actor: @actor)
    end

    assert_equal 3, calls
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end

  def test_move_to_reraises_move_conflict_after_five_attempts
    calls = 0
    original_parent_id = @page.parent_recording_id
    locker = lambda do |*|
      calls += 1
      raise RecordingStudio::MoveConflict, "retry"
    end

    RecordingStudio.stub(:lock_for_move!, locker) do
      error = assert_raises(RecordingStudio::MoveConflict) do
        @page.move_to!(new_parent: @target_folder, actor: @actor)
      end
      assert_equal "retry", error.message
    end

    assert_equal 5, calls
    assert_equal original_parent_id, @page.reload.parent_recording_id
  end

  def test_api_move_reports_an_exhausted_conflict_as_409
    destination = @target_folder
    access_grant = Struct.new(:destination) do
      def accessible_recordings
        RecordingStudio::Recording.where(id: destination.id)
      end

      def authorize!(**)
        true
      end
    end.new(destination)
    context = Struct.new(:recording, :api_client, :credential, :access_grant, :params, keyword_init: true).new(
      recording: @page,
      api_client: Struct.new(:id).new("client-1"),
      credential: Struct.new(:id).new("credential-1"),
      access_grant: access_grant,
      params: { parent_id: destination.id }
    )
    locker = lambda do |*|
      raise RecordingStudio::MoveConflict, "retry"
    end

    RecordingStudio.stub(:lock_for_move!, locker) do
      error = assert_raises(RecordingStudio::Moveable::Api::Conflict) do
        RecordingStudio::Moveable::Api::MoveRecording.call(context)
      end

      assert_equal 409, error.class::STATUS
      assert_equal "The tree changed, please try again", error.message
      assert_equal ["The tree changed, please try again"], error.details
    end

    assert_equal @source_folder.id, @page.reload.parent_recording_id
  end

  def test_move_to_blocks_self_and_descendant_destinations
    self_error = assert_raises(ArgumentError) do
      @source_folder.move_to!(new_parent: @source_folder, actor: @actor)
    end
    assert_match(/under itself/, self_error.message)

    descendant_error = assert_raises(ArgumentError) do
      @source_folder.move_to!(new_parent: @child_folder, actor: @actor)
    end
    assert_match(/under its descendant/, descendant_error.message)
  end

  def test_builtin_authorization_raises_access_denied
    outsider = create_user(email: "outsider@example.com")

    error = assert_raises(RecordingStudio::AccessDenied) do
      @page.move_to!(new_parent: @target_folder, actor: outsider)
    end

    assert_match(/source recording/, error.message)
  end

  def test_custom_authorization_hook_mode
    RecordingStudio::Moveable.configure do |config|
      config.use_builtin_access = false
      config.authorization_hook = lambda do |actor:, source:, destination:, **|
        actor == @actor && source.root_recording_id == destination.root_recording_id
      end
    end

    outsider = create_user(email: "another@example.com")

    denied = assert_raises(RecordingStudio::AccessDenied) do
      @page.move_to!(new_parent: @target_folder, actor: outsider)
    end
    assert_match(/authorization hook denied/, denied.message)

    @page.move_to!(new_parent: @target_folder, actor: @actor)
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end

  private

  def enable_cross_root_for(*recordable_types)
    recordable_types.each do |recordable_type|
      set_cross_root_for(recordable_type, true)
    end
  end

  def disable_cross_root_for(*recordable_types)
    recordable_types.each do |recordable_type|
      set_cross_root_for(recordable_type, false)
    end
  end

  def set_cross_root_for(recordable_type, value)
    RecordingStudio.set_capability_options(
      :movable,
      on: recordable_type.name,
      allow_cross_root: value
    )
  end
end
