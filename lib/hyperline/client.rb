# frozen_string_literal: true

module Hyperline
  class Client
    attr_reader :configuration

    def initialize(api_key: nil, base_url: nil, **options)
      @configuration = Configuration.new
      @configuration.api_key      = api_key || Hyperline.configuration.api_key
      @configuration.base_url     = base_url || Hyperline.configuration.base_url
      @configuration.timeout      = options.fetch(:timeout, Hyperline.configuration.timeout)
      @configuration.open_timeout = options.fetch(:open_timeout, Hyperline.configuration.open_timeout)
      @configuration.max_retries  = options.fetch(:max_retries, Hyperline.configuration.max_retries)

      raise ArgumentError, 'api_key is required' unless @configuration.api_key

      @connection = Connection.build(@configuration)
    end

    def products
      @products ||= Resources::Products.new(@connection)
    end

    def subscriptions
      @subscriptions ||= Resources::Subscriptions.new(@connection)
    end

    def invoices
      @invoices ||= Resources::Invoices.new(@connection)
    end
  end
end
