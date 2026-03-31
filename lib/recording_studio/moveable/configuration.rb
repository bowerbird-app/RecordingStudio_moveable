# frozen_string_literal: true

module RecordingStudio
  module Moveable
    class Configuration
      attr_accessor :use_builtin_access, :authorization_hook
      attr_writer :default_redirect_path

      def initialize
        # Safe default: rely on RecordingStudio's built-in access checks.
        @use_builtin_access = true
        # Safe default: custom mode denies unless the host app explicitly allows.
        @authorization_hook = ->(**) { false }
        @default_redirect_path = "/"
      end

      def default_redirect_path
        value = @default_redirect_path
        value.present? ? value : "/"
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
    end
  end
end
