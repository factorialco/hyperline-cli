# frozen_string_literal: true

module Hyperline
  module Resources
    class Products < BaseResource
      private

      def base_path
        '/v1/products'
      end
    end
  end
end
