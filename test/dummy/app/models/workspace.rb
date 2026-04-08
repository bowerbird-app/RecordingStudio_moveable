class Workspace < ApplicationRecord
	RecordingStudioIcons.register_default_icon self,
		library: :heroicons,
		name: "rectangle-stack",
		variant: :outline
end
