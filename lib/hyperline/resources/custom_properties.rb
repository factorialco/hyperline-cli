# frozen_string_literal: true

module Hyperline
  module Resources
    class CustomProperties < BaseResource
      def get(_id)
        raise NotImplementedError, 'GET /v1/custom-properties/{id} does not exist. Use #list and filter locally.'
      end

      private

      def base_path
        '/v1/custom-properties'
      end
    end
  end
end
