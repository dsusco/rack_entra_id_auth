require 'ruby-saml'

module RackEntraIdAuth
  class Railtie < ::Rails::Railtie
    initializer 'rack_entra_id_auth.middleware' do |app, b, c|
      if RackEntraIdAuth.config.mock_server
        require 'rack_entra_id_auth/mock_middleware'

        app.middleware.use RackEntraIdAuth::MockMiddleware
      else
        require 'rack_entra_id_auth/middleware'

        app.middleware.use RackEntraIdAuth::Middleware
      end
    end
  end
end
