# frozen_string_literal: true

require "pathname"
require "test_helper"

class NoLegacyAccessApiReferencesTest < Minitest::Test
  FORBIDDEN_PATTERNS = {
    /RecordingStudio::Services::AccessCheck/ => "Use RecordingStudioAccessible query APIs instead of RecordingStudio::Services::AccessCheck.",
    /RecordingStudio::Access\b/ =>
      "Do not reference RecordingStudio::Access in runtime integration code. " \
      "Route access through Accessible APIs or a compatibility helper.",
    /RecordingStudioAccessible::AllowsAccessibleChildren/ =>
      "Use RecordingStudio.enable_capability(:accessible, on: self) instead.",
    /recording_studio_accessible_children/ =>
      "Use RecordingStudio.enable_capability(:accessible, on: self) instead.",
    /RecordingStudioAccessible::Services::GrantRecordingAccess/ =>
      "Use RecordingStudioAccessible.grant_access for direct grants."
  }.freeze

  ALLOWED_FILES = [
    File.expand_path("../test/dummy/db/migrate/20260217072823_add_indexes_for_access_container_lookup.rb", __dir__),
    File.expand_path("../test/dummy/db/migrate/20260217072824_replace_container_with_root_recording.rb", __dir__),
    File.expand_path("../test/dummy/db/schema.rb", __dir__),
    File.expand_path(__FILE__)
  ].freeze

  TARGET_GLOBS = [
    File.expand_path("../app/**/*.rb", __dir__),
    File.expand_path("../lib/**/*.rb", __dir__),
    File.expand_path("../test/**/*.rb", __dir__)
  ].freeze

  def test_runtime_code_does_not_reintroduce_legacy_access_api_references
    violations = scan_files.flat_map do |file_path|
      next [] if ALLOWED_FILES.include?(file_path)

      lines = File.readlines(file_path, chomp: true)
      FORBIDDEN_PATTERNS.flat_map do |pattern, message|
        lines.filter_map.with_index(1) do |line, line_number|
          next if line.lstrip.start_with?("#")
          next unless line.match?(pattern)

          "#{relative_path(file_path)}:#{line_number}: #{message}"
        end
      end
    end

    assert violations.empty?, violations.join("\n")
  end

  private

  def scan_files
    TARGET_GLOBS.flat_map { |glob| Dir.glob(glob) }.uniq.sort
  end

  def relative_path(file_path)
    Pathname.new(file_path).relative_path_from(Pathname.new(File.expand_path("..", __dir__))).to_s
  end
end
