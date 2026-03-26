# frozen_string_literal: true

module Hyperline
  module Resources
    class PriceBooks < BaseResource
      private

      def base_path
        '/v1/price-books'
      end
    end
  end
end
