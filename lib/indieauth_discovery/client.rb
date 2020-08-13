# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware/response/follow_redirects'
require 'link-header-parser'
require 'nokogiri'

require_relative './errors'
require_relative './url'

module IndieAuthDiscovery
  # Client information discovery according to the IndieAuth spec.
  #
  # @see https://indieauth.spec.indieweb.org/#client-information-discovery
  class Client
    attr_reader :url, :name, :logo, :photo

    def initialize(url)
      @url = URL.new(url)
    end

    # Returns a new Client after canonicalizing and verifying the URL and discovering the h-app card.
    def self.discover(url)
      new(url).discover
    end

    # Returns the Client after canonicalizing and verifying the URL and discovering the h-app card.
    def discover
      canonicalize_url
      fetch_profile
      find_endpoints
      self
    end

    private

    def canonicalize_url
      url.canonicalize
    end

    def fetch_client
      @response ||= get_follow_redirects(url.to_s)
      @client_document = parse_html_document(response)
    end

    def find_app
    end

    def parse_html_document(response)
      return Nokogiri::HTML('') unless response.headers['content-type'].start_with?('text/html')

      Nokogiri::HTML(response.body)
    end

    def get_follow_redirects(url)
      Faraday.new(url: url) do |faraday|
        faraday.use(FaradayMiddleware::FollowRedirects)
        faraday.adapter(Faraday.default_adapter)
      end.get
    end
  end
end
