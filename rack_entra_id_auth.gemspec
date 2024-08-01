require_relative 'lib/rack_entra_id_auth/version'

Gem::Specification.new do |s|
  s.name    = 'rack_entra_id_auth'
  s.version = RackEntraIdAuth::VERSION
  s.authors = ['David Susco']
  s.email   = ['dsusco@gmail.com']

  s.summary     = 'Rails aware Rack middleware for Entra ID authentication.'
  s.description = s.summary
  s.homepage    = 'https://github.com/dsusco/rack_entra_id_auth'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.0.0'

  s.metadata = {
    'bug_tracker_uri'   => "#{s.homepage}/issues",
    'changelog_uri'     => "#{s.homepage}/releases/tag/v#{s.version}",
    'homepage_uri'      => s.homepage,
    'source_code_uri'   => s.homepage
  }

  s.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  s.add_dependency 'activesupport', '~> 7.0'
  s.add_dependency 'rack', '~> 2.2'
  s.add_dependency 'ruby-saml', '~> 1.10'

  s.add_development_dependency 'minitest', '~> 5.16'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rubocop', '~> 1.21'
end
