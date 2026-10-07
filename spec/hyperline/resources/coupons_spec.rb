# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::Coupons do
  let(:client) { build_client }
  let(:coupons) { client.coupons }
  let(:coupon) do
    {
      id: 'cou_001',
      name: 'Launch',
      type: 'percent',
      discount_percent: 50,
      repeat: 'duration',
      duration: { count: 1, period: 'months' }
    }
  end

  before { allow(coupons).to receive(:sleep) }

  describe '#list' do
    it 'returns a collection and sends take and skip as query params' do
      stub = stub_request(:get, 'https://api.hyperline.co/v1/coupons')
             .with(query: { take: 10, skip: 20 })
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { meta: { total: 31, taken: 10, skipped: 20 }, data: [coupon] }.to_json
             )

      result = coupons.list(take: 10, skip: 20)

      expect(stub).to have_been_requested
      expect(result).to be_a(Hyperline::Collection)
      expect(result.data.first['id']).to eq('cou_001')
      expect(result.total).to eq(31)
    end

    it 'pages through the remaining coupons' do
      [[{ take: 1 }, 0, 'cou_001'], [{ take: 1, skip: 1 }, 1, 'cou_002']].each do |query, skipped, id|
        stub_api(:get, '/v1/coupons', query: query,
                                      body: { meta: { total: 2, taken: 1, skipped: skipped }, data: [{ id: id }] })
      end

      ids = coupons.list(take: 1).auto_paginate.map { |c| c['id'] }

      expect(ids).to eq(%w[cou_001 cou_002])
    end
  end

  describe '#get' do
    it 'fetches a coupon by id' do
      stub_api(:get, '/v1/coupons/cou_001', body: coupon)

      expect(coupons.get('cou_001')['discount_percent']).to eq(50)
    end

    it 'raises NotFoundError for an unknown coupon' do
      stub_api(:get, '/v1/coupons/cou_missing', status: 404, body: { message: 'Not found' })

      expect { coupons.get('cou_missing') }.to raise_error(Hyperline::NotFoundError)
    end
  end

  describe '#create' do
    let(:attrs) do
      {
        name: 'Launch', type: 'percent', discount_percent: 50, repeat: 'duration',
        duration: { count: 1, period: 'months' }, redemption_limit: nil
      }
    end

    it 'posts the definition and parses the 201 response' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/coupons')
             .with(body: attrs.to_json)
             .to_return(status: 201, headers: { 'Content-Type' => 'application/json' }, body: coupon.to_json)

      result = coupons.create(**attrs)

      expect(stub).to have_been_requested
      expect(result['id']).to eq('cou_001')
      expect(result['duration']).to eq('count' => 1, 'period' => 'months')
    end

    it 'posts an amount coupon with its currency' do
      body = { name: 'Ten off', type: 'amount', discount_amount: 1000, currency: 'EUR' }
      stub = stub_request(:post, 'https://api.hyperline.co/v1/coupons')
             .with(body: body.to_json)
             .to_return(status: 201, headers: { 'Content-Type' => 'application/json' }, body: '{"id":"cou_002"}')

      coupons.create(**body)

      expect(stub).to have_been_requested
    end

    it 'sends the Idempotency-Key header when given' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/coupons')
             .with(headers: { 'Idempotency-Key' => 'coupon-launch' })
             .to_return(status: 201, headers: { 'Content-Type' => 'application/json' }, body: coupon.to_json)

      coupons.create(idempotency_key: 'coupon-launch', **attrs)

      expect(stub).to have_been_requested
    end

    it 'omits the header and does not retry without a key' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/coupons')
             .with { |req| !req.headers.key?('Idempotency-Key') }
             .to_return(status: 503, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      expect { coupons.create(**attrs) }.to raise_error(Hyperline::ServerError)
      expect(stub).to have_been_requested.once
    end

    it 'retries a 5xx when a key is given' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/coupons')
             .to_return({ status: 503, headers: { 'Content-Type' => 'application/json' }, body: '{}' },
                        { status: 201, headers: { 'Content-Type' => 'application/json' }, body: coupon.to_json })

      result = coupons.create(idempotency_key: 'k', **attrs)

      expect(result['id']).to eq('cou_001')
      expect(stub).to have_been_requested.twice
    end

    it 'maps a 400 to BadRequestError' do
      stub_api(:post, '/v1/coupons', status: 400, body: { message: 'name is required' })

      expect { coupons.create(type: 'percent') }.to raise_error(Hyperline::BadRequestError, /name is required/)
    end
  end

  describe '#update' do
    it 'puts the changes to the coupon path' do
      stub = stub_request(:put, 'https://api.hyperline.co/v1/coupons/cou_001')
             .with(body: { name: 'Renamed' }.to_json)
             .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                        body: coupon.merge(name: 'Renamed').to_json)

      expect(coupons.update('cou_001', name: 'Renamed')['name']).to eq('Renamed')
      expect(stub).to have_been_requested
    end
  end

  describe '#delete' do
    it 'accepts an empty 204 body' do
      stub = stub_request(:delete, 'https://api.hyperline.co/v1/coupons/cou_001').to_return(status: 204, body: '')

      expect { coupons.delete('cou_001') }.not_to raise_error
      expect(stub).to have_been_requested
    end

    it 'accepts an empty 204 body with a JSON content type' do
      stub_request(:delete, 'https://api.hyperline.co/v1/coupons/cou_001')
        .to_return(status: 204, headers: { 'Content-Type' => 'application/json' }, body: '')

      expect { coupons.delete('cou_001') }.not_to raise_error
    end

    it 'raises NotFoundError for an unknown coupon' do
      stub_api(:delete, '/v1/coupons/cou_missing', status: 404, body: { message: 'Not found' })

      expect { coupons.delete('cou_missing') }.to raise_error(Hyperline::NotFoundError)
    end
  end

  describe 'error mapping' do
    it 'maps 401, 429 and 500' do
      { 401 => Hyperline::AuthenticationError, 429 => Hyperline::RateLimitError,
        500 => Hyperline::ServerError }.each do |status, error|
        stub_api(:get, '/v1/coupons/cou_x', status: status, body: { message: 'boom' })

        expect { coupons.get('cou_x') }.to raise_error(error)
      end
    end
  end
end
