# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

# Load gem rake tasks
load "lib/inertia_i18n/tasks/inertia_i18n.rake"

# Mock :environment task since we are not in a Rails app
task :environment do
  # No-op
end

task default: %i[spec rubocop]
