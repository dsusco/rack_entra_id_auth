module RackEntraIdAuth
  class Railtie < ::Rails::Railtie
    config.rack_entra_id_auth = RackEntraIdAuth.config

    initializer 'rack_entra_id_auth.middleware' do |app|
      if config.rack_entra_id_auth.mock_server
        require 'rack_entra_id_auth/mock_middleware'

        app.middleware.use MockMiddleware
      else
        require 'rack_entra_id_auth/middleware'

        app.middleware.use Middleware
      end
    end
  end
end
