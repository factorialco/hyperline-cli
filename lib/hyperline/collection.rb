# frozen_string_literal: true

module Hyperline
  class Collection
    include Enumerable

    attr_reader :data, :meta

    def initialize(data:, meta:, resource:, params:)
      @data     = data
      @meta     = meta
      @resource = resource
      @params   = params
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

      @resource.list(**@params, skip: skipped + taken)
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
