# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'

module Hyperline
  # @api private
  module Connection
    def self.build(config)
      Faraday.new(url: config.base_url) do |f|
        f.request :json
        f.request :retry, retry_options(config)

        f.headers['Authorization'] = "Bearer #{config.api_key}"
        f.headers['User-Agent']    = "hyperline-ruby/#{Hyperline::VERSION}"
        f.headers['Accept']        = 'application/json'

        f.response :json, content_type: /\bjson$/
        f.response :raise_error

        f.options.timeout      = config.timeout
        f.options.open_timeout = config.open_timeout

        f.adapter Faraday.default_adapter
      end
    end

    def self.retry_options(config)
      {
        max: config.max_retries,
        interval: 0.5,
        interval_randomness: 0.5,
        backoff_factor: 2,
        retry_statuses: [429, 500, 502, 503, 504],
        methods: %i[get head options],
        retry_block: ->(_env, _opts, _retries, _exc) {}
      }
    end
    private_class_method :retry_options
  end
end
