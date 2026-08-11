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
end
