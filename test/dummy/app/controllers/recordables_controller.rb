class RecordablesController < ApplicationController
  def index
    @recordables = [ Workspace, RecordingStudioFolder, RecordingStudioPage, RecordingStudioArchiveBox ]
  end
end