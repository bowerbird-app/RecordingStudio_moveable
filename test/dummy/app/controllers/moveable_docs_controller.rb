class MoveableDocsController < ApplicationController
  def show
    MoveableDemo::Bootstrap.call(actor: Current.actor)
  end
end