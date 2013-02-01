Gem::Specification.new do |s|
  s.name        = 'knife-stalenodes'
  s.version     = '0.0.1'
  s.date        = '2013-01-31'
  s.summary     = 'Knife plugin for listing nodes that have not checked in'
  s.description = s.summary
  s.authors     = ["Paul Mooring"]
  s.email       = ['paul@opscode.com']
  s.homepage    = "https://github.com/paulmooring/knife-stalenodes"
  s.files       = ['lib/chef/knife/stalenodes.rb']

  s.add_dependency "chef"
  s.require_paths = ["lib"]
end
