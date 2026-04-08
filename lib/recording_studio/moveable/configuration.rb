# frozen_string_literal: true

module RecordingStudio
  module Moveable
    class Configuration
      attr_accessor :use_builtin_access, :authorization_hook, :redirect_resolver
      attr_writer :default_redirect_path, :default_redirect_mode

      def initialize
        # Safe default: rely on RecordingStudio's built-in access checks.
        @use_builtin_access = true
        # Safe default: custom mode denies unless the host app explicitly allows.
        @authorization_hook = ->(**) { false }
        @default_redirect_path = "/"
        @default_redirect_mode = :previous_page
        @redirect_resolver = nil
      end

      def default_redirect_path
        value = @default_redirect_path
        value.presence || "/"
      end

      def default_redirect_mode
        normalize_redirect_mode(@default_redirect_mode) || "previous_page"
      end

      def resolve_redirect(recording:, helpers:, fallback:, mode:)
        return fallback unless redirect_resolver.respond_to?(:call)

        redirect_resolver.call(
          recording: recording,
          helpers: helpers,
          fallback: fallback,
          mode: mode
        ).presence || fallback
      end

      def authorize_move?(actor:, source:, destination:, impersonator: nil, metadata: {})
        return false unless authorization_hook.respond_to?(:call)

        authorization_hook.call(
          actor: actor,
          source: source,
          destination: destination,
          impersonator: impersonator,
          metadata: metadata
        )
      end

      private

      def normalize_redirect_mode(value)
        candidate = value.to_s.presence
        return if candidate.blank?

        %w[previous_page moved_record destination root].include?(candidate) ? candidate : nil
      end
    end
  end
end
