module ApplicationHelper
	def moveable_demo_icon_classes(size: :md)
		case size.to_sym
		when :lg
			"h-6 w-6"
		else
			"h-5 w-5"
		end
	end

	def moveable_demo_recordable_icon(recordable, size: :md, css_class: nil)
		render_recording_studio_icon(
			recordable,
			class: [moveable_demo_icon_classes(size: size), css_class].compact.join(" ")
		)
	end
end
