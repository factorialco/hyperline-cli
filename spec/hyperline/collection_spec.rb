# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Collection do
  let(:client) { build_client }

  def page_body(skipped:, taken:, total:, ids:)
    { meta: { total: total, taken: taken, skipped: skipped }, data: ids.map { |i| { id: i } } }
  end

  describe '#next_page' do
    it 're-issues the default list for a page that came from it' do
      first = stub_request(:get, 'https://api.hyperline.co/v1/features')
              .with(query: { take: 1 })
              .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                         body: page_body(skipped: 0, taken: 1, total: 2, ids: %w[a]).to_json)
      second = stub_request(:get, 'https://api.hyperline.co/v1/features')
               .with(query: { take: 1, skip: 1 })
               .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                          body: page_body(skipped: 1, taken: 1, total: 2, ids: %w[b]).to_json)

      page = client.features.list(take: 1)

      expect(page.next_page.data.first['id']).to eq('b')
      expect(first).to have_been_requested
      expect(second).to have_been_requested
    end

    # The regression this exists for: next_page used to call the resource's default #list whatever
    # method had produced the page, so a custom one paged into the wrong endpoint -- and for
    # subscriptions that endpoint does not even exist.
    it 'stays on the custom list method that produced the page' do
      stub_request(:get, 'https://api.hyperline.co/v1/subscriptions/templates')
        .with(query: { take: 1 })
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                   body: page_body(skipped: 0, taken: 1, total: 2, ids: %w[tpl_a]).to_json)
      second = stub_request(:get, 'https://api.hyperline.co/v1/subscriptions/templates')
               .with(query: { take: 1, skip: 1 })
               .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                          body: page_body(skipped: 1, taken: 1, total: 2, ids: %w[tpl_b]).to_json)

      page = client.subscriptions.list_templates(take: 1)

      expect(page.next_page.data.first['id']).to eq('tpl_b')
      expect(second).to have_been_requested
    end

    it 'is nil on the last page' do
      stub_api(:get, '/v1/features', query: { take: 1 },
                                     body: page_body(skipped: 0, taken: 1, total: 1, ids: %w[a]))

      expect(client.features.list(take: 1).next_page).to be_nil
    end
  end

  describe '#auto_paginate' do
    it 'walks every page of a custom list method' do
      stub_request(:get, 'https://api.hyperline.co/v1/subscriptions/templates')
        .with(query: { take: 1 })
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                   body: page_body(skipped: 0, taken: 1, total: 2, ids: %w[tpl_a]).to_json)
      stub_request(:get, 'https://api.hyperline.co/v1/subscriptions/templates')
        .with(query: { take: 1, skip: 1 })
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                   body: page_body(skipped: 1, taken: 1, total: 2, ids: %w[tpl_b]).to_json)

      seen = []
      client.subscriptions.list_templates(take: 1).auto_paginate { |row| seen << row['id'] }

      expect(seen).to eq(%w[tpl_a tpl_b])
    end
  end
end
