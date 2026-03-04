# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omniauth-line-login/version"

Gem::Specification.new do |s|
  s.name        = "omniauth-line-login"
  s.version     = OmniAuth::Line::VERSION
  s.authors     = ["kazasiki", "buferago"]
  s.email       = ["kazasiki@gmail.com"]
  s.homepage    = "https://github.com/buferago/omniauth-line"
  s.description = %q{OmniAuth strategy for LINE Login with OpenID Connect email support}
  s.summary     = %q{OmniAuth strategy for LINE Login - fork with ID token email extraction}
  s.license     = "MIT"

  s.files         = Dir['lib/**/*', 'LICENSE', 'README.md', '*.gemspec']
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 2.7"

  s.add_dependency 'json', '>= 2.3.0'
  s.add_dependency 'omniauth-oauth2', '~> 1.8'
  s.add_development_dependency 'bundler', '~> 2.0'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'webmock'
end
