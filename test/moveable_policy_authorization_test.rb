# frozen_string_literal: true

require "test_helper"

class MoveablePolicyTest < Minitest::Test
  def setup
    RecordingStudio::Moveable.reset_configuration!
    @actor = Object.new
    @source = Struct.new(:id).new("source")
    @destination = Struct.new(:id).new("destination")
    @impersonator = Struct.new(:id).new("impersonator")
  end

  def teardown
    RecordingStudio::Moveable.reset_configuration!
  end

  def test_destination_selectable_requires_source_and_destination_edit_access
    allowed = lambda do |actor:, recording:, role:|
      assert_same @actor, actor
      assert_equal :edit, role

      [@source, @destination].include?(recording)
    end

    RecordingStudio::Moveable::Access.stub(:allowed?, allowed) do
      policy = RecordingStudio::Moveable::Policy.new(actor: @actor, source: @source)
      hidden_destination = Struct.new(:id).new("hidden")

      assert policy.source_visible?
      assert policy.destination_visible?(destination: @destination)
      assert_equal [@destination], policy.filter_visible_destinations(
        destinations: [@destination, hidden_destination]
      )
    end
  end

  def test_built_in_access_is_backed_by_recording_studio_accessible
    assert defined?(RecordingStudioAccessible)
  end

  def test_destination_selectable_returns_false_when_destination_is_not_editable
    allowed = lambda do |actor:, recording:, role:|
      assert_same @actor, actor
      assert_equal :edit, role

      recording == @source
    end

    RecordingStudio::Moveable::Access.stub(:allowed?, allowed) do
      policy = RecordingStudio::Moveable::Policy.new(actor: @actor, source: @source)

      assert policy.source_editable?
      assert_not policy.destination_selectable?(destination: @destination)
    end
  end

  def test_authorize_move_raises_when_source_is_not_editable
    RecordingStudio::Moveable::Access.stub(:allowed?, ->(**) { false }) do
      policy = RecordingStudio::Moveable::Policy.new(actor: @actor, source: @source)

      error = assert_raises(RecordingStudio::AccessDenied) do
        policy.authorize_move!(destination: @destination)
      end

      assert_equal "Actor does not have edit access on the source recording", error.message
    end
  end

  def test_authorize_move_raises_when_destination_is_not_editable
    allowed = lambda do |recording:, **|
      recording == @source
    end

    RecordingStudio::Moveable::Access.stub(:allowed?, allowed) do
      policy = RecordingStudio::Moveable::Policy.new(actor: @actor, source: @source)

      error = assert_raises(RecordingStudio::AccessDenied) do
        policy.authorize_move!(destination: @destination)
      end

      assert_equal "Actor does not have edit access on the target recording", error.message
    end
  end

  def test_custom_authorization_mode_uses_hook_context
    received = []

    RecordingStudio::Moveable.configure do |config|
      config.use_builtin_access = false
      config.authorization_hook = lambda do |actor:, source:, destination:, impersonator:, metadata:|
        received << {
          actor: actor,
          source: source,
          destination: destination,
          impersonator: impersonator,
          metadata: metadata
        }
        [@source, @destination].include?(destination)
      end
    end

    policy = RecordingStudio::Moveable::Policy.new(
      actor: @actor,
      source: @source,
      impersonator: @impersonator,
      metadata: { "reason" => "reorg" }
    )

    assert policy.source_editable?
    assert policy.destination_selectable?(destination: @destination)
    assert policy.authorize_move!(destination: @destination)
    assert_equal 3, received.size
    assert_equal @source, received.first.fetch(:destination)
    assert_equal @destination, received[1].fetch(:destination)
    assert_equal @destination, received.last.fetch(:destination)
    assert(received.all? { |entry| entry[:actor] == @actor })
    assert(received.all? { |entry| entry[:source] == @source })
    assert(received.all? { |entry| entry[:impersonator] == @impersonator })
    assert(received.all? { |entry| entry[:metadata] == { "reason" => "reorg" } })
  end

  def test_custom_authorization_mode_raises_when_hook_denies_move
    RecordingStudio::Moveable.configure do |config|
      config.use_builtin_access = false
      config.authorization_hook = ->(**) { false }
    end

    policy = RecordingStudio::Moveable::Policy.new(actor: @actor, source: @source)

    error = assert_raises(RecordingStudio::AccessDenied) do
      policy.authorize_move!(destination: @destination)
    end

    assert_equal "Move authorization hook denied this move", error.message
  end
end

class MoveableAuthorizationTest < Minitest::Test
  FakePolicy = Struct.new(:source_visible_result, :source_editable_result, :destination_visible_result,
                          :destination_selectable_result, :filtered_result, :filtered_destinations,
                          :authorized_destination, keyword_init: true) do
    def source_visible?
      source_visible_result
    end

    def source_editable?
      source_editable_result
    end

    def destination_visible?(destination:)
      self.authorized_destination = destination
      destination_visible_result
    end

    def destination_selectable?(destination:)
      self.authorized_destination = destination
      destination_selectable_result
    end

    def filter_visible_destinations(destinations:)
      self.filtered_destinations = destinations
      filtered_result
    end

    define_method(:authorize_move!) do |destination:|
      self.authorized_destination = destination
      true
    end
  end

  def test_policy_builder_passes_context_to_policy
    actor = :actor
    source = :source
    impersonator = :impersonator
    metadata = { test: true }
    policy = Object.new

    policy_builder = lambda do |**kwargs|
      assert_equal(
        {
          actor: actor,
          source: source,
          impersonator: impersonator,
          metadata: metadata
        },
        kwargs
      )
      policy
    end

    RecordingStudio::Moveable::Policy.stub(:new, policy_builder) do
      assert_same policy,
                  RecordingStudio::Moveable::Authorization.policy(
                    actor: actor,
                    source: source,
                    impersonator: impersonator,
                    metadata: metadata
                  )
    end
  end

  def test_wrapper_methods_delegate_to_policy
    destination = :destination
    fake_policy = FakePolicy.new(
      source_visible_result: true,
      source_editable_result: false,
      destination_visible_result: true,
      destination_selectable_result: false,
      filtered_result: [:filtered]
    )

    RecordingStudio::Moveable::Authorization.stub(:policy, fake_policy) do
      assert RecordingStudio::Moveable::Authorization.source_visible?(actor: :actor, source: :source)
      assert_not RecordingStudio::Moveable::Authorization.source_allowed?(actor: :actor, source: :source)
      assert RecordingStudio::Moveable::Authorization.destination_visible?(
        actor: :actor,
        source: :source,
        destination: destination
      )
      assert_not RecordingStudio::Moveable::Authorization.destination_allowed?(
        actor: :actor,
        source: :source,
        destination: destination
      )
      assert_equal [:filtered], RecordingStudio::Moveable::Authorization.filter_visible_destinations(
        actor: :actor,
        source: :source,
        destinations: %i[one two]
      )
      assert RecordingStudio::Moveable::Authorization.assert_move_allowed!(
        actor: :actor,
        source: :source,
        destination: destination
      )
      assert_equal destination, fake_policy.authorized_destination
      assert_equal %i[one two], fake_policy.filtered_destinations
    end
  end
end
