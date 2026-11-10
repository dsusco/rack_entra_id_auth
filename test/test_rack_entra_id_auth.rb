require 'test_helper'

class TestRackEntraIdAuth < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RackEntraIdAuth::VERSION
  end

  def test_config_is_memoized
    assert_same RackEntraIdAuth.config, RackEntraIdAuth.config
  end

  def test_configure_yields_the_config
    RackEntraIdAuth.configure { |config| config.login_path = '/sign_in' }

    assert_equal '/sign_in', RackEntraIdAuth.config.login_path
  end

  def test_does_not_load_active_support_configurable
    refute defined?(ActiveSupport::Configurable),
           'ActiveSupport::Configurable is deprecated in Rails 8.1 and removed in 8.2'
  end
end
