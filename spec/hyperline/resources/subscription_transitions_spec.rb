# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::SubscriptionTransitions do
  let(:client) { build_client }
  let(:transitions) { client.subscription_transitions }
  let(:transition) do
    {
      id: 'subtr_001',
      source_subscription_id: 'sub_001',
      target_subscription_id: 'sub_002',
      status: 'scheduled',
      transition_date: '2026-11-28T16:43:59.000Z'
    }
  end

  before { allow(transitions).to receive(:sleep) }

  describe '#list' do
    it 'filters by source subscription and status' do
      stub = stub_api(:get, '/v2/subscriptions/transitions',
                      query: { source_subscription_id: 'sub_001', status: 'scheduled' },
                      body: { meta: { total: 1, taken: 1, skipped: 0 }, data: [transition] })

      result = transitions.list(source_subscription_id: 'sub_001', status: 'scheduled')

      expect(stub).to have_been_requested
      expect(result.data.map { |t| t['id'] }).to eq(['subtr_001'])
    end
  end

  describe '#create' do
    it 'posts the transition with its idempotency key' do
      stub = stub_request(:post, 'https://api.hyperline.co/v2/subscriptions/transitions')
             .with(
               body: hash_including('source_subscription_id' => 'sub_001',
                                    'application_schedule' => 'scheduled'),
               headers: { 'Idempotency-Key' => 'key-1' }
             )
             .to_return(status: 201, headers: { 'Content-Type' => 'application/json' },
                        body: transition.to_json)

      result = transitions.create(
        source_subscription_id: 'sub_001',
        application_schedule: 'scheduled',
        transition_date: '2026-11-28T16:43:59.000Z',
        target_subscription: { products: [] },
        idempotency_key: 'key-1'
      )

      expect(stub).to have_been_requested
      expect(result['target_subscription_id']).to eq('sub_002')
    end

    it 'raises BadRequestError when one is already pending' do
      message = 'Subscription already has a pending transition'
      stub_api(:post, '/v2/subscriptions/transitions', status: 400, body: { message: message })

      expect { transitions.create(source_subscription_id: 'sub_001') }
        .to raise_error(Hyperline::BadRequestError)
    end
  end

  describe '#cancel' do
    it 'cancels a scheduled transition' do
      stub_api(:post, '/v2/subscriptions/transitions/subtr_001/cancel',
               body: transition.merge(status: 'cancelled'))

      expect(transitions.cancel('subtr_001')['status']).to eq('cancelled')
    end
  end
end
