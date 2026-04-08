# frozen_string_literal: true

require "test_helper"

class MoveablesHelperTest < Minitest::Test
  def helper
    @helper ||= Class.new do
      include RecordingStudioMoveable::MoveablesHelper
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

  def test_moveable_picker_item_omits_badge_and_meta
    recordable = Struct.new(:title).new("Studio Workspace")
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

    assert_equal "Studio Workspace", item[:label]
    assert_equal "Root", item[:description]
    assert_not item.key?(:badge)
    assert_not item.key?(:meta)
  end
end
