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

    # Canonicalizes and verifies the URL.
    #
    # @see https://indieauth.spec.indieweb.org/#user-profile-url
    # @see https://indieauth.spec.indieweb.org/#client-identifier
    def canonicalize
      canonical = normalize_url(original_url)
      canonical, verify_response = verify_url(canonical)
      canonical = ensure_path(canonical)
      canonical = follow_redirects(canonical, verify_response)

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

    def normalize_url(url)
      URI.parse(url).normalize
    end

    # @see https://indieauth.spec.indieweb.org/#url-canonicalization
    def verify_url(uri)
      if (uri.is_a?(URI::HTTPS) || uri.is_a?(URI::HTTP)) && (last_response = check_url?(uri))
        # Use the URL as-is if its already HTTP(S) and is available
        [uri.to_s, last_response]
      elsif (last_response = check_url?(URI.parse("https://#{uri}")))
        # If no scheme was given (e.g. example.com), try HTTPS
        ["https://#{uri}", last_response]
      elsif (last_response = check_url?(URI.parse("http://#{uri}")))
        # Try HTTP if HTTPS is not available
        ["http://#{uri}", last_response]
      else
        # The URL is considered invalid if none of the above work
        raise_invalid_url_error(uri)
      end
    end

    def check_url?(uri)
      response = Faraday.head(uri)
      return false unless response.status < 400

      response
    rescue *FARADAY_ERRORS
      nil
    end

    def ensure_path(uri)
      return uri unless URI.parse(uri).path == ''

      "#{uri}/"
    end

    # @see https://indieauth.spec.indieweb.org/#redirect-examples
    def follow_redirects(uri, response)
      return uri unless [301, 302].include?(response.status)

      redirects = []
      redirector(uri, redirects).head

      uri = redirects.last if redirects.any? && redirects.last != uri
      uri
    end

    def redirector(uri, redirects)
      @redirector ||=
        begin
          callback = ->(old_env, new_env) { redirects << new_env.url.to_s if old_env.status == 301 }
          Faraday.new(url: uri) do |faraday|
            faraday.use(FaradayMiddleware::FollowRedirects, callback: callback)
            faraday.adapter(Faraday.default_adapter)
          end
        end
    end

    def raise_invalid_url_error(url)
      raise InvalidURLError.new(:invalid_url, 'URL must begin with http:// or https://', url)
    end
  end
end
