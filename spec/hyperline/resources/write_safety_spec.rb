# frozen_string_literal: true

require 'spec_helper'

# The idempotency key is what makes retrying a write safe: verified against the Hyperline sandbox,
# the same key replays the first response, and the same body with no key creates a second
# operation. These examples pin both halves of that -- the header is actually sent, and the retry
# never engages without it.
RSpec.describe Hyperline::Resources::Requests do
  let(:client) { build_client }
  let(:subscriptions) { client.subscriptions }
  let(:operation) do
    {
      type: 'update_count',
      payload: { product_id: 'itm_001', count: 25 },
      application_schedule: 'immediately',
      payment_schedule: 'immediately',
      calculation_method: 'pro_rata'
    }
  end

  before { allow(subscriptions).to receive(:sleep) }

  describe 'the idempotency header' do
    it 'is sent when the caller supplies a key' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/subscriptions/sub_001/update')
             .with(headers: { 'Idempotency-Key' => 'seat-sub_001-25' })
             .to_return(
               status: 201,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'supd_001' }.to_json
             )

      result = subscriptions.update_operation('sub_001', operation, idempotency_key: 'seat-sub_001-25')

      expect(stub).to have_been_requested
      expect(result['id']).to eq('supd_001')
    end

    it 'is absent when the caller supplies none' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/subscriptions/sub_001/update')
             .with { |req| !req.headers.key?('Idempotency-Key') }
             .to_return(
               status: 201,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'supd_001' }.to_json
             )

      subscriptions.update_operation('sub_001', operation)

      expect(stub).to have_been_requested
    end
  end

  describe 'retrying a write' do
    it 'retries a 429 when a key makes the replay safe' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/subscriptions/sub_001/update')
             .to_return({ status: 429, headers: { 'Content-Type' => 'application/json' }, body: '{}' },
                        { status: 201, headers: { 'Content-Type' => 'application/json' },
                          body: { id: 'supd_001' }.to_json })

      result = subscriptions.update_operation('sub_001', operation, idempotency_key: 'k')

      expect(result['id']).to eq('supd_001')
      expect(stub).to have_been_requested.twice
    end

    it 'retries a 500 as well' do
      stub_request(:post, 'https://api.hyperline.co/v1/subscriptions/sub_001/update')
        .to_return({ status: 500, headers: { 'Content-Type' => 'application/json' }, body: '{}' },
                   { status: 201, headers: { 'Content-Type' => 'application/json' },
                     body: { id: 'supd_001' }.to_json })

      expect(subscriptions.update_operation('sub_001', operation, idempotency_key: 'k')['id'])
        .to eq('supd_001')
    end

    # Without a key a retry duplicates the operation instead of replaying it, so a single failure
    # has to surface rather than being quietly attempted again.
    it 'does not retry without a key' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/subscriptions/sub_001/update')
             .to_return(status: 429, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      expect { subscriptions.update_operation('sub_001', operation) }
        .to raise_error(Hyperline::RateLimitError)
      expect(stub).to have_been_requested.once
    end

    it 'gives up after a bounded number of attempts' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/subscriptions/sub_001/update')
             .to_return(status: 503, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      expect { subscriptions.update_operation('sub_001', operation, idempotency_key: 'k') }
        .to raise_error(Hyperline::ServerError)
      expect(stub).to have_been_requested.times(described_class::MAX_WRITE_RETRIES + 1)
    end

    # A 409 means the write landed or conflicts with state; repeating it cannot help.
    it 'does not retry a conflict' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/subscriptions/sub_001/update')
             .to_return(status: 409, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      expect { subscriptions.update_operation('sub_001', operation, idempotency_key: 'k') }
        .to raise_error(Hyperline::ConflictError)
      expect(stub).to have_been_requested.once
    end
  end
end
