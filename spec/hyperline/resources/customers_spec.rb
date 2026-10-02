# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::Customers do
  let(:client) { build_client }
  let(:customers) { client.customers }

  describe '#get' do
    it 'returns a customer' do
      stub_api(
        :get,
        '/v1/customers/cus_001',
        body: {
          id: 'cus_001',
          name: 'Vault-Tec',
          billing_email: 'billing@vault-tec.com',
          currency: 'EUR',
          country: 'DE'
        }
      )

      result = customers.get('cus_001')

      expect(result['id']).to eq('cus_001')
      expect(result['billing_email']).to eq('billing@vault-tec.com')
    end

    it 'raises NotFoundError on 404' do
      stub_api(:get, '/v1/customers/cus_missing', status: 404, body: { message: 'Customer not found' })

      expect { customers.get('cus_missing') }.to raise_error(Hyperline::NotFoundError)
    end
  end

  describe '#features' do
    it 'returns the resolved feature map for a customer' do
      stub_api(
        :get,
        '/v1/customers/cus_001/features',
        body: {
          features: {
            expenses_core: { value: true, source: 'subscription' },
            ats_active_jobs: { value: false, source: 'default' }
          }
        }
      )

      result = customers.features('cus_001')

      expect(result['features']['expenses_core']['value']).to be(true)
      expect(result['features']['ats_active_jobs']['value']).to be(false)
    end

    it 'raises NotFoundError on 404' do
      stub_api(
        :get,
        '/v1/customers/cus_missing/features',
        status: 404,
        body: { message: 'Customer not found' }
      )

      expect { customers.features('cus_missing') }.to raise_error(Hyperline::NotFoundError)
    end
  end

  describe '#get_v2' do
    it 'gets /v2/customers/{id}' do
      stub = stub_api(:get, '/v2/customers/cus_001', body: { id: 'cus_001' })

      expect(customers.get_v2('cus_001')['id']).to eq('cus_001')
      expect(stub).to have_been_requested
    end
  end

  describe '#payment_methods' do
    def page(ids, skipped:, total:)
      { meta: { total: total, taken: ids.size, skipped: skipped }, data: ids.map { |i| { id: i } } }
    end

    it 'lists with take/skip and pages through the same customer' do
      stub_api(:get, '/v1/customers/cus_001/payment-methods', query: { 'take' => '1' },
                                                              body: page(%w[pm_1], skipped: 0, total: 2))
      stub_api(:get, '/v1/customers/cus_001/payment-methods', query: { 'take' => '1', 'skip' => '1' },
                                                              body: page(%w[pm_2], skipped: 1, total: 2))

      result = customers.payment_methods('cus_001', take: 1)

      expect(result).to be_a(Hyperline::Collection)
      expect(result.auto_paginate.map { |m| m['id'] }).to eq(%w[pm_1 pm_2])
    end

    it 'accepts a bare array response' do
      stub_api(:get, '/v1/customers/cus_001/payment-methods', body: [{ id: 'pm_1' }])

      result = customers.payment_methods('cus_001')

      expect(result.data.first['id']).to eq('pm_1')
      expect(result.next_page?).to be(false)
    end
  end

  describe '#delete_payment_method' do
    it 'deletes with the idempotency key' do
      stub = stub_request(:delete, 'https://api.hyperline.co/v1/customers/cus_001/payment-methods/pm_1')
             .with(headers: { 'Idempotency-Key' => 'key-1' })
             .to_return(status: 204, body: '')

      customers.delete_payment_method('cus_001', 'pm_1', idempotency_key: 'key-1')

      expect(stub).to have_been_requested
    end
  end

  describe '#portal' do
    it 'returns the portal url' do
      stub = stub_api(:get, '/v1/customers/cus_001/portal', body: { url: 'https://portal.example.com/x' })

      expect(customers.portal('cus_001')['url']).to eq('https://portal.example.com/x')
      expect(stub).to have_been_requested
    end
  end

  describe '#update' do
    it 'puts the attributes with the idempotency key' do
      stub = stub_request(:put, 'https://api.hyperline.co/v1/customers/cus_001')
             .with(body: { name: 'New' }.to_json, headers: { 'Idempotency-Key' => 'key-1' })
             .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      customers.update('cus_001', name: 'New', idempotency_key: 'key-1')

      expect(stub).to have_been_requested
    end
  end
end
