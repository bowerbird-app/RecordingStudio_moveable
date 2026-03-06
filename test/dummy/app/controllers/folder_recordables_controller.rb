class FolderRecordablesController < ApplicationController
  def index
    MoveableDemo::Bootstrap.call(actor: Current.actor)

    @folder_recordables = RecordingStudioFolder.order(created_at: :desc).limit(200)
    @recordings_by_folder_id = RecordingStudio::Recording.where(
      recordable_type: "RecordingStudioFolder",
      recordable_id: @folder_recordables.map(&:id)
    ).index_by(&:recordable_id)
  end
end