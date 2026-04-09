class WorkspaceSelectionsController < ApplicationController
  def update
    root_recording = accessible_workspace_roots.find { |root| root.id == params[:root_recording_id] }

    if root_recording.present?
      session[ApplicationController::WORKSPACE_SESSION_KEY] = root_recording.id
      redirect_to safe_return_to, notice: "Switched to #{workspace_label_for(root_recording)}."
    else
      redirect_to safe_return_to, alert: "Workspace is not available."
    end
  end

  private

  def safe_return_to
    candidate = params[:return_to].to_s
    return root_path if candidate.blank?
    return root_path unless candidate.start_with?("/")
    return root_path if candidate.start_with?("//")

    candidate
  end
end
