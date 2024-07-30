module RackEntraIdAuth
  module Generators
    class InitializerGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Create an initializer to configure RackEntraIdAuth.'

      def create_initializer
        template 'rack_entra_id_auth_initializer.rb', Rails.root.join('config', 'initializers', 'rack_entra_id_auth.rb')
      end
    end
  end
end
