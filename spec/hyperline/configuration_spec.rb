# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Configuration do
  subject(:config) { described_class.new }

  it 'has default base_url' do
    expect(config.base_url).to eq('https://api.hyperline.co')
  end

  it 'has default timeout' do
    expect(config.timeout).to eq(30)
  end

  it 'has default open_timeout' do
    expect(config.open_timeout).to eq(10)
  end

  it 'has default max_retries' do
    expect(config.max_retries).to eq(3)
  end

  it 'allows setting api_key' do
    config.api_key = 'test_key'
    expect(config.api_key).to eq('test_key')
  end

  it 'allows setting sandbox base_url' do
    config.base_url = 'https://sandbox.api.hyperline.co'
    expect(config.base_url).to eq('https://sandbox.api.hyperline.co')
  end
end
