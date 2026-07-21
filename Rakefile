# frozen_string_literal: true

begin
  require "bundler/setup"
rescue LoadError
  puts "You must `gem install bundler` and `bundle install` to run rake tasks"
end

require "bundler/gem_tasks"

task :verify_release_branch do
  unless `git rev-parse --abbrev-ref HEAD`.chomp == "main"
    warn "Gem can only be released from the main branch"
    exit 1
  end
end

Rake::Task[:release].prerequisites.prepend("verify_release_branch")

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: [:spec]

namespace :appraisal do
  desc "Update the appraisal gemfiles"
  task :update do
    Dir.glob("gemfiles/*.gemfile*") do |file|
      File.delete(file) if File.file?(file)
    end

    system "bundle exec appraisal generate" || abort("appraisal generate failed")

    Dir.glob("gemfiles/*.gemfile") do |file|
      puts "Locking #{file}"
      Bundler.with_unbundled_env do
        system(
          {
            "BUNDLE_GEMFILE" => file
          },
          "bundle", "lock", "--update"
        ) || abort("appraisal lock failed on #{file}")
      end
    end
  end
end
