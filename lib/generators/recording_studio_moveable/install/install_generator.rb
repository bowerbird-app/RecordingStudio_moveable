# frozen_string_literal: true

module RecordingStudioMoveable
  module Generators
    class InstallGenerator < Rails::Generators::Base
      YAML_CONFIG_PROMPT = "Would you like to add `config/recording_studio_moveable.yml` " \
                           "for environment-specific settings? [y/N]"

      source_root File.expand_path("templates", __dir__)

      desc "Installs RecordingStudioMoveable into your application"

      def mount_engine
        route 'mount RecordingStudioMoveable::Engine, at: "/recording_studio_moveable", as: :recording_studio_moveable'
      end

      def copy_initializer
        template "recording_studio_moveable_initializer.rb", "config/initializers/recording_studio_moveable.rb"
      end

      def add_javascript_import
        javascript_path = Rails.root.join("app/javascript/application.js")

        unless File.exist?(javascript_path)
          say(
            "JavaScript entrypoint not found. Add `import \"recording_studio_moveable\"` " \
            "to your app entrypoint to enable modal links.",
            :yellow
          )
          return
        end

        javascript_content = File.read(javascript_path)
        import_line = 'import "recording_studio_moveable"'

        if javascript_content.include?(import_line)
          say "RecordingStudio Moveable JavaScript already imported.", :green
          return
        end

        append_to_file javascript_path, "\n#{import_line}\n"
        say "Added RecordingStudio Moveable JavaScript import.", :green
      end

      def add_yaml_config
        return unless yes?(YAML_CONFIG_PROMPT)

        template "recording_studio_moveable.yml", "config/recording_studio_moveable.yml"
      end

      def add_tailwind_source
        tailwind_css_path = Rails.root.join("app/assets/tailwind/application.css")

        unless File.exist?(tailwind_css_path)
          say "Tailwind CSS not detected. Skipping Tailwind configuration.", :yellow
          say "If you use Tailwind, add this line to your Tailwind CSS config:", :yellow
          say '  @source "../../vendor/bundle/**/recording_studio_moveable/app/views/**/*.erb";', :yellow
          return
        end

        tailwind_content = File.read(tailwind_css_path)
        source_line = '@source "../../vendor/bundle/**/recording_studio_moveable/app/views/**/*.erb";'

        if tailwind_content.include?(source_line)
          say "Tailwind already configured to include RecordingStudioMoveable views.", :green
          return
        end

        # Insert the @source directive after @import "tailwindcss";
        if tailwind_content.include?('@import "tailwindcss"')
          inject_into_file tailwind_css_path, after: "@import \"tailwindcss\";\n" do
            "\n/* Include RecordingStudioMoveable views for Tailwind CSS */\n#{source_line}\n"
          end
          say "Added RecordingStudioMoveable views to Tailwind CSS configuration.", :green
          say "Run 'bin/rails tailwindcss:build' to rebuild your CSS.", :green
        else
          say "Could not find @import \"tailwindcss\" in your Tailwind config.", :yellow
          say "Please manually add this line to your Tailwind CSS config:", :yellow
          say "  #{source_line}", :yellow
        end
      end

      def show_readme
        readme "INSTALL.md" if behavior == :invoke
      end
    end
  end
end
