class RecordingStudioFoldersController < ApplicationController
  def show
    @folder = RecordingStudioFolder.find(params[:id])
    @recording = RecordingStudio::Recording.find_by!(recordable: @folder)
  end
end
