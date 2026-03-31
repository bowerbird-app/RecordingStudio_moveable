# frozen_string_literal: true

require_relative "hooks"

module GemTemplate
  class Configuration
    attr_accessor :api_key, :enable_feature_x, :timeout,
                  :move_modal_prefetch_enabled, :move_modal_prefetch_delay_ms,
                  :move_modal_prefetch_ttl_ms, :move_modal_reuse_shell
    attr_reader :hooks

    def initialize
      @api_key = ENV.fetch("GEM_TEMPLATE_API_KEY", nil)
      @enable_feature_x = false
      @timeout = 5
      @move_modal_prefetch_enabled = true
      @move_modal_prefetch_delay_ms = 80
      @move_modal_prefetch_ttl_ms = 10_000
      @move_modal_reuse_shell = true
      @hooks = Hooks.new
    end

    def to_h
      {
        api_key: api_key,
        enable_feature_x: enable_feature_x,
        timeout: timeout,
        move_modal_prefetch_enabled: move_modal_prefetch_enabled,
        move_modal_prefetch_delay_ms: move_modal_prefetch_delay_ms,
        move_modal_prefetch_ttl_ms: move_modal_prefetch_ttl_ms,
        move_modal_reuse_shell: move_modal_reuse_shell,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end
  end
end
