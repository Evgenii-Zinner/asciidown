# asciidown

A fast, lightweight, pure Ruby converter from AsciiDoc to GitHub Flavored Markdown (GFM). Zero external dependencies.

[![CI](https://github.com/Evgenii-Zinner/asciidown/actions/workflows/ci.yml/badge.svg)](https://github.com/Evgenii-Zinner/asciidown/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/Evgenii-Zinner/asciidown/branch/main/graph/badge.svg)](https://codecov.io/gh/Evgenii-Zinner/asciidown)
[![Gem Version](https://img.shields.io/gem/v/asciidown.svg)](https://rubygems.org/gems/asciidown)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- **Pure Ruby:** 100% dependency-free, runs in-memory with zero native or Node.js runtime requirements.
- **YAML Front Matter:** Automatically extracts document title and headers (`:author:`, `:tags:`, `:published: true`) into YAML Front Matter or ATX headings.
- **Liquid Tag Preservation:** Preserves `{% embed %}`, `{% youtube %}`, and `{{ var }}` without mangling (great for static site generators and blogging platforms).
- **Syntax Highlighting & Callouts:** Converts `[source,ruby]` listings with dynamic backtick fences (safely handles nested backticks) and translates callout numbers (`<1>`, `<2>`) into unicode circled numbers (`①`, `②`).
- **Tables:** Full AsciiDoc pipe table (`|===`) conversion to GFM pipe tables with column alignment (`cols="<,^,>"`), empty cell preservation, and escaped pipe support.
- **Blockquotes & Admonitions:** Formats single-line (`NOTE:`) and block admonitions (`[WARNING]` + `====`), as well as blockquotes (`____`) with optional author attributions (`— Author`).
- **Lists & Inlines:** Multi-level bulleted (`*`, `**`) and numbered (`.`, `..`) lists, headings (`==` to `======`), bold, italic, bold-italic, strikethrough, highlights (`<mark>`), cross-references (`<<anchor,Label>>`), images, and links.
- **CLI Executable:** Includes `asciidown` (and `asciidoc2md` alias) for command-line conversion and shell pipelines.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem "asciidown"
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install asciidown
```

## Usage

### Ruby API

```ruby
require "asciidown"

asciidoc = <<~ADOC
  = Scaling Rails Applications
  :author: Jane Developer
  :tags: ruby, rails

  == Introduction
  Check out our guide at https://example.com[Documentation].

  [source,ruby]
  ----
  def hello
    puts "world" <1>
  end
  ----
ADOC

# Convert with YAML front matter
markdown = Asciidown.call(asciidoc)
puts markdown

# Convert with ATX H1 heading instead of front matter
markdown_plain = Asciidown.call(asciidoc, front_matter: false)
```

### Command Line Interface

```bash
# Convert a file to standard output
$ asciidown article.adoc

# Convert a file and save to output
$ asciidown article.adoc -o article.md

# Pipe through STDIN
$ cat article.adoc | asciidown > article.md

# Disable YAML front matter (produce standard ATX H1 heading)
$ asciidown --no-front-matter article.adoc
```

## Architecture

The gem is built around clean, modular subcomponents:
- `Asciidown::Converter`: Core parser state machine processing AsciiDoc line streams into GFM blocks.
- `Asciidown::Substitutors`: Inline text substitutions for quotes, attributes, macros, and callout numbers.
- `Asciidown::BlockHelpers`: Helper logic for heading detection, list markers, and block titles.
- `Asciidown::DocumentState`: Manages document attributes, section cross-references, and delimiter nesting.
- `Asciidown::CLI`: Standard command-line interface with option parsing and stream routing.

## Development

After checking out the repo, run `bundle install` to install dependencies. Then run the test suite and linter:

```bash
$ bundle exec rake
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Evgenii-Zinner/asciidown.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
