# frozen_string_literal: true

require 'uri'

module Hyperline
  module Resources
    class Invoices < BaseResource
      def update(id, **attrs)
        request(:patch, resource_path(id), attrs)
      end

      def validate(id)
        request(:post, "#{resource_path(id)}/validate")
      end

      def charge(id, idempotency_key: nil, **params)
        request(:post, "#{resource_path(id)}/charge", params, idempotency_key: idempotency_key)
      end

      # GET /v2/invoices. Unlike /v1/invoices, which silently ignores `customer_id`, the v2 list
      # honours it. Cursor-paginated: params are `limit` and `cursor`.
      def list_v2(**params)
        response = request(:get, '/v2/invoices', params)
        cursor_collection(response, method: :list_v2, params: params)
      end

      def get_v2(id)
        request(:get, "/v2/invoices/#{id}")
      end

      def void(id)
        request(:post, "#{resource_path(id)}/void")
      end

      # The API answers with the PDF itself or a 302 to a temporary URL. The redirect is followed
      # once on a bare connection, because the Authorization header must not reach the other host.
      def download(id, **params)
        response = connection.get("/v2/invoices/#{id}/download", params)
        response = follow_redirect(response) if redirect?(response)
        build_download(response)
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

      def redirect?(response)
        [301, 302, 303, 307, 308].include?(response.status) && response.headers['Location']
      end

      def follow_redirect(response)
        target = URI.join(response.env.url.to_s, response.headers['Location'])
        bare = Faraday.new do |f|
          f.response :raise_error
          f.options.timeout = connection.options.timeout
          f.options.open_timeout = connection.options.open_timeout
          f.adapter Faraday.default_adapter
        end
        bare.get(target.to_s)
      end

      def build_download(response)
        disposition = response.headers['Content-Disposition'].to_s
        Download.new(
          body: response.body,
          content_type: response.headers['Content-Type'],
          filename: disposition[/filename\*?=(?:UTF-8'')?"?([^";]+)"?/i, 1]
        )
      end

      def base_path
        '/v1/invoices'
      end
    end
  end
end
