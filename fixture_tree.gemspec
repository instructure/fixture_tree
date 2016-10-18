Gem::Specification.new do |s|
  s.name = 'fixture_tree'
  s.version = '1.0.0'
  s.summary = "Helper for creating directory hierarchies to use with tests"
  s.homepage = 'https://github.com/instructure/fixture_tree'
  s.author = 'Alex Boyd'
  s.email = 'aboyd@instructure.com'
  s.files = Dir.glob("{lib,spec}/**/*") # should probably write specs
end