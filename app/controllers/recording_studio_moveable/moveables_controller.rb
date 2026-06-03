# frozen_string_literal: true

module RecordingStudioMoveable
  # rubocop:disable Metrics/ClassLength
  class MoveablesController < ApplicationController
    include RecordingStudioMoveable::MoveablesHelper

    helper RecordingStudioMoveable::MoveablesHelper

    helper_method :move_recording_path_for, :move_back_path, :move_workspaces_path_for, :moveable_root_label

    rescue_from LoadError, with: :handle_missing_access_dependency

    before_action :ensure_actor!
    before_action :load_recording

    def show
      prepare_show_state
      render layout: full_page_layout
    end

    def modal
      prepare_show_state
      @display = :modal
      render :modal, layout: false
    end

    def workspaces
      prepare_shared_state(display: :full_page)
      @back_path = workspace_recording_path
      @workspace_roots = filtered_workspace_roots

      render layout: full_page_layout
    end

    def update
      destination = find_destination!(params[:destination_id])
      move_recording!(destination)
      redirect_to move_redirect_target(destination: destination), notice: move_success_notice
    rescue *move_failure_exceptions => e
      redirect_to failed_move_path, alert: e.message
    end

    def moveable_root_label(count: 1)
      RecordingStudioMoveable::RootLabel.resolve(helpers, count: count)
    end

    private

    def prepare_show_state
      prepare_shared_state(display: params[:display] == "modal" ? :modal : :full_page)
      @current_root = current_root_recording
      @target_root = selected_target_root
      @back_path = target_root_back_path
      @workspace_selection_path = workspace_selection_path
      @destinations = filtered_destinations
    end

    def prepare_shared_state(display:)
      @display = display
      @query = params[:q].to_s.strip
      @redirect_to = form_redirect_target
      @redirect_mode = requested_redirect_mode
    end

    def move_recording!(destination)
      @recording.move_to!(
        new_parent: destination,
        actor: current_recording_studio_actor,
        impersonator: current_recording_studio_impersonator,
        metadata: move_metadata
      )
    end

    def failed_move_path
      move_recording_path_for(
        recording_id: @recording.id,
        display: params[:display],
        target_root_id: params[:target_root_id].presence,
        redirect_to: explicit_redirect_target,
        redirect_mode: requested_redirect_mode
      )
    end

    def failed_dependency_path
      return redirect_path unless defined?(@recording) && @recording.present?

      move_back_path
    end

    def handle_missing_access_dependency(error)
      redirect_to failed_dependency_path, alert: error.message
    end

    def load_recording
      @recording = RecordingStudio::Recording.find(params[:recording_id])
      raise ActiveRecord::RecordNotFound unless source_visible?
    end

    def ensure_actor!
      return if current_recording_studio_actor.present?

      raise RecordingStudio::AccessDenied, "A current actor is required to move recordings"
    end

    def filtered_destinations
      return [] unless source_allowed_for_destinations?

      destination_search.results(
        query: @query,
        root: @target_root
      )
    end

    def filtered_workspace_roots
      return [] unless source_allowed_for_destinations?

      destination_search.workspace_results(query: @query)
    end

    def source_allowed_for_destinations?
      move_policy.source_editable?
    end

    def find_destination!(destination_id)
      destination = RecordingStudio::Recording.find(destination_id)
      unless destination_search.allowed_destination?(destination)
        raise RecordingStudio::AccessDenied, "Destination is not allowed for this move"
      end

      destination
    end

    def destination_search
      @destination_search ||= RecordingStudio::Moveable::DestinationSearch.new(
        actor: current_recording_studio_actor,
        source: @recording,
        impersonator: current_recording_studio_impersonator,
        metadata: move_metadata,
        policy: move_policy
      )
    end

    def move_metadata
      raw_metadata = params[:metadata]
      return {} unless raw_metadata.respond_to?(:to_unsafe_h) || raw_metadata.respond_to?(:to_h)

      metadata_hash = if raw_metadata.respond_to?(:to_unsafe_h)
                        raw_metadata.to_unsafe_h
                      else
                        raw_metadata.to_h
                      end

      { "client_metadata" => metadata_hash.deep_stringify_keys }
    end

    def source_visible?
      move_policy.source_visible?
    end

    def move_policy
      @move_policy ||= RecordingStudio::Moveable::Policy.new(
        actor: current_recording_studio_actor,
        source: @recording,
        impersonator: current_recording_studio_impersonator,
        metadata: move_metadata
      )
    end

    def redirect_path
      helper = main_app
      return helper.root_path if helper.respond_to?(:root_path)

      RecordingStudio::Moveable.configuration.default_redirect_path
    end

    def move_redirect_target(destination: nil)
      return explicit_redirect_target if explicit_redirect_target.present?

      redirect_target = redirect_target_for_mode(requested_redirect_mode, destination: destination)
      return redirect_target if redirect_target.present?

      move_back_path
    end

    def move_recording_path_for(...)
      RecordingStudioMoveable::Engine.routes.url_helpers.move_recording_path(...)
    end

    def move_workspaces_path_for(...)
      RecordingStudioMoveable::Engine.routes.url_helpers.move_recording_workspaces_path(...)
    end

    def workspace_recording_path
      move_recording_path_for(
        recording_id: @recording.id,
        redirect_to: form_redirect_target,
        redirect_mode: requested_redirect_mode
      )
    end

    def move_back_path
      explicit_redirect_target || normalize_redirect_target(request&.referer) || redirect_path
    end

    def target_root_back_path
      return move_back_path unless @target_root.present?

      move_workspaces_path_for(
        recording_id: @recording.id,
        redirect_to: form_redirect_target,
        redirect_mode: requested_redirect_mode
      )
    end

    def workspace_selection_path
      return unless source_allowed_for_cross_root_destinations?

      move_workspaces_path_for(
        recording_id: @recording.id,
        redirect_to: form_redirect_target,
        redirect_mode: requested_redirect_mode
      )
    end

    def source_allowed_for_cross_root_destinations?
      destination_search.workspace_results(query: nil, limit: 1).any?
    end

    def move_failure_exceptions
      [
        RecordingStudio::AccessDenied,
        ArgumentError,
        ActiveRecord::RecordInvalid,
        ActiveRecord::RecordNotFound,
        ("RecordingStudio::InvalidParent".safe_constantize)
      ].compact
    end

    def selected_target_root
      return if params[:target_root_id].blank?

      root = RecordingStudio::Recording.find(params[:target_root_id])
      raise ActiveRecord::RecordNotFound unless destination_search.allowed_workspace_root?(root)

      root
    end

    def current_root_recording
      RecordingStudio.root_recording_or_self(@recording)
    end

    def explicit_redirect_target
      @explicit_redirect_target ||= normalize_redirect_target(params[:redirect_to])
    end

    def form_redirect_target
      return explicit_redirect_target if explicit_redirect_target.present?
      return move_back_path if requested_redirect_mode == "previous_page"

      nil
    end

    def requested_redirect_mode
      @requested_redirect_mode ||= begin
        normalized_mode = normalize_redirect_mode(params[:redirect_mode])
        normalized_mode.presence || RecordingStudio::Moveable.configuration.default_redirect_mode
      end
    end

    def normalize_redirect_mode(candidate)
      value = candidate.to_s.presence
      return if value.blank?

      %w[previous_page moved_record destination root].include?(value) ? value : nil
    end

    def redirect_target_for_mode(mode, destination:)
      case mode
      when "previous_page"
        move_back_path
      when "moved_record"
        recording_redirect_path_for(@recording, mode: mode)
      when "destination"
        recording_redirect_path_for(destination, mode: mode)
      when "root"
        redirect_path
      end
    end

    def move_success_notice
      I18n.t("recording_studio_moveable.moveables.update.notice", default: "Moved successfully.")
    end

    def recording_redirect_path_for(recording, mode:)
      return if recording.blank?

      helper = main_app
      redirect_target = resolved_recording_redirect_target(recording: recording, helper: helper, mode: mode)

      normalize_redirect_target(redirect_target)
    rescue ActionController::UrlGenerationError, NoMethodError
      nil
    end

    def resolved_recording_redirect_target(recording:, helper:, mode:)
      default_path = helper.polymorphic_path(recording.recordable)

      RecordingStudio::Moveable.configuration.resolve_redirect(
        recording: recording,
        helpers: helper,
        fallback: default_path,
        mode: mode
      )
    end

    def normalize_redirect_target(candidate)
      return if candidate.blank?

      redirect_uri = URI.parse(candidate)
      current_uri = URI.parse(request.original_url)

      return unless safe_redirect_target?(redirect_uri, current_uri)

      redirect_path = [redirect_uri.path.presence || "/", redirect_uri.query.presence].compact.join("?")
      return if redirect_path == request.fullpath

      redirect_path
    rescue URI::InvalidURIError
      nil
    end

    def safe_redirect_target?(redirect_uri, current_uri)
      safe_redirect_scheme?(redirect_uri) && same_redirect_host?(redirect_uri, current_uri) &&
        same_redirect_port?(redirect_uri, current_uri)
    end

    def safe_redirect_scheme?(redirect_uri)
      redirect_uri.scheme.blank? || %w[http https].include?(redirect_uri.scheme)
    end

    def same_redirect_host?(redirect_uri, current_uri)
      redirect_uri.host.blank? || redirect_uri.host == current_uri.host
    end

    def same_redirect_port?(redirect_uri, current_uri)
      redirect_uri.port.blank? || redirect_uri.port == current_uri.port
    end

    def full_page_layout
      return false unless @display == :full_page

      RecordingStudioMoveable.configuration.full_page_layout.presence || "recording_studio_moveable"
    end
  end
  # rubocop:enable Metrics/ClassLength
end
