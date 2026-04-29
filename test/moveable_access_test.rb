# frozen_string_literal: true

require "test_helper"

class MoveableAccessTest < Minitest::Test
  FakeRecording = Struct.new(:id, :parent_recording, keyword_init: true)

  def test_allowed_uses_accessible_public_authorization_api
    actor = Struct.new(:id).new(7)
    recording = FakeRecording.new(id: 10)

    authorized = lambda do |actor:, recording:, role:|
      assert_equal 7, actor.id
      assert_equal 10, recording.id
      assert_equal :edit, role

      true
    end

    RecordingStudioAccessible.stub(:authorized?, authorized) do
      assert RecordingStudio::Moveable::Access.allowed?(actor: actor, recording: recording, role: :edit)
    end
  end

  def test_allowed_passes_target_recording_to_accessible_public_api
    actor = Struct.new(:id).new(11)
    root = FakeRecording.new(id: 1)
    section = FakeRecording.new(id: 2, parent_recording: root)
    page = FakeRecording.new(id: 3, parent_recording: section)

    authorized = lambda do |actor:, recording:, role:|
      assert_equal 11, actor.id
      assert_same page, recording
      assert_equal :edit, role

      true
    end

    RecordingStudioAccessible.stub(:authorized?, authorized) do
      assert RecordingStudio::Moveable::Access.allowed?(actor: actor, recording: page, role: :edit)
    end
  end

  def test_allowed_returns_false_without_actor_or_recording
    RecordingStudioAccessible.stub(:authorized?, ->(**) { flunk "expected no authorization lookup" }) do
      assert_not RecordingStudio::Moveable::Access.allowed?(
        actor: nil,
        recording: FakeRecording.new(id: 10),
        role: :edit
      )
      assert_not RecordingStudio::Moveable::Access.allowed?(
        actor: Object.new,
        recording: nil,
        role: :edit
      )
    end
  end
end
