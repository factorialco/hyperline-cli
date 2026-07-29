# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::PriceBooks do
  let(:client) { build_client }
  let(:price_books) { client.price_books }

  describe '#list' do
    it 'returns a collection of price books' do
      stub_api(
        :get,
        '/v1/price-books',
        body: {
          meta: { total: 1, taken: 1, skipped: 0 },
          data: [{ id: 'pb_001', name: 'F25 ES' }]
        }
      )

      result = price_books.list

      expect(result).to be_a(Hyperline::Collection)
      expect(result.data.first['name']).to eq('F25 ES')
    end
  end

  describe '#create' do
    it 'creates a price book' do
      stub =
        stub_request(:post, 'https://api.hyperline.co/v1/price-books').with(
          body: { name: 'F25 ES', description: 'Spanish F25 catalog' }.to_json
        ).to_return(
          status: 201,
          headers: { 'Content-Type' => 'application/json' },
          body: { id: 'pb_001', name: 'F25 ES' }.to_json
        )

      result = price_books.create(name: 'F25 ES', description: 'Spanish F25 catalog')

      expect(stub).to have_been_requested
      expect(result['id']).to eq('pb_001')
    end
  end

  describe '#add_products' do
    it 'attaches products to the price book' do
      stub =
        stub_request(:post, 'https://api.hyperline.co/v1/price-books/pb_001/products').with(
          body: { product_ids: %w[itm_001 itm_002] }.to_json
        ).to_return(status: 204, headers: { 'Content-Type' => 'application/json' }, body: '')

      price_books.add_products('pb_001', product_ids: %w[itm_001 itm_002])

      expect(stub).to have_been_requested
    end
  end

  describe '#remove_product' do
    it 'removes a product from the price book' do
      stub =
        stub_request(
          :delete,
          'https://api.hyperline.co/v1/price-books/pb_001/products/itm_001'
        ).to_return(status: 204, headers: { 'Content-Type' => 'application/json' }, body: '')

      price_books.remove_product('pb_001', 'itm_001')

      expect(stub).to have_been_requested
    end
  end
end
