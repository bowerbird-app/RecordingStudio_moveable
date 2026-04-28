# frozen_string_literal: true

module RecordingStudioMoveable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception if superclass == ActionController::Base
    layout "application" if superclass == ActionController::Base
    include Rails.application.routes.url_helpers

    helper Rails.application.routes.url_helpers

    private

    def current_recording_studio_actor
      if defined?(Current) && Current.respond_to?(:actor)
        actor = Current.actor
        return actor if actor.present?
      end

      configured_recording_studio_context(:current_actor_resolver)
    end

    def current_recording_studio_impersonator
      if defined?(Current) && Current.respond_to?(:impersonator)
        impersonator = Current.impersonator
        return impersonator if impersonator.present?
      end

      configured_recording_studio_context(:current_impersonator_resolver)
    end

    def configured_recording_studio_context(resolver_name)
      resolver = RecordingStudioMoveable.configuration.public_send(resolver_name)
      return unless resolver.respond_to?(:call)

      resolver.call(controller: self)
    end
  end
end
