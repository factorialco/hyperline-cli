# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::Subscriptions do
  let(:client) { build_client }
  let(:subscriptions) { client.subscriptions }

  describe '#list' do
    it 'returns a collection of subscriptions' do
      stub_api(:get, '/v1/subscriptions', body: fixture('subscriptions_list'))

      result = subscriptions.list

      expect(result).to be_a(Hyperline::Collection)
      expect(result.data.length).to eq(1)
      expect(result.data.first['id']).to eq('sub_001')
    end
  end

  describe '#get' do
    it 'uses v2 endpoint' do
      stub = stub_api(:get, '/v2/subscriptions/sub_001', body: fixture('subscription'))

      result = subscriptions.get('sub_001')

      expect(stub).to have_been_requested
      expect(result['id']).to eq('sub_001')
    end
  end

  describe '#create' do
    it 'creates a subscription' do
      body = { customer_id: 'cus_001', plan_id: 'plan_001' }
      stub = stub_request(:post, 'https://api.hyperline.co/v1/subscriptions')
             .with(body: body.to_json)
             .to_return(
               status: 201,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'sub_002', status: 'pending' }.to_json
             )

      result = subscriptions.create(**body)

      expect(stub).to have_been_requested
      expect(result['id']).to eq('sub_002')
    end
  end

  describe '#update' do
    it 'uses v2 endpoint' do
      stub = stub_request(:put, 'https://api.hyperline.co/v2/subscriptions/sub_001')
             .with(body: { name: 'Updated' }.to_json)
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'sub_001', name: 'Updated' }.to_json
             )

      result = subscriptions.update('sub_001', name: 'Updated')

      expect(stub).to have_been_requested
      expect(result['name']).to eq('Updated')
    end
  end

  describe 'action methods' do
    %w[cancel pause activate reactivate reinstate renew].each do |action|
      describe "##{action}" do
        it "posts to the #{action} endpoint" do
          stub = stub_request(:post, "https://api.hyperline.co/v1/subscriptions/sub_001/#{action}")
                 .to_return(
                   status: 200,
                   headers: { 'Content-Type' => 'application/json' },
                   body: { id: 'sub_001', status: action }.to_json
                 )

          subscriptions.public_send(action, 'sub_001')

          expect(stub).to have_been_requested
        end
      end
    end

    it 'passes params to cancel' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/subscriptions/sub_001/cancel')
             .with(body: { cancel_at: 'period_end' }.to_json)
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'sub_001', status: 'cancelled' }.to_json
             )

      subscriptions.cancel('sub_001', cancel_at: 'period_end')

      expect(stub).to have_been_requested
    end
  end

  describe 'templates' do
    describe '#list_templates' do
      it 'returns templates collection' do
        body = {
          meta: { total: 1, taken: 1, skipped: 0 },
          data: [{ id: 'tpl_001', name: 'Monthly Template' }]
        }
        stub_api(:get, '/v1/subscriptions/templates', body: body)

        result = subscriptions.list_templates

        expect(result).to be_a(Hyperline::Collection)
        expect(result.data.first['id']).to eq('tpl_001')
      end
    end

    describe '#get_template' do
      it 'returns a template' do
        stub_api(:get, '/v1/subscriptions/templates/tpl_001',
                 body: { id: 'tpl_001', name: 'Monthly Template' })

        result = subscriptions.get_template('tpl_001')

        expect(result['id']).to eq('tpl_001')
      end
    end
  end
end
