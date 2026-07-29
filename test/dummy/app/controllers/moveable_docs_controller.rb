class MoveableDocsController < ApplicationController
  def access
  end

  def setup
  end

  def methods
  end

  def redirects
  end

  def api
  end

  def scalar
    render layout: false
  end

  def openapi
    render json: RecordingStudioApi.openapi_document(version: "v1")
  end
end
