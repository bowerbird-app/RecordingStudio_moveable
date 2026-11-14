# frozen_string_literal: true

require "timeout"
require_relative "../test_helper"

class MoveableMoveLockGate
  def initialize
    @queue = Queue.new
    @opened = false
    @mutex = Mutex.new
  end

  def wait
    @queue.pop
  end

  def open
    @mutex.synchronize do
      return if @opened

      @opened = true
      @queue << true
    end
  end
end

# Real Postgres sessions. Transactional tests would hide the other connection's rows.
class MoveableMoveLockTest < ActiveSupport::TestCase
  Session = Struct.new(:thread, :holder)

  self.use_transactional_tests = false

  def setup
    super
    @threads = []
    @gates = []
  end

  def teardown
    @gates.each(&:open)
    join_threads
    RecordingStudio.configuration.hooks.clear(:after_record)
    super
  end

  def test_move_racing_a_create_under_the_subtree_keeps_one_root
    actor = create_user
    _, source_root = create_workspace_root
    _, destination_root = create_workspace_root
    grant_root_access(root: source_root, actor: actor, role: :admin)
    grant_root_access(root: destination_root, actor: actor, role: :admin)
    parent = source_root.record(RecordingStudioFolder, actor: actor, parent_recording: source_root) { |f| f.name = "Parent" }
    child = source_root.record(RecordingStudioFolder, actor: actor, parent_recording: parent) { |f| f.name = "Child" }
    sibling = source_root.record(RecordingStudioPage, actor: actor, parent_recording: source_root) { |p| p.title = "Sibling" }
    destination = destination_root.record(RecordingStudioFolder, actor: actor, parent_recording: destination_root) do |folder|
      folder.name = "Destination"
    end
    parent.log_event!(action: "parent-note", actor: actor)
    child.log_event!(action: "child-note", actor: actor)

    release = track_gate
    held = Queue.new
    hold_after_record("During move", held, release)

    creator = start_session do
      source_root.record(RecordingStudioPage, actor: actor, parent_recording: child) { |page| page.title = "During move" }
    end
    new_id = Timeout.timeout(5) { held.pop }

    mover = start_session do
      parent.move_to!(new_parent: destination, actor: actor)
    end
    wait_for_lock_wait
    release.open
    finish_session(mover)
    finish_session(creator)

    new_recording = RecordingStudio::Recording.unscoped.find(new_id)
    [parent, child, new_recording].each do |recording|
      assert_equal destination_root.id, recording.reload.root_recording_id
      events = RecordingStudio::Event.unscoped.where(recording_id: recording.id)
      assert_predicate events, :any?
      events.each do |event|
        assert_equal destination_root.id, event.root_recording_id
      end
    end
    assert_equal source_root.id, sibling.reload.root_recording_id
    assert_equal source_root.id, sibling.events.pick(:root_recording_id)
  end

  private

  def hold_after_record(title, held, release)
    RecordingStudio.configuration.hooks.after_record do |event|
      next unless event.recordable.respond_to?(:title) && event.recordable.title == title

      held << event.recording_id
      release.wait
    end
  end

  def start_session
    holder = { error: nil, result: nil }
    thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        holder[:result] = yield
      end
    rescue StandardError => e
      holder[:error] = e
    end
    @threads << thread
    Session.new(thread, holder)
  end

  def finish_session(session)
    session.thread.join(10)
    raise "database session still running" if session.thread.alive?

    raise session.holder[:error] if session.holder[:error]

    session.holder[:result]
  end

  def track_gate
    gate = MoveableMoveLockGate.new
    @gates << gate
    gate
  end

  def wait_for_lock_wait
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    loop do
      return if recording_lock_waiters.positive?

      timed_out = Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      raise "timed out waiting for a row lock" if timed_out

      sleep 0.05
    end
  end

  def recording_lock_waiters
    ActiveRecord::Base.uncached do
      ActiveRecord::Base.connection.select_value(<<~SQL.squish).to_i
        SELECT COUNT(*)
        FROM pg_stat_activity
        WHERE datname = current_database()
          AND pid <> pg_backend_pid()
          AND wait_event_type = 'Lock'
      SQL
    end
  end

  def join_threads
    @threads.each do |thread|
      next unless thread
      next if thread.join(10)

      cancel_other_queries!
      thread.join(2)
    end
  end

  def cancel_other_queries!
    pids = ActiveRecord::Base.connection.select_values(<<~SQL.squish)
      SELECT pid FROM pg_stat_activity
      WHERE datname = current_database()
        AND pid <> pg_backend_pid()
        AND state <> 'idle'
    SQL
    pids.each do |pid|
      ActiveRecord::Base.connection.select_value("SELECT pg_cancel_backend(#{pid.to_i})")
    end
  end
end
