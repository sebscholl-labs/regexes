# frozen_string_literal: true

require_relative 'lib/regexes/version'

Gem::Specification.new do |spec|
  spec.name    = 'regexes'
  spec.version = Regexes::VERSION
  spec.authors = ['Sebastian Scholl']
  spec.email   = ['sebscholl@gmail.com']

  spec.summary     = 'Named, tested regular expressions for Ruby: frozen Regexps for UUIDs, IP addresses, times ' \
                     'and more, with chainable anchors, repetition and captures.'
  spec.description = <<~TEXT
    Regexes is a library of frozen Regexp objects named for what they match (letters, digits, UUIDs,
    ISO 8601 times, domain names, email addresses), each chaining the variations every expression allows:
    anchored, repeated, case-insensitive, and for sets of characters, excluded and extended. No dependencies.
  TEXT
  spec.homepage    = 'https://github.com/sebscholl-labs/regexes'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 4.0'

  spec.metadata = {
    'bug_tracker_uri'       => 'https://github.com/sebscholl-labs/regexes/issues',
    'changelog_uri'         => 'https://github.com/sebscholl-labs/regexes/blob/main/gem/CHANGELOG.md',
    'documentation_uri'     => 'https://sebscholl-labs.github.io/regexes/',
    'source_code_uri'       => 'https://github.com/sebscholl-labs/regexes/tree/main/gem',
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['lib/**/*.rb'] + %w[CHANGELOG.md LICENSE.txt README.md]
  end

  spec.require_paths = ['lib']

  # No runtime dependencies.
end
