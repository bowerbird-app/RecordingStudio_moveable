# frozen_string_literal: true

require "test_helper"

class MoveableCapabilitiesTest < Minitest::Test
  class FakeRelation
    def initialize(records)
      @records = records
    end

    def pluck(attribute)
      @records.map { |record| record.public_send(attribute) }
    end

    def update_all(attributes)
      @records.each do |record|
        attributes.each { |key, value| record.public_send("#{key}=", value) }
      end
    end
  end

  class FakeLock
    attr_reader :looked_up_ids

    def initialize(records)
      @records = records
      @looked_up_ids = []
    end

    def find(id)
      looked_up_ids << id
      @records.fetch(id)
    end
  end

  class FakeRecording
    include RecordingStudio::Moveable::Capabilities::Moveable::RecordingMethods

    class << self
      attr_accessor :records, :lock_proxy

      def transaction
        yield
      end

      def find(id)
        records.fetch(id)
      end

      def lock
        self.lock_proxy ||= FakeLock.new(records)
      end

      def where(conditions)
        matches = records.values.select do |record|
          if conditions.key?(:parent_recording_id)
            Array(conditions[:parent_recording_id]).include?(record.parent_recording_id)
          elsif conditions.key?(:id)
            Array(conditions[:id]).include?(record.id)
          else
            false
          end
        end

        FakeRelation.new(matches)
      end
    end

    attr_accessor :id, :parent_recording_id, :parent_recording, :root_recording_id, :recordable_type,
                  :updated_with, :logged_event, :asserted_capability, :root_checked_with,
                  :descendant_guard_with

    def initialize(id:, parent_recording_id: nil, root_recording_id: nil, recordable_type: "RecordingStudioFolder")
      @id = id
      @parent_recording_id = parent_recording_id
      @root_recording_id = root_recording_id
      @recordable_type = recordable_type
      self.class.records ||= {}
      self.class.records[id] = self
    end

    def reload
      self
    end

    define_method(:update!) do |attributes|
      self.updated_with = attributes
      self.parent_recording = attributes[:parent_recording] if attributes.key?(:parent_recording)
      self.parent_recording_id = attributes[:parent_recording]&.id if attributes.key?(:parent_recording)
      self.root_recording_id = attributes[:root_recording_id] if attributes.key?(:root_recording_id)
      true
    end

    def log_event!(**attributes)
      self.logged_event = attributes
    end

    def assert_capability!(capability)
      self.asserted_capability = capability
    end

    def assert_recording_belongs_to_root!(recording)
      self.root_checked_with = recording
    end

    def assert_parent_recording_not_self_or_descendant!(recording)
      self.descendant_guard_with = recording
    end
  end

  class FakePolicy
    attr_reader :destination, :destinations

    define_method(:authorize_move!) do |destination:|
      @destinations ||= []
      @destinations << destination
      @destination = destination
      true
    end
  end

  def setup
    FakeRecording.records = {}
    FakeRecording.lock_proxy = nil
  end

  def root_id_resolver
    lambda do |recording|
      recording.root_recording_id || recording.id
    end
  end

  def test_capability_options_only_allows_explicit_true
    capabilities = RecordingStudio::Moveable::Capabilities::Moveable

    assert_equal({ allow_cross_root: true }, capabilities.capability_options(allow_cross_root: true))
    assert_equal({ allow_cross_root: false }, capabilities.capability_options(allow_cross_root: "true"))
    assert_equal({ allow_cross_root: false }, capabilities.capability_options({}))
  end

  def test_to_wraps_include_for_with_validated_keyword_options
    capabilities = RecordingStudio::Moveable::Capabilities::Moveable
    captured = nil

    RecordingStudio::Capabilities.stub(:include_for, lambda { |name, **options|
      captured = [name, options]
      :factory_module
    }) do
      result = capabilities.to(allow_cross_root: true)

      assert_equal :factory_module, result
    end

    assert_equal [:movable, { allow_cross_root: true }], captured
  end

  def test_enabled_aliases_to
    capabilities = RecordingStudio::Moveable::Capabilities::Moveable

    assert_equal capabilities.method(:to), capabilities.method(:enabled)
  end

  def test_enabled_delegates_keyword_options_to_include_for
    capabilities = RecordingStudio::Moveable::Capabilities::Moveable
    captured = nil

    RecordingStudio::Capabilities.stub(:include_for, lambda { |name, **options|
      captured = [name, options]
      :alias_module
    }) do
      result = capabilities.enabled(allow_cross_root: true)

      assert_equal :alias_module, result
    end

    assert_equal [:movable, { allow_cross_root: true }], captured
  end

  def test_to_rejects_unknown_options
    error = assert_raises(ArgumentError) do
      RecordingStudio::Capabilities::Moveable.to(foo: true)
    end

    assert_match(/Unknown Moveable option\(s\): foo/, error.message)
  end

  def test_to_rejects_positional_destination_types
    error = assert_raises(ArgumentError) do
      RecordingStudio::Capabilities::Moveable.to("Workspace", allow_cross_root: true)
    end

    assert_equal RecordingStudio::Moveable::Capabilities::Moveable::DESTINATION_API_REMOVED_MESSAGE, error.message
    assert_match(/recording_studio_recordable allowed_parent_types/, error.message)
    assert_match(/Moveable\.to\(allow_cross_root:/, error.message)
  end

  def test_enabled_rejects_positional_destination_types
    error = assert_raises(ArgumentError) do
      RecordingStudio::Capabilities::Moveable.enabled("Workspace")
    end

    assert_equal RecordingStudio::Moveable::Capabilities::Moveable::DESTINATION_API_REMOVED_MESSAGE, error.message
  end

  def test_legacy_movable_alias_delegates_to_the_same_methods
    moveable = RecordingStudio::Moveable::Capabilities::Moveable
    captured = nil

    moveable.stub(:to, lambda { |*args, **options|
      captured = [args, options]
      :legacy_module
    }) do
      result = RecordingStudio::Capabilities::Movable.to(allow_cross_root: true)

      assert_equal :legacy_module, result
      assert_equal :legacy_module, RecordingStudio::Capabilities::Movable.enabled(allow_cross_root: true)
    end

    assert_equal [[], { allow_cross_root: true }], captured
  end

  def test_legacy_movable_to_rejects_positional_destination_types
    error = assert_raises(ArgumentError) do
      RecordingStudio::Capabilities::Movable.to("Workspace")
    end

    assert_equal RecordingStudio::Moveable::Capabilities::Moveable::DESTINATION_API_REMOVED_MESSAGE, error.message
  end

  def test_installing_the_gem_registers_movable_without_enabling_it
    assert RecordingStudio.registered_capabilities.key?(:movable)
    refute RecordingStudio.capability_enabled?(:movable, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:movable, for: "RecordingStudioArchiveBox")
  end

  def test_recording_methods_expose_cross_root_flag
    recording = FakeRecording.new(id: "source", recordable_type: "RecordingStudioPage")
    capability_options = lambda do |_capability, for_type:|
      assert_equal "RecordingStudioPage", for_type
      { allow_cross_root: true }
    end

    RecordingStudio.stub(:capability_options, capability_options) do
      assert recording.send(:moveable_allows_cross_root?)
    end
  end

  def test_recording_methods_compute_cross_root_and_descendants
    source = FakeRecording.new(id: "source", root_recording_id: "root-1")
    child = FakeRecording.new(id: "child", parent_recording_id: "source", root_recording_id: "root-1")
    FakeRecording.new(id: "grandchild", parent_recording_id: "child", root_recording_id: "root-1")
    other_root = FakeRecording.new(id: "root-2", root_recording_id: nil)

    assert_equal %w[child grandchild], source.send(:descendant_ids)
    RecordingStudio.stub(:root_recording_id_for, root_id_resolver) do
      assert_not source.send(:cross_root?, child)
      assert source.send(:cross_root?, other_root)
      assert_equal "root-1", source.send(:resolved_root_id, child)
      assert_equal "root-2", source.send(:resolved_root_id, other_root)
    end
  end

  def test_move_to_updates_parent_and_logs_event_for_same_root_move
    source = FakeRecording.new(
      id: "source",
      parent_recording_id: "parent-1",
      root_recording_id: "root-1",
      recordable_type: "RecordingStudioPage"
    )
    FakeRecording.new(id: "child", parent_recording_id: "source", root_recording_id: "root-1")
    target = FakeRecording.new(id: "target", root_recording_id: "root-1", recordable_type: "RecordingStudioFolder")
    policy = FakePolicy.new

    capability_options = ->(*, **) { { allow_cross_root: false } }
    parent_allowed = lambda do |child_type:, parent_recording:|
      assert_equal "RecordingStudioPage", child_type
      assert_equal target, parent_recording
      true
    end

    RecordingStudio.stub(:capability_options, capability_options) do
      RecordingStudio.stub(:root_recording_id_for, root_id_resolver) do
        RecordingStudio.stub(:assert_parent_allowed!, parent_allowed) do
          RecordingStudio::Moveable::Policy.stub(:new, policy) do
            source.move_to!(new_parent: target, actor: :actor, impersonator: :impersonator,
                            metadata: { reason: "reorg" })
          end
        end
      end
    end

    assert_equal :movable, source.asserted_capability
    assert_equal target, source.root_checked_with
    assert_equal target, source.descendant_guard_with
    assert_equal({ parent_recording: target }, source.updated_with)
    assert_equal target, policy.destination
    assert_equal [target, target], policy.destinations
    assert_equal %w[child source target], FakeRecording.lock_proxy.looked_up_ids
    assert_equal "moved", source.logged_event[:action]
    assert_equal :actor, source.logged_event[:actor]
    assert_equal :impersonator, source.logged_event[:impersonator]
    assert_equal(
      {
        reason: "reorg",
        from_parent_id: "parent-1",
        to_parent_id: "target",
        from_root_id: "root-1",
        to_root_id: "root-1"
      },
      source.logged_event[:metadata]
    )
  end

  def test_move_to_transfers_descendants_for_cross_root_move
    source = FakeRecording.new(
      id: "source",
      root_recording_id: "root-1",
      recordable_type: "RecordingStudioFolder"
    )
    child = FakeRecording.new(id: "child", parent_recording_id: "source", root_recording_id: "root-1")
    target = FakeRecording.new(id: "target", root_recording_id: "root-2", recordable_type: "RecordingStudioFolder")

    capability_options = ->(*, **) { { allow_cross_root: true } }

    RecordingStudio.stub(:capability_options, capability_options) do
      RecordingStudio.stub(:root_recording_id_for, root_id_resolver) do
        RecordingStudio.stub(:assert_parent_allowed!, true) do
          RecordingStudio::Moveable::Policy.stub(:new, FakePolicy.new) do
            source.moveable_to!(new_parent: target, actor: :actor)
          end
        end
      end
    end

    assert_equal "root-2", child.root_recording_id
    assert_equal({ parent_recording: target, root_recording_id: "root-2" }, source.updated_with)
    assert_equal "root-2", source.root_recording_id
  end

  def test_move_to_authorizes_each_descendant_before_transferring_subtree
    source = FakeRecording.new(
      id: "source",
      root_recording_id: "root-1",
      recordable_type: "RecordingStudioFolder"
    )
    child = FakeRecording.new(id: "child", parent_recording_id: "source", root_recording_id: "root-1")
    grandchild = FakeRecording.new(id: "grandchild", parent_recording_id: "child", root_recording_id: "root-1")
    target = FakeRecording.new(id: "target", root_recording_id: "root-2", recordable_type: "RecordingStudioFolder")
    sources_checked = []

    policy = FakePolicy.new

    capability_options = ->(*, **) { { allow_cross_root: true } }

    RecordingStudio.stub(:capability_options, capability_options) do
      RecordingStudio.stub(:root_recording_id_for, root_id_resolver) do
        RecordingStudio.stub(:assert_parent_allowed!, true) do
          RecordingStudio::Moveable::Policy.stub(:new, lambda { |source:, **|
            sources_checked << source
            policy
          }) do
            source.moveable_to!(new_parent: target, actor: :actor)
          end
        end
      end
    end

    assert_equal [source, child, grandchild], sources_checked
    assert_equal [target, target, target], policy.destinations
  end

  def test_move_to_rejects_disallowed_parent_type
    source = FakeRecording.new(id: "source", root_recording_id: "root-1", recordable_type: "RecordingStudioPage")
    target = FakeRecording.new(id: "target", root_recording_id: "root-1", recordable_type: "RecordingStudioArchiveBox")

    capability_options = ->(*, **) { { allow_cross_root: false } }
    parent_allowed = lambda do |**|
      raise ArgumentError, "RecordingStudioPage cannot be recorded under RecordingStudioArchiveBox"
    end

    RecordingStudio.stub(:capability_options, capability_options) do
      RecordingStudio.stub(:root_recording_id_for, root_id_resolver) do
        RecordingStudio.stub(:assert_parent_allowed!, parent_allowed) do
          error = assert_raises(ArgumentError) do
            source.move_to!(new_parent: target, actor: :actor)
          end

          assert_match(/RecordingStudioPage cannot be recorded under RecordingStudioArchiveBox/, error.message)
        end
      end
    end
  end

  def test_move_to_rejects_cross_root_when_not_allowed
    source = FakeRecording.new(id: "source", root_recording_id: "root-1", recordable_type: "RecordingStudioPage")
    target = FakeRecording.new(id: "target", root_recording_id: "root-2", recordable_type: "RecordingStudioFolder")

    capability_options = ->(*, **) { { allow_cross_root: false } }

    RecordingStudio.stub(:capability_options, capability_options) do
      RecordingStudio.stub(:root_recording_id_for, root_id_resolver) do
        error = assert_raises(ArgumentError) do
          source.move_to!(new_parent: target, actor: :actor)
        end

        assert_equal "Destination must belong to this root recording", error.message
      end
    end
  end
end
