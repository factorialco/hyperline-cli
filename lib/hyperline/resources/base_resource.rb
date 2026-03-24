# frozen_string_literal: true

module Hyperline
  module Resources
    class BaseResource
      attr_reader :connection

      def initialize(connection)
        @connection = connection
      end

      def list(**params)
        response = request(:get, resource_path, params)
        Collection.new(
          data: response['data'],
          meta: response['meta'],
          resource: self,
          params: params
        )
      end

      def get(id)
        request(:get, resource_path(id))
      end

      def create(**attrs)
        request(:post, resource_path, attrs)
      end

      def update(id, **attrs)
        request(:put, resource_path(id), attrs)
      end

      def delete(id)
        request(:delete, resource_path(id))
      end

      private

      def resource_path(id = nil)
        id ? "#{base_path}/#{id}" : base_path
      end

      def base_path
        raise NotImplementedError, "#{self.class} must implement #base_path"
      end

      def request(method, path, body = nil)
        response = case method
                   when :get
                     connection.get(path, body)
                   when :post
                     connection.post(path, body)
                   when :put
                     connection.put(path, body)
                   when :patch
                     connection.patch(path, body)
                   when :delete
                     connection.delete(path) { |req| req.body = body if body }
                   end
        response.body
      rescue Faraday::ClientError, Faraday::ServerError => e
        handle_error(e)
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
