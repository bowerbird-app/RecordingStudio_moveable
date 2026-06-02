# frozen_string_literal: true

require "test_helper"

class DestinationSearchTest < Minitest::Test
  Recording = Struct.new(
    :id, :parent_recording_id, :root_recording_id, :recordable_type, :recordable,
    keyword_init: true
  )
  TitleRecordable = Struct.new(:title, keyword_init: true)
  NameRecordable = Struct.new(:name, keyword_init: true)
  BlankRecordable = Struct.new(:title, :name, :id, keyword_init: true)
  HookedFolderRecordable = Struct.new(:name, :id, keyword_init: true) do
    def self.recordable_type_label
      "Folder"
    end

    class << self
      alias_method :recording_studio_type_label, :recordable_type_label
    end

    def recordable_name
      "📁 #{name}"
    end

    alias_method :recording_studio_label, :recordable_name
  end
  ArchiveRecordable = Struct.new(:id, keyword_init: true) do
    def self.recordable_type_label
      "Archive box"
    end

    class << self
      alias_method :recording_studio_type_label, :recordable_type_label
    end
  end

  class FakePolicy
    attr_reader :destinations_seen, :destination_checked

    def initialize(filtered_destinations:, destination_allowed: true)
      @filtered_destinations = filtered_destinations
      @destination_allowed = destination_allowed
    end

    def filter_visible_destinations(destinations:)
      @destinations_seen = destinations
      @filtered_destinations
    end

    def destination_selectable?(destination:)
      @destination_checked = destination
      @destination_allowed
    end
  end

  class FakeScope
    class WhereChain
      def initialize(scope)
        @scope = scope
      end

      def not(id:)
        FakeScope.new(@scope.records.reject { |record| Array(id).include?(record.id) })
      end
    end

    attr_reader :records

    def initialize(records)
      @records = records
    end

    def where(conditions = :__none__)
      return WhereChain.new(self) if conditions == :__none__

      filtered = records.select do |record|
        conditions.all? do |key, value|
          Array(value).include?(record.public_send(key))
        end
      end

      FakeScope.new(filtered)
    end

    def includes(_association)
      self
    end

    def order(updated_at:)
      updated_at == :desc ? FakeScope.new(records.reverse) : self
    end

    def to_a
      records
    end

    def pluck(attribute)
      records.map { |record| record.public_send(attribute) }
    end
  end

  def setup
    ensure_recording_class!

    @source = recording(
      id: "source-id",
      root_recording_id: "root-1",
      recordable_type: "RecordingStudioPage",
      recordable: TitleRecordable.new(title: "Source Page")
    )
  end

  def test_results_filters_visible_records_then_promotes_root_items_before_limiting
    root_folder = recording(
      id: "root-folder",
      parent_recording_id: nil,
      root_recording_id: "root-1",
      recordable_type: "RecordingStudioFolder",
      recordable: NameRecordable.new(name: "Alpha Root Folder")
    )
    nested_folder = recording(
      id: "nested-folder",
      parent_recording_id: "parent-1",
      root_recording_id: "root-1",
      recordable_type: "RecordingStudioFolder",
      recordable: NameRecordable.new(name: "Beta Nested Folder")
    )
    policy = FakePolicy.new(filtered_destinations: [nested_folder, root_folder])
    search = build_search(policy: policy)

    search.stub(:structurally_allowed_destinations, lambda { |root: nil, across_roots: false|
      assert_nil root
      assert_equal false, across_roots
      [root_folder, nested_folder]
    }) do
      result = search.results(query: "folder", limit: 1)

      assert_equal [root_folder], result
      assert_equal [root_folder, nested_folder], policy.destinations_seen
    end
  end

  def test_workspace_results_filters_by_query_and_can_skip_limit
    client_root = recording(
      id: "root-2",
      parent_recording_id: nil,
      recordable_type: "Workspace",
      recordable: NameRecordable.new(name: "Client Workspace")
    )
    archive_root = recording(
      id: "root-3",
      parent_recording_id: nil,
      recordable_type: "Workspace",
      recordable: NameRecordable.new(name: "Archive Workspace")
    )
    search = build_search

    search.stub(:cross_root_workspace_destinations, [client_root, archive_root]) do
      assert_equal [client_root], search.workspace_results(query: "client", limit: nil)
      assert_equal [archive_root], search.workspace_results(query: "archive", limit: 5)
    end
  end

  def test_allowed_workspace_root_uses_resolved_root_ids
    search = build_search
    nested_recording = recording(id: "child", root_recording_id: "root-2")
    direct_root = recording(id: "root-3")

    search.stub(:workspace_root_ids, %w[root-2 root-3]) do
      assert search.allowed_workspace_root?(nested_recording)
      assert search.allowed_workspace_root?(direct_root)
      assert_not search.allowed_workspace_root?(recording(id: "root-4"))
    end
  end

  def test_allowed_destination_requires_structural_and_policy_approval
    destination = recording(id: "destination-1")
    allowed_policy = FakePolicy.new(filtered_destinations: [], destination_allowed: true)
    denied_policy = FakePolicy.new(filtered_destinations: [], destination_allowed: false)
    allowed_search = build_search(policy: allowed_policy)
    denied_search = build_search(policy: denied_policy)

    allowed_search.stub(:structurally_allowed_destination?, true) do
      assert allowed_search.allowed_destination?(destination)
      assert_equal destination, allowed_policy.destination_checked
    end

    denied_search.stub(:structurally_allowed_destination?, true) do
      assert_not denied_search.allowed_destination?(destination)
      assert_equal destination, denied_policy.destination_checked
    end

    allowed_search.stub(:structurally_allowed_destination?, false) do
      assert_not allowed_search.allowed_destination?(destination)
    end
  end

  def test_core_allowed_parent_types_and_cross_root_flag_use_core_and_capability_options
    allowed_parent_types = lambda do |recordable_type|
      assert_equal "RecordingStudioPage", recordable_type
      [:Workspace, "RecordingStudioFolder"]
    end
    capability_options = lambda do |capability, for_type:|
      assert_equal :movable, capability
      assert_equal "RecordingStudioPage", for_type
      { allow_cross_root: true }
    end

    RecordingStudio.stub(:allowed_parent_types_for, allowed_parent_types) do
      search = build_search

      RecordingStudio.stub(:capability_options, capability_options) do
        assert_equal %w[Workspace RecordingStudioFolder], search.send(:core_allowed_parent_types)
        assert search.send(:allow_cross_root?)
      end
    end
  end

  def test_policy_builds_default_policy_from_context
    received = nil
    fake_policy = Object.new

    RecordingStudio::Moveable::Policy.stub(:new, lambda { |**kwargs|
      received = kwargs
      fake_policy
    }) do
      search = RecordingStudio::Moveable::DestinationSearch.new(
        actor: :actor,
        source: @source,
        impersonator: :impersonator,
        metadata: { scope: "mix" }
      )

      assert_equal fake_policy, search.send(:policy)
    end

    assert_equal(
      {
        actor: :actor,
        source: @source,
        impersonator: :impersonator,
        metadata: { scope: "mix" }
      },
      received
    )
  end

  def test_structurally_allowed_destinations_filters_by_root_type_and_exclusions
    same_root = recording(id: "folder-1", root_recording_id: "root-1", recordable_type: "RecordingStudioFolder")
    other_root = recording(id: "folder-2", root_recording_id: "root-2", recordable_type: "RecordingStudioFolder")
    excluded = recording(id: "child-1", root_recording_id: "root-1", recordable_type: "RecordingStudioFolder")
    wrong_type = recording(id: "page-1", root_recording_id: "root-1", recordable_type: "RecordingStudioPage")
    scope = FakeScope.new([same_root, other_root, excluded, wrong_type])
    search = build_search

    capability_options = ->(*, **) { { allow_cross_root: false } }

    RecordingStudio.stub(:capability_options, capability_options) do
      with_core_hierarchy do
        RecordingStudio::Recording.stub(:all, scope) do
          search.stub(:excluded_destination_ids, %w[source-id child-1]) do
            assert_equal [same_root], search.send(:structurally_allowed_destinations)
            assert_equal [other_root, same_root], search.send(:structurally_allowed_destinations, across_roots: true)
          end
        end
      end
    end
  end

  def test_structurally_allowed_destination_checks_root_type_and_exclusions
    same_root = recording(id: "folder-1", root_recording_id: "root-1", recordable_type: "RecordingStudioFolder")
    cross_root = recording(id: "folder-2", root_recording_id: "root-2", recordable_type: "RecordingStudioFolder")
    wrong_type = recording(id: "page-1", root_recording_id: "root-1", recordable_type: "RecordingStudioPage")
    search = build_search

    capability_options = ->(*, **) { { allow_cross_root: false } }
    parent_allowed = ->(child_type:, parent_recording:) { child_type == "RecordingStudioPage" && parent_recording.recordable_type == "RecordingStudioFolder" }

    RecordingStudio.stub(:capability_options, capability_options) do
      with_core_hierarchy(parent_allowed: parent_allowed) do
        search.stub(:excluded_destination_ids, ["source-id"]) do
          assert search.send(:structurally_allowed_destination?, same_root)
          assert_not search.send(:structurally_allowed_destination?, cross_root)
          assert_not search.send(:structurally_allowed_destination?, wrong_type)
        end
      end
    end

    capability_options = ->(*, **) { { allow_cross_root: true } }

    RecordingStudio.stub(:capability_options, capability_options) do
      with_core_hierarchy(parent_allowed: parent_allowed) do
        search.stub(:excluded_destination_ids, %w[source-id folder-2]) do
          assert_not search.send(:structurally_allowed_destination?, cross_root)
        end
      end
    end
  end

  def test_cross_root_workspace_destinations_and_workspace_root_ids_use_visible_destinations
    same_root = recording(id: "folder-1", root_recording_id: "root-1", recordable_type: "RecordingStudioFolder")
    workspace_a = recording(id: "root-2", root_recording_id: "root-2", recordable_type: "RecordingStudioFolder")
    workspace_b = recording(id: "root-3", root_recording_id: "root-3", recordable_type: "RecordingStudioFolder")
    roots_scope = FakeScope.new([workspace_a, workspace_b, same_root])
    policy = FakePolicy.new(filtered_destinations: [workspace_a, workspace_b, workspace_a])
    search = build_search(policy: policy)

    capability_options = ->(*, **) { { allow_cross_root: true } }

    RecordingStudio.stub(:capability_options, capability_options) do
      with_core_hierarchy do
        search.stub(:structurally_allowed_destinations, [same_root, workspace_a, workspace_b]) do
          RecordingStudio::Recording.stub(:where, lambda { |id:|
            FakeScope.new(roots_scope.records.select { |record| Array(id).include?(record.id) })
          }) do
            assert_equal %w[root-2 root-3], search.send(:workspace_root_ids)
            assert_equal [workspace_b, workspace_a], search.send(:cross_root_workspace_destinations)
            assert_equal [same_root, workspace_a, workspace_b], policy.destinations_seen
          end
        end
      end
    end
  end

  def test_cross_root_workspace_destinations_returns_empty_when_cross_root_disabled
    search = build_search

    capability_options = ->(*, **) { { allow_cross_root: false } }

    RecordingStudio.stub(:capability_options, capability_options) do
      assert_equal [], search.send(:cross_root_workspace_destinations)
    end
  end

  def test_descendant_ids_walks_down_tree_until_no_children_remain
    child = recording(id: "child-1", parent_recording_id: "source-id")
    grandchild = recording(id: "child-2", parent_recording_id: "child-1")
    search = build_search

    RecordingStudio::Recording.stub(:where, lambda { |parent_recording_id:|
      matching = [child, grandchild].select { |record| Array(parent_recording_id).include?(record.parent_recording_id) }
      FakeScope.new(matching)
    }) do
      assert_equal %w[child-1 child-2], search.send(:descendant_ids, @source)
    end
  end

  def test_excluded_destination_ids_include_descendants
    search = build_search

    search.stub(:descendant_ids, %w[child-1 child-2]) do
      assert_equal %w[source-id child-1 child-2], search.send(:excluded_destination_ids)
    end
  end

  def test_results_exclude_root_when_source_is_already_directly_under_root
    source = recording(
      id: "folder-1",
      parent_recording_id: "root-1",
      root_recording_id: "root-1",
      recordable_type: "RecordingStudioFolder"
    )
    root_destination = recording(
      id: "root-1",
      parent_recording_id: nil,
      root_recording_id: "root-1",
      recordable_type: "Workspace",
      recordable: NameRecordable.new(name: "Client Workspace")
    )
    sibling_folder = recording(
      id: "folder-2",
      parent_recording_id: "root-1",
      root_recording_id: "root-1",
      recordable_type: "RecordingStudioFolder",
      recordable: NameRecordable.new(name: "Delivered")
    )
    scope = FakeScope.new([source, root_destination, sibling_folder])
    policy = FakePolicy.new(filtered_destinations: [sibling_folder])
    search = build_search(source: source, policy: policy)

    capability_options = ->(*, **) { { allow_cross_root: false } }

    RecordingStudio.stub(:capability_options, capability_options) do
      with_core_hierarchy(allowed_types: %w[Workspace RecordingStudioFolder]) do
        RecordingStudio::Recording.stub(:all, scope) do
          search.stub(:descendant_ids, []) do
            assert_equal [sibling_folder], search.results(limit: nil)
            assert_equal [sibling_folder], policy.destinations_seen
          end
        end
      end
    end
  end

  def test_results_keep_root_when_source_is_nested_below_root
    root_destination = recording(
      id: "root-1",
      parent_recording_id: nil,
      root_recording_id: "root-1",
      recordable_type: "Workspace",
      recordable: NameRecordable.new(name: "Client Workspace")
    )
    source = recording(
      id: "page-1",
      parent_recording_id: "folder-1",
      root_recording_id: "root-1",
      recordable_type: "RecordingStudioPage"
    )
    sibling_folder = recording(
      id: "folder-2",
      parent_recording_id: "root-1",
      root_recording_id: "root-1",
      recordable_type: "RecordingStudioFolder",
      recordable: NameRecordable.new(name: "Delivered")
    )
    scope = FakeScope.new([source, root_destination, sibling_folder])
    policy = FakePolicy.new(filtered_destinations: [sibling_folder, root_destination])
    search = build_search(source: source, policy: policy)

    capability_options = ->(*, **) { { allow_cross_root: false } }

    RecordingStudio.stub(:capability_options, capability_options) do
      with_core_hierarchy(allowed_types: %w[Workspace RecordingStudioFolder]) do
        RecordingStudio::Recording.stub(:all, scope) do
          search.stub(:descendant_ids, []) do
            assert_equal [root_destination, sibling_folder], search.results(limit: nil)
          end
        end
      end
    end
  end

  def test_filter_by_query_matches_title_name_type_and_identifier
    titled = recording(
      id: "folder-1",
      recordable_type: "RecordingStudioFolder",
      recordable: TitleRecordable.new(title: "Mix Notes")
    )
    named = recording(
      id: "workspace-7",
      recordable_type: "RecordingStudioFolder",
      recordable: HookedFolderRecordable.new(name: "Client Space", id: "folder-7")
    )
    typed = recording(
      id: "abc-123",
      recordable_type: "RecordingStudioArchiveBox",
      recordable: ArchiveRecordable.new(id: "archive-9")
    )
    search = build_search

    assert_equal [titled, named, typed], search.send(:filter_by_query, [titled, named, typed], nil)
    assert_equal [titled], search.send(:filter_by_query, [titled, named, typed], "mix")
    assert_equal [named], search.send(:filter_by_query, [titled, named, typed], "client")
    assert_equal [named], search.send(:filter_by_query, [titled, named, typed], "📁 client")
    assert_equal [typed], search.send(:filter_by_query, [titled, named, typed], "archive box")
    assert_equal [typed], search.send(:filter_by_query, [titled, named, typed], "abc-123")
  end

  def test_promote_workspace_root_keeps_root_items_ahead_of_nested_items
    root_recording = recording(id: "root-a", parent_recording_id: nil)
    nested_recording = recording(id: "nested-a", parent_recording_id: "root-a")
    second_root = recording(id: "root-b", parent_recording_id: nil)
    search = build_search

    promoted = search.send(:promote_workspace_root, [nested_recording, root_recording, second_root])

    assert_equal [root_recording, second_root, nested_recording], promoted
  end

  def test_searchable_terms_and_resolved_root_id_follow_label_contract
    search = build_search
    titled = TitleRecordable.new(title: "Song Draft")
    named = HookedFolderRecordable.new(name: "Workspace A", id: "folder-a")
    blank = ArchiveRecordable.new(id: "archive-a")
    recording = self.recording(id: "searchable", recordable_type: "RecordingStudioFolder", recordable: named)

    assert_includes search.send(:searchable_terms, self.recording(id: "titled", recordable: titled)), "song draft"
    assert_includes search.send(:searchable_terms, recording), "📁 workspace a"
    assert_includes search.send(:searchable_terms, recording), "folder"
    archive_recording = self.recording(
      id: "archive",
      recordable_type: "RecordingStudioArchiveBox",
      recordable: blank
    )

    assert_includes search.send(:searchable_terms, archive_recording), "archive box"
    RecordingStudio.stub(:root_recording_id_for, root_id_resolver) do
      assert_equal "root-1", search.send(:resolved_root_id, recording(id: "child", root_recording_id: "root-1"))
      assert_equal "direct-root", search.send(:resolved_root_id, recording(id: "direct-root"))
    end
  end

  def test_searchable_terms_delegate_to_recording_studio_labels
    recordable = TitleRecordable.new(title: "Source")
    recording = self.recording(id: "delegated-id", recordable: recordable)
    recording_studio_labels = Module.new
    recording_studio_labels.define_singleton_method(:title_for) { |candidate| "title:#{candidate.title}" }
    recording_studio_labels.define_singleton_method(:name_for) { |candidate| "name:#{candidate.title}" }
    recording_studio_labels.define_singleton_method(:type_label_for) { |_candidate| "Page" }

    RecordingStudioMoveable::Labels.stub(:resolver, recording_studio_labels) do
      expected_terms = ["title:source", "name:source", "page", "delegated-id"]

      assert_equal expected_terms, build_search.send(:searchable_terms, recording)
    end
  end

  private

  def root_id_resolver
    lambda do |recording|
      recording.root_recording_id || recording.id
    end
  end

  def with_core_hierarchy(allowed_types: ["RecordingStudioFolder"], parent_allowed: nil)
    parent_allowed ||= lambda do |child_type:, parent_recording:|
      child_type.present? && allowed_types.include?(parent_recording.recordable_type)
    end

    RecordingStudio.stub(:allowed_parent_types_for, ->(_type) { allowed_types }) do
      RecordingStudio.stub(:parent_allowed?, parent_allowed) do
        RecordingStudio.stub(:root_recording_id_for, root_id_resolver) do
          yield
        end
      end
    end
  end

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

    recording_class.define_singleton_method(:all) { [] } unless recording_class.respond_to?(:all)
    recording_class.define_singleton_method(:where) { |**| [] } unless recording_class.respond_to?(:where)
  end

  def build_search(source: @source, policy: FakePolicy.new(filtered_destinations: []))
    RecordingStudio::Moveable::DestinationSearch.new(actor: :actor, source: source, policy: policy)
  end

  def recording(
    id:,
    parent_recording_id: nil,
    root_recording_id: nil,
    recordable_type: "RecordingStudioFolder",
    recordable: nil
  )
    Recording.new(
      id: id,
      parent_recording_id: parent_recording_id,
      root_recording_id: root_recording_id,
      recordable_type: recordable_type,
      recordable: recordable || BlankRecordable.new(title: nil, name: nil, id: nil)
    )
  end
end
