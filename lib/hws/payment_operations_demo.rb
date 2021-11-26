# frozen_string_literal: true

require 'hws-resources'
require 'hws-transactions'
require 'hws-stores'
require 'hws-instruments'

module Hws
  # Main demo app module
  module PaymentOperationsDemo
    require 'hws/payment_operations_demo/transactional_value_store'
    require 'hws/payment_operations_demo/virtual_account'

    # ActiveRecord Models for the demo
    module Models
      require 'hws/payment_operations_demo/models/instrument_resource_store'
    end

    # Exceptions for the demo
    module Exceptions
      require 'hws/payment_operations_demo/exceptions/exceptions'
    end
  end
end

require 'hws/payment_operations_demo/railtie' if defined?(Rails::Railtie)
