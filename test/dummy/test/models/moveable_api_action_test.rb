# frozen_string_literal: true

require_relative "../test_helper"

class MoveableApiActionTest < ActiveSupport::TestCase
  CrossRootAccessGrant = Struct.new(:destination) do
    def accessible_recordings
      RecordingStudio::Recording.where(id: destination.id)
    end

    def authorize!(**)
      true
    end
  end

  ApiPrincipal = Struct.new(:id)

  test "registers the Moveable-owned move action before the API fallback" do
    action = RecordingStudioApi.capability_action(:move, version: "v1")

    assert_equal :movable, action.capability
    assert_equal Gem::Version.new("1.0.0"), action.version
    assert_equal :post, action.http_verb
    assert_equal :member, action.scope
    assert_equal :edit, action.required_role
    assert_equal RecordingStudio::Moveable::Api::MoveRecording, action.handler
    assert_equal RecordingStudioApi::Serializers::ResourceRecordingSerializer, action.serializer

    accepted = action.input_contract.call(destination_id: "destination-id")
    rejected = action.input_contract.call(destination_id: "destination-id", unapproved: "value")

    assert_predicate accepted, :success?
    refute_predicate rejected, :success?
    assert_includes rejected.errors, "Unknown parameters: unapproved"
  end

  test "exposes move only for Moveable-enabled recordable types" do
    page_actions = RecordingStudioApi.capability_actions_for("RecordingStudioPage", version: "v1").map(&:name)
    archive_actions = RecordingStudioApi.capability_actions_for("RecordingStudioArchiveBox", version: "v1").map(&:name)

    assert_includes page_actions, "move"
    refute_includes archive_actions, "move"
  end

  test "translates a cross-root conflict without moving the recording" do
    actor = create_user
    _, source_root = create_workspace_root
    _, destination_root = create_workspace_root
    source = source_root.record(RecordingStudioFolder, actor: actor, parent_recording: source_root) do |folder|
      folder.name = "Cross-root source"
    end
    destination = destination_root.record(RecordingStudioFolder, actor: actor, parent_recording: destination_root) do |folder|
      folder.name = "Cross-root destination"
    end
    original_parent_id = source.parent_recording_id
    RecordingStudio.set_capability_options(:movable, on: RecordingStudioFolder.name, allow_cross_root: false)
    RecordingStudio::Moveable.configure do |config|
      config.use_builtin_access = false
      config.authorization_hook = ->(**) { true }
    end

    context = RecordingStudioApi::ActionContext.new(
      recording: source,
      api_client: ApiPrincipal.new("client-1"),
      credential: ApiPrincipal.new("credential-1"),
      access_recording: source_root,
      access_grant: CrossRootAccessGrant.new(destination),
      root_recording: source_root,
      params: { parent_id: destination.id }
    )

    error = assert_raises(RecordingStudioApi::InvalidActionInputError) do
      RecordingStudio::Moveable::Api::MoveRecording.call(context)
    end

    assert_equal "Destination must belong to this root recording", error.message
    assert_equal original_parent_id, source.reload.parent_recording_id
  end
end
