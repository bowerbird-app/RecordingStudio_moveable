# frozen_string_literal: true

module GemTemplate
  class MoveablesController < ApplicationController
    include GemTemplate::MoveablesHelper

    before_action :load_recording
    before_action :ensure_actor!

    def show
      @display = params[:display] == "modal" ? :modal : :full_page
      @query = params[:q].to_s.strip
      @destinations = filtered_destinations

      render layout: @display == :full_page
    end

    def update
      destination = find_destination!(params[:destination_id])
      metadata = move_metadata

      @recording.move_to!(
        new_parent: destination,
        actor: Current.actor,
        impersonator: resolve_impersonator,
        metadata: metadata
      )

      redirect_to redirect_path, notice: "Moved successfully."
    rescue RecordingStudio::AccessDenied, ArgumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      redirect_to move_recording_path(recording_id: @recording.id), alert: e.message
    end

    private

    def load_recording
      @recording = RecordingStudio::Recording.find(params[:recording_id])
    end

    def ensure_actor!
      raise RecordingStudio::AccessDenied, "A current actor is required to move recordings" if Current.actor.blank?
    end

    def filtered_destinations
      return [] unless RecordingStudio::Moveable::Authorization.source_allowed?(actor: Current.actor, source: @recording)

      relation = RecordingStudio::Recording.where(root_recording_id: @recording.root_recording_id)
                                          .where(recordable_type: allowed_parent_types)
                                          .where.not(id: excluded_destination_ids)
                                          .includes(:recordable)
                                          .order(updated_at: :desc)

      destinations = relation.limit(200).to_a

      if @query.present?
        query = @query.downcase
        destinations.select! { |recording| moveable_label_for(recording).downcase.include?(query) }
      end

      destinations.select do |destination|
        RecordingStudio::Moveable::Authorization.destination_allowed?(actor: Current.actor, source: @recording,
                                                                      destination: destination)
      end
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

    def redirect_path
      helper = main_app
      return helper.root_path if helper.respond_to?(:root_path)

      RecordingStudio::Moveable.configuration.default_redirect_path
    end
  end
end
