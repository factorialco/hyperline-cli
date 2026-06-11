# frozen_string_literal: true

module Hyperline
  module Resources
    class PriceConfigurations < BaseResource
      def update_prices(id, prices:)
        request(:put, "#{resource_path(id)}/prices", prices)
      end

      def archive(id)
        request(:put, "#{resource_path(id)}/archive")
      end

      def unarchive(id)
        request(:put, "#{resource_path(id)}/unarchive")
      end

      private

      def base_path
        '/v1/price-configurations'
      end
    end
  end
end
