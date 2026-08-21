# frozen_string_literal: true

module Hyperline
  module Resources
    class PriceBooks < BaseResource
      # Attaches products to the price book, copying their default price
      # configurations into it.
      def add_products(id, product_ids:, idempotency_key: nil)
        request(
          :post,
          "#{resource_path(id)}/products",
          { product_ids: product_ids },
          idempotency_key: idempotency_key
        )
      end

      def remove_product(id, product_id, idempotency_key: nil)
        request(
          :delete,
          "#{resource_path(id)}/products/#{product_id}",
          nil,
          idempotency_key: idempotency_key
        )
      end

      private

      def base_path
        '/v1/price-books'
      end
    end
  end
end
