# frozen_string_literal: true

module Hyperline
  module Resources
    class Invoices < BaseResource
      def update(id, **attrs)
        request(:patch, resource_path(id), attrs)
      end

      def validate(id)
        request(:post, "#{resource_path(id)}/validate")
      end

      def charge(id, **params)
        request(:post, "#{resource_path(id)}/charge", params)
      end

      def void(id)
        request(:post, "#{resource_path(id)}/void")
      end

      def download(id)
        response = connection.get("#{resource_path(id)}/download")
        response.body
      rescue Faraday::ClientError, Faraday::ServerError => e
        handle_error(e)
      end

      def create_credit_note(id, **attrs)
        request(:post, "#{resource_path(id)}/credit-notes", attrs)
      end

      def mark_uncollectible(id)
        request(:post, "#{resource_path(id)}/uncollectible")
      end

      def create_transaction(id, **attrs)
        request(:post, "#{resource_path(id)}/transactions", attrs)
      end

      def delete_transaction(id, transaction_id)
        request(:delete, "#{resource_path(id)}/transactions/#{transaction_id}")
      end

      private

      def base_path
        '/v1/invoices'
      end
    end
  end
end
