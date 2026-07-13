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

      # Finds the entity whose custom property `slug` equals `value`, filtering server-side via the
      # documented `custom_properties` query param. The result is ALWAYS re-verified client-side:
      # Hyperline silently ignores unknown query params (returning the unfiltered list), so trusting
      # the first element would return an arbitrary entity. Returns the entity hash or nil.
      def find_by_custom_property(slug, value)
        response = request(:get, search_path, { custom_properties: { slug => value } })
        Array(response['data']).find { |entity| entity.dig('custom_properties', slug) == value }
      end

      # Finds the entity imported from an external provider (Chargebee, Stripe, ...) by its id in
      # that provider, using the documented `integration_entity_id` filter. Re-verified client-side
      # against the entity's `integrations` array for the same reason as above. Returns the entity
      # hash or nil.
      def find_by_integration_entity_id(entity_id)
        response = request(:get, search_path, { integration_entity_id: entity_id })
        Array(response['data']).find do |entity|
          Array(entity['integrations']).any? { |integration| integration['entity_id'] == entity_id }
        end
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

      # List path used for search/filtering; overridable when it differs from base_path
      # (e.g. subscriptions list is v2 while other subscription paths are v1).
      def search_path
        base_path
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
