# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
require "minitest/mock"
require "rails"
require "i18n"
require "recording_studio_accessible"
require "recording_studio_moveable"
require "yaml"

# Do not append gem locales to I18n.load_path here. Rails engines already put
# config/locales on the load path when the dummy boots; an explicit append can
# re-order files so gem English overrides the host. Unit tests (no Rails app)
# seed the backend from en.yml without touching the load path.
I18n.available_locales = Array(I18n.available_locales) | %i[en]
I18n.default_locale = :en
_gem_english = YAML.safe_load_file(
  File.expand_path("../config/locales/en.yml", __dir__),
  aliases: true
).fetch("en")
I18n.backend.store_translations(:en, _gem_english)

module Minitest
  module Assertions
    def assert_not(object, message = nil)
      message ||= "Expected #{mu_pp(object)} to be falsy"
      assert(!object, message)
    end

    def assert_not_nil(object, message = nil)
      message ||= "Expected #{mu_pp(object)} to not be nil"
      refute_nil(object, message)
    end
  end
end
