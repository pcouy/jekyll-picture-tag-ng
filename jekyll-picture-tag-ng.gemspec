# frozen_string_literal: true

require_relative "lib/jekyll-picture-tag-ng/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-picture-tag-ng"
  spec.version = Jekyll::PictureTag::VERSION
  spec.authors = ["pcouy"]
  spec.email = ["contact@pierre-couy.dev"]

  spec.summary = "Replace the default Kramdown rendering of pictures to use auto-generated alternatives"
  spec.description = "This plugin will auto-generate alternative versions of your jpg and webp files. For each specified
  version, a jpeg and a webp version will be generated. When including images in markdown documents, the HTML `picture`
  tag will be used to display the appropriate version using media queries."
  spec.homepage = "https://github.com/pcouy/jekyll-picture-tag-ng"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "jekyll"
  spec.add_dependency "kramdown"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
