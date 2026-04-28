# frozen_string_literal: true

require "test_helper"

class MoveableAccessTest < Minitest::Test
  FakeRecording = Struct.new(
    :id,
    :parent_recording,
    :parent_recording_id,
    :root_recording,
    :root_recording_id,
    keyword_init: true
  )
  FakeRole = Struct.new(:role, keyword_init: true)
  FakeAccessRecording = Struct.new(:parent_recording_id, :recordable, keyword_init: true)

  QueryRelation = Struct.new(:records, :pluck_values, keyword_init: true) do
    def where(**)
      self
    end

    def pluck(_column)
      pluck_values
    end

    def order(**)
      self
    end

    def first
      Array(records).first
    end
  end

  def setup
    ensure_recording_class!
  end

  def test_allowed_uses_accessible_direct_access_query_for_root_role
    actor = Struct.new(:id).new(7)
    root = FakeRecording.new(
      id: 10,
      parent_recording: nil,
      parent_recording_id: nil,
      root_recording: nil,
      root_recording_id: nil
    )
    access_recordings = [
      FakeAccessRecording.new(parent_recording_id: root.id, recordable: FakeRole.new(role: :admin))
    ]
    unscoped = QueryRelation.new(records: [], pluck_values: [])

    RecordingStudio::Recording.stub(:unscoped, unscoped) do
      RecordingStudioAccessible::DirectAccessQuery.stub(:access_recordings_for_actor_in, access_recordings) do
        assert RecordingStudio::Moveable::Access.allowed?(actor: actor, recording: root, role: :edit)
      end
    end
  end

  def test_allowed_uses_nearest_access_on_the_path
    actor = Struct.new(:id).new(11)
    root = FakeRecording.new(
      id: 1,
      parent_recording: nil,
      parent_recording_id: nil,
      root_recording: nil,
      root_recording_id: nil
    )
    section = FakeRecording.new(
      id: 2,
      parent_recording: root,
      parent_recording_id: root.id,
      root_recording: root,
      root_recording_id: root.id
    )
    page = FakeRecording.new(
      id: 3,
      parent_recording: section,
      parent_recording_id: section.id,
      root_recording: root,
      root_recording_id: root.id
    )

    access_recordings = [
      FakeAccessRecording.new(parent_recording_id: section.id, recordable: FakeRole.new(role: :edit)),
      FakeAccessRecording.new(parent_recording_id: root.id, recordable: FakeRole.new(role: :view))
    ]

    RecordingStudio::Recording.stub(:unscoped, QueryRelation.new(records: [], pluck_values: [])) do
      RecordingStudioAccessible::DirectAccessQuery.stub(:access_recordings_for_actor_in, access_recordings) do
        assert RecordingStudio::Moveable::Access.allowed?(actor: actor, recording: page, role: :edit)
      end
    end
  end

  private

  def ensure_recording_class!
    recording_class = if defined?(RecordingStudio::Recording)
                        RecordingStudio::Recording
                      else
                        recording_studio_module = if Object.const_defined?(:RecordingStudio)
                                                    RecordingStudio
                                                  else
                                                    Object.const_set(:RecordingStudio, Module.new)
                                                  end

                        recording_studio_module.const_set(:Recording, Class.new)
                      end

    recording_class.define_singleton_method(:unscoped) { [] } unless recording_class.respond_to?(:unscoped)
  end
end
