# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'obligation/version'

Gem::Specification.new do |spec|
  spec.name          = 'obligation'
  spec.version       = Obligation::VERSION
  spec.authors       = ['Jan Graichen']
  spec.email         = ['jg@altimos.de']
  spec.summary       = %q{Support library to provide Futures and Promises for different concurrency models.}
  spec.description   = %q{Support library to provide Futures and Promises for different concurrency models.}
  spec.homepage      = 'https://github.com/jgraichen/obligation'
  spec.license       = 'LGPLv3'

  spec.files         = Dir['**/*'].grep(%r{^((bin|lib|test|spec|features)/|.*\.gemspec|.*LICENSE.*|.*README.*|.*CHANGELOG.*)})
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'concurrent-ruby', '~> 0.5.0'

  spec.add_development_dependency 'bundler', '~> 1.5'
end
