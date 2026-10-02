# frozen_string_literal: true

require 'spec_helper'
require 'openssl'

RSpec.describe Hyperline::Webhook do
  let(:raw_secret) { 'a-test-signing-key-0123456789abcd' }
  let(:secret) { "whsec_#{[raw_secret].pack('m0')}" }
  let(:now) { Time.at(1_700_000_000) }
  let(:payload) { { type: 'invoice.created', data: { id: 'inv_001' } }.to_json }
  let(:msg_id) { 'msg_abc123' }
  let(:timestamp) { now.to_i.to_s }

  def sign(content, key: raw_secret)
    [OpenSSL::HMAC.digest('SHA256', key, content)].pack('m0')
  end

  let(:signature) { sign("#{msg_id}.#{timestamp}.#{payload}") }
  let(:headers) do
    {
      'webhook-id' => msg_id,
      'webhook-timestamp' => timestamp,
      'webhook-signature' => "v1,#{signature}"
    }
  end

  def verify(overrides = {})
    described_class.verify!(payload: payload, headers: headers.merge(overrides), secret: secret, now: now)
  end

  it 'returns the parsed payload for a valid signature' do
    expect(verify).to eq('type' => 'invoice.created', 'data' => { 'id' => 'inv_001' })
  end

  it 'accepts any matching signature in a space-separated list' do
    other = sign('something else')

    expect(verify('webhook-signature' => "v1,#{other} v1,#{signature}")).to include('type' => 'invoice.created')
  end

  it 'accepts header keys case-insensitively' do
    mixed = { 'Webhook-Id' => msg_id, 'WEBHOOK-TIMESTAMP' => timestamp, 'Webhook-Signature' => "v1,#{signature}" }

    result = described_class.verify!(payload: payload, headers: mixed, secret: secret, now: now)

    expect(result['type']).to eq('invoice.created')
  end

  it 'rejects a bad signature' do
    expect { verify('webhook-signature' => "v1,#{sign('tampered')}") }
      .to raise_error(Hyperline::WebhookSignatureError, /No matching signature/)
  end

  it 'rejects a signature from another secret' do
    wrong = sign("#{msg_id}.#{timestamp}.#{payload}", key: 'another-key')

    expect { verify('webhook-signature' => "v1,#{wrong}") }.to raise_error(Hyperline::WebhookSignatureError)
  end

  it 'ignores non-v1 signature versions' do
    expect { verify('webhook-signature' => "v2,#{signature}") }.to raise_error(Hyperline::WebhookSignatureError)
  end

  it 'rejects a tampered body' do
    expect do
      described_class.verify!(payload: payload.sub('inv_001', 'inv_999'), headers: headers, secret: secret, now: now)
    end.to raise_error(Hyperline::WebhookSignatureError)
  end

  it 'rejects a stale timestamp' do
    old = (now.to_i - 301).to_s
    stale = headers.merge('webhook-timestamp' => old,
                          'webhook-signature' => "v1,#{sign("#{msg_id}.#{old}.#{payload}")}")

    expect { described_class.verify!(payload: payload, headers: stale, secret: secret, now: now) }
      .to raise_error(Hyperline::WebhookSignatureError, /tolerance/)
  end

  it 'rejects a timestamp too far in the future' do
    future = (now.to_i + 301).to_s
    ahead = headers.merge('webhook-timestamp' => future,
                          'webhook-signature' => "v1,#{sign("#{msg_id}.#{future}.#{payload}")}")

    expect { described_class.verify!(payload: payload, headers: ahead, secret: secret, now: now) }
      .to raise_error(Hyperline::WebhookSignatureError)
  end

  it 'honours a custom tolerance' do
    old = (now.to_i - 600).to_s
    aged = headers.merge('webhook-timestamp' => old,
                         'webhook-signature' => "v1,#{sign("#{msg_id}.#{old}.#{payload}")}")

    result = described_class.verify!(payload: payload, headers: aged, secret: secret, tolerance: 900, now: now)

    expect(result['type']).to eq('invoice.created')
  end

  it 'rejects missing headers' do
    expect { described_class.verify!(payload: payload, headers: {}, secret: secret, now: now) }
      .to raise_error(Hyperline::WebhookSignatureError, /Missing/)
  end

  it 'rejects a non-numeric timestamp' do
    expect { verify('webhook-timestamp' => 'yesterday') }.to raise_error(Hyperline::WebhookSignatureError)
  end

  it 'verifies a vector computed outside Ruby (openssl dgst, key "secret")' do
    result = described_class.verify!(
      payload: '{"a":1}',
      headers: {
        'webhook-id' => 'msg_1',
        'webhook-timestamp' => '1700000000',
        'webhook-signature' => 'v1,Q5nZ7DiOGwijBBqvBVAK6c0zDr2JLkXI7TaV4f+Q2vY='
      },
      secret: 'whsec_c2VjcmV0',
      now: now
    )

    expect(result).to eq('a' => 1)
  end
end
