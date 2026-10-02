# frozen_string_literal: true

module Hyperline
  module Resources
    class Customers < BaseResource
      def features(id)
        request(:get, "#{base_path}/#{id}/features")
      end

      def get_v2(id)
        request(:get, "/v2/customers/#{id}")
      end

      def payment_methods(id, **params)
        response = request(:get, "#{resource_path(id)}/payment-methods", params)
        data = response.is_a?(Array) ? response : Array(response['data'])
        meta = response.is_a?(Hash) && response['meta'] ? response['meta'] : bare_meta(data)
        Collection.new(
          data: data, meta: meta, resource: self, params: params,
          method: :payment_methods, args: [id]
        )
      end

      def delete_payment_method(id, payment_method_id, idempotency_key: nil)
        request(
          :delete,
          "#{resource_path(id)}/payment-methods/#{payment_method_id}",
          nil,
          idempotency_key: idempotency_key
        )
      end

      # Returns `{ "url" => ... }`, a link to the customer's hosted portal.
      def portal(id)
        request(:get, "#{resource_path(id)}/portal")
      end

      private

      def bare_meta(data)
        { 'total' => data.size, 'taken' => data.size, 'skipped' => 0 }
      end

      def base_path
        '/v1/customers'
      end
    end
  end
end
