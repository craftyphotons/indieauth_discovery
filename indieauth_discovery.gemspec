# frozen_string_literal: true

require_relative 'lib/indieauth_discovery/version'

Gem::Specification.new do |spec|
  spec.name          = 'indieauth_discovery'
  spec.version       = IndieAuthDiscovery::VERSION
  spec.authors       = ['Tony Burns']
  spec.email         = ['tony@tonyburns.net']

  spec.summary       = 'IndieAuth profile and client discovery'
  spec.description   = 'Profile and client discovery for IndieAuth clients and providers'
  spec.homepage      = 'https://github.com/craftyphotons/indieauth_discovery'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/craftyphotons/indieauth_discovery'
  spec.metadata['changelog_uri'] = 'https://github.com/craftyphotons/indieauth_discovery/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'faraday', '~> 0.9'
  spec.add_runtime_dependency 'faraday_middleware', '~> 0.14'
  spec.add_runtime_dependency 'link-header-parser', '~> 2.0'
  spec.add_runtime_dependency 'nokogiri', '~> 1.10'
end
