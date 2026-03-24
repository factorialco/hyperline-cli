# frozen_string_literal: true

module Hyperline
  module Resources
    class Subscriptions < BaseResource
      def get(id)
        request(:get, "/v2/subscriptions/#{id}")
      end

      def update(id, **attrs)
        request(:put, "/v2/subscriptions/#{id}", attrs)
      end

      def cancel(id, **params)
        request(:post, "#{resource_path(id)}/cancel", params)
      end

      def pause(id, **params)
        request(:post, "#{resource_path(id)}/pause", params)
      end

      def activate(id, **params)
        request(:post, "#{resource_path(id)}/activate", params)
      end

      def reactivate(id, **params)
        request(:post, "#{resource_path(id)}/reactivate", params)
      end

      def reinstate(id, **params)
        request(:post, "#{resource_path(id)}/reinstate", params)
      end

      def renew(id, **params)
        request(:post, "#{resource_path(id)}/renew", params)
      end

      def list_templates(**params)
        response = request(:get, "#{base_path}/templates", params)
        Collection.new(
          data: response['data'],
          meta: response['meta'],
          resource: self,
          params: params
        )
      end

      def get_template(id)
        request(:get, "#{base_path}/templates/#{id}")
      end

      private

      def base_path
        '/v1/subscriptions'
      end
    end
  end
end
