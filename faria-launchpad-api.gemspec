# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'faria/launchpad/api/version'

Gem::Specification.new do |spec|
  spec.name          = "faria-launchpad-api"
  spec.version       = Faria::Launchpad::Api::VERSION
  spec.authors       = ["Josh Goebel"]
  spec.email         = ["me@joshgoebel.com"]

  spec.summary       = %q{Ruby library to interface with Faria LaunchPad.}
  spec.description   = %q{Ruby library to interface with Faria LaunchPad, including an API client and Rails helpers.}
  spec.homepage      = "https://github.com/eduvo/launchpad_api"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # additional files to not package in the gem
  %w(.gitignore .travis.yml).each do |file|
    spec.files.reject! {|f| f == file}
  end
  # puts spec.files
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  # need 1.5.4 since they have been changing the component API a lot in minor
  # point releases
  spec.add_dependency "jwt", "~> 1.5.4"
  spec.add_dependency "jwe", "~> 0.1.0"
  spec.add_dependency "addressable", "~> 2.4"
end
