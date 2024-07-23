require 'rack'
require 'ruby-saml'

require 'rack_entra_id_auth/configuration'

module RackEntraIdAuth
  def self.configure
    yield config
  end

  def self.config
    @config ||= Configuration.new
  end
end

require 'rack_entra_id_auth/railtie' if defined?(Rails::Railtie)
