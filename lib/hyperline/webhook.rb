# frozen_string_literal: true

require 'json'
require 'openssl'

module Hyperline
  # Verifies Svix-style webhook signatures: HMAC-SHA256 over "<id>.<timestamp>.<raw body>", keyed
  # by the base64-decoded secret.
  module Webhook
    DEFAULT_TOLERANCE = 300
    SECRET_PREFIX = 'whsec_'

    # Returns the parsed JSON payload. `payload` must be the raw request body: re-serialising a
    # parsed body changes the bytes and breaks the signature.
    def self.verify!(payload:, headers:, secret:, tolerance: DEFAULT_TOLERANCE, now: Time.now)
      normalized = headers.to_h.transform_keys { |key| key.to_s.downcase }
      id, timestamp, signatures = extract(normalized)

      check_timestamp!(timestamp, tolerance, now)
      expected = sign(secret, "#{id}.#{timestamp}.#{payload}")
      raise WebhookSignatureError, 'No matching signature found' unless match?(expected, signatures)

      JSON.parse(payload)
    end

    def self.extract(headers)
      id = headers['webhook-id']
      timestamp = headers['webhook-timestamp']
      signature = headers['webhook-signature']
      if [id, timestamp, signature].any? { |value| value.nil? || value.to_s.empty? }
        raise WebhookSignatureError, 'Missing webhook-id, webhook-timestamp or webhook-signature header'
      end

      [id.to_s, timestamp.to_s, signature.to_s]
    end
    private_class_method :extract

    def self.check_timestamp!(timestamp, tolerance, now)
      raise WebhookSignatureError, 'Invalid webhook-timestamp header' unless timestamp.match?(/\A\d+\z/)

      return unless (now.to_i - timestamp.to_i).abs > tolerance

      raise WebhookSignatureError, 'Webhook timestamp is outside the tolerance window'
    end
    private_class_method :check_timestamp!

    def self.sign(secret, content)
      key = secret.to_s.delete_prefix(SECRET_PREFIX).unpack1('m')
      [OpenSSL::HMAC.digest('SHA256', key, content)].pack('m0')
    end
    private_class_method :sign

    def self.match?(expected, header)
      header.split.any? do |entry|
        version, signature = entry.split(',', 2)
        version == 'v1' && secure_compare?(expected, signature.to_s)
      end
    end
    private_class_method :match?

    def self.secure_compare?(expected, candidate)
      expected.bytesize == candidate.bytesize && OpenSSL.fixed_length_secure_compare(expected, candidate)
    end
    private_class_method :secure_compare?
  end
end
