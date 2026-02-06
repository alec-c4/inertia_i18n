# frozen_string_literal: true

require "rails/railtie"

module InertiaI18n
  class Railtie < Rails::Railtie
    rake_tasks do
      load "inertia_i18n/tasks/inertia_i18n.rake"
    end

    initializer "inertia_i18n.load_yaml_config" do
      yaml_path = Rails.root.join("config", "inertia_i18n.yml")
      InertiaI18n.configuration.load_from_yaml(yaml_path.to_s) if yaml_path.exist?
    end
  end
end
