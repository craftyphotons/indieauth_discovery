# frozen_string_literal: true

require 'indieauth_discovery/url'

RSpec.describe IndieAuthDiscovery::URL do
  subject(:url) { described_class }

  let(:profile_body) { File.read(File.expand_path('../../support/fixtures/profile.html', __dir__)) }

  describe '#canonicalize' do
    # https://indieauth.spec.indieweb.org/#url-canonicalization
    context 'with a valid HTTP(s) URL' do
      it 'adds an empty path if none is present' do
        stub_request(:head, 'https://example.org/').to_return(status: 204)
        stub_request(:get, 'https://example.org/')
          .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
        result = url.canonicalize('https://example.org')
        expect(result.canonical_url).to eq('https://example.org/')
      end

      it 'does not add a trailing slash if a path is present' do
        stub_request(:head, 'https://example.org/me').to_return(status: 204)
        stub_request(:get, 'https://example.org/me')
          .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
        result = url.canonicalize('https://example.org/me')
        expect(result.canonical_url).to eq('https://example.org/me')
      end

      it 'retains any query string parameters' do
        stub_request(:head, 'https://example.org/users').with(query: hash_including('id' => '100'))
                                                        .to_return(status: 204)
        stub_request(:get, 'https://example.org/users').with(query: hash_including('id' => '100'))
                                                       .to_return(status: 200, body: profile_body,
                                                                  headers: { 'Content-Type': 'text/html' })
        result = url.canonicalize('https://example.org/users?id=100')
        expect(result.canonical_url).to eq('https://example.org/users?id=100')
      end
    end

    # https://indieauth.spec.indieweb.org/#url-canonicalization
    context 'with a generic URL that responds via https' do
      before do
        stub_request(:head, 'https://example.org/').to_return(status: 204)
        stub_request(:get, 'https://example.org/')
          .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
      end

      it 'uses https for the URL' do
        result = url.canonicalize('example.org')
        expect(result.canonical_url).to eq('https://example.org/')
      end
    end

    [Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET, EOFError, Timeout::Error].each do |e|
      context "with a generic URL when #{e} occurs when attempting https for the URL" do
        before do
          stub_request(:head, 'https://example.org/').to_raise(e)

          stub_request(:head, 'http://example.org/').to_return(status: 204)
          stub_request(:get, 'http://example.org/')
            .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
        end

        it 'uses http for the URL' do
          result = url.canonicalize('example.org')
          expect(result.canonical_url).to eq('http://example.org/')
        end
      end

      context "with a generic URL when #{e} occurs when attempting both https and http for the URL" do
        before do
          stub_request(:head, 'https://example.org/').to_raise(e)
          stub_request(:head, 'http://example.org/').to_raise(e)
        end

        it 'raises a discovery error' do
          expect { url.canonicalize('example.org') }.to(
            raise_error(
              an_instance_of(IndieAuthDiscovery::InvalidURLError)
                .and(having_attributes(error: :invalid_url))
            )
          )
        end
      end
    end

    # https://indieauth.spec.indieweb.org/#http-to-https
    context 'when the URL redirects permanently from http to https' do
      before do
        stub_request(:head, 'http://example.com/')
          .to_return(status: 301, headers: { 'Location' => 'https://example.com/' })
        stub_request(:head, 'https://example.com/').to_return(status: 204)
        stub_request(:get, 'https://example.com/')
          .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
      end

      it 'uses the https URL' do
        result = url.canonicalize('example.com')
        expect(result.canonical_url).to eq('https://example.com/')
      end
    end

    # https://indieauth.spec.indieweb.org/#temporary-redirect
    context 'when the URL redirects permanently from www to no-www' do
      before do
        stub_request(:head, 'http://www.example.com/')
          .to_return(status: 301, headers: { 'Location' => 'https://example.com/' })
        stub_request(:head, 'https://www.example.com/').to_raise(Errno::ECONNREFUSED)
        stub_request(:head, 'https://example.com/').to_return(status: 204)
        stub_request(:get, 'https://example.com/')
          .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
      end

      it 'uses the https URL' do
        result = url.canonicalize('www.example.com')
        expect(result.canonical_url).to eq('https://example.com/')
      end
    end

    # https://indieauth.spec.indieweb.org/#temporary-redirect
    context 'when the URL redirects temporarily' do
      before do
        stub_request(:head, 'http://example.com/')
          .to_return(status: 301, headers: { 'Location' => 'https://example.com/' })
        stub_request(:head, 'https://example.com/')
          .to_return(status: 302, headers: { 'Location' => 'https://example.com/username' })
        stub_request(:head, 'https://example.com/username').to_return(status: 204)
        stub_request(:get, 'https://example.com/')
          .to_return(status: 302, headers: { 'Location' => 'https://example.com/username' })
        stub_request(:get, 'https://example.com/username')
          .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
      end

      it 'uses the last permanent redirect URL' do
        result = url.canonicalize('example.com')
        expect(result.canonical_url).to eq('https://example.com/')
      end
    end

    # https://indieauth.spec.indieweb.org/#permanent-redirect-to-a-different-domain
    context 'when the URL redirects permanently to a different domain' do
      before do
        stub_request(:head, 'http://username.example/')
          .to_return(status: 301, headers: { 'Location' => 'https://example.com/username' })
        stub_request(:head, 'https://username.example/').to_raise(Errno::ECONNREFUSED)
        stub_request(:head, 'https://example.com/username').to_return(status: 204)
        stub_request(:get, 'https://example.com/username')
          .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
      end

      it 'uses the permanent redirect URL' do
        result = url.canonicalize('username.example')
        expect(result.canonical_url).to eq('https://example.com/username')
      end
    end

    # https://indieauth.spec.indieweb.org/#temporary-redirect-to-a-different-domain
    context 'when the URL redirects temporarily to a different domain' do
      before do
        stub_request(:head, 'http://username.example/')
          .to_return(status: 302, headers: { 'Location' => 'https://example.com/username' })
        stub_request(:head, 'https://username.example/').to_raise(Errno::ECONNREFUSED)
        stub_request(:head, 'https://example.com/username').to_return(status: 204)
        stub_request(:get, 'http://username.example/')
          .to_return(status: 302, headers: { 'Location' => 'https://example.com/username' })
        stub_request(:get, 'https://example.com/username')
          .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
      end

      it 'uses the last permanent redirect URL' do
        result = url.canonicalize('username.example')
        expect(result.canonical_url).to eq('http://username.example/')
      end
    end

    # https://indieauth.spec.indieweb.org/#temporary-redirect-to-a-different-domain
    context 'when the URL redirects temporarily and then permanently to a different domain' do
      before do
        stub_request(:head, 'http://username.example/')
          .to_return(status: 301, headers: { 'Location' => 'https://example.com/username' })
        stub_request(:head, 'https://username.example/')
          .to_raise(Errno::ECONNREFUSED)
        stub_request(:head, 'https://example.com/username')
          .to_return(status: 302, headers: { 'Location' => 'https://example.com/~username' })
        stub_request(:head, 'https://example.com/~username')
          .and_return(status: 301, headers: { 'Location' => 'https://example.com/~username/' })
        stub_request(:head, 'https://example.com/~username/')
          .and_return(status: 204)

        stub_request(:get, 'http://username.example/')
          .to_return(status: 301, headers: { 'Location' => 'https://example.com/username' })
        stub_request(:get, 'https://example.com/username')
          .to_return(status: 302, headers: { 'Location' => 'https://example.com/~username' })
        stub_request(:get, 'https://example.com/~username')
          .to_return(status: 301, headers: { 'Location' => 'https://example.com/~username/' })
        stub_request(:get, 'https://example.com/~username/')
          .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
      end

      it 'uses the last permanent redirect URL before a temporary redirect' do
        result = url.canonicalize('username.example')
        expect(result.canonical_url).to eq('https://example.com/username')
      end
    end

    context 'with a non-HTTP(S) URL' do
      before do
        stub_request(:head, 'http://ftp//example.org/me/').to_raise(Faraday::ConnectionFailed)
        stub_request(:head, 'https://ftp//example.org/me/').to_raise(Faraday::ConnectionFailed)
      end

      it 'raises a discovery error' do
        expect { url.canonicalize('ftp://example.org/me/') }.to(
          raise_error(
            an_instance_of(IndieAuthDiscovery::InvalidURLError)
              .and(having_attributes(error: :invalid_url))
          )
        )
      end
    end

    context 'with an invalid URL' do
      it 'raises a discovery error' do
        expect { url.canonicalize('#%#^@!#%#$#@') }.to(
          raise_error(
            an_instance_of(IndieAuthDiscovery::InvalidURLError)
              .and(having_attributes(error: :invalid_url))
          )
        )
      end
    end
  end

  describe 'conversions' do
    subject(:url) { described_class.new('https://example.org/me') }

    before do
      stub_request(:head, 'https://example.org/me').to_return(status: 204)
      stub_request(:get, 'https://example.org/me')
        .to_return(status: 200, body: profile_body, headers: { 'Content-Type': 'text/html' })
      url.canonicalize
    end

    describe '#to_s' do
      it 'returns the canonical URL as a string' do
        expect(url.to_s).to eq('https://example.org/me')
      end
    end

    describe '#to_uri' do
      it 'returns the canonical URL as a URI' do
        expect(url.to_uri).to eq(URI.parse('https://example.org/me'))
      end
    end
  end
end
