# frozen_string_literal: true

require_relative "hooks"

module RecordingStudioMoveable
  class Configuration
    SERIALIZABLE_ATTRIBUTES = %i[
      api_key
      enable_feature_x
      timeout
      move_modal_prefetch_enabled
      move_modal_prefetch_delay_ms
      move_modal_prefetch_ttl_ms
      move_modal_reuse_shell
      full_page_layout
      current_actor_resolver
      current_impersonator_resolver
    ].freeze

    attr_accessor :api_key,
                  :enable_feature_x,
                  :timeout,
                  :move_modal_prefetch_enabled,
                  :move_modal_prefetch_delay_ms,
                  :move_modal_prefetch_ttl_ms,
                  :move_modal_reuse_shell,
                  :full_page_layout,
                  :current_actor_resolver,
                  :current_impersonator_resolver
    attr_reader :hooks

    def initialize
      @api_key = ENV.fetch("RECORDING_STUDIO_MOVEABLE_API_KEY", nil)
      @enable_feature_x = false
      @timeout = 5
      @move_modal_prefetch_enabled = true
      @move_modal_prefetch_delay_ms = 80
      @move_modal_prefetch_ttl_ms = 10_000
      @move_modal_reuse_shell = true
      @full_page_layout = "recording_studio_moveable"
      initialize_context_resolvers
      @hooks = Hooks.new
    end

    def to_h
      SERIALIZABLE_ATTRIBUTES.index_with { |attribute| public_send(attribute) }
                             .merge(hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size))
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end

    def initialize_context_resolvers
      @current_actor_resolver = nil
      @current_impersonator_resolver = nil
    end
  end
end
