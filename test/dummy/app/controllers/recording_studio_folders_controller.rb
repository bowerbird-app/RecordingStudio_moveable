class RecordingStudioFoldersController < ApplicationController
  def show
    @folder = RecordingStudioFolder.find(params[:id])
    @recording = require_recording_view_access!(RecordingStudio::Recording.find_by!(recordable: @folder))
    @children = filter_viewable_recordings(RecordingStudio::Recording.where(
      root_recording_id: @recording.root_recording_id,
      parent_recording_id: @recording.id,
      recordable_type: [ "RecordingStudioFolder", "RecordingStudioPage" ]
    ).includes(:recordable).order(recordable_type: :asc, updated_at: :desc))
  end
end
