# frozen_string_literal: true

require 'json'

module Hyperline
  module Resources
    # HTTP plumbing shared by every resource: verb dispatch, idempotency keys, the bounded retry
    # for writes, and the mapping from a Faraday failure to a Hyperline error.
    #
    # Hyperline honours the standard `Idempotency-Key` header on mutating verbs: verified against
    # the sandbox on 2026-08-21, the same key with the same body replays the first response and
    # returns the same operation id, while the same body with no key creates a second operation.
    # That verification is the only reason a write may be retried here at all, which is why the
    # retry engages exclusively when a caller supplies a key.
    module Requests
      MAX_WRITE_RETRIES = 2

      private

      # Without a key the call is made once, because a retried write with no key duplicates the
      # operation rather than replaying it. With a key, 429 and 5xx are retried a bounded number
      # of times; every other status is the API's answer and is raised immediately.
      def request(method, path, body = nil, idempotency_key: nil)
        return perform(method, path, body, nil) if idempotency_key.nil?

        attempt = 0
        begin
          perform(method, path, body, idempotency_key)
        rescue RateLimitError, ServerError
          attempt += 1
          raise if attempt > MAX_WRITE_RETRIES

          pause_before_retry(attempt)
          retry
        end
      end

      def perform(method, path, body, idempotency_key)
        dispatch(method, path, body, idempotency_key).body
      rescue Faraday::ClientError, Faraday::ServerError => e
        handle_error(e)
      end

      def dispatch(method, path, body, idempotency_key)
        case method
        when :get
          connection.get(path, body)
        when :post
          connection.post(path) { |req| prepare(req, body, idempotency_key) }
        when :put
          connection.put(path) { |req| prepare(req, body, idempotency_key) }
        when :patch
          connection.patch(path) { |req| prepare(req, body, idempotency_key) }
        when :delete
          connection.delete(path) { |req| prepare(req, body, idempotency_key) }
        end
      end

      def prepare(request, body, idempotency_key)
        request.headers['Idempotency-Key'] = idempotency_key if idempotency_key
        request.body = body if body
      end

      def pause_before_retry(attempt)
        sleep(0.5 * (2**(attempt - 1)))
      end

      def handle_error(error)
        status = error.response&.dig(:status)
        body = parse_error_body(error.response&.dig(:body))
        raise ErrorMapper.from_response(status, body)
      end

      def parse_error_body(body)
        return body if body.is_a?(Hash)
        return nil if body.nil?

        JSON.parse(body)
      rescue JSON::ParserError
        { 'message' => body.to_s }
      end
    end
  end
end
