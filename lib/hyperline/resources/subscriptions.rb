# frozen_string_literal: true

module Hyperline
  module Resources
    class Subscriptions < BaseResource
      # /v1/subscriptions does not exist -- it answers 404 "Route not found" -- so listing goes
      # through the v2 path that search already uses. base_path stays on v1 because the action
      # sub-paths below genuinely live there: POST /v1/subscriptions/{id}/update is what the API
      # accepts, and so are cancel, pause and the rest.
      def list(**params)
        response = request(:get, search_path, params)
        Collection.new(
          data: response['data'],
          meta: response['meta'],
          resource: self,
          params: params
        )
      end

      def get(id)
        request(:get, "/v2/subscriptions/#{id}")
      end

      def update(id, idempotency_key: nil, **attrs)
        request(:put, "/v2/subscriptions/#{id}", attrs, idempotency_key: idempotency_key)
      end

      # Applies or schedules an operation on a subscription. POST /v1/subscriptions/{id}/update.
      #
      # The payload below is the shape the API actually accepts, verified against the sandbox on
      # 2026-08-21. `payment_schedule` is required and was missing from this example before, so the
      # documented call returned 400:
      #
      #   {
      #     type: "update_count",                              # or add_coupon / remove_coupon /
      #     payload: { product_id:, count: },                  #    update_prices
      #     application_schedule: "immediately",
      #     payment_schedule: "immediately",                   # immediately / next_invoice / custom
      #     calculation_method: "pro_rata"                     # pro_rata / pay_in_full /
      #   }                                                    #    do_not_charge
      #
      # The response is the created operation, `{ "id" => "supd_..." }`. update_count sets the
      # count outright rather than incrementing it, so applying the same one twice lands on the
      # same number -- but it does create two operations unless an idempotency key is passed.
      def update_operation(id, body, idempotency_key: nil)
        request(:post, "#{resource_path(id)}/update", body, idempotency_key: idempotency_key)
      end

      def preview_timeline(id, **params)
        request(:get, "#{resource_path(id)}/preview-timeline", params)
      end

      # Takes the same body as #update_operation and returns the estimate without applying it.
      def simulate_updates(id, body)
        request(:post, "#{resource_path(id)}/simulate-updates", body)
      end

      def cancel(id, idempotency_key: nil, **params)
        request(
          :post,
          "#{resource_path(id)}/cancel",
          params,
          idempotency_key: idempotency_key
        )
      end

      def pause(id, idempotency_key: nil, **params)
        request(
          :post,
          "#{resource_path(id)}/pause",
          params,
          idempotency_key: idempotency_key
        )
      end

      def activate(id, idempotency_key: nil, **params)
        request(
          :post,
          "#{resource_path(id)}/activate",
          params,
          idempotency_key: idempotency_key
        )
      end

      def reactivate(id, idempotency_key: nil, **params)
        request(
          :post,
          "#{resource_path(id)}/reactivate",
          params,
          idempotency_key: idempotency_key
        )
      end

      def reinstate(id, idempotency_key: nil, **params)
        request(
          :post,
          "#{resource_path(id)}/reinstate",
          params,
          idempotency_key: idempotency_key
        )
      end

      def renew(id, idempotency_key: nil, **params)
        request(
          :post,
          "#{resource_path(id)}/renew",
          params,
          idempotency_key: idempotency_key
        )
      end

      def list_templates(**params)
        response = request(:get, "#{base_path}/templates", params)
        Collection.new(
          data: response['data'],
          meta: response['meta'],
          resource: self,
          params: params,
          method: :list_templates
        )
      end

      def get_template(id)
        request(:get, "#{base_path}/templates/#{id}")
      end

      private

      def base_path
        '/v1/subscriptions'
      end

      # Listing/searching subscriptions is on v2 (get/update are already v2 above).
      def search_path
        '/v2/subscriptions'
      end
    end
  end
end
