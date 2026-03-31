class EventsController < ApplicationController
  def index
    MoveableDemo::Bootstrap.call(actor: Current.actor)

    @events = RecordingStudio::Event.includes(:recording).order(occurred_at: :desc, created_at: :desc).limit(200)
  end
end