require 'uri'

module RackEntraIdAuth
  class EntraIdRequest
    attr_reader :request

    def initialize(request, saml_setting_overrides = {})
      @request = request

      @saml_settings = OneLogin::RubySaml::Settings.new(RackEntraIdAuth.config.ruby_saml_settings.merge(saml_setting_overrides))
    end

    # Returns the request's base URL and path without the path_info at the end.
    #
    # @return [String]
    #
    def base_url
      "#{request.base_url}#{request.path}".sub(Regexp.new("#{request.path_info}$"), '')
    end

    # Returns whether the request is a Service Provider initiated sign-on
    # request. Returns true if the request's path info equals the login path
    # configuration (login_path), otherwise returns false.
    #
    # @return [Bool]
    #
    def login?
      request.path_info.eql?(RackEntraIdAuth.config.login_path)
    end

    # Returns whether the request contains a single sign-on response (for
    # Service Provider initiated single sign-on requests). Returns true if the
    # request's header contains a SAMLResponse and if the request's base_url and
    # path match the ACS service url setting (assertion_consumer_service_url),
    # otherwise returns false.
    #
    # @return [Bool]
    #
    def login_response?
      saml_response.present? and "#{request.base_url}#{request.path}".eql?(@saml_settings.assertion_consumer_service_url)
    end

    # Returns whether the request is a Service Provider initiated logout
    # request. Returns true if the request's path info equals the logout path
    # configuration (logout_path), otherwise returns false.
    #
    # @return [Bool]
    #
    def logout?
      request.path_info.eql?(RackEntraIdAuth.config.logout_path)
    end

    # Returns whether the request contains a single logout request (for ID
    # Provider initiated single logout requests). Returns true if the request
    # contains a SAMLRequest query parameter and if the request's base_url and
    # path match the single logout service url setting
    # (single_logout_service_url), otherwise returns false.
    #
    # @return [Bool]
    #
    def logout_request?
      request.params['SAMLRequest'].present? and "#{request.base_url}#{request.path}".eql?(@saml_settings.single_logout_service_url)
    end

    # Returns whether the request contains a single logout response for Service
    # Provider initiated logout request. Returns true if the request contains a
    # SAMLResponse query parameter and if the request's base_url and path match
    # the single logout service url setting (single_logout_service_url),
    # otherwise returns false.
    #
    # @return [Bool]
    #
    def logout_response?
      request.params['SAMLResponse'].present? and "#{request.base_url}#{request.path}".eql?(@saml_settings.single_logout_service_url)
    end

    # Returns the RelayState in the header of the request or its query
    # parameters.
    #
    # @return [String]
    #
    def relay_state_url
      request.get_header('rack.request.form_hash')['RelayState'] || request.params['RelayState']
    end

    # A single sign-on response for the SAMLResponse in the request's header.
    # This is the response sent by the ID Provider for Service Provider
    # initiated single sign-on requests.
    #
    # @param auth_request_id [String] If provided, check that the inResponseTo
    #        in the response matches the uuid of the sign-on request that
    #        initiated the response.
    # @param skip_conditions [Bool] Skip the conditions validation.
    # @param allowed_clock_drift [Float] The allowed clock drift when checking
    #        time stamps.
    # @param skip_subject_confirmation [Bool] Skip the subject confirmation
    #        validation.
    # @param skip_recipient_check [Bool] Skip the recipient validation of the
    #        subject confirmation element.
    # @param skip_audience [Bool] Skip the audience validation.
    #
    # @return [OneLogin::RubySaml::Response] A single sign-on response for a
    #         Service Provideer initiated single sign-on request.
    #
    def saml_auth_response (auth_request_id: request.session[:auth_request_id], skip_conditions: false, allowed_clock_drift: nil, skip_subject_confirmation: false, skip_recipient_check: false, skip_audience: false)
      response = OneLogin::RubySaml::Response.new(
        saml_response,
        { :settings => @saml_settings,
          :matches_request_id => auth_request_id,
          :skip_conditions => skip_conditions,
          :allowed_clock_drift => allowed_clock_drift,
          :skip_subject_confirmation => skip_subject_confirmation,
          :skip_recipient_check => skip_recipient_check,
          :skip_audience => skip_audience })

      # the auth request's ID is no longer needed
      request.session.delete(:auth_request_id)

      response
    end

    # A single logout request for the SAMLRequest in the request's query
    # parameters. This is the request sent by the ID Provider for ID Provider
    # initiated single logout requests.
    #
    # @param allowed_clock_drift [Float] The allowed clock drift when checking
    #        time stamps.
    # @param relax_signature_validation [Bool] If true and there's no ID
    #        Provider certs in the settings then ignore the signature validation
    #        on the request.
    #
    # @return [OneLogin::RubySaml::Logoutresponse] A single logout response for
    #         a Service Provideer initiated single logout request.
    #
    def saml_logout_request (allowed_clock_drift: nil, relax_signature_validation: false)
      OneLogin::RubySaml::SloLogoutrequest.new(
        request.params['SAMLRequest'],
        { :settings => @saml_settings,
          :allowed_clock_drift => allowed_clock_drift,
          :relax_signature_validation => relax_signature_validation })
    end

    # A single logout response for the SAMLResponse in the request's query
    # parameters. This is the response sent by the ID Provider for Service
    # Provider initiated single logout requests.
    #
    # @param logout_request_id [String] If provided, check that the inResponseTo
    #        in the response matches the uuid of the logout request that
    #        initiated the response.
    # @param relax_signature_validation [Bool] If true and there's no ID
    #        Provider certs in the settings then ignore the signature validation
    #        on the response.
    #
    # @return [OneLogin::RubySaml::Logoutresponse] A single logout response for
    #         a Service Provideer initiated single logout request.
    #
    def saml_logout_response (logout_request_id: request.session[:logout_request_id], relax_signature_validation: false)
      logout_response = OneLogin::RubySaml::Logoutresponse.new(
        request.params['SAMLResponse'],
        @saml_settings,
        { :get_params => request.params,
          :matches_request_id => logout_request_id,
          :relax_signature_validation => relax_signature_validation })

      # the logout request's ID is no longer needed
      request.session.delete(:logout_request_id)

      logout_response
    end

    # Returns a single logout reponse URL for the settings provided. Used for ID
    # Provider initiated log outs.
    #
    # @param request_id [String] The ID of the LogoutRequest sent by this SP to
    #        the IdP. That ID will be placed as the InResponseTo in the logout
    #        response.
    # @param logout_message [String] The message to be placed as StatusMessage
    #        in the logout response.
    # @param params [Hash] Extra query parameters to be added to the URL (e.g.
    #        RelayState).
    # @param logout_status_code [String] The StatusCode to be placed as
    #        StatusMessage in the logout response.
    #
    # @return [String]
    #
    def slo_response_url (request_id: nil, logout_message: nil, params: {}, logout_status_code: nil)
      OneLogin::RubySaml::SloLogoutresponse.new.create(
        @saml_settings,
        request_id,
        logout_message,
        params,
        logout_status_code)
    end

    # Returns a single logout request URL for the settings provided if an ID
    # Provider single logout target URL is present in the settings
    # (idp_slo_service_url), otherwise returns nil. Used for Service Provider
    # initiated log outs.
    #
    # @param params [Hash] Extra query parameters to be added to the URL (e.g.
    #        RelayState).
    #
    # @return [String|nil]
    #
    def slo_url (params = {})
      logout_request = OneLogin::RubySaml::Logoutrequest.new

      if @saml_settings.idp_slo_service_url.present?
        # store the logout request's uuid to validate it in the response
        request.session[:logout_request_id] = logout_request.uuid

        # return nil if no single logout url is set
        logout_request.create(@saml_settings, params)
      end
    end

    # Returns a single sign-on authentication request URL for the settings
    # provided. Used for Service Provider initiated sign-ins.
    #
    # @param params [Hash] Extra query parameters to be added to the URL (e.g.
    #        RelayState).
    #
    # @return [String]
    #
    def sso_url (params = {})
      auth_request = OneLogin::RubySaml::Authrequest.new

      # store the auth request's uuid to validate it in the response
      request.session[:auth_request_id] = auth_request.uuid

      auth_request.create(@saml_settings, params)
    end

    private

    def saml_response
      request.get_header('rack.request.form_hash').try(:[], 'SAMLResponse')
    end
  end
end
