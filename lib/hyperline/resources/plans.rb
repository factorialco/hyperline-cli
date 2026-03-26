# frozen_string_literal: true

module Hyperline
  module Resources
    class Plans < BaseResource
      def archive(id)
        request(:put, "#{resource_path(id)}/archive")
      end

      def unarchive(id)
        request(:put, "#{resource_path(id)}/unarchive")
      end

      private

      def base_path
        '/v1/plans'
      end
    end
  end
end
