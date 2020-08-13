# frozen_string_literal: true

require 'spec_helper'

require 'indieauth_discovery/client'

RSpec.describe IndieAuthDiscovery::Profile do
  subject(:client) { described_class.discover(client_url) }

  let(:client_body) { File.read(File.expand_path('../../support/fixtures/client.html', __dir__)) }

  context 'with valid absolute redirect_uri link in the headers' do
    let(:client_url) { 'https://example.org/' }

    before do
      stub_request(:head, client_url).to_return(status: 204)
      stub_request(:get, client_url).to_return(
        status: 200, body: '',
        headers: {
          'Content-Type': 'text/html',
          'Link': [
            '<https://example.org/redirect>; rel="redirect_uri"'
          ]
        }
      )
    end

    it 'discovers the redirect URI' do
      expect(client.redirect_uris).to include('https://example.org/redirect')
    end
  end

  context 'with valid relative redirect_uri link in the headers' do
    let(:client_url) { 'https://example.org/' }

    before do
      stub_request(:head, client_url).to_return(status: 204)
      stub_request(:get, client_url).to_return(
        status: 200, body: '',
        headers: {
          'Content-Type': 'text/html',
          'Link': [
            '</redirect>; rel="redirect_uri"'
          ]
        }
      )
    end

    it 'discovers the redirect URI' do
      expect(client.redirect_uris).to include('https://example.org/redirect')
    end
  end

  context 'with multiple valid links in the headers' do
    let(:client_url) { 'https://example.org/' }

    before do
      stub_request(:head, client_url).to_return(status: 204)
      stub_request(:get, client_url).to_return(
        status: 200, body: '',
        headers: {
          'Content-Type': 'text/html',
          'Link': [
            '<https://example.org/redirect>; rel="redirect_uri"',
            '<device://example.org/device-redirect>; rel="redirect_uri"'
          ]
        }
      )
    end

    %w(https://example.org/redirect device://example.org/redirect).each do |uri|
      it "discovers all of the #{uri}" do
        expect(client.redirect_uris).to include('https://example.org/redirect')
      end
    end
  end

  context 'with valid absolute redirect_uri link on the page' do
    let(:profile_url) { 'https://example.org/' }

    before do
      stub_request(:head, profile_url).to_return(status: 204)
      stub_request(:get, profile_url)
        .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
    end

    it 'discovers the authorization endpoint' do
      expect(profile.authorization_endpoint).to eq('https://example.org/auth')
    end

    it 'discovers the token endpoint' do
      expect(profile.token_endpoint).to eq('https://example.org/token')
    end

    it 'discovers the Micropub endpoint' do
      expect(profile.micropub_endpoint).to eq('https://example.org/micropub')
    end
  end

  context 'with both valid links in the header and valid links on the page' do
    let(:profile_url) { 'https://example.org/me/' }

    before do
      stub_request(:head, profile_url).to_return(status: 204)
      stub_request(:get, profile_url).to_return(
        status: 200, body: '',
        headers: {
          'Content-Type': 'text/html',
          'Link': [
            '<https://example.org/auth-from-header>; rel="authorization_endpoint"',
            '<https://example.org/token-from-header>; rel="token_endpoint"',
            '<https://example.org/micropub-from-header>; rel="micropub"'
          ]
        }
      )
    end

    it 'discovers the authorization endpoint from the header' do
      expect(profile.authorization_endpoint).to eq('https://example.org/auth-from-header')
    end

    it 'discovers the token endpoint from the header' do
      expect(profile.token_endpoint).to eq('https://example.org/token-from-header')
    end

    it 'discovers the Micropub endpoint from the header' do
      expect(profile.micropub_endpoint).to eq('https://example.org/micropub-from-header')
    end
  end
end
