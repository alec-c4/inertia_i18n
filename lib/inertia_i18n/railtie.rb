# frozen_string_literal: true

require "rails/railtie"

module InertiaI18n
  class Railtie < Rails::Railtie
    rake_tasks do
      load "inertia_i18n/tasks/inertia_i18n.rake"
    end
  end
end
