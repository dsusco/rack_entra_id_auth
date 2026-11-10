require 'test_helper'

class TestMiddleware < Minitest::Test
  def setup
    super
    configure_saml!
  end

  def call (env, app: downstream_app)
    linted(RackEntraIdAuth::Middleware, app).call(env)
  end

  def test_passes_through_normal_requests
    status, _headers, body = call(env_for('https://app.example.com/dashboard'))

    assert_equal 200, status
    assert_equal ['downstream'], body.to_enum.to_a
  end

  def test_login_redirects_to_idp
    session = {}
    status, headers, _body = call(env_for('https://app.example.com/login', session: session))

    assert_equal 302, status
    assert headers['location'].start_with?(IDP_SSO_URL)
    assert_equal 'https://app.example.com', query_params(headers['location'])['RelayState']
    refute_nil session[:auth_request_id]
  end

  def test_login_uses_configured_relay_state
    RackEntraIdAuth.config.login_relay_state_url = 'https://app.example.com/home'

    _status, headers, _body = call(env_for('https://app.example.com/login'))

    assert_equal 'https://app.example.com/home', query_params(headers['location'])['RelayState']
  end

  def test_login_ignores_off_site_relay_state_param
    url = "https://app.example.com/login?relay_state=#{CGI.escape('https://evil.example.net/')}"

    _status, headers, _body = call(env_for(url))

    refute_equal 'https://evil.example.net/', query_params(headers['location'])['RelayState']
  end

  def test_intercepts_401_and_redirects_to_idp
    status, headers, _body = call(env_for('https://app.example.com/secret'),
                                  app: downstream_app(401))

    assert_equal 302, status
    assert headers['location'].start_with?(IDP_SSO_URL)
    assert_equal 'https://app.example.com/secret', query_params(headers['location'])['RelayState']
  end

  def test_excluded_paths_are_not_intercepted
    RackEntraIdAuth.config.exclude_paths = ['/up']

    status, _headers, _body = call(env_for('https://app.example.com/up'), app: downstream_app(401))

    assert_equal 401, status
  end

  def test_logout_clears_session_and_skips_single_logout_by_default
    session = { entra_id: { 'name' => 'someone' } }
    status, headers, _body = call(env_for('https://app.example.com/logout', session: session))

    assert_equal 302, status
    assert_equal 'https://app.example.com', headers['location']
    refute session.key?(:entra_id)
  end

  def test_logout_redirects_to_idp_when_single_logout_enabled
    RackEntraIdAuth.config.skip_single_logout = false
    session = { entra_id: { 'name' => 'someone' } }

    status, headers, _body = call(env_for('https://app.example.com/logout', session: session))

    assert_equal 302, status
    assert headers['location'].start_with?(IDP_SLO_URL)
    refute session.key?(:entra_id)
  end

  def test_logout_skip_single_logout_param
    RackEntraIdAuth.config.skip_single_logout = false

    _status, headers, _body = call(env_for('https://app.example.com/logout?skip_single_logout=1'))

    assert_equal 'https://app.example.com', headers['location']
  end

  def test_invalid_login_response_returns_500
    env = form_post_env(ACS_URL, { 'SAMLResponse' => Base64.strict_encode64('<not-saml/>') })

    status, headers, body = call(env)

    assert_equal 500, status
    content = body.to_enum.to_a.join
    assert_match(/Invalid single login reponse/, content)
    assert_equal content.bytesize.to_s, headers['content-length']
  end
end
