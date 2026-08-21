# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::ErrorMapper do
  describe '.from_response' do
    {
      400 => Hyperline::BadRequestError,
      401 => Hyperline::AuthenticationError,
      404 => Hyperline::NotFoundError,
      409 => Hyperline::ConflictError,
      422 => Hyperline::UnprocessableEntityError,
      429 => Hyperline::RateLimitError,
      500 => Hyperline::ServerError,
      503 => Hyperline::ServerError
    }.each do |status, klass|
      it "maps #{status} to #{klass}" do
        expect(described_class.from_response(status, nil)).to be_a(klass)
      end
    end

    # 409 and 422 used to land here, which made "already exists" and "not allowed" arrive as the
    # same generic failure as an unrecognised status.
    it 'maps an unrecognised 4xx to the generic error' do
      error = described_class.from_response(418, nil)

      expect(error).to be_an_instance_of(Hyperline::ApiError)
    end

    it 'carries the status and the parsed message' do
      error = described_class.from_response(409, { 'message' => 'feature code taken' })

      expect(error.status).to eq(409)
      expect(error.message).to eq('feature code taken')
    end
  end
end
