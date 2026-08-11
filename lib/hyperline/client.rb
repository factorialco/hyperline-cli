# frozen_string_literal: true

module Hyperline
  class Client
    attr_reader :configuration

    def initialize(api_key: nil, base_url: nil, **options)
      @configuration = Configuration.new
      @configuration.api_key = api_key || Hyperline.configuration.api_key
      @configuration.base_url = base_url || Hyperline.configuration.base_url
      @configuration.timeout = options.fetch(:timeout, Hyperline.configuration.timeout)
      @configuration.open_timeout =
        options.fetch(:open_timeout, Hyperline.configuration.open_timeout)
      @configuration.max_retries = options.fetch(:max_retries, Hyperline.configuration.max_retries)

      raise ArgumentError, 'api_key is required' unless @configuration.api_key

      @connection = Connection.build(@configuration)
    end

    def products
      @products ||= Resources::Products.new(@connection)
    end

    def customers
      @customers ||= Resources::Customers.new(@connection)
    end

    def subscriptions
      @subscriptions ||= Resources::Subscriptions.new(@connection)
    end

    def invoices
      @invoices ||= Resources::Invoices.new(@connection)
    end

    def plans
      @plans ||= Resources::Plans.new(@connection)
    end

    def price_configurations
      @price_configurations ||= Resources::PriceConfigurations.new(@connection)
    end

    def custom_properties
      @custom_properties ||= Resources::CustomProperties.new(@connection)
    end

    def aggregators
      @aggregators ||= Resources::Aggregators.new(@connection)
    end

    def price_books
      @price_books ||= Resources::PriceBooks.new(@connection)
    end
  end
end
