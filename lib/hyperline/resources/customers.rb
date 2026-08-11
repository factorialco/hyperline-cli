# frozen_string_literal: true

module Hyperline
  module Resources
    class Customers < BaseResource
      def features(id)
        request(:get, "#{base_path}/#{id}/features")
      end

      private

      def base_path
        '/v1/customers'
      end
    end
  end
end
