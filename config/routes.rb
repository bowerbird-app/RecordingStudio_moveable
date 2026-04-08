# frozen_string_literal: true

RecordingStudioMoveable::Engine.routes.draw do
  root "home#index"

  get "/move/:recording_id", to: "moveables#show", as: :move_recording
  get "/move/:recording_id/modal", to: "moveables#modal", as: :move_recording_modal
  post "/move/:recording_id", to: "moveables#update"
end
