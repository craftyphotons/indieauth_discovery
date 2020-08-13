# `indieauth_discovery`

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/craftyphotons/indieauth_discovery/Verify/main?style=for-the-badge)](https://github.com/craftyphotons/indieauth_discovery/actions?query=workflow%3AVerify)
&nbsp;
[![Code Climate maintainability](https://img.shields.io/codeclimate/maintainability/craftyphotons/indieauth_discovery?style=for-the-badge)](https://codeclimate.com/github/craftyphotons/indieauth_discovery)
&nbsp;
[![Coveralls github branch](https://img.shields.io/coveralls/github/craftyphotons/indieauth_discovery/main?style=for-the-badge)](https://coveralls.io/github/craftyphotons/indieauth_discovery)
&nbsp;
[![Gem](https://img.shields.io/gem/v/indieauth_discovery?style=for-the-badge)](https://rubygems.org/gems/indieauth_discovery)

Profile and client discovery for [Ruby](https://www.ruby-lang.org/en)-based [IndieAuth](https://indieauth.spec.indieweb.org) clients and providers.

## Features

- [x] [User profile URL](https://indieauth.spec.indieweb.org/#user-profile-url) and [client identifier](https://indieauth.spec.indieweb.org/#client-identifier) validation and [canonicalization](https://indieauth.spec.indieweb.org/#url-canonicalization) with 
- [x] Handling of [permanant and temporary redirects](https://indieauth.spec.indieweb.org/#redirect-examples)
- [x] [Authorization, token, and MicroPub endpoint discovery](https://indieauth.spec.indieweb.org/#discovery-by-clients) from user profiles

## Roadmap

- [ ] [Client information discovery](https://indieauth.spec.indieweb.org/#client-information-discovery) from [`h-app` and `h-xapp`](https://indieweb.org/h-x-app)
- [ ] [Redirect URI verification](https://indieauth.spec.indieweb.org/#redirect-url)

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'indieauth_discovery'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install indieauth_discovery

## Usage

### URL verification and canonicalization

`indieauth_discovery` can canonicalize and verify URLs indepedently of information discovery via the `IndieAuthDiscovery::URL` class:

``` ruby
require 'indieauth_discovery/url'

url = IndieAuthDiscovery::URL.new('example.com')
url.canonicalize

# or

url = IndieAuthDiscovery::URL.canonicalize('example.com')

url.original_url # example.com
url.canonical_url # http://example.com/
```

The `#canonicalize` method performs the following steps:

1. Normalizes the URL (downcases the hostname)
2. Verifies the URL if already `http` or `https` by performing an HTTP `HEAD` request
3. If the URL is generic without a scheme (i.e. `example.com`), attempts to verify the URL with an HTTP `HEAD` request to both `https://<url>` and `http://<url>`, prioritizing HTTPS
4. Ensures the URL has a path by appending `/` to it if the path component is empty
5. Follows up to three redirects, and uses the last permanent (301) redirect as the canonical URL

If none of the steps above result in a verified URL, an `IndieAuthDiscovery::InvalidURLError` will be raised.

### User profile discovery

User profile information can be discovered with `indieauth_discovery` via the `IndieAuthDiscovery::Profile` class:

``` ruby
require 'indieauth_discovery/profile'

profile = IndieAuthDiscovery::Profile.new('example.com')
profile.discover

# or

profile = IndieAuthDiscovery::Profile.discover('example.com')

profile.url # http://example.com/
profile.authorization_endpoint # http://example.com/auth
profile.token_endpoint # http://example.com/token
profile.micropub_endpoint # http://example.com/micropub
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [craftyphotons/indieauth_discovery](https://github.com/craftyphotons/indieauth_discovery). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/craftyphotons/indieauth_discovery/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the IndieauthDiscovery project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/indieauth_discovery/blob/master/CODE_OF_CONDUCT.md).
