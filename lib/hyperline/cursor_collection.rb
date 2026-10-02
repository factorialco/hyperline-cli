# frozen_string_literal: true

module Hyperline
  # A page of a cursor-paginated (v2) list. Mirrors Collection, but pages by an opaque cursor
  # instead of a skip offset.
  class CursorCollection
    include Enumerable

    attr_reader :data, :next_cursor

    def initialize(data:, next_cursor:, has_more:, resource:, params:, method:, args: [])
      @data        = data
      @next_cursor = next_cursor
      @has_more    = has_more
      @resource    = resource
      @params      = params
      @method      = method
      @args        = args
    end

    def each(&block)
      data.each(&block)
    end

    # A cursor with no `has_more` flag still means another page; a flag without a cursor cannot be
    # followed, so both must agree before paging on.
    def next_page?
      return false if next_cursor.nil? || next_cursor.to_s.empty?

      @has_more.nil? || @has_more
    end
    alias has_more? next_page?

    def next_page
      return nil unless next_page?

      @resource.public_send(@method, *@args, **@params, cursor: next_cursor)
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

      each_page { |page| page.each(&block) }
    end
  end
end
