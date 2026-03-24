# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Client do
  it 'requires an api_key' do
    expect { described_class.new }.to raise_error(ArgumentError, 'api_key is required')
  end

  it 'accepts api_key as argument' do
    client = described_class.new(api_key: 'test_key')
    expect(client.configuration.api_key).to eq('test_key')
  end

  it 'uses global configuration api_key' do
    Hyperline.configure { |c| c.api_key = 'global_key' }
    client = described_class.new
    expect(client.configuration.api_key).to eq('global_key')
  end

  it 'overrides global config with explicit arguments' do
    Hyperline.configure { |c| c.api_key = 'global_key' }
    client = described_class.new(api_key: 'override_key')
    expect(client.configuration.api_key).to eq('override_key')
  end

  it 'exposes products resource' do
    client = described_class.new(api_key: 'test_key')
    expect(client.products).to be_a(Hyperline::Resources::Products)
  end

  it 'exposes subscriptions resource' do
    client = described_class.new(api_key: 'test_key')
    expect(client.subscriptions).to be_a(Hyperline::Resources::Subscriptions)
  end

  it 'exposes invoices resource' do
    client = described_class.new(api_key: 'test_key')
    expect(client.invoices).to be_a(Hyperline::Resources::Invoices)
  end

  it 'memoizes resource instances' do
    client = described_class.new(api_key: 'test_key')
    expect(client.products).to be(client.products)
  end

  describe 'Hyperline.client singleton' do
    it 'returns a client using global config' do
      Hyperline.configure { |c| c.api_key = 'singleton_key' }
      expect(Hyperline.client).to be_a(described_class)
      expect(Hyperline.client.configuration.api_key).to eq('singleton_key')
    end

    it 'returns the same client instance' do
      Hyperline.configure { |c| c.api_key = 'singleton_key' }
      expect(Hyperline.client).to be(Hyperline.client)
    end
  end
end
