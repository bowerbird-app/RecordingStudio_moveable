# frozen_string_literal: true

module GemTemplate
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    layout "application"
    include Rails.application.routes.url_helpers

    helper Rails.application.routes.url_helpers

    before_action :set_current_context

    private

    def set_current_context
      return unless defined?(Current)

      Current.actor = current_user if respond_to?(:current_user, true)
      Current.impersonator = nil if Current.respond_to?(:impersonator=)
    end
  end
end
