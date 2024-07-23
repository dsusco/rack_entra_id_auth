require 'rack_entra_id_auth/configuration'
require 'rack_entra_id_auth/railtie' if defined?(Rails::Railtie)

module RackEntraIdAuth
  def self.configure
    yield config
  end

  def self.config
    @config ||= Configuration.new
  end
end
