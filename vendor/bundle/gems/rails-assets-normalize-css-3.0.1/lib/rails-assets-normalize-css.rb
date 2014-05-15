require "rails-assets-normalize-css/version"


if defined?(Rails)
  module RailsAssetsNormalizeCss
    class Engine < ::Rails::Engine
      # Rails -> use vendor directory.
    end
  end
end
