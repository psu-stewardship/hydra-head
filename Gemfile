source "https://rubygems.org"

# Specify gem dependencies in hydra-head.gemspec
gemspec

gem 'active-fedora', github: 'no-reply/active_fedora', branch: 'af7-rdf'

path = File.expand_path('../hydra-core/spec/test_app_templates/Gemfile.extra', __FILE__)
if File.exists?(path)
  eval File.read(path), nil, path
end
