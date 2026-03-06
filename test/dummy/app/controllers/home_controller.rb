class HomeController < ApplicationController
  def index
    @workspace = Workspace.first
    @root_recording = RecordingStudio::Recording.unscoped.find_by(
      recordable: @workspace,
      parent_recording_id: nil
    )
    @folders = RecordingStudio::Recording.where(root_recording_id: @root_recording&.id, recordable_type: "RecordingStudioFolder")
                                         .includes(:recordable).limit(10)
    @pages = RecordingStudio::Recording.where(root_recording_id: @root_recording&.id, recordable_type: "RecordingStudioPage")
                                       .includes(:recordable).limit(10)
    @archive_boxes = RecordingStudio::Recording.where(root_recording_id: @root_recording&.id,
                                                      recordable_type: "RecordingStudioArchiveBox")
                                               .includes(:recordable).limit(10)
  end
end
