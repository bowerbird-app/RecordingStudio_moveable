# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
require "rails"
require "recording_studio_accessible"
require "recording_studio_moveable"

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
