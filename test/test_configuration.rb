require 'test_helper'

class TestConfiguration < Minitest::Test
  def config
    @config ||= RackEntraIdAuth::Configuration.new
  end

  def test_defaults
    assert_equal [],        config.exclude_paths
    assert_equal '/login',  config.login_path
    assert_equal '/logout', config.logout_path
    assert_equal true,      config.mock_server
    assert_equal({},        config.mock_attributes)
    assert_equal :entra_id, config.session_key
    assert_equal true,      config.skip_single_logout
    assert_nil config.login_relay_state_url
    assert_nil config.logout_relay_state_url
  end

  def test_mutable_defaults_are_not_shared_between_instances
    config.exclude_paths << '/up'
    config.mock_attributes['someone'] = {}

    other = RackEntraIdAuth::Configuration.new

    assert_equal [], other.exclude_paths
    assert_equal({}, other.mock_attributes)
  end

  def test_defaults_constant_is_not_mutated
    config.exclude_paths << '/up'

    assert_equal [], RackEntraIdAuth::Configuration::DEFAULTS[:exclude_paths]
  end

  def test_ruby_saml_settings_are_readable_and_writable
    config.idp_sso_service_url = 'https://idp.example.com/saml2'

    assert_equal 'https://idp.example.com/saml2', config.idp_sso_service_url
  end

  def test_ruby_saml_settings_only_include_saml_keys
    config.idp_sso_service_url = 'https://idp.example.com/saml2'
    config.login_path = '/sign_in'

    assert_equal({ idp_sso_service_url: 'https://idp.example.com/saml2' },
                 config.ruby_saml_settings)
  end

  def test_ruby_saml_settings_drops_nil_values
    # nil values would override ruby-saml's own defaults (the cause of the
    # deflate error fixed in 1.3.3)
    config.compress_request = nil
    config.soft = false

    settings = config.ruby_saml_settings

    refute settings.key?(:compress_request)
    assert_equal false, settings[:soft]
  end

  def test_ruby_saml_settings_keep_ruby_saml_defaults
    settings = OneLogin::RubySaml::Settings.new(config.ruby_saml_settings)

    assert_equal true, settings.compress_request
    assert_equal true, settings.soft
  end

  def test_configuration_options_sets_saml_settings
    config.configuration_options(idp_sso_service_url: 'https://idp.example.com/saml2',
                                 sp_entity_id: 'https://app.example.com/')

    assert_equal 'https://idp.example.com/saml2', config.idp_sso_service_url
    assert_equal 'https://app.example.com/', config.sp_entity_id
  end

  def test_configuration_options_ignores_nil_and_unknown_keys
    config.idp_sso_service_url = 'https://idp.example.com/saml2'

    config.configuration_options(idp_sso_service_url: nil,
                                 login_path: '/ignored',
                                 not_a_setting: 'ignored')

    assert_equal 'https://idp.example.com/saml2', config.idp_sso_service_url
    assert_equal '/login', config.login_path
  end

  def test_default_session_value_proc
    attributes = {
      'http://schemas.microsoft.com/identity/claims/displayname' => ['Bobby Tables'],
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress' => ['rtables@example.com'],
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => ['Students'],
      'roles' => ['a', 'b']
    }

    assert_equal({ 'displayname'  => 'Bobby Tables',
                   'emailaddress' => 'rtables@example.com',
                   'groups'       => ['Students'],
                   'roles'        => ['a', 'b'] },
                 config.session_value_proc.call(attributes))
  end
end
