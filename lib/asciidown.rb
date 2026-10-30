# frozen_string_literal: true

require "yaml"
require_relative "asciidown/version"
require_relative "asciidown/constants"
require_relative "asciidown/document_state"
require_relative "asciidown/substitutors"
require_relative "asciidown/block_helpers"
require_relative "asciidown/converter"
require_relative "asciidown/cli"

# Translates AsciiDoc text to GitHub Flavored Markdown.
class Asciidown
  def self.call(asciidoc, **)
    new(asciidoc, **).call
  end

  def self.perform(asciidoc, **)
    call(asciidoc, **)
  end

  def initialize(asciidoc, attributes: {}, front_matter: true)
    @raw = asciidoc.to_s
    @initial_attrs = attributes
    @front_matter = front_matter
  end

  def call
    return "" if @raw.strip.empty?

    # 1. Protect Liquid tags
    protected_text, liquid_tags = protect_liquid_tags(@raw)

    state = DocumentState.new(@initial_attrs)
    result = Converter.convert(protected_text, state)

    # 2. Restore Liquid tags
    final_body = restore_liquid_tags(result, liquid_tags)

    # 3. Format Front Matter if requested
    if @front_matter && (state.key?("doctitle") || state.key?("tags") || state.key?("description"))
      fm_hash = {}
      fm_hash["title"] = state["doctitle"] if state.key?("doctitle")
      state.attrs.each do |k, v|
        next if %w[empty idprefix idseparator markdown-line-break markdown-strikethrough nbsp quotes sp vbar zwsp
                   doctitle].include?(k)

        fm_hash[k] = v
      end
      front_matter_str = restore_liquid_tags(YAML.dump(fm_hash).strip, liquid_tags)
      body_without_title = final_body.sub(/^#\s+[^\n]+\n+/, "")
      "#{front_matter_str}\n---\n\n#{body_without_title.strip}\n"
    else
      "#{final_body.strip}\n"
    end
  end

  private

  def protect_liquid_tags(text)
    tags = []
    protected_content = text.gsub(/(?:\{%.*?%\}|\{\{.*?\}\})/m) do |match|
      placeholder = "<!--LIQUID_TAG_PLACEHOLDER_#{tags.size}-->"
      tags << match
      placeholder
    end
    [protected_content, tags]
  end

  def restore_liquid_tags(text, tags)
    tags.each_with_index.reduce(text) do |content, (tag, index)|
      content.gsub("<!--LIQUID_TAG_PLACEHOLDER_#{index}-->", tag)
    end
  end
end

AsciidocToMarkdown = Asciidown
