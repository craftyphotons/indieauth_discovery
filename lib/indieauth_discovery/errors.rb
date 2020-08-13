# frozen_string_literal: true

module IndieAuthDiscovery
  # Base class for IndieAuthDiscovery errors.
  class Error < StandardError
    attr_accessor :error, :error_reason, :error_uri

    def initialize(error, error_reason = nil, error_uri = nil)
      @error = error
      @error_reason = error_reason
      @error_uri = error_uri

      super(message)
    end

    def message
      [error, error_reason, error_uri].compact.join(' | ')
    end
  end

  # Error raised when endpoint discovery fails.
  class DiscoveryError < Error
  end

  # Error raised when a URL is invalid.
  class InvalidURLError < Error
  end
end
