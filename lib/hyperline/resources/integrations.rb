# frozen_string_literal: true

module Hyperline
  module Resources
    class Integrations < BaseResource
      # Returns `{ "token" => ..., "token_type" => ... }`, a short-lived token for embedding
      # Hyperline's integration components for one customer.
      def create_component_token(customer_id:, idempotency_key: nil)
        request(
          :post,
          '/v1/integrations/components/token',
          { customer_id: customer_id },
          idempotency_key: idempotency_key
        )
      end

      private

      def base_path
        '/v1/integrations'
      end
    end
  end
end
