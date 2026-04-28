# frozen_string_literal: true

require "bundler"
require "bundler/gem_tasks"
require "rake/testtask"
require "rbconfig"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
                 .exclude("test/dummy/**/*_test.rb", "test/rename_verification_test.rb")
  t.verbose = false
end

namespace :test do
  desc "Run rename verification tests to validate gem naming consistency"
  task :rename_verification do
    ruby "test/rename_verification_test.rb", verbose: true
  end

  desc "Run rename verification tests in verbose mode"
  task :rename_verification_verbose do
    ruby "test/rename_verification_test.rb", "--verbose", verbose: true
  end
end

def dummy_test_launcher
  <<~'RUBY'
    dummy_dir, dummy_gemfile = ARGV
    env_pairs = {
      "PATH" => ENV.fetch("PATH"),
      "HOME" => ENV.fetch("HOME"),
      "LANG" => ENV["LANG"],
      "LC_ALL" => ENV["LC_ALL"],
      "BUNDLE_PATH" => ENV["BUNDLE_PATH"],
      "BUNDLE_APP_CONFIG" => ENV["BUNDLE_APP_CONFIG"],
      "BUNDLE_GEMFILE" => dummy_gemfile,
      "DB_HOST" => ENV["DB_HOST"],
      "DB_PORT" => ENV["DB_PORT"],
      "DB_USER" => ENV["DB_USER"],
      "DB_PASSWORD" => ENV["DB_PASSWORD"],
      "DB_NAME" => ENV["DB_NAME"],
      "DATABASE_URL" => ENV["DATABASE_URL"]
    }.compact

    command_env = ["env", "-i", *env_pairs.map { |key, value| "#{key}=#{value}" }]

    Dir.chdir(dummy_dir) do
      success = system(*command_env, "bundle", "exec", "rails", "tailwindcss:build", "RAILS_ENV=test")
      success &&= system(*command_env, "bundle", "exec", "rails", "db:prepare", "RAILS_ENV=test")
      success &&= system(*command_env, "bundle", "exec", "rails", "test")
      exit(success ? 0 : 1)
    end
  RUBY
end

def dummy_test_child_env
  ENV.to_h.reject do |key, _value|
    key == "RUBYOPT" || key == "BUNDLE_BIN_PATH" || key == "BUNDLE_GEMFILE" || key.start_with?("BUNDLER_")
  end
end

def run_dummy_test_suite(dummy_dir:, dummy_gemfile:)
  success = system(dummy_test_child_env, RbConfig.ruby, "-e", dummy_test_launcher, dummy_dir, dummy_gemfile)
  raise "Dummy app tests failed" unless success
end

desc "Run all tests for the gem"
task "app:test" do
  Rake::Task[:test].invoke

  dummy_gemfile = File.expand_path("test/dummy/Gemfile", __dir__)
  dummy_dir = File.expand_path("test/dummy", __dir__)

  run_dummy_test_suite(dummy_dir: dummy_dir, dummy_gemfile: dummy_gemfile)
end

task default: :test
