# frozen_string_literal: true

module GemTemplate
  # rubocop:disable Metrics/ClassLength
  class MoveablesController < ApplicationController
    include GemTemplate::MoveablesHelper

    helper_method :move_recording_path_for, :move_back_path

    before_action :ensure_actor!
    before_action :load_recording

    def show
      prepare_show_state
      render layout: full_page_layout
    end

    def update
      move_recording!(find_destination!(params[:destination_id]))
      redirect_to move_redirect_target, notice: "Moved successfully."
    rescue RecordingStudio::AccessDenied, ArgumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      redirect_to failed_move_path, alert: e.message
    end

    private

    def prepare_show_state
      @display = params[:display] == "modal" ? :modal : :full_page
      @query = params[:q].to_s.strip
      @redirect_to = move_redirect_target
      @destinations = filtered_destinations
    end

    def move_recording!(destination)
      @recording.move_to!(
        new_parent: destination,
        actor: Current.actor,
        impersonator: resolve_impersonator,
        metadata: move_metadata
      )
    end

    def failed_move_path
      move_recording_path_for(
        recording_id: @recording.id,
        display: params[:display],
        redirect_to: move_redirect_target
      )
    end

    def load_recording
      @recording = RecordingStudio::Recording.find(params[:recording_id])
      raise ActiveRecord::RecordNotFound unless source_visible?
    end

    def ensure_actor!
      raise RecordingStudio::AccessDenied, "A current actor is required to move recordings" if Current.actor.blank?
    end

    def filtered_destinations
      return [] unless source_allowed_for_destinations?

      destinations = destination_candidates
      destinations = filter_destinations_by_query(destinations)

      RecordingStudio::Moveable::Authorization.filter_visible_destinations(
        actor: Current.actor,
        source: @recording,
        destinations: destinations,
        impersonator: resolve_impersonator
      )
    end

    def source_allowed_for_destinations?
      RecordingStudio::Moveable::Authorization.source_allowed?(actor: Current.actor, source: @recording)
    end

    def destination_candidates
      RecordingStudio::Recording.where(root_recording_id: @recording.root_recording_id)
                                .where(recordable_type: allowed_parent_types)
                                .where.not(id: excluded_destination_ids)
                                .includes(:recordable)
                                .order(updated_at: :desc)
                                .limit(200)
                                .to_a
    end

    def filter_destinations_by_query(destinations)
      return destinations unless @query.present?

      query = @query.downcase
      destinations.select { |recording| moveable_label_for(recording).downcase.include?(query) }
    end

    def excluded_destination_ids
      [@recording.id, *descendant_ids(@recording)]
    end

    def descendant_ids(recording)
      descendants = []
      frontier = [recording.id]

      until frontier.empty?
        children = RecordingStudio::Recording.where(parent_recording_id: frontier).pluck(:id)
        descendants.concat(children)
        frontier = children
      end

      descendants
    end

    def allowed_parent_types
      options = RecordingStudio.capability_options(:movable, for_type: @recording.recordable_type) || {}
      Array(options[:allowed_parent_types]).map(&:to_s)
    end

    def find_destination!(destination_id)
      destination = RecordingStudio::Recording.find(destination_id)
      unless filtered_destinations.map(&:id).include?(destination.id)
        raise RecordingStudio::AccessDenied, "Destination is not allowed for this move"
      end

      destination
    end

    def move_metadata
      raw_metadata = params[:metadata]
      return {} unless raw_metadata.respond_to?(:to_unsafe_h) || raw_metadata.respond_to?(:to_h)

      metadata_hash = if raw_metadata.respond_to?(:to_unsafe_h)
                        raw_metadata.to_unsafe_h
                      else
                        raw_metadata.to_h
                      end

      metadata_hash.stringify_keys
    end

    def resolve_impersonator
      Current.respond_to?(:impersonator) ? Current.impersonator : nil
    end

    def source_visible?
      RecordingStudio::Moveable::Authorization.source_visible?(
        actor: Current.actor,
        source: @recording,
        impersonator: resolve_impersonator
      )
    end

    def redirect_path
      helper = main_app
      return helper.root_path if helper.respond_to?(:root_path)

      RecordingStudio::Moveable.configuration.default_redirect_path
    end

    def move_redirect_target
      explicit_redirect = normalize_redirect_target(params[:redirect_to])
      return explicit_redirect if explicit_redirect.present?

      move_back_path
    end

    def move_recording_path_for(...)
      GemTemplate::Engine.routes.url_helpers.move_recording_path(...)
    end

    def move_back_path
      normalize_redirect_target(request&.referer) || redirect_path
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
      return "flat_pack_sidebar" if lookup_context.exists?("layouts/flat_pack_sidebar", [], false)

      true
    end
  end
  # rubocop:enable Metrics/ClassLength
end
