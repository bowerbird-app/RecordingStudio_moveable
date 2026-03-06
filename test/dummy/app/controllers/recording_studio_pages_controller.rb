class RecordingStudioPagesController < ApplicationController
  def show
    @page = RecordingStudioPage.find(params[:id])
    @recording = RecordingStudio::Recording.find_by!(recordable: @page)
  end
end
