module RackEntraIdAuth
  class Middleware
    def initialize (app, config = {})
      @app = app
      @config = RackEntraIdAuth.config.ruby_saml_settings.merge(config)
    end

    def call (env)
    end
  end
end
