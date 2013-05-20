# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pubkey_audit/version'

Gem::Specification.new do |spec|
  spec.name          = "pubkey_audit"
  spec.version       = PubkeyAudit::VERSION
  spec.authors       = ["Daniel Leavitt"]
  spec.email         = ["daniel.leavitt@gmail.com"]
  spec.description   = %q{Maps public keys on your servers against a Google Docs-based identity file to determine who has access to your servers.}
  spec.summary       = %q{Determine whose public keys are on your servers.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency 'net-ssh'
  spec.add_dependency 'google_doc_seed'
  spec.add_dependency 'toml'
  spec.add_dependency 'pry'
  spec.add_dependency 'thor'
  spec.add_dependency 'parallel'
  spec.add_dependency 'ruby-progressbar'
  spec.add_dependency 'faraday'
end
