# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::Products do
  let(:client) { build_client }
  let(:products) { client.products }

  describe '#archive' do
    # PUT, not POST: the collection convention would suggest POST, which answers 404.
    it 'puts to the archive path' do
      stub = stub_request(:put, 'https://api.hyperline.co/v1/products/itm_001/archive')
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'itm_001', status: 'archived' }.to_json
             )

      expect(products.archive('itm_001')['status']).to eq('archived')
      expect(stub).to have_been_requested
    end
  end

  describe '#features' do
    # This endpoint answers with a bare array, not a meta/data envelope, so there is nothing to
    # wrap in a Collection and no page to walk.
    it 'returns the linked features as a plain array' do
      stub_api(
        :get,
        '/v1/products/itm_001/features',
        body: [{ feature_code: 'seats', value: 100 }, { feature_code: 'ai', value: true }]
      )

      result = products.features('itm_001')

      expect(result).to be_an(Array)
      expect(result.map { |f| f['feature_code'] }).to contain_exactly('seats', 'ai')
    end
  end

  describe '#link_feature' do
    it 'puts the value to the product-feature path' do
      stub = stub_request(:put, 'https://api.hyperline.co/v1/products/itm_001/features/seats')
             .with(body: { value: 100 }.to_json)
             .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      products.link_feature('itm_001', 'seats', value: 100)

      expect(stub).to have_been_requested
    end

    it 'sends the idempotency key when given one' do
      stub = stub_request(:put, 'https://api.hyperline.co/v1/products/itm_001/features/seats')
             .with(headers: { 'Idempotency-Key' => 'link-itm_001-seats-100' })
             .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      products.link_feature('itm_001', 'seats', value: 100,
                                                idempotency_key: 'link-itm_001-seats-100')

      expect(stub).to have_been_requested
    end

    # A value the feature's type cannot hold -- a cap on a boolean feature -- is a provisioning
    # error, not something to swallow.
    it 'raises when the value does not fit the feature type' do
      stub_api(:put, '/v1/products/itm_001/features/ai', status: 400,
                                                         body: { message: 'must be a boolean' })

      expect { products.link_feature('itm_001', 'ai', value: 5) }
        .to raise_error(Hyperline::BadRequestError, /boolean/)
    end
  end

  describe '#unlink_feature' do
    it 'deletes the product-feature path' do
      stub = stub_request(:delete, 'https://api.hyperline.co/v1/products/itm_001/features/seats')
             .to_return(status: 204, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      products.unlink_feature('itm_001', 'seats')

      expect(stub).to have_been_requested
    end
  end
end
