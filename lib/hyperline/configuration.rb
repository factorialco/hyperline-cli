# frozen_string_literal: true

module Hyperline
  class Configuration
    DEFAULT_BASE_URL     = 'https://sandbox.api.hyperline.co'
    DEFAULT_TIMEOUT      = 30
    DEFAULT_OPEN_TIMEOUT = 10
    DEFAULT_MAX_RETRIES  = 3

    attr_accessor :api_key, :base_url, :timeout, :open_timeout, :max_retries

    def initialize
      @api_key      = nil
      @base_url     = DEFAULT_BASE_URL
      @timeout      = DEFAULT_TIMEOUT
      @open_timeout = DEFAULT_OPEN_TIMEOUT
      @max_retries  = DEFAULT_MAX_RETRIES
    end
  end
end
