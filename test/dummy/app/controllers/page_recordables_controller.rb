class PageRecordablesController < ApplicationController
  def index
    MoveableDemo::Bootstrap.call(actor: Current.actor)

    @page_recordables = RecordingStudioPage.order(created_at: :desc).limit(200)
    @recordings_by_page_id = RecordingStudio::Recording.where(
      recordable_type: "RecordingStudioPage",
      recordable_id: @page_recordables.map(&:id)
    ).index_by(&:recordable_id)
  end
end