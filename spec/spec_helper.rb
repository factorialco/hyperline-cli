# frozen_string_literal: true

require 'hyperline'
require 'webmock/rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.order = :random

  config.before do
    Hyperline.reset!
  end
end

def fixture_path(name)
  File.join(File.dirname(__FILE__), 'fixtures', "#{name}.json")
end

def fixture(name)
  JSON.parse(File.read(fixture_path(name)))
end

def stub_api(method, path, status: 200, body: {}, query: nil)
  stub = stub_request(method, "https://api.hyperline.co#{path}")
  stub = stub.with(query: query) if query
  stub.to_return(
    status: status,
    headers: { 'Content-Type' => 'application/json' },
    body: body.to_json
  )
end

def build_client
  Hyperline::Client.new(api_key: 'test_key_123')
end
