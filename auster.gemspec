# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cfer/auster/version"

Gem::Specification.new do |spec|
  spec.name          = "auster"
  spec.version       = Cfer::Auster::VERSION
  spec.authors       = ["Ed Ropple"]
  spec.email         = ["ed+auster@edropple.com"]

  spec.summary       = "Best-practices tooling and structure around Cfer."
  spec.homepage      = "https://github.com/eropple/auster"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = ["auster"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"

  spec.add_runtime_dependency "cri", "~> 2.8.0"
  spec.add_runtime_dependency "search_up", "~> 1.0.2"
  spec.add_runtime_dependency "activesupport", "~> 5.0.2"
  spec.add_runtime_dependency "ice_nine", "~> 0.11.2"
  spec.add_runtime_dependency "kwalify", "~> 0.7.2"
  spec.add_runtime_dependency "cfer", "~> 0.5.0"
  spec.add_runtime_dependency "semantic", "~> 1.6.0"
  spec.add_runtime_dependency "aws-sdk", "~> 2.9.11"
end
