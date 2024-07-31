require 'active_record/session_store'
require 'rails/generators/active_record'

module RackEntraIdAuth
  module Generators
    class SessionsMigrationGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      argument :file_name, :type => :string, :default => 'create_sessions'

      desc 'Create a migration for Active Record Session Store with a sessionindex column.'

      source_root File.expand_path('templates', __dir__)

      def create_sessions_migration
        migration_template 'migration.rb', Rails.root.join('db', 'migrate', "#{file_name}.rb")
      end

      protected

        def self.next_migration_number (dirname)
          ActiveRecord::Generators::Base.next_migration_number(dirname)
        end

        def session_table_name
          current_table_name = ActiveRecord::SessionStore::Session.table_name

          if current_table_name == 'session' || current_table_name == 'sessions'
            current_table_name = ActiveRecord::Base.pluralize_table_names ? 'sessions' : 'session'
          end

          current_table_name
        end

        def migration_version
          "[#{ActiveRecord::Migration.current_version}]"
        end
    end
  end
end
