require 'rack_entra_id_auth/entra_id_request'

module RackEntraIdAuth
  class MockMiddleware
    def initialize (app)
      @app = app
    end

    def call (env)
      request = Rack::Request.new(env)
      entra_id_request = EntraIdRequest.new(request)

      # mock a login page
      if entra_id_request.login? and request.request_method.eql?('GET')
        log(env, 'Rendering mock login page…')

        return [ 200,
                 { 'Content-Type' => 'text/html' },
                 [ login_page(request.url) ] ]
      end

      # mock a login request
      if entra_id_request.login? and request.request_method.eql?('POST')
        log(env, 'Initializing session and redirecting to relay state URL…')

        attributes = RackEntraIdAuth.config.mock_attributes[request.params['username'].to_sym] || {}
        redirect_url = request.params['relay_state'] ||
                       request.params['RelayState'] ||
                       RackEntraIdAuth.config.login_relay_state_url ||
                       entra_id_request.base_url

        request.session[RackEntraIdAuth.config.session_key] = RackEntraIdAuth.config.session_value_proc.call(attributes)

        return found_redirect_response(redirect_url, 'Initializing session and redirecting to relay state URL')
      end

      # mock a logout request
      if entra_id_request.logout?
        log(env, 'Destroying session and redirecting to relay state URL…')

        redirect_url = request.params['relay_state'] ||
                       request.params['RelayState'] ||
                       RackEntraIdAuth.config.logout_relay_state_url ||
                       entra_id_request.base_url

        request.session.send (request.session.respond_to?(:destroy) ? :destroy : :clear)

        return found_redirect_response(redirect_url, 'Destroying session and redirecting to relay state URL')
      end

      response = @app.call(env)

      # Authenticate 401s
      if response[0] == 401
        log(env, 'Intercepted 401 Unauthorized response, redirecting to mock login URL…')

        login_url = URI::HTTP.build(host: request.host,
                                    port: request.port,
                                    path: RackEntraIdAuth.config.login_path,
                                    query: URI.encode_www_form({ :RelayState => request.url }))

        return found_redirect_response(
                 login_url,
                 'Intercepted 401 Unauthorized response, redirecting to mock login URL')
      end

      response
    end

    protected

      def found_redirect_response (url, message = "Redirecting to URL")
        [ 302,
          { 'location' => url,
            'content-type' => 'text/plain' },
          [ "#{message}: #{url}" ] ]
      end

      def login_page (action)
        options = RackEntraIdAuth.config.mock_attributes.keys.map { |key| %Q~<option value="#{key}">#{key}</option>~ } .join

        <<-EOS
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Mock Middleware Login</title>
  </head>

  <body>
    <form action="#{action}" method="post">
      <label for="username">Username</label>

      <select id="username" name="username">
        <option label="No User" value=""></option>
        #{options}
      </select>

      <input type="submit" value="Login">
    </form>
  </body>
</html>
        EOS
      end

      def log(env, message, level = :info)
        env['rack.logger'] ||= Rails.logger if defined?(Rails.logger)
        message = "rack_entra_id_auth: #{message}"

        if env['rack.logger']
          env['rack.logger'].send(level, message)
        else
          env['rack.errors'].write(message.concat("\n"))
        end
      end
  end
end
