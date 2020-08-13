# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware/response/follow_redirects'
require 'nokogiri'

require_relative './errors'

module IndieAuthDiscovery
  # Canonicalization for IndieAuth client and user profile URLs.
  class URL
    attr_reader :original_url, :canonical_url

    def initialize(original_url)
      @original_url = original_url.to_s
      @canonical_url = original_url.to_s
    end

    def self.canonicalize(original_url)
      url = new(original_url)
      url.canonicalize
      url
    end

    # Canonicalize and verify the URL.
    #
    # https://indieauth.spec.indieweb.org/#user-profile-url
    def canonicalize # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      # Normalize the URI (i.e. downcase the hostname)
      uri = URI.parse(@original_url).normalize

      # https://indieauth.spec.indieweb.org/#url-canonicalization
      canonical =
        if (uri.is_a?(URI::HTTPS) || uri.is_a?(URI::HTTP)) && (last_response = check_url?(uri))
          # Use the URL as-is if its already HTTP(S) and is available
          last_success_response = last_response
          uri.to_s
        elsif (last_response = check_url?(URI.parse("https://#{uri}")))
          # If no scheme was given (e.g. example.com), try HTTPS
          last_success_response = last_response
          "https://#{uri}"
        elsif (last_response = check_url?(URI.parse("http://#{uri}")))
          # Try HTTP if HTTPS is not available
          last_success_response = last_response
          "http://#{uri}"
        else
          # The URL is considered invalid if none of the above work
          raise_invalid_url_error(uri)
        end

      # Ensure that the URI has a path
      canonical = "#{canonical}/" if URI.parse(canonical).path == ''

      # Follow redirects
      if [301, 302].include?(last_success_response.status)
        redirects = []
        callback = ->(old_env, new_env) { redirects << new_env.url.to_s if old_env.status == 301 }
        redirector = Faraday.new(url: canonical) do |faraday|
          faraday.use(FaradayMiddleware::FollowRedirects, callback: callback)
          faraday.adapter(Faraday.default_adapter)
        end
        redirector.head

        canonical = redirects.last if redirects.any? && redirects.last != canonical
      end

      @canonical_url = canonical
    rescue URI::InvalidURIError, *FARADAY_ERRORS
      raise_invalid_url_error(original_url)
    end

    # Returns the canonical URL as a string.
    def to_s
      @canonical_url
    end

    # Returns the canonical URL as a URI.
    def to_uri
      URI.parse(@canonical_url)
    end

    private

    FARADAY_ERRORS = [Faraday::ConnectionFailed, Faraday::TimeoutError].freeze

    def check_url?(uri)
      response = Faraday.head(uri)
      return false unless response.status < 400

      response
    rescue *FARADAY_ERRORS
      nil
    end

    def raise_invalid_url_error(url)
      raise InvalidURLError.new(:invalid_url, 'URL must begin with http:// or https://', url)
    end
  end
end
