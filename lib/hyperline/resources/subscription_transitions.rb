# frozen_string_literal: true

module Hyperline
  module Resources
    # Scheduled moves of a subscription to a new configuration. Unlike a scheduled
    # Subscriptions#update_operation, a transition can be listed and cancelled until it applies,
    # verified against the sandbox on 2026-10-28:
    #
    #   create(
    #     source_subscription_id: "sub_...",
    #     application_schedule: "scheduled",                 # or immediately / last_renewal
    #     transition_date: "2026-11-28T16:43:59.000Z",
    #     calculation_method: "do_not_charge",               # or pro_rata / pro_rata_separate_documents
    #     billing_cycle_transition_method: "keep_current_billing_cycle",
    #     target_subscription: { products: [...], coupons: [...] },
    #     idempotency_key: "..."
    #   )
    #
    # `target_subscription` replaces the whole configuration: every product (with its `prices`
    # and `count`) and every coupon has to be sent again, or it is not on the target. Copying the
    # source's products and coupons keeps their prices and coupon end dates.
    #
    # A subscription holds one pending transition at a time: creating a second answers 400
    # "Subscription already has a pending transition", so a change is replaced by cancelling the
    # pending one first. The transition creates a draft target subscription with its own id
    # (`target_subscription_id`); `base_subscription_id` is the id it started from.
    #
    # Listing is take/skip paginated and filters by `source_subscription_id` and `status`.
    class SubscriptionTransitions < BaseResource
      def cancel(id, idempotency_key: nil)
        request(:post, "#{resource_path(id)}/cancel", nil, idempotency_key: idempotency_key)
      end

      private

      def base_path
        '/v2/subscriptions/transitions'
      end
    end
  end
end
