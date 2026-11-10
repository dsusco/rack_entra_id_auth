require 'test_helper'

class TestEntraIdRequest < Minitest::Test
  def setup
    super
    configure_saml!
  end

  # --- path matching ---------------------------------------------------------

  def test_login_and_logout_paths
    assert entra_id_request('https://app.example.com/login').login?
    refute entra_id_request('https://app.example.com/login/other').login?
    assert entra_id_request('https://app.example.com/logout').logout?
    refute entra_id_request('https://app.example.com/login').logout?
  end

  def test_custom_login_path
    RackEntraIdAuth.config.login_path = '/sign_in'

    assert entra_id_request('https://app.example.com/sign_in').login?
    refute entra_id_request('https://app.example.com/login').login?
  end

  def test_excluded_path_with_string
    RackEntraIdAuth.config.exclude_paths = ['/up']

    assert entra_id_request('https://app.example.com/up').excluded_path?
    refute entra_id_request('https://app.example.com/up/more').excluded_path?
  end

  def test_excluded_path_with_regexp
    RackEntraIdAuth.config.exclude_paths = [%r{\A/assets/}]

    assert entra_id_request('https://app.example.com/assets/app.css').excluded_path?
    refute entra_id_request('https://app.example.com/dashboard').excluded_path?
  end

  def test_base_url_strips_path_info
    assert_equal 'https://app.example.com',
                 entra_id_request('https://app.example.com/some/page').base_url
  end

  # --- SAML message detection ------------------------------------------------

  def test_login_response_requires_posted_saml_response_at_acs_url
    request = Rack::Request.new(form_post_env(ACS_URL, { 'SAMLResponse' => 'abc' }))
    assert RackEntraIdAuth::EntraIdRequest.new(request).login_response?

    request = Rack::Request.new(form_post_env('https://app.example.com/elsewhere', { 'SAMLResponse' => 'abc' }))
    refute RackEntraIdAuth::EntraIdRequest.new(request).login_response?

    refute entra_id_request("#{ACS_URL}?SAMLResponse=abc").login_response?
  end

  def test_login_response_works_without_form_already_parsed
    # Regression: previously relied on another middleware (Rack::MethodOverride)
    # having already parsed the POST body.
    env = form_post_env(ACS_URL, { 'SAMLResponse' => 'abc' })
    refute env.key?('rack.request.form_hash')

    assert RackEntraIdAuth::EntraIdRequest.new(Rack::Request.new(env)).login_response?
  end

  def test_logout_request_and_response_detection
    assert entra_id_request("#{SLO_SERVICE_URL}?SAMLRequest=abc").logout_request?
    refute entra_id_request("#{SLO_SERVICE_URL}?SAMLResponse=abc").logout_request?
    assert entra_id_request("#{SLO_SERVICE_URL}?SAMLResponse=abc").logout_response?
    refute entra_id_request('https://app.example.com/other?SAMLResponse=abc').logout_response?
  end

  # --- relay state -----------------------------------------------------------

  def test_relay_state_url_from_posted_form
    env = form_post_env(ACS_URL, { 'SAMLResponse' => 'abc',
                                   'RelayState'   => 'https://app.example.com/dashboard' })

    assert_equal 'https://app.example.com/dashboard',
                 RackEntraIdAuth::EntraIdRequest.new(Rack::Request.new(env)).relay_state_url
  end

  def test_relay_state_url_from_query_string
    url = "#{SLO_SERVICE_URL}?RelayState=#{URI.encode_www_form_component('https://app.example.com/bye')}"

    assert_equal 'https://app.example.com/bye', entra_id_request(url).relay_state_url
  end

  def test_relay_state_url_falls_back_to_base_url_when_missing_from_post
    request = RackEntraIdAuth::EntraIdRequest.new(
      Rack::Request.new(form_post_env(ACS_URL, { 'SAMLResponse' => 'abc' })))

    # the middleware checks login_response? first, which parses the form
    assert request.login_response?
    assert_equal 'https://app.example.com', request.relay_state_url
  end

  def test_relay_state_url_rejects_other_hosts
    env = form_post_env(ACS_URL, { 'SAMLResponse' => 'abc',
                                   'RelayState'   => 'https://evil.example.net/phish' })

    assert_equal 'https://app.example.com',
                 RackEntraIdAuth::EntraIdRequest.new(Rack::Request.new(env)).relay_state_url
  end

  def test_relay_state_url_rejects_non_http_urls
    url = "#{SLO_SERVICE_URL}?RelayState=#{URI.encode_www_form_component('javascript:alert(1)')}"

    assert_equal 'https://app.example.com', entra_id_request(url).relay_state_url
  end

  # --- outgoing SAML URLs ----------------------------------------------------

  def test_sso_url_points_at_idp_and_stores_request_id
    session = {}
    request = entra_id_request('https://app.example.com/login', session: session)

    url = request.sso_url(RelayState: 'https://app.example.com/')

    assert url.start_with?(IDP_SSO_URL)
    assert query_params(url).key?('SAMLRequest')
    assert_equal 'https://app.example.com/', query_params(url)['RelayState']
    refute_nil session[:auth_request_id]
  end

  def test_slo_url_points_at_idp_and_stores_request_id
    session = {}
    url = entra_id_request('https://app.example.com/logout', session: session).slo_url

    assert url.start_with?(IDP_SLO_URL)
    refute_nil session[:logout_request_id]
  end

  def test_slo_url_is_nil_without_idp_slo_service_url
    RackEntraIdAuth.config.idp_slo_service_url = nil
    session = {}

    assert_nil entra_id_request('https://app.example.com/logout', session: session).slo_url
    assert_nil session[:logout_request_id]
  end
end
