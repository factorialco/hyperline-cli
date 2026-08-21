# frozen_string_literal: true

module Hyperline
  module Resources
    class Products < BaseResource
      # Archiving is a PUT: the collection convention here would suggest POST, which answers 404
      # "Route not found".
      def archive(id, idempotency_key: nil)
        request(:put, "#{resource_path(id)}/archive", nil, idempotency_key: idempotency_key)
      end

      # The features linked to this product, as a bare array of
      # `{ "feature_code" => ..., "value" => ... }` -- this endpoint answers with no meta/data
      # envelope, so there is nothing to paginate and no Collection to build.
      def features(id)
        request(:get, "#{resource_path(id)}/features")
      end

      # Attaches a feature to the product at a given value: `true` for a boolean feature, the cap
      # for a numeric one. Idempotent in effect -- linking the same value again is a no-op -- and
      # 400 means the feature's value_type cannot hold the value.
      def link_feature(id, code, value:, idempotency_key: nil)
        request(
          :put,
          "#{resource_path(id)}/features/#{code}",
          { value: value },
          idempotency_key: idempotency_key
        )
      end

      def unlink_feature(id, code, idempotency_key: nil)
        request(
          :delete,
          "#{resource_path(id)}/features/#{code}",
          nil,
          idempotency_key: idempotency_key
        )
      end

      private

      def base_path
        '/v1/products'
      end
    end
  end
end
