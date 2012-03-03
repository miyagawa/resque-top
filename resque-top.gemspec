# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "resque-top/version"

Gem::Specification.new do |s|
  s.name        = "resque-top"
  s.version     = Resque::Top::VERSION
  s.authors     = ["Tatsuhiko Miyagawa"]
  s.email       = ["miyagawa@bulknews.net"]
  s.homepage    = "https://github.com/miyagawa/resque-top"
  s.summary     = s.description
  s.description = %q{top for Resque}

  s.rubyforge_project = "resque-top"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  #   s.add_development_dependency "rspec"
  s.add_runtime_dependency "resque"
  s.add_runtime_dependency "slop", "~> 2.0"
end
