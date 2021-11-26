# frozen_string_literal: true

require 'rails/generators/active_record'

class Hws::PaymentOperationsDemo::InstallGenerator < Rails::Generators::Base # :nodoc:
  include Rails::Generators::Migration

  source_root File.expand_path('templates', __dir__)

  def self.next_migration_number(path)
    ActiveRecord::Generators::Base.next_migration_number(path)
  end

  def install_dependencies
    generate 'hws:resources:install'
    generate 'hws:stores:install'
    generate 'hws:transactions:install'
    generate 'hws:instruments:install'
  end

  def copy_migrations
    migration_template 'migration.rb.erb', 'db/migrate/create_hws_instrument_resource_store_table.rb'
  end
end
