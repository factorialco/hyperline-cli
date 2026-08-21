# frozen_string_literal: true

module Hyperline
  module Resources
    # Features are the first-class entitlements a product grants. Hyperline resolves the effective
    # set per customer from the features linked to the products on their subscription, which is why
    # these are defined once here and then attached with Products#link_feature.
    #
    # The identifier is the feature's `code`, not an opaque id, so `get`, `update` and `delete` all
    # take a code. Creating one whose code exists answers 409 rather than replacing it.
    class Features < BaseResource
      # Archiving is a PUT, as it is for products. It is also a prerequisite for deletion: DELETE
      # on an active feature answers 400 "Cannot delete a feature that is not archived", so
      # removing one is archive-then-delete rather than a single call.
      def archive(code, idempotency_key: nil)
        request(:put, "#{resource_path(code)}/archive", nil, idempotency_key: idempotency_key)
      end

      private

      def base_path
        '/v1/features'
      end
    end
  end
end
