class HomeController < ApplicationController
  def index
    @root_recording = Current.root_recording
    @workspace = Current.workspace

    @items = RecordingStudio::Recording.where(
      root_recording_id: @root_recording&.id,
      parent_recording_id: @root_recording&.id,
      recordable_type: [ "RecordingStudioFolder", "RecordingStudioPage" ]
    ).includes(:recordable).order(recordable_type: :asc, updated_at: :desc)

    render :index
  end
end
