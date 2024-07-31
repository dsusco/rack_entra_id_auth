require 'rack_entra_id_auth/entra_id_request'

module RackEntraIdAuth
  class Middleware
    def initialize (app)
      @app = app
    end

    def call (env)
      request = Rack::Request.new(env)
      entra_id_request = EntraIdRequest.new(request)

      # SP initiated single sign-on request
      if entra_id_request.login?
        log(env, 'Redirecting login request to Entra ID single sign-on URL…')

        sso_url = entra_id_request.sso_url(
          { :RelayState => request.params['relay_state'] || RackEntraIdAuth.config.login_relay_state_url || entra_id_request.base_url })

        return found_redirect_response(
          sso_url,
          'Redirecting login request to Entra ID single sign-on URL')
      end

      # SP initiated logout/single logout request
      if entra_id_request.logout?
        log(env, 'Destroying session…')

        # destroy session in case single logout fails
        request.session.send (request.session.respond_to?(:destroy) ? :destroy : :clear)

        relay_state_url = request.params['relay_state'] || RackEntraIdAuth.config.logout_relay_state_url || entra_id_request.base_url

        slo_url = entra_id_request.slo_url({ :RelayState => relay_state_url })

        if request.params['skip_single_logout'].blank? and
           !RackEntraIdAuth.config.skip_single_logout and
           slo_url.present?

          log(env, 'Redirecting logout request to Entra ID single logout URL…')

          return found_redirect_response(
            slo_url,
            'Redirecting logout request to Entra ID single logout URL')
        end

        log(env, 'Skipping single logout because of skip_single_logout query parameter…') if request.params['skip_single_logout'].present?
        log(env, 'Skipping single logout because of skip_single_logout configuration setting…') if RackEntraIdAuth.config.skip_single_logout
        log(env, 'Skipping single logout because no Entra ID single logout URL was found…') if slo_url.blank?

        log(env, 'Redirecting to relay state URL…')

        return found_redirect_response(relay_state_url)
      end

      # SP initiatied single sign-on response
      if entra_id_request.login_response?
        log(env, 'Received single login response…')

        auth_response = entra_id_request.saml_auth_response()

        if !auth_response.is_valid?
          log(env, "Invalid single login reponse from Entra ID: #{auth_response.errors.first}")

          return internal_server_error_response("Invalid login reponse from Entra ID: #{auth_response.errors.first}")
        end

        if !auth_response.success?
          log(env, 'Unsuccessful single single reponse from Entra ID.')

          return internal_server_error_response('Unsuccessful login reponse from Entra ID.')
        end

        log(env, 'Initializing session and redirecting to relay state URL…')

        # initialize the session with the response's SAML attributes
        request.session[RackEntraIdAuth.config.session_key] = RackEntraIdAuth.config.session_value_proc.call(auth_response.attributes.all)

        return found_redirect_response(
                 entra_id_request.relay_state_url,
                 'Received single login response, redirecting to relay state URL')
      end

      # IdP initiatied single logout request
      if entra_id_request.logout_request? and !RackEntraIdAuth.config.skip_single_logout
        log(env, 'Received single logout request…')

        logout_request = entra_id_request.saml_logout_request()

        if !logout_request.is_valid?
          log(env, "Invalid single logout request from Entra ID: #{logout_request.errors.first}")

          return internal_server_error_response("Invalid logout request from Entra ID: #{logout_request.errors.first}")
        end

        log(env, 'Destroying session and sending logout response to Entra ID…')

        # destroy the session
        request.session.send (request.session.respond_to?(:destroy) ? :destroy : :clear)

        response_url = entra_id_request.slo_response_url(
          request_id: logout_request.id,
          logout_message: nil,
          params: {
            :RelayState => entra_id_request.relay_state_url
          },
          logout_status_code: nil)

        return found_redirect_response(
                 response_url,
                 'Received single logout request, redirecting to Entra ID')
      end

      # SP initiated single logout response
      if entra_id_request.logout_response?
        log(env, 'Received single logout response…')

        logout_response = entra_id_request.saml_logout_response()

        if !logout_response.validate
          log(env, "Invalid single logout reponse from Entra ID: #{logout_response.errors.first}")

          return internal_server_error_response("Invalid logout reponse from Entra ID: #{logout_response.errors.first}")
        end

        if !logout_response.success?
          log(env, 'Unsuccessful single logout reponse from Entra ID.')

          return internal_server_error_response('Unsuccessful logout reponse from Entra ID.')
        end

        log(env, 'Destroying session and redirecting to relay state URL…')

        # session should already be destroyed from SP initiated logout/single logout request, but just to be safe…
        request.session.send (request.session.respond_to?(:destroy) ? :destroy : :clear)

        return found_redirect_response(
                 entra_id_request.relay_state_url,
                 'Received single logout response, redirecting to relay state URL')
      end

      response = @app.call(env)

      # Authenticate 401s
      if response[0] == 401
        log(env, 'Intercepted 401 Unauthorized response, redirecting to Entra ID single sign-on URL…')

        return found_redirect_response(
                 entra_id_request.sso_url(:RelayState => request.url),
                 'Intercepted 401 Unauthorized response, redirecting to Entra ID single sign-on URL')
      end

      response
    end

    protected

      def found_redirect_response (url, message = 'Redirecting to URL')
        [ 302,
          { 'location' => url,
            'content-type' => 'text/plain' },
          [ "#{message}: #{url}" ] ]
      end

      def internal_server_error_response (content = 'Internal server error')
        [ 500,
          { 'content-type' => 'text/html',
            'content-length' => content.length },
            [ content ] ]
      end

      def log (env, message, level = :info)
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
