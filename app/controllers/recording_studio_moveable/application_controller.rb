# frozen_string_literal: true

module RecordingStudioMoveable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception if superclass == ActionController::Base
    layout "application" if superclass == ActionController::Base
    include Rails.application.routes.url_helpers

    helper Rails.application.routes.url_helpers
  end
end
