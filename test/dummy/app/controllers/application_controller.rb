class ApplicationController < ActionController::Base
  WORKSPACE_SESSION_KEY = :current_workspace_root_id

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  layout :application_layout

  before_action :authenticate_user!
  before_action :set_current_actor
  before_action :set_workspace_context, unless: :devise_controller?

  helper_method :accessible_workspace_roots, :current_workspace_root, :current_workspace_label, :workspace_label_for

  private

  def application_layout
    devise_controller? ? "application" : "flat_pack_sidebar"
  end

  def set_current_actor
    Current.actor = request.env["warden"]&.authenticated?(:user) ? current_user : nil
  end

  def set_workspace_context
    return if Current.actor.blank?

    root_recording = selected_workspace_root || default_workspace_root || accessible_workspace_roots.first
    Current.root_recording = root_recording
    Current.workspace = root_recording&.recordable
    session[WORKSPACE_SESSION_KEY] = root_recording&.id
  end

  def accessible_workspace_roots
    return [] if Current.actor.blank?

    @accessible_workspace_roots ||= begin
      roots_by_id = RecordingStudio::Recording.where(id: accessible_workspace_root_ids)
                                              .includes(:recordable)
                                              .index_by(&:id)

      accessible_workspace_root_ids.filter_map { |root_id| roots_by_id[root_id] }
                                   .uniq
                                   .sort_by { |root_recording| workspace_label_for(root_recording).downcase }
    end
  end

  def current_workspace_root
    Current.root_recording
  end

  def current_workspace_label
    workspace_label_for(current_workspace_root)
  end

  def workspace_label_for(root_recording)
    return "Workspace" if root_recording.blank?

    recordable = root_recording.recordable
    return recordable.name if recordable.respond_to?(:name) && recordable.name.present?

    "Workspace"
  end

  def selected_workspace_root
    return if session[WORKSPACE_SESSION_KEY].blank?

    accessible_workspace_roots.find { |root_recording| root_recording.id == session[WORKSPACE_SESSION_KEY] }
  end

  def default_workspace_root
    preferred_names = MoveableDemo::Bootstrap::WORKSPACES.filter_map do |workspace_data|
      workspace_data[:name] if workspace_data[:grant_access]
    end

    preferred_names.each do |workspace_name|
      matching_root = accessible_workspace_roots.find do |root_recording|
        workspace_label_for(root_recording) == workspace_name
      end
      return matching_root if matching_root.present?
    end

    nil
  end

  def accessible_workspace_root_ids
    @accessible_workspace_root_ids ||= begin
      accessible_query = RecordingStudioAccessible::DirectAccessQuery.access_recordings_for_actor_in(
        recordings: workspace_roots_scope,
        actor: Current.actor
      )

      accessible_query.unscope(:order).distinct.pluck(:parent_recording_id)
    end
  end

  def workspace_roots_scope
    RecordingStudio::Recording.where(recordable_type: "Workspace", parent_recording_id: nil)
  end

  def require_recording_view_access!(recording)
    raise ActiveRecord::RecordNotFound unless recording_viewable?(recording)

    recording
  end

  def filter_viewable_recordings(recordings)
    Array(recordings).select { |recording| recording_viewable?(recording) }
  end

  def recording_viewable?(recording)
    RecordingStudio::Moveable::Access.allowed?(
      actor: Current.actor,
      recording: recording,
      role: :view
    )
  end
end
