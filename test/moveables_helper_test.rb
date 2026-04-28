# frozen_string_literal: true

require "test_helper"

class MoveablesHelperTest < Minitest::Test
  HookedFolderRecordable = Struct.new(:name, keyword_init: true) do
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

  NamelessRecordable = Class.new

  class TagBuilder
    def meta(name:, content:)
      %(<meta name="#{name}" content="#{content}">)
    end

    def div(content = "", data: {})
      attributes = data.map do |key, value|
        %(data-#{key.to_s.tr('_', '-')}="#{value}")
      end.join(" ")

      %(<div #{attributes}>#{content}</div>)
    end
  end

  class RenderHelper
    include RecordingStudioMoveable::MoveablesHelper

    attr_reader :rendered_component

    def tag
      @tag ||= TagBuilder.new
    end

    def content_tag(name, data: {})
      attributes = data.map do |key, value|
        %(data-#{key.to_s.tr('_', '-')}="#{value}")
      end.join(" ")

      %(<#{name} #{attributes}>#{yield}</#{name}>)
    end

    def render(component)
      @rendered_component = component
      modal = Struct.new(:body_content) do
        def body
          self.body_content = yield
        end
      end.new

      yield modal
      %(<modal>#{modal.body_content}</modal>)
    end
  end

  def helper
    @helper ||= Class.new do
      include RecordingStudioMoveable::MoveablesHelper
    end.new
  end

  def helper_with_root_label(&block)
    Class.new do
      include RecordingStudioMoveable::MoveablesHelper

      define_method(:recording_studio_moveable_root_label, &block)
    end.new
  end

  def test_asset_available_when_propshaft_can_resolve_asset
    load_path = Minitest::Mock.new
    load_path.expect :find, Object.new, ["tailwind.css"]
    assets = Struct.new(:load_path).new(load_path)
    application = Struct.new(:assets).new(assets)

    Rails.stub(:application, application) do
      assert helper.recording_studio_moveable_asset_available?("tailwind.css")
    end

    load_path.verify
  end

  def test_asset_unavailable_when_propshaft_cannot_resolve_asset
    load_path = Minitest::Mock.new
    load_path.expect :find, nil, ["tailwind.css"]
    assets = Struct.new(:load_path).new(load_path)
    application = Struct.new(:assets).new(assets)

    Rails.stub(:application, application) do
      assert_not helper.recording_studio_moveable_asset_available?("tailwind.css")
    end

    load_path.verify
  end

  def test_asset_unavailable_without_load_path_support
    application = Struct.new(:assets).new(Object.new)

    Rails.stub(:application, application) do
      assert_not helper.recording_studio_moveable_asset_available?("tailwind.css")
    end
  end

  def test_asset_unavailable_when_lookup_raises
    load_path = Object.new
    load_path.define_singleton_method(:find) { |_asset_name| raise "boom" }
    assets = Struct.new(:load_path).new(load_path)
    application = Struct.new(:assets).new(assets)

    Rails.stub(:application, application) do
      assert_not helper.recording_studio_moveable_asset_available?("tailwind.css")
    end
  end

  def test_moveable_meta_tags_renders_enablement_tag
    render_helper = RenderHelper.new

    assert_equal(
      '<meta name="recording-studio-moveable" content="enabled">',
      render_helper.recording_studio_moveable_meta_tags
    )
  end

  def test_modal_template_wraps_modal_component_markup
    render_helper = RenderHelper.new
    render_helper.define_singleton_method(:recording_studio_moveable_modal_component) { "<modal-body />" }

    html = render_helper.recording_studio_moveable_modal_template

    assert_includes html, 'data-recording-studio-moveable-modal-root="true"'
    assert_includes html, "<modal-body />"
  end

  def test_modal_component_builds_flatpack_modal_with_body_placeholder
    render_helper = RenderHelper.new
    captured_options = nil
    fake_component = Struct.new(:options).new(nil)
    unless defined?(FlatPack::Modal::Component)
      flat_pack_module = Object.const_defined?(:FlatPack) ? FlatPack : Object.const_set(:FlatPack, Module.new)
      modal_module = if flat_pack_module.const_defined?(:Modal)
                       flat_pack_module.const_get(:Modal)
                     else
                       flat_pack_module.const_set(:Modal, Module.new)
                     end
      modal_module.const_set(:Component, Class.new) unless modal_module.const_defined?(:Component)
    end

    FlatPack::Modal::Component.stub(:new, lambda { |**kwargs|
      captured_options = kwargs
      fake_component.options = kwargs
      fake_component
    }) do
      html = render_helper.recording_studio_moveable_modal_component

      assert_equal fake_component, render_helper.rendered_component
      assert_equal "recording-studio-moveable-modal", captured_options[:id]
      assert_equal :lg, captured_options[:size]
      assert_equal :fixed, captured_options[:body_height_mode]
      assert_equal "70vh", captured_options[:body_height]
      assert_equal({ recording_studio_moveable_modal_element: true }, captured_options[:data])
      assert_includes html, 'data-recording-studio-moveable-modal-body="true"'
    end
  end

  def test_moveable_title_for_wraps_moveable_label
    recordable = Struct.new(:title).new("Mix Notes")
    recording = Struct.new(:id, :recordable, :recordable_type).new("rec-1", recordable, "RecordingStudioPage")
    recording_studio_labels = Module.new
    recording_studio_labels.define_singleton_method(:name_for) { |candidate| "stubbed #{candidate.title}" }
    recording_studio_labels.define_singleton_method(:type_label_for) { |_candidate| "Page" }

    RecordingStudioMoveable::Labels.stub(:resolver, recording_studio_labels) do
      assert_equal "Move stubbed Mix Notes", helper.moveable_title_for(recording)
    end
  end

  def test_moveable_label_and_type_delegate_to_recording_studio_labels
    recordable = Struct.new(:title).new("Tracking Folder")
    recording = Struct.new(:id, :recordable, :recordable_type).new("rec-2", recordable, "RecordingStudioFolder")
    received = []
    recording_studio_labels = Module.new
    recording_studio_labels.define_singleton_method(:name_for) do |candidate|
      received << [:name_for, candidate]
      "resolved name"
    end
    recording_studio_labels.define_singleton_method(:type_label_for) do |candidate|
      received << [:type_label_for, candidate]
      "resolved type"
    end

    RecordingStudioMoveable::Labels.stub(:resolver, recording_studio_labels) do
      assert_equal "resolved name", helper.moveable_label_for(recording)
      assert_equal "resolved type", helper.moveable_type_for(recording)
    end

    assert_equal [[:name_for, recordable], [:type_label_for, recordable]], received
  end

  def test_moveable_label_follows_parent_hook_contract_without_parent_labels
    named_recording = Struct.new(:id, :recordable, :recordable_type).new(
      "rec-2",
      HookedFolderRecordable.new(name: "Tracking Folder"),
      "RecordingStudioFolder"
    )
    fallback_recording = Struct.new(:id, :recordable, :recordable_type).new(
      "rec-3",
      ArchiveRecordable.new(id: "box-3"),
      "RecordingStudioArchiveBox"
    )

    assert_equal "📁 Tracking Folder", helper.moveable_label_for(named_recording)
    assert_equal "Folder", helper.moveable_type_for(named_recording)
    assert_equal "Move Tracking Folder", helper.moveable_title_for(named_recording)
    assert_equal "MoveablesHelperTest::ArchiveRecordable #box-3", helper.moveable_label_for(fallback_recording)
    assert_equal "Archive box", helper.moveable_type_for(fallback_recording)
  end

  def test_moveable_label_falls_back_to_class_name_when_recordable_has_no_identifier
    recording = Struct.new(:id, :recordable, :recordable_type).new(
      "rec-4",
      NamelessRecordable.new,
      "NamelessRecordable"
    )

    assert_equal "MoveablesHelperTest::NamelessRecordable", helper.moveable_label_for(recording)
  end

  def test_picker_item_collection_helpers_return_expected_shapes
    workspace_root = Struct.new(:id, :recordable, :recordable_type).new(
      "root-1",
      Struct.new(:name).new("Studio Workspace"),
      "Workspace"
    )
    destination = Struct.new(:id, :recordable, :recordable_type).new(
      "dest-1",
      Struct.new(:title).new("Lyrics"),
      "RecordingStudioPage"
    )

    workspace_items = helper.moveable_workspace_picker_items_for([workspace_root])
    picker_items = helper.moveable_picker_items_for([destination])

    assert_equal "workspace", workspace_items.first[:kind]
    assert_equal "Choose destinations in Studio Workspace", workspace_items.first[:description]
    assert_equal "record", picker_items.first[:kind]
    assert_equal "—", picker_items.first[:description]
  end

  def test_moveable_picker_item_omits_badge_and_meta
    recordable = HookedFolderRecordable.new(name: "Studio Workspace")
    parent_recordable = Struct.new(:title).new("Root")
    parent = Struct.new(:recordable, :recordable_type, :id, :parent_recording).new(
      parent_recordable,
      "RecordingStudio::Folder",
      "parent-id",
      nil
    )
    recording = Struct.new(:id, :recordable, :recordable_type, :parent_recording).new(
      "18b15f1a-7a98-471b-ad98-16f880f175cb",
      recordable,
      "RecordingStudio::Folder",
      parent
    )

    item = helper.moveable_picker_item_for(recording)

    assert_equal "📁 Studio Workspace", item[:label]
    assert_equal "Folder", item[:description]
    assert_not item.key?(:badge)
    assert_not item.key?(:meta)
  end

  def test_moveable_root_label_defaults_to_workspace_terms
    assert_equal "workspace", helper.moveable_root_label
    assert_equal "workspaces", helper.moveable_root_label(count: 2)
  end

  def test_moveable_root_label_uses_app_override_when_available
    custom_helper = helper_with_root_label do |count: 1|
      count.to_i == 1 ? "space" : "spaces"
    end

    assert_equal "space", custom_helper.moveable_root_label
    assert_equal "spaces", custom_helper.moveable_root_label(count: 2)
  end
end
