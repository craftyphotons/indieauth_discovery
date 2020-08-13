# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware/response/follow_redirects'
require 'link-header-parser'
require 'nokogiri'

require_relative './errors'
require_relative './url'

module IndieAuthDiscovery
  # User profile information discovery according to the IndieAuth spec.
  #
  # @see https://indieauth.spec.indieweb.org/#discovery-by-clients
  class Profile
    attr_reader :profile_url, :authorization_endpoint, :micropub_endpoint, :token_endpoint, :response

    def initialize(default_scheme: :https)
      @default_scheme = default_scheme
    end

    def call(url)
      @profile_url = URL.canonicalize(url)
      retrieve
      discover
    end

    private

    def retrieve
      @response ||= get_follow_redirects(profile_url.to_s)
      @link_headers = parse_link_headers(response)
      @profile_document = parse_html_document(response)
    end

    def discover
      @authorization_endpoint = first_link('authorization_endpoint')
      @token_endpoint = first_link('token_endpoint')
      @micropub_endpoint = first_link('micropub')
    end

    def parse_link_headers(response)
      return {} unless response.headers['link']

      LinkHeaderParser.parse(response.headers['link'], base: profile_url.to_s).group_by_relation_type
    end

    def parse_html_document(response)
      return Nokogiri::HTML('') unless response.headers['content-type'].start_with?('text/html')

      Nokogiri::HTML(response.body)
    end

    def first_link(rel)
      @link_headers[rel.to_sym]&.first&.target_uri ||
        @profile_document.at_xpath("//link[@rel='#{rel}']")&.attribute('href')&.to_s
    end

    def get_follow_redirects(url)
      Faraday.new(url: url) do |faraday|
        faraday.use(FaradayMiddleware::FollowRedirects)
        faraday.adapter(Faraday.default_adapter)
      end.get
    end
  end
end
