# frozen_string_literal: true

module RecordingStudioMoveable
  module Labels
    EMPTY_LABEL = "—"

    module_function

    def name_for(recordable)
      return EMPTY_LABEL unless recordable

      explicit_name_for(recordable) ||
        squished_value(recordable, :title) ||
        squished_value(recordable, :name) ||
        fallback_name_for(recordable)
    end

    def type_label_for(recordable_or_type)
      return EMPTY_LABEL if recordable_or_type.blank?

      type_name = type_name_for(recordable_or_type)
      return EMPTY_LABEL if type_name.blank?

      klass = type_name.safe_constantize

      explicit_type_label_for(klass) || fallback_type_label_for(type_name)
    end

    def title_for(recordable)
      return EMPTY_LABEL unless recordable

      squished_value(recordable, :title) ||
        squished_value(recordable, :name) ||
        name_for(recordable)
    end

    def resolver
      if defined?(RecordingStudio::Labels)
        RecordingStudio::Labels
      else
        self
      end
    end

    def explicit_name_for(recordable)
      call_first_present(recordable, :recordable_name, :recording_studio_label)
    end
    private_class_method :explicit_name_for

    def explicit_type_label_for(recordable_class)
      call_first_present(recordable_class, :recordable_type_label, :recording_studio_type_label)
    end
    private_class_method :explicit_type_label_for

    def fallback_name_for(recordable)
      class_name = normalize_label(recordable.class.name) || recordable.class.to_s
      identifier = recordable.respond_to?(:id) ? recordable.id : nil

      identifier.present? ? "#{class_name} ##{identifier}" : class_name
    end
    private_class_method :fallback_name_for

    def fallback_type_label_for(type_name)
      demodulized = type_name.demodulize
      normalized = demodulized.sub(/\ARecordingStudio/, "").presence || demodulized
      normalized.underscore.humanize
    end
    private_class_method :fallback_type_label_for

    def type_name_for(recordable_or_type)
      case recordable_or_type
      when String
        recordable_or_type
      when Class
        recordable_or_type.name
      else
        recordable_or_type.class.name
      end
    end
    private_class_method :type_name_for

    def squished_value(recordable, method_name)
      return unless recordable.respond_to?(method_name)

      normalize_label(recordable.public_send(method_name))
    end
    private_class_method :squished_value

    def call_first_present(target, *method_names)
      method_names.each do |method_name|
        next unless target.respond_to?(method_name)

        value = normalize_label(target.public_send(method_name))
        return value if value.present?
      end

      nil
    end
    private_class_method :call_first_present

    def normalize_label(value)
      text = value.to_s.squish
      text.presence
    end
    private_class_method :normalize_label
  end
end
