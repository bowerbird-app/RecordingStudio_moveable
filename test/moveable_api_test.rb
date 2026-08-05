# frozen_string_literal: true

require "test_helper"

class MoveableApiTest < Minitest::Test
  ActionContext = Struct.new(:recording, :api_client, :credential, :access_grant, :params, keyword_init: true)
  ApiPrincipal = Struct.new(:id)

  class AccessibleRecordings
    attr_reader :looked_up_ids

    def initialize(records)
      @records = records
      @looked_up_ids = []
    end

    def find_by(id:)
      looked_up_ids << id
      @records[id]
    end
  end

  class AccessGrant
    attr_reader :authorized_recordings

    def initialize(records)
      @records = AccessibleRecordings.new(records)
      @authorized_recordings = []
    end

    def accessible_recordings
      @records
    end

    def authorize!(recording:, role:)
      authorized_recordings << [recording, role]
    end
  end

  class Recording
    attr_reader :recordable_type, :moved_with

    def initialize(recordable_type: "RecordingStudioPage", move_error: nil)
      @recordable_type = recordable_type
      @move_error = move_error
    end

    def move_to!(new_parent:, actor:, metadata:)
      raise @move_error if @move_error

      @moved_with = { new_parent: new_parent, actor: actor, metadata: metadata }
    end

    def reload
      self
    end
  end

  def test_registration_is_a_noop_without_recording_studio_api
    refute Object.const_defined?(:RecordingStudioApi, false)

    assert_nil RecordingStudio::Moveable::Api.register_capability_action!
  end

  def test_registration_registers_moveable_owned_member_action
    with_fake_recording_studio_api do |api|
      RecordingStudio::Moveable::Api.register_capability_action!

      registration = api.registrations.fetch(0)

      assert_equal :move, registration.fetch(:name)
      assert_equal :movable, registration.fetch(:capability)
      assert_equal "1.0.0", registration.fetch(:version)
      assert_equal ["Moveable-owned move action"], registration.fetch(:version_notes)
      assert_equal :post, registration.fetch(:http_verb)
      assert_equal :member, registration.fetch(:scope)
      assert_equal :edit, registration.fetch(:required_role)
      assert_equal RecordingStudio::Moveable::Api::MoveRecording, registration.fetch(:handler)
      assert_equal api.serializer, registration.fetch(:serializer)
      refute registration.fetch(:openapi).key?(:tags)
      assert_equal "Move", registration.fetch(:openapi).fetch(:summary)
      assert_equal expected_input_contract, registration.fetch(:input_contract)
    end
  end

  def test_registration_does_not_replace_an_existing_move_action
    existing_action = Object.new

    with_fake_recording_studio_api(existing_action:) do |api|
      assert_nil RecordingStudio::Moveable::Api.register_capability_action!
      assert_empty api.registrations
    end
  end

  def test_registration_registers_public_and_named_api_surfaces_independently
    with_fake_recording_studio_api(api_names: %w[public operations partners]) do |api|
      RecordingStudio::Moveable::Api.register_capability_action!
      registered_apis = api.registrations.map { |registration| registration.fetch(:api) }

      assert_equal %w[public operations partners], registered_apis
    end
  end

  def test_registration_does_not_replace_existing_actions_on_any_api_surface
    existing_actions = {
      "public" => Object.new,
      "operations" => Object.new
    }

    with_fake_recording_studio_api(api_names: %w[public operations partners], existing_actions:) do |api|
      RecordingStudio::Moveable::Api.register_capability_action!
      registered_apis = api.registrations.map { |registration| registration.fetch(:api) }

      assert_equal ["partners"], registered_apis
    end
  end

  def test_api_0_2_input_contract_filters_internal_string_and_symbol_keys
    with_fake_recording_studio_api(api_names: %w[public]) do |api|
      RecordingStudio::Moveable::Api.register_capability_action!
      contract = api.registrations.fetch(0).fetch(:input_contract)

      assert_operator contract.class, :<, api.action_input_contract

      result = contract.call("parent_id" => "destination", "api_key" => "public", api_version: "v1")

      assert result.success?, result.errors.join(", ")
      assert_equal({ parent_id: "destination" }, result.value)

      unknown_result = contract.call(parent_id: "destination", api_key: "public", "api_version" => "v1", extra: true)

      refute unknown_result.success?
      assert_equal ["Unknown parameters: extra"], unknown_result.errors
    end
  end

  def test_handler_authorizes_both_recordings_and_moves_to_parent_id
    destination = Recording.new(recordable_type: "RecordingStudioFolder")
    source = Recording.new
    access_grant = AccessGrant.new("destination" => destination)
    client = ApiPrincipal.new("client-1")
    credential = ApiPrincipal.new("credential-1")

    with_fake_recording_studio_api do
      result = RecordingStudio::Moveable::Api::MoveRecording.call(
        action_context(
          source:,
          access_grant:,
          client:,
          credential:,
          params: { parent_id: "destination" }
        )
      )

      assert_same source, result
      assert_equal [[source, :edit], [destination, :edit]], access_grant.authorized_recordings
      assert_equal(
        {
          new_parent: destination,
          actor: client,
          metadata: {
            api_action: "move",
            api_client_id: "client-1",
            api_credential_id: "credential-1"
          }
        },
        source.moved_with
      )
    end
  end

  def test_handler_accepts_legacy_destination_parameter_names
    destination = Recording.new(recordable_type: "RecordingStudioFolder")
    source = Recording.new
    access_grant = AccessGrant.new("destination" => destination)

    with_fake_recording_studio_api do
      RecordingStudio::Moveable::Api::MoveRecording.call(
        action_context(
          source:,
          access_grant:,
          params: { new_parent_id: "destination" }
        )
      )
    end

    assert_equal destination, source.moved_with.fetch(:new_parent)
  end

  def test_handler_rejects_missing_destination
    with_fake_recording_studio_api do |api|
      error = assert_raises(api.unsupported_action_error) do
        RecordingStudio::Moveable::Api::MoveRecording.call(
          action_context(source: Recording.new, access_grant: AccessGrant.new({}), params: {})
        )
      end

      assert_equal "parent_id is required for move", error.message
    end
  end

  def test_handler_does_not_disclose_or_authorize_destination_outside_access_scope
    source = Recording.new
    access_grant = AccessGrant.new({})

    with_fake_recording_studio_api do |api|
      error = assert_raises(api.not_found_error) do
        RecordingStudio::Moveable::Api::MoveRecording.call(
          action_context(source:, access_grant:, params: { destination_id: "hidden" })
        )
      end

      assert_equal "Destination recording was not found in this API scope", error.message
      assert_empty access_grant.authorized_recordings
    end
  end

  def test_handler_rejects_recordings_without_moveable_behavior
    unsupported_recording = Struct.new(:recordable_type).new("RecordingStudioArchiveBox")
    destination = Recording.new

    with_fake_recording_studio_api do |api|
      error = assert_raises(api.unsupported_action_error) do
        RecordingStudio::Moveable::Api::MoveRecording.call(
          action_context(
            source: unsupported_recording,
            access_grant: AccessGrant.new("destination" => destination),
            params: { destination_id: "destination" }
          )
        )
      end

      assert_equal "Move is not supported for RecordingStudioArchiveBox", error.message
    end
  end

  def test_handler_translates_known_structural_move_failures_without_mutation
    with_fake_recording_studio_api do |api|
      structural_failures(api).each do |move_error, expected_error_class|
        source = Recording.new(move_error:)

        error = assert_raises(expected_error_class) do
          RecordingStudio::Moveable::Api::MoveRecording.call(
            action_context(
              source:,
              access_grant: AccessGrant.new("destination" => Recording.new),
              params: { destination_id: "destination" }
            )
          )
        end

        assert_equal move_error.message, error.message
        assert_equal [move_error.message], error.details if error.respond_to?(:details)
        assert_nil source.moved_with
      end
    end
  end

  def test_handler_translates_move_policy_denial_without_mutation
    source = Recording.new(move_error: RecordingStudio::AccessDenied.new("Move authorization hook denied this move"))

    with_fake_recording_studio_api do |api|
      error = assert_raises(api.authorization_error) do
        RecordingStudio::Moveable::Api::MoveRecording.call(
          action_context(
            source:,
            access_grant: AccessGrant.new("destination" => Recording.new),
            params: { destination_id: "destination" }
          )
        )
      end

      assert_equal "Move authorization hook denied this move", error.message
      assert_nil source.moved_with
    end
  end

  def test_handler_preserves_unrecognized_argument_errors
    source = Recording.new(move_error: ArgumentError.new("unexpected move failure"))

    with_fake_recording_studio_api do
      error = assert_raises(ArgumentError) do
        RecordingStudio::Moveable::Api::MoveRecording.call(
          action_context(
            source:,
            access_grant: AccessGrant.new("destination" => Recording.new),
            params: { destination_id: "destination" }
          )
        )
      end

      assert_equal "unexpected move failure", error.message
      assert_nil source.moved_with
    end
  end

  private

  def expected_input_contract
    {
      reject_unknown: true,
      fields: {
        parent_id: { type: :string, allow_blank: false },
        destination_id: { type: :string, allow_blank: false },
        new_parent_id: { type: :string, allow_blank: false }
      }
    }
  end

  def action_context(source:, access_grant:, params:, client: ApiPrincipal.new("client-1"),
                     credential: ApiPrincipal.new("credential-1"))
    ActionContext.new(
      recording: source,
      api_client: client,
      credential: credential,
      access_grant:,
      params:
    )
  end

  def structural_failures(api)
    [
      [ArgumentError.new("Cannot move a recording under itself"), api.invalid_action_input_error],
      [ArgumentError.new("Cannot move a recording under its descendant"), api.invalid_action_input_error],
      [ArgumentError.new("Destination must belong to this root recording"), api.invalid_action_input_error],
      [RecordingStudio::InvalidParent.new("RecordingStudioPage cannot be recorded under RecordingStudioArchiveBox"),
       api.invalid_action_input_error],
      [RecordingStudio::CapabilityDisabled.new("movable is not enabled"), api.unsupported_action_error]
    ]
  end

  def with_fake_recording_studio_api(existing_action: nil, existing_actions: {}, api_names: nil)
    api = Module.new
    serializers = Module.new
    serializer = Class.new
    invalid_action_input_error = Class.new(StandardError) do
      attr_reader :details

      def initialize(message, details: [])
        super(message)
        @details = details
      end
    end

    serializers.const_set(:ResourceRecordingSerializer, serializer)
    api.const_set(:Serializers, serializers)
    api.const_set(:UnsupportedActionError, Class.new(StandardError))
    api.const_set(:InvalidActionInputError, invalid_action_input_error)
    api.const_set(:AuthorizationError, Class.new(StandardError))
    api.const_set(:NotFoundError, Class.new(StandardError))
    api.instance_variable_set(:@existing_action, existing_action)
    api.instance_variable_set(:@existing_actions, existing_actions.transform_keys(&:to_s))
    api.instance_variable_set(:@registrations, [])
    api.instance_variable_set(:@serializer, serializer)

    if api_names
      define_api_0_2_behavior(api, api_names)
    else
      api.define_singleton_method(:capability_action) { |name| @existing_action if name == :move }
      api.define_singleton_method(:register_capability_action) do |name, **options|
        @registrations << options.merge(name:)
      end
    end

    api.define_singleton_method(:registrations) { @registrations }
    api.define_singleton_method(:serializer) { @serializer }
    api.define_singleton_method(:action_input_contract) { const_get(:ActionInputContract) }
    api.define_singleton_method(:unsupported_action_error) { const_get(:UnsupportedActionError) }
    api.define_singleton_method(:invalid_action_input_error) { const_get(:InvalidActionInputError) }
    api.define_singleton_method(:authorization_error) { const_get(:AuthorizationError) }
    api.define_singleton_method(:not_found_error) { const_get(:NotFoundError) }

    Object.const_set(:RecordingStudioApi, api)
    yield api
  ensure
    Object.send(:remove_const, :RecordingStudioApi) if Object.const_defined?(:RecordingStudioApi, false)
  end

  def define_api_0_2_behavior(api, api_names)
    configuration = fake_api_configuration(api_names)

    api.const_set(:ActionInputContract, fake_action_input_contract_class)
    api.define_singleton_method(:configuration) { configuration }
    api.define_singleton_method(:capability_action) do |name, api: :public|
      @existing_actions[api.to_s] if name == :move
    end
    api.define_singleton_method(:register_capability_action) do |name, api: :public, **options|
      @registrations << options.merge(name:, api: api.to_s)
    end
  end

  def fake_action_input_contract_class
    contract_result = Struct.new(:success?, :value, :errors, keyword_init: true)
    Class.new do
      define_method(:initialize) do |definition|
        @definition = definition
        @fields = definition.fetch(:fields).keys.map(&:to_sym)
      end

      define_method(:call) do |raw_params|
        params = raw_params.to_h.transform_keys(&:to_sym)
        unknown_keys = params.keys - @fields
        errors = unknown_keys.empty? ? [] : ["Unknown parameters: #{unknown_keys.sort.join(', ')}"]
        value = errors.empty? ? params.slice(*@fields) : nil
        contract_result.new(success?: errors.empty?, value:, errors:)
      end

      define_method(:as_json) { |*| @definition }
    end
  end

  def fake_api_configuration(api_names)
    definitions = api_names.map { |name| Struct.new(:name).new(name.to_s) }
    Struct.new(:definitions) do
      def each_api(&)
        definitions.each(&)
      end
    end.new(definitions)
  end
end
