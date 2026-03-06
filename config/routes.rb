# frozen_string_literal: true

GemTemplate::Engine.routes.draw do
  root "home#index"

  get "/move/:recording_id", to: "moveables#show", as: :move_recording
  post "/move/:recording_id", to: "moveables#update"
end
