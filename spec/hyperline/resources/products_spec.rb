# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::Products do
  let(:client) { build_client }
  let(:products) { client.products }

  describe '#list' do
    it 'returns a collection of products' do
      stub_api(:get, '/v1/products', body: fixture('products_list'), query: { 'take' => '10' })

      result = products.list(take: 10)

      expect(result).to be_a(Hyperline::Collection)
      expect(result.data.length).to eq(2)
      expect(result.total).to eq(2)
      expect(result.data.first['id']).to eq('itm_001')
    end
  end

  describe '#get' do
    it 'returns a product' do
      stub_api(:get, '/v1/products/itm_001', body: fixture('product'))

      result = products.get('itm_001')

      expect(result['id']).to eq('itm_001')
      expect(result['name']).to eq('Pro Plan')
    end
  end

  describe '#create' do
    it 'creates a product' do
      stub =
        stub_request(:post, 'https://api.hyperline.co/v1/products').with(
          body: { name: 'New Plan', type: 'flat_fee' }.to_json
        ).to_return(
          status: 201,
          headers: {
            'Content-Type' => 'application/json'
          },
          body: { id: 'itm_003', name: 'New Plan', type: 'flat_fee' }.to_json
        )

      result = products.create(name: 'New Plan', type: 'flat_fee')

      expect(stub).to have_been_requested
      expect(result['id']).to eq('itm_003')
    end
  end

  describe '#update' do
    it 'updates a product' do
      stub =
        stub_request(:put, 'https://api.hyperline.co/v1/products/itm_001').with(
          body: { name: 'Updated Plan' }.to_json
        ).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'application/json'
          },
          body: { id: 'itm_001', name: 'Updated Plan' }.to_json
        )

      result = products.update('itm_001', name: 'Updated Plan')

      expect(stub).to have_been_requested
      expect(result['name']).to eq('Updated Plan')
    end
  end

  describe '#delete' do
    it 'archives a product' do
      stub = stub_api(:delete, '/v1/products/itm_001', status: 204, body: '')

      products.delete('itm_001')

      expect(stub).to have_been_requested
    end
  end

  describe 'error handling' do
    it 'raises AuthenticationError on 401' do
      stub_api(:get, '/v1/products', status: 401, body: { message: 'Invalid API key' })

      expect { products.list }.to raise_error(Hyperline::AuthenticationError) do |error|
        expect(error.status).to eq(401)
        expect(error.message).to eq('Invalid API key')
      end
    end

    it 'raises NotFoundError on 404' do
      stub_api(
        :get,
        '/v1/products/itm_missing',
        status: 404,
        body: {
          message: 'Product not found'
        }
      )

      expect { products.get('itm_missing') }.to raise_error(Hyperline::NotFoundError)
    end

    it 'raises RateLimitError on 429' do
      stub_api(:get, '/v1/products/itm_001', status: 429, body: { message: 'Rate limit exceeded' })

      expect { products.get('itm_001') }.to raise_error(Hyperline::RateLimitError)
    end

    it 'raises ApiError when response has nil status' do
      stub_request(:post, 'https://api.hyperline.co/v1/products').to_raise(
        Faraday::ClientError.new('unexpected error')
      )

      expect { products.create(name: 'Test') }.to raise_error(Hyperline::ApiError) do |error|
        expect(error.status).to be_nil
      end
    end

    it 'raises ServerError on 500' do
      stub_api(:get, '/v1/products', status: 500, body: { message: 'Internal server error' })

      expect { products.list }.to raise_error(Hyperline::ServerError) do |error|
        expect(error.status).to eq(500)
      end
    end
  end
end
