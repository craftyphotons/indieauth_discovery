# `indieauth_discovery`

Profile and client discovery for [Ruby](https://www.ruby-lang.org/en)-based [IndieAuth](https://indieauth.spec.indieweb.org) clients and providers.

## Features

* [User profile URL](https://indieauth.spec.indieweb.org/#user-profile-url) and [client identifier](https://indieauth.spec.indieweb.org/#client-identifier) validation and [canonicalization](https://indieauth.spec.indieweb.org/#url-canonicalization)
* Handling of [permanant and temporary redirects](https://indieauth.spec.indieweb.org/#redirect-examples)
* [Authorization, token, and MicroPub endpoint discovery](https://indieauth.spec.indieweb.org/#discovery-by-clients)
* [Client information discovery](https://indieauth.spec.indieweb.org/#client-information-discovery) from [`h-app` and `h-xapp`](https://indieweb.org/h-x-app)
* [Redirect URI verification](https://indieauth.spec.indieweb.org/#redirect-url)

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

_TODO: Write usage instructions here_

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [craftyphotons/indieauth_discovery](https://github.com/craftyphotons/indieauth_discovery). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/craftyphotons/indieauth_discovery/blob/main/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the IndieauthDiscovery project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/indieauth_discovery/blob/master/CODE_OF_CONDUCT.md).
