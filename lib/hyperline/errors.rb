# frozen_string_literal: true

module Hyperline
  class ApiError < StandardError
    attr_reader :status, :body

    def initialize(message = nil, status: nil, body: nil)
      @status = status
      @body = body
      super(message || parsed_message || "API error (HTTP #{status})")
    end

    private

    def parsed_message
      return nil unless body.is_a?(Hash)

      body['message']
    end
  end

  class AuthenticationError < ApiError; end
  class BadRequestError < ApiError; end
  class NotFoundError < ApiError; end
  class RateLimitError < ApiError; end
  class ServerError < ApiError; end

  # @api private
  module ErrorMapper
    MAPPED = {
      400 => BadRequestError,
      401 => AuthenticationError,
      404 => NotFoundError,
      429 => RateLimitError
    }.freeze

    def self.from_response(status, body)
      klass = MAPPED[status] || (status >= 500 ? ServerError : ApiError)
      klass.new(status: status, body: body)
    end
  end
end
