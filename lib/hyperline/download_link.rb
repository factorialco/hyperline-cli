# frozen_string_literal: true

require 'time'
require 'uri'

module Hyperline
  # A temporary, pre-signed URL for a document. `url` is nil when the API answered with the file
  # itself instead of a redirect; callers then fall back to the resource's `download`.
  # `expires_at` is derived from the X-Amz-Date and X-Amz-Expires query params when present.
  DownloadLink = Struct.new(:url, :expires_at, keyword_init: true) do
    def self.from_location(location)
      return new(url: nil, expires_at: nil) if location.nil?

      new(url: location, expires_at: expiry_of(location))
    end

    def self.expiry_of(location)
      params = URI.decode_www_form(URI.parse(location).query.to_s).to_h
      issued = params['X-Amz-Date']
      ttl = params['X-Amz-Expires']
      return nil unless issued && ttl

      Time.strptime("#{issued.delete_suffix('Z')}+0000", '%Y%m%dT%H%M%S%z').utc + Integer(ttl)
    rescue ArgumentError, URI::InvalidURIError
      nil
    end
    private_class_method :expiry_of
  end
end
