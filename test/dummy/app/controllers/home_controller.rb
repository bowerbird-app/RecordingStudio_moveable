class HomeController < ApplicationController
  def index
    MoveableDemo::Bootstrap.call(actor: Current.actor)

    @workspace = Workspace.first
    @root_recording = RecordingStudio::Recording.unscoped.find_by(
      recordable: @workspace,
      parent_recording_id: nil
    )

    @items = RecordingStudio::Recording.where(
      root_recording_id: @root_recording&.id,
      parent_recording_id: @root_recording&.id,
      recordable_type: ["RecordingStudioFolder", "RecordingStudioPage"]
    ).includes(:recordable).order(recordable_type: :asc, updated_at: :desc)

    render :index
  end
end
