RackEntraIdAuth.configure do |config|
  # Ruby SAML needs to be configured with the Entra ID application it will using
  # as the Identify Provider (IdP) as well as your application that it will be
  # using as the Service Provider (SP).
  #
  # All of the Ruby SAML settings are exposed as configuration attributes on the
  # RackEntraIdAuth.config object and can be set from within this initializer or
  # within `config/application.rb' or the environment-specific configuration
  # files (e.g. config.rack_entra_id_auth.idp_entity_id = '…'). Any default
  # settings defined by Ruby SAML are used by RackEntraIdAuth and called out
  # below. They can also be found here:
  # https://github.com/SAML-Toolkits/ruby-saml/blob/master/lib/onelogin/ruby-saml/settings.rb#L276

  # ------------------------
  # RackEntraIdAuth Settings
  # ------------------------

  # The login/logout paths are used by the middleware to create single
  # sign-on/logout requests and redirect them to the IdP SSO/SLO Service URLs
  # set below, respectively. It's handy to define these as routes in your
  # application so you can use the route helpers in your views.
  #TODO route generator
  # config.login_path  = '/login'
  # config.logout_path = '/logout'

  # By default, all the login/logout responses from the IdP are redirected to
  # base URL of your application after the response is successfully processed
  # and the user's session is set/deleted. If you'd like the user redirected to
  # another URL upon successful login/logout this can be set below. These can
  # also be overridden on a per-request basis by adding a `relay_state` query
  # parameter to requests for the login/logout paths above, e.g.
  # `http://your:app/login?relay_state=https%3A%2F%2Fyour.app%2Fgo_here_instead`
  # config.login_relay_state_url  = ''
  # config.logout_relay_state_url = ''

  # ----------------------------------------------------------------------------
  # THIS SETTING HAS NO EFFECT IN AN INITIALIZER (it's set too late). It needs
  # to be in `config/application.rb` or an environment-specific configuration
  # file. You'll likely want to put it in in your
  # `config/environments/production.rb` file as
  # `config.rack_entra_id_auth.mock_server = false`.
  # ----------------------------------------------------------------------------
  # config.mock_server = false

  # If mock_server is enabled these are the usernames you'll be able to log in
  # as with the mock middleware, as well as the assoicatied "SAML" attributes
  # that will be placed in the user's session.
  # config.mock_attributes = {
  #   'rtables' => {
  #     'displayname'  => 'Little Bobby Tables',
  #     'groups'       => ['Students'],
  #     'givenname'    => "Robert');DROP TABLE Students;-- ?",
  #     'surname'      => 'Tables',
  #     'emailaddress' => 'rtables@your.app',
  #     'name'         => 'rtables@your.app'
  #   },
  #   'badmin' => {
  #     'displayname'  => 'Bad Admin',
  #     'groups'       => ['Admins'],
  #     'givenname'    => 'Bad',
  #     'surname'      => 'Admin',
  #     'emailaddress' => 'badmin@your.app',
  #     'name'         => 'badmin@your.app'
  #   }
  # }

  # The hash key the SAML attributes are stored under in the sessions hash.
  # config.session_key = :entra_id

  # The SAML attributes can be modified before they are stored within the user's
  # session via the proc below. The following is the default proc.
  # config.session_value_proc = Proc.new { |attributes|
  #   attributes.inject({}) do |memo, (key, value)|
  #     key = key.split('/').last
  #     value = value.first if value.kind_of?(Array) and value.length.eql?(1) and !key.eql?('groups')
  #     memo[key] = value
  #     memo
  #   end
  # }

  # Single logout requires changing the application's session store to work, so
  # it is disabled by default. Once the session store is configured uncomment
  # the line below to enable single logout.
  # config.skip_single_logout = true

  # ----------------------
  # Ruby SAML IdP Settings
  # ----------------------

  # When the Entra ID application is set up you'll be provided with single sign-
  # on/logout service URLs. RackEntraIdAuth needs these so it can direct the
  # single sign-on/logout requests that originate from within your application.
  # The public certificate provided by the IdP also needs to be in these
  # requests and should be set below as well.

  # config.idp_entity_id                  = ''
  config.idp_sso_service_url            = "IdP SINGLE SIGN-ON SERVICE URL"
  config.idp_slo_service_url            = "IdP SINGLE LOGOUT SERVICE URL"
  # config.idp_slo_response_service_url   = ''
  config.idp_cert                       = 'IdP X509CERTIFICATE'
  # config.idp_cert_fingerprint           = ''
  # config.idp_cert_fingerprint_algorithm = XMLSecurity::Document::SHA1
  # config.idp_cert_multi                 = ''
  # config.idp_attribute_names            = ''
  # config.idp_name_qualifier             = ''
  # config.valid_until                    = ''

  # ---------------------
  # Ruby SAML SP Settings
  # ---------------------

  # When the Entra ID application is set up you'll need to provide some way to
  # identify your application (the SP) to it as well as the URLs your
  # application will use to handle single sign-on/logout reseponses sent by the
  # IdP to your application. Your application does not need to be aware of these
  # URLs, the RackEntraIdAuth middleware will intercept and handle them.
  # However, these URLs should not conflict with any routes within your
  # application as requests sent to them will never make it to your application.

  config.sp_entity_id                      = 'https://your.app/'
  config.assertion_consumer_service_url    = 'https://your.app/saml/login'
  config.single_logout_service_url         = 'https://your.app/saml/logout'
  # config.sp_name_qualifier                 = ''
  # config.name_identifier_format            = ''
  # config.name_identifier_value             = ''
  # config.name_identifier_value_requested   = ''
  # config.sessionindex                      = ''
  # Ruby SAML normally compresses requests/responses and double quotes the XML
  # attributes. Uncomment the lines below to change that.
  # config.compress_request                  = false
  # config.compress_response                 = false
  # config.double_quote_xml_attribute_values = false
  # config.message_max_bytesize              = 250000
  # config.passive                           = ''
  # config.attributes_index                  = ''
  # config.force_authn                       = ''
  # config.certificate                       = ''
  # config.private_key                       = ''
  # config.sp_cert_multi                     = ''
  # config.authn_context                     = ''
  # config.authn_context_comparison          = ''
  # config.authn_context_decl_ref            = ''

  # ---------------------------
  # Ruby SAML Workflow Settings
  # ---------------------------

  # The default Ruby SAML security configurations can be overriden by
  # uncommenting the lines below.
  # config.security = {
  #   :authn_requests_signed      => true,
  #   :logout_requests_signed     => true,
  #   :logout_responses_signed    => true,
  #   :want_assertions_signed     => true,
  #   :want_assertions_encrypted  => true,
  #   :want_name_id               => true,
  #   :metadata_signed            => true,
  #   :digest_method              => XMLSecurity::Document::SHA1,
  #   :signature_method           => XMLSecurity::Document::RSA_SHA1,
  #   :check_idp_cert_expiration  => true,
  #   :check_sp_cert_expiration   => true,
  #   :strict_audience_validation => true,
  #   :lowercase_url_encoding     => true
  # }

  # Ruby SAML normally doesn't raise SAML validation errors, uncomment the line
  # below to raise them.
  # config.soft = false
end
