class EventsController < ApplicationController
  def index
    @events = RecordingStudio::Event.includes(:recording)
                                   .where(recording: { root_recording_id: Current.root_recording&.id })
                                   .order(occurred_at: :desc, created_at: :desc)
                                   .limit(200)
  end
end
