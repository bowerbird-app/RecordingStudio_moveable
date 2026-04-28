class RecordingStudioPagesController < ApplicationController
  def show
    @page = RecordingStudioPage.find(params[:id])
    @recording = require_recording_view_access!(RecordingStudio::Recording.find_by!(recordable: @page))
  end
end
