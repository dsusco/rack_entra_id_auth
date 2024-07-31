module RackEntraIdAuth
  module Generators
    class InitializerGenerator < Rails::Generators::Base
      desc 'Create an initializer to configure RackEntraIdAuth.'

      source_root File.expand_path('templates', __dir__)

      def create_initializer
        template 'config_initializer.rb', Rails.root.join('config', 'initializers', 'rack_entra_id_auth.rb')
      end
    end
  end
end
