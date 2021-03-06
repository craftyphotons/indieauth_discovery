# frozen_string_literal: true

require 'spec_helper'

require 'indieauth_discovery/profile'

RSpec.describe IndieAuthDiscovery::Profile do
  subject(:profile) { described_class.discover(profile_url) }

  let(:profile_body) { File.read(File.expand_path('../../support/fixtures/profile.html', __dir__)) }

  context 'with valid absolute links in the headers' do
    let(:profile_url) { 'https://example.org/me/' }

    before do
      stub_request(:head, profile_url).to_return(status: 204)
      stub_request(:get, profile_url).to_return(
        status: 200, body: '',
        headers: {
          'Content-Type': 'text/html',
          'Link': [
            '<https://example.org/auth>; rel="authorization_endpoint"',
            '<https://example.org/token>; rel="token_endpoint"'
          ]
        }
      )
    end

    it 'discovers the authorization endpoint' do
      expect(profile.authorization_endpoint).to eq('https://example.org/auth')
    end

    it 'discovers the token endpoint' do
      expect(profile.token_endpoint).to eq('https://example.org/token')
    end
  end

  context 'with valid links on the page' do
    let(:profile_url) { 'https://example.org/me/' }

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
