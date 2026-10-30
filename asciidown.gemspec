# frozen_string_literal: true

require_relative "lib/asciidown/version"

Gem::Specification.new do |spec|
  spec.name = "asciidown"
  spec.version = Asciidown::VERSION
  spec.authors = ["Evgenii Zinner"]
  spec.email = ["evgenii.zinner@gmail.com"]

  spec.summary = "Fast, pure Ruby converter from AsciiDoc to GitHub Flavored Markdown"
  spec.description = <<~DESC.strip.gsub("\n", " ")
    A lightweight, dependency-free Ruby service and CLI tool to translate
    AsciiDoc content into GitHub Flavored Markdown with support for YAML front
    matter, pipe tables, callouts, and Liquid tags.
  DESC
  spec.homepage = "https://github.com/Evgenii-Zinner/asciidown"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "bin/*", "README.md", "LICENSE.txt"]
  spec.bindir = "bin"
  spec.executables = %w[asciidown asciidoc2md]
  spec.require_paths = ["lib"]
end
