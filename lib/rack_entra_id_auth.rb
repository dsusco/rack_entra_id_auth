require 'rack_entra_id_auth/configuration'

module RackEntraIdAuth
  def self.configure
    yield config
  end

  def self.config
    @config ||= Configuration.new
  end
end

# done here so the RackEntraIdAuth.config method can be used in the Railtie
require 'rack_entra_id_auth/railtie' if defined?(Rails::Railtie)
