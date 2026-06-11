# frozen_string_literal: true

require_relative 'hyperline/version'
require_relative 'hyperline/configuration'
require_relative 'hyperline/errors'
require_relative 'hyperline/connection'
require_relative 'hyperline/collection'
require_relative 'hyperline/resources/base_resource'
require_relative 'hyperline/resources/products'
require_relative 'hyperline/resources/subscriptions'
require_relative 'hyperline/resources/invoices'
require_relative 'hyperline/resources/plans'
require_relative 'hyperline/resources/custom_properties'
require_relative 'hyperline/resources/price_configurations'
require_relative 'hyperline/client'

module Hyperline
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def client
      @client_mutex ||= Mutex.new
      @client_mutex.synchronize { @client ||= Client.new }
    end

    def reset!
      @configuration = Configuration.new
      @client = nil
    end
  end
end
