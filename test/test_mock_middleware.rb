require 'test_helper'

class TestMockMiddleware < Minitest::Test
  def setup
    super
    RackEntraIdAuth.config.mock_attributes = {
      'rtables' => { 'displayname' => ['Bobby Tables'], 'groups' => ['Students'] }
    }
  end

  def call (env, app: downstream_app)
    linted(RackEntraIdAuth::MockMiddleware, app).call(env)
  end

  def test_passes_through_normal_requests
    status, _headers, _body = call(env_for('https://app.example.com/dashboard'))

    assert_equal 200, status
  end

  def test_get_login_renders_mock_login_page
    status, headers, body = call(env_for('https://app.example.com/login'))

    assert_equal 200, status
    assert_equal 'text/html', headers['content-type']
    assert_includes body.to_enum.to_a.join, '<option value="rtables">rtables</option>'
  end

  def test_post_login_sets_session_and_redirects
    session = {}
    env = form_post_env('https://app.example.com/login',
                        { 'username' => 'rtables', 'RelayState' => 'https://app.example.com/home' },
                        session: session)

    status, headers, _body = call(env)

    assert_equal 302, status
    assert_equal 'https://app.example.com/home', headers['location']
    assert_equal({ 'displayname' => 'Bobby Tables', 'groups' => ['Students'] }, session[:entra_id])
  end

  def test_post_login_with_unknown_user_sets_empty_session_value
    session = {}
    env = form_post_env('https://app.example.com/login', { 'username' => 'nobody' }, session: session)

    call(env)

    assert_equal({}, session[:entra_id])
  end

  def test_logout_clears_session
    session = { entra_id: { 'name' => 'someone' } }

    status, headers, _body = call(env_for('https://app.example.com/logout', session: session))

    assert_equal 302, status
    assert_equal 'https://app.example.com', headers['location']
    assert_empty session
  end

  def test_intercepts_401_and_redirects_to_mock_login
    status, headers, _body = call(env_for('https://app.example.com/secret?x=1'),
                                  app: downstream_app(401))

    assert_equal 302, status
    location = headers['location']
    assert_kind_of String, location
    assert location.start_with?('https://app.example.com/login?'), "expected https, got #{location}"
    assert_equal 'https://app.example.com/secret?x=1', query_params(location)['RelayState']
  end

  def test_401_redirect_keeps_non_default_port
    _status, headers, _body = call(env_for('http://localhost:3000/secret'),
                                   app: downstream_app(401))

    assert headers['location'].start_with?('http://localhost:3000/login?')
  end

  def test_excluded_paths_are_not_intercepted
    RackEntraIdAuth.config.exclude_paths = [%r{\A/assets/}]

    status, _headers, _body = call(env_for('https://app.example.com/assets/app.css'),
                                   app: downstream_app(401))

    assert_equal 401, status
  end
end
