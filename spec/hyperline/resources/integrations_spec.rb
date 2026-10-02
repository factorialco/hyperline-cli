# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::Integrations do
  let(:client) { build_client }

  describe '#create_component_token' do
    it 'posts the customer id and returns the token' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/integrations/components/token')
             .with(body: { customer_id: 'cus_001' }.to_json, headers: { 'Idempotency-Key' => 'key-1' })
             .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                        body: { token: 'tok', token_type: 'Bearer' }.to_json)

      result = client.integrations.create_component_token(customer_id: 'cus_001', idempotency_key: 'key-1')

      expect(stub).to have_been_requested
      expect(result).to eq('token' => 'tok', 'token_type' => 'Bearer')
    end
  end
end
