class RecordingsController < ApplicationController
  def index
    MoveableDemo::Bootstrap.call(actor: Current.actor)

    @recordings = RecordingStudio::Recording.includes(:recordable)
                                           .order(created_at: :desc)
                                           .limit(200)
  end
end