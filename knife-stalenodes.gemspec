$:.unshift(File.dirname(__FILE__) + '/lib')
require 'knife-stalenodes/version'

Gem::Specification.new do |s|
  s.name        = 'knife-stalenodes'
  s.version     = KnifeStalenodes::VERSION
  s.date        = '2013-12-22'
  s.summary     = 'Knife plugin for listing nodes that have not checked in'
  s.description = s.summary
  s.authors     = ["Paul Mooring"]
  s.email       = ['paul@getchef.com']
  s.homepage    = "https://github.com/paulmooring/knife-stalenodes"

  s.add_dependency "chef"
  s.require_paths = ["lib"]
  s.files = %w(LICENSE README.rdoc) + Dir.glob("lib/**/*")
end
