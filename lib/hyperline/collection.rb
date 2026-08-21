# frozen_string_literal: true

module Hyperline
  class Collection
    include Enumerable

    attr_reader :data, :meta

    # `method` is the resource method that produced this page. It matters because next_page has to
    # re-issue the *same* call: defaulting to #list meant a page from a custom list method, such as
    # Subscriptions#list_templates, paged into the resource's default endpoint instead.
    def initialize(data:, meta:, resource:, params:, method: :list)
      @data     = data
      @meta     = meta
      @resource = resource
      @params   = params
      @method   = method
    end

    def each(&block)
      data.each(&block)
    end

    def total
      meta['total']
    end

    def taken
      meta['taken']
    end

    def skipped
      meta['skipped']
    end

    def next_page?
      skipped + taken < total
    end

    def next_page
      return nil unless next_page?

      @resource.public_send(@method, **@params, skip: skipped + taken)
    end

    def each_page
      return enum_for(:each_page) unless block_given?

      page = self
      loop do
        yield page
        break unless page.next_page?

        page = page.next_page
      end
    end

    def auto_paginate(&block)
      return enum_for(:auto_paginate) unless block_given?

      each_page do |page|
        page.each(&block)
      end
    end
  end
end
