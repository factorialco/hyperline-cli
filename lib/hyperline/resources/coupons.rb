# frozen_string_literal: true

module Hyperline
  module Resources
    # The coupon catalog. A coupon defined here is applied to a subscription afterwards with
    # Subscriptions#update_operation (type `add_coupon`), which takes the catalog `coupon_id`;
    # inline coupons are not accepted there.
    #
    # Creating takes `name` plus either `type: 'percent', discount_percent:` or
    # `type: 'amount', discount_amount:, currency:`, and optionally `description`,
    # `expiration_date`, `redemption_limit`, `product_ids`, `repeat` (once, forever or duration),
    # `duration` (`{ count:, period: }`) and `properties`.
    #
    # Listing is take/skip paginated like the other v1 lists: `list(take: 50).auto_paginate`.
    # DELETE answers 204 with an empty body, which the JSON middleware leaves as a blank body
    # rather than raising.
    class Coupons < BaseResource
      private

      def base_path
        '/v1/coupons'
      end
    end
  end
end
