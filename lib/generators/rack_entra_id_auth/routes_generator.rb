module RackEntraIdAuth
  module Generators
    class RoutesGenerator < Rails::Generators::Base
      desc 'Create route helpers for single sign-on/logout requests handled by the RackEntraIdAuth middleware.'

      def create_login_route
        route "get '#{RackEntraIdAuth.config.login_path}', as: :login, to: ->(env) { [204, {}, ['']] }"
      end

      def create_logout_route
        route "get '#{RackEntraIdAuth.config.logout_path}', as: :logout, to: ->(env) { [204, {}, ['']] }"
      end
    end
  end
end
