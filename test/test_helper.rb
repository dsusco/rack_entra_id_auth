$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'rack'
require 'rack/lint'
require 'rack/mock_request'
require 'stringio'
require 'base64'
require 'logger'

require 'rack_entra_id_auth'
require 'rack_entra_id_auth/middleware'
require 'rack_entra_id_auth/mock_middleware'

require 'minitest/autorun'

# keep ruby-saml's debug output out of the test run
OneLogin::RubySaml::Logging.logger = Logger.new(nil)

module RackEntraIdAuthTestHelpers
  IDP_SSO_URL    = 'https://idp.example.com/saml2'.freeze
  IDP_SLO_URL    = 'https://idp.example.com/saml2/logout'.freeze
  ACS_URL        = 'https://app.example.com/saml/login'.freeze
  SLO_SERVICE_URL = 'https://app.example.com/saml/logout'.freeze

  def setup
    super
    # every test starts with a fresh configuration
    RackEntraIdAuth.instance_variable_set(:@config, nil)
  end

  def teardown
    RackEntraIdAuth.instance_variable_set(:@config, nil)
    super
  end

  def configure_saml!
    RackEntraIdAuth.configure do |config|
      config.idp_sso_service_url            = IDP_SSO_URL
      config.idp_slo_service_url            = IDP_SLO_URL
      config.sp_entity_id                   = 'https://app.example.com/'
      config.assertion_consumer_service_url = ACS_URL
      config.single_logout_service_url      = SLO_SERVICE_URL
    end
  end

  # Builds a Rack env with an in-memory session and a quiet error stream.
  def env_for (url, session: {}, **options)
    Rack::MockRequest.env_for(url, {
      'rack.session' => session,
      'rack.errors'  => StringIO.new
    }.merge(options))
  end

  def rack_request (url, **)
    Rack::Request.new(env_for(url, **))
  end

  def entra_id_request (url, **)
    RackEntraIdAuth::EntraIdRequest.new(rack_request(url, **))
  end

  # POST with a form-encoded body.
  # Pass params with braces, e.g. form_post_env(url, { 'a' => 1 }), or Ruby will
  # treat the string-keyed hash as keyword arguments.
  def form_post_env (url, params, session: {})
    env_for(url,
            session: session,
            method: 'POST',
            input: URI.encode_www_form(params),
            'CONTENT_TYPE' => 'application/x-www-form-urlencoded')
  end

  # A downstream app that returns the given status.
  def downstream_app (status = 200)
    ->(_env) { [status, { 'content-type' => 'text/plain' }, ['downstream']] }
  end

  # Wraps a middleware in Rack::Lint so header and body violations fail tests.
  def linted (middleware_class, app = downstream_app)
    Rack::Lint.new(middleware_class.new(app))
  end

  def query_params (url)
    URI.decode_www_form(URI.parse(url).query.to_s).to_h
  end
end

class Minitest::Test
  include RackEntraIdAuthTestHelpers
end
