# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::Subscriptions do
  let(:client) { build_client }
  let(:subscriptions) { client.subscriptions }

  describe '#list' do
    # This stubbed /v1/subscriptions, which does not exist -- the real endpoint answers 404 "Route
    # not found", so the example asserted the bug rather than the behaviour.
    it 'lists through the v2 path' do
      stub = stub_api(:get, '/v2/subscriptions', body: fixture('subscriptions_list'))

      result = subscriptions.list

      expect(stub).to have_been_requested
      expect(result).to be_a(Hyperline::Collection)
      expect(result.data.first['id']).to eq('sub_001')
    end

    # base_path stays on v1 because the action sub-paths genuinely live there.
    it 'leaves the action paths on v1' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/subscriptions/sub_001/cancel')
             .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      subscriptions.cancel('sub_001')

      expect(stub).to have_been_requested
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

  describe '#find_by_custom_property' do
    it 'searches the v2 list endpoint filtered by custom_properties and returns the verified match' do
      stub = stub_request(:get, 'https://api.hyperline.co/v2/subscriptions')
             .with(query: { 'custom_properties' => { 'chargebee_subscription_id' => 'cb_sub_1' } })
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: {
                 data: [
                   { id: 'sub_native_1', custom_properties: { chargebee_subscription_id: 'cb_sub_1' } }
                 ],
                 meta: { total: 1 }
               }.to_json
             )

      result = subscriptions.find_by_custom_property('chargebee_subscription_id', 'cb_sub_1')

      expect(stub).to have_been_requested
      expect(result['id']).to eq('sub_native_1')
    end

    it 'returns nil when there is no match' do
      stub_request(:get, 'https://api.hyperline.co/v2/subscriptions')
        .with(query: { 'custom_properties' => { 'chargebee_subscription_id' => 'missing' } })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { data: [], meta: { total: 0 } }.to_json
        )

      expect(subscriptions.find_by_custom_property('chargebee_subscription_id', 'missing')).to be_nil
    end

    it 'returns nil (instead of an arbitrary entity) when the API ignores the filter' do
      # Hyperline silently drops unknown query params and returns the unfiltered list; the
      # client-side verification must reject entities whose property does not actually match.
      stub_request(:get, 'https://api.hyperline.co/v2/subscriptions')
        .with(query: { 'custom_properties' => { 'chargebee_subscription_id' => 'missing' } })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { data: [{ id: 'sub_other', custom_properties: {} }], meta: { total: 1 } }.to_json
        )

      expect(subscriptions.find_by_custom_property('chargebee_subscription_id', 'missing')).to be_nil
    end

    it 'pages through the result set when the match is not on the first page' do
      # The filter may be ignored server-side, so a real match can sit on any page. Searching only
      # the first response would return nil for an entity that does exist.
      page1 = stub_request(:get, 'https://api.hyperline.co/v2/subscriptions')
              .with(query: { 'custom_properties' => { 'chargebee_subscription_id' => 'cb_sub_2' } })
              .to_return(
                status: 200,
                headers: { 'Content-Type' => 'application/json' },
                body: {
                  data: [{ id: 'sub_other', custom_properties: {} }],
                  meta: { total: 2, taken: 1, skipped: 0 }
                }.to_json
              )
      page2 = stub_request(:get, 'https://api.hyperline.co/v2/subscriptions')
              .with(query: {
                      'custom_properties' => { 'chargebee_subscription_id' => 'cb_sub_2' },
                      'skip' => '1'
                    })
              .to_return(
                status: 200,
                headers: { 'Content-Type' => 'application/json' },
                body: {
                  data: [{ id: 'sub_native_2', custom_properties: { chargebee_subscription_id: 'cb_sub_2' } }],
                  meta: { total: 2, taken: 1, skipped: 1 }
                }.to_json
              )

      result = subscriptions.find_by_custom_property('chargebee_subscription_id', 'cb_sub_2')

      expect(page1).to have_been_requested
      expect(page2).to have_been_requested
      expect(result['id']).to eq('sub_native_2')
    end

    it 'stops after one page when meta omits the pagination counters' do
      stub = stub_request(:get, 'https://api.hyperline.co/v2/subscriptions')
             .with(query: { 'custom_properties' => { 'chargebee_subscription_id' => 'missing' } })
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { data: [{ id: 'sub_other', custom_properties: {} }] }.to_json
             )

      expect(subscriptions.find_by_custom_property('chargebee_subscription_id', 'missing')).to be_nil
      expect(stub).to have_been_requested.once
    end
  end

  describe '#find_by_integration_entity_id' do
    it 'filters by integration_entity_id and returns the entity whose integrations match' do
      stub = stub_request(:get, 'https://api.hyperline.co/v2/subscriptions')
             .with(query: { 'integration_entity_id' => 'cb_sub_1' })
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: {
                 data: [
                   {
                     id: 'sub_native_1',
                     integrations: [{ entity_id: 'cb_sub_1', provider_name: 'chargebee' }]
                   }
                 ],
                 meta: { total: 1 }
               }.to_json
             )

      result = subscriptions.find_by_integration_entity_id('cb_sub_1')

      expect(stub).to have_been_requested
      expect(result['id']).to eq('sub_native_1')
    end

    it 'returns nil (instead of an arbitrary entity) when the API ignores the filter' do
      stub_request(:get, 'https://api.hyperline.co/v2/subscriptions')
        .with(query: { 'integration_entity_id' => 'missing' })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            data: [
              { id: 'sub_other', integrations: [{ entity_id: 'ZZZ', provider_name: 'chargebee' }] }
            ],
            meta: { total: 1 }
          }.to_json
        )

      expect(subscriptions.find_by_integration_entity_id('missing')).to be_nil
    end

    it 'pages through the result set when the match is not on the first page' do
      page1 = stub_request(:get, 'https://api.hyperline.co/v2/subscriptions')
              .with(query: { 'integration_entity_id' => 'cb_sub_2' })
              .to_return(
                status: 200,
                headers: { 'Content-Type' => 'application/json' },
                body: {
                  data: [{ id: 'sub_other', integrations: [{ entity_id: 'ZZZ' }] }],
                  meta: { total: 2, taken: 1, skipped: 0 }
                }.to_json
              )
      page2 = stub_request(:get, 'https://api.hyperline.co/v2/subscriptions')
              .with(query: { 'integration_entity_id' => 'cb_sub_2', 'skip' => '1' })
              .to_return(
                status: 200,
                headers: { 'Content-Type' => 'application/json' },
                body: {
                  data: [{ id: 'sub_native_2', integrations: [{ entity_id: 'cb_sub_2' }] }],
                  meta: { total: 2, taken: 1, skipped: 1 }
                }.to_json
              )

      result = subscriptions.find_by_integration_entity_id('cb_sub_2')

      expect(page1).to have_been_requested
      expect(page2).to have_been_requested
      expect(result['id']).to eq('sub_native_2')
    end
  end

  describe '#update_operation' do
    # The payload is the one the API accepts, verified against the sandbox. payment_schedule was
    # missing here, so this example documented a body that returns 400 -- invisible because the
    # request is stubbed.
    it 'posts the operation payload to the v1 update endpoint' do
      body = {
        type: 'update_count',
        payload: { product_id: 'itm_001', count: 25 },
        application_schedule: 'immediately',
        payment_schedule: 'immediately',
        calculation_method: 'pro_rata'
      }
      stub = stub_request(:post, 'https://api.hyperline.co/v1/subscriptions/sub_001/update')
             .with(body: body.to_json)
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'sub_001', status: 'active' }.to_json
             )

      result = subscriptions.update_operation('sub_001', body)

      expect(stub).to have_been_requested
      expect(result['id']).to eq('sub_001')
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
