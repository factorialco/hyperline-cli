# frozen_string_literal: true

require_relative 'lib/hyperline/version'

Gem::Specification.new do |spec|
  spec.name          = 'hyperline'
  spec.version       = Hyperline::VERSION
  spec.authors       = ['Hyperline']
  spec.email         = ['support@hyperline.co']

  spec.summary       = 'Ruby client for the Hyperline billing API'
  spec.description   = 'Idiomatic Ruby client for the Hyperline billing platform. ' \
                       'Covers Products, Subscriptions, and Invoices with automatic ' \
                       'pagination, retry, and error handling.'
  spec.homepage      = 'https://docs.hyperline.co'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/hyperline/hyperline-ruby'
  spec.metadata['changelog_uri']   = 'https://github.com/hyperline/hyperline-ruby/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE.txt', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'faraday-retry', '~> 2.0'
end
