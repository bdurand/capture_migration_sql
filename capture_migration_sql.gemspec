# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "capture_migration_sql"
  spec.version = File.read(File.expand_path("VERSION", __dir__)).strip
  spec.authors = ["Brian Durand"]
  spec.email = ["bbdurand@gmail.com"]

  spec.summary = "Capture the SQL that is executed when running ActiveRecord migrations so that it can be run in in other environments that don't support migrations."
  spec.homepage = "https://github.com/bdurand/capture_migration_sql"
  spec.license = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  ignore_files = %w[
    .
    Appraisals
    Gemfile
    Gemfile.lock
    Rakefile
    gemfiles/
    spec/
  ]
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| ignore_files.any? { |path| f.start_with?(path) } }
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 4.2"

  spec.add_development_dependency "bundler"

  spec.required_ruby_version = ">= 2.5"
end
