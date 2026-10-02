# frozen_string_literal: true

module Hyperline
  # A downloaded file. `to_str` keeps callers that treated the old return value as the raw bytes
  # (File.binwrite, String#include?) working.
  Download = Struct.new(:body, :content_type, :filename, keyword_init: true) do
    def to_str
      body.to_s
    end
    alias_method :to_s, :to_str
  end
end
