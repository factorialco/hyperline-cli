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

  class AuthenticationError < ApiError
  end

  class BadRequestError < ApiError
  end

  class NotFoundError < ApiError
  end

  # 409. The request conflicts with existing state -- most often a unique key that is already
  # taken, such as creating a feature whose code exists. Distinct from a validation failure
  # because the caller's payload is well formed: the resource is simply already there, which is
  # frequently the answer a caller wants to treat as success.
  class ConflictError < ApiError
  end

  # 422. The payload parsed but the API refused it on semantic grounds -- a limit on a boolean
  # feature, a count below a committed minimum. Separated from BadRequestError so a caller can
  # tell "malformed" from "well formed and not allowed".
  class UnprocessableEntityError < ApiError
  end

  class RateLimitError < ApiError
  end

  class ServerError < ApiError
  end

  # @api private
  module ErrorMapper
    MAPPED = {
      400 => BadRequestError,
      401 => AuthenticationError,
      404 => NotFoundError,
      409 => ConflictError,
      422 => UnprocessableEntityError,
      429 => RateLimitError
    }.freeze

    def self.from_response(status, body)
      error_class_for(status).new(status: status, body: body)
    end

    def self.error_class_for(status)
      return ApiError if status.nil?

      MAPPED[status] || (status >= 500 ? ServerError : ApiError)
    end
  end
end
