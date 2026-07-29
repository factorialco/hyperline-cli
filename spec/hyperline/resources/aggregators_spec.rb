# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::Aggregators do
  let(:client) { build_client }
  let(:aggregators) { client.aggregators }

  describe '#list' do
    it 'returns a collection of aggregators' do
      stub_api(
        :get,
        '/v1/aggregators',
        body: {
          meta: { total: 1, taken: 1, skipped: 0 },
          data: [{ id: 'agg_001', name: 'seats', operation: 'count' }]
        }
      )

      result = aggregators.list

      expect(result).to be_a(Hyperline::Collection)
      expect(result.data.length).to eq(1)
      expect(result.data.first['name']).to eq('seats')
    end
  end

  describe '#create' do
    it 'creates an aggregator' do
      stub =
        stub_request(:post, 'https://api.hyperline.co/v1/aggregators').with(
          body: {
            name: 'seats',
            entity: 'seats',
            operation: 'count',
            type: 'metered',
            unit_name: 'seat'
          }.to_json
        ).to_return(
          status: 201,
          headers: { 'Content-Type' => 'application/json' },
          body: { id: 'agg_001', name: 'seats' }.to_json
        )

      result =
        aggregators.create(
          name: 'seats',
          entity: 'seats',
          operation: 'count',
          type: 'metered',
          unit_name: 'seat'
        )

      expect(stub).to have_been_requested
      expect(result['id']).to eq('agg_001')
    end
  end

  describe '#get' do
    it 'returns an aggregator' do
      stub_api(:get, '/v1/aggregators/agg_001', body: { id: 'agg_001', name: 'seats' })

      result = aggregators.get('agg_001')

      expect(result['id']).to eq('agg_001')
    end
  end
end
