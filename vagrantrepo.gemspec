
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrantrepo/version'

Gem::Specification.new do |spec|
  spec.name          = 'vagrantrepo'
  spec.version       = Vagrantrepo::VERSION
  spec.authors       = ['Jan Vansteenkiste']
  spec.email         = ['jan@vstone.eu']

  spec.summary       = 'Generate metadata files for vagrant boxes.'
  spec.description   = 'Create meatadata files for all folders with boxes.'
  spec.homepage      = 'https://github.com/vStone/vagrantrepo'
  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'slop', '~> 4.6.2'

  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.52.0'
end
