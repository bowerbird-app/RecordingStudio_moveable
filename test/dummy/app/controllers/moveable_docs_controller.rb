class MoveableDocsController < ApplicationController
  def show
    MoveableDemo::Bootstrap.call(actor: Current.actor)
  end

  def access
    MoveableDemo::Bootstrap.call(actor: Current.actor)
  end

  def setup
    MoveableDemo::Bootstrap.call(actor: Current.actor)
  end

  def methods
    MoveableDemo::Bootstrap.call(actor: Current.actor)
  end

  def redirects
    MoveableDemo::Bootstrap.call(actor: Current.actor)
  end
end