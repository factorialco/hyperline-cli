# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::Features do
  let(:client) { build_client }
  let(:features) { client.features }

  describe '#list' do
    it 'returns a collection of features' do
      stub_api(
        :get,
        '/v1/features',
        body: {
          meta: { total: 1, taken: 1, skipped: 0 },
          data: [{ code: 'ai_ticketing_core', value_type: 'boolean', default_value: false }]
        }
      )

      result = features.list

      expect(result).to be_a(Hyperline::Collection)
      expect(result.data.first['code']).to eq('ai_ticketing_core')
    end
  end

  # The identifier is the code, not an opaque id.
  describe '#get' do
    it 'addresses a feature by its code' do
      stub_api(:get, '/v1/features/ai_ticketing_core', body: { code: 'ai_ticketing_core' })

      expect(features.get('ai_ticketing_core')['code']).to eq('ai_ticketing_core')
    end
  end

  describe '#create' do
    it 'posts the definition' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/features')
             .with(body: { code: 'seats', value_type: 'number', resolution_strategy: 'max' }.to_json)
             .to_return(
               status: 201,
               headers: { 'Content-Type' => 'application/json' },
               body: { code: 'seats' }.to_json
             )

      features.create(code: 'seats', value_type: 'number', resolution_strategy: 'max')

      expect(stub).to have_been_requested
    end

    # A code that already exists is a conflict, not a silent replacement -- the catalog push
    # depends on being able to treat that as "already defined".
    it 'raises a conflict when the code is taken' do
      stub_api(:post, '/v1/features', status: 409, body: { message: 'code taken' })

      expect { features.create(code: 'seats') }.to raise_error(Hyperline::ConflictError)
    end
  end

  describe '#archive' do
    it 'puts to the archive path' do
      stub = stub_request(:put, 'https://api.hyperline.co/v1/features/seats/archive')
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { code: 'seats', status: 'archived' }.to_json
             )

      expect(features.archive('seats')['status']).to eq('archived')
      expect(stub).to have_been_requested
    end
  end

  # Deleting an active feature answers 400: archiving is a prerequisite, not an alternative.
  describe '#delete' do
    it 'refuses a feature that has not been archived' do
      stub_api(:delete, '/v1/features/seats', status: 400,
                                              body: { message: 'Cannot delete a feature that is not archived' })

      expect { features.delete('seats') }
        .to raise_error(Hyperline::BadRequestError, /not archived/)
    end
  end

  describe '#update' do
    it 'puts the definition to the code path' do
      stub = stub_request(:put, 'https://api.hyperline.co/v1/features/seats')
             .with(body: { value_type: 'number' }.to_json)
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { code: 'seats' }.to_json
             )

      features.update('seats', value_type: 'number')

      expect(stub).to have_been_requested
    end
  end
end
