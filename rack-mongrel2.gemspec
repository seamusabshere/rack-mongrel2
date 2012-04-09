# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack/mongrel2/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Daniel Huckstep', "Seamus Abshere"]
  gem.email         = ['darkhelmet@darkhelmetlive.com', "seamus@abshere.net"]
  gem.summary     = %Q{The only Mongrel2 Rack handler you'll ever need.}
  gem.description = %Q{A Rack handler for the Mongrel2 web server, by Zed Shaw. http://mongrel2.org/}
  gem.homepage      = "https://github.com/seamusabshere/rack-mongrel2"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "rack-mongrel2"
  gem.require_paths = ["lib"]
  gem.version       = Rack::Mongrel2::VERSION

  gem.add_runtime_dependency 'zmq2'
  gem.add_runtime_dependency 'multi_json'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'rake'
end
