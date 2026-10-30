# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/asciidown"

RSpec.describe Asciidown do
  describe ".call" do
    it "aliases .perform to .call" do
      expect(described_class.perform("= Title\n\nBody")).to eq(described_class.call("= Title\n\nBody"))
    end

    context "with empty or blank inputs" do
      it "returns an empty string when given empty text" do
        expect(described_class.call("")).to eq("")
      end

      it "returns an empty string when given nil or whitespace" do
        expect(described_class.call(nil)).to eq("")
        expect(described_class.call("   \n\n  ")).to eq("")
      end
    end

    context "with Liquid tags" do
      it "preserves embed and social liquid tags intact without alteration" do
        input = <<~ADOC
          Check out this video:

          {% youtube dQw4w9WgXcQ %}

          And article link:
          {% embed https://dev.to/ben/announcing-something %}
        ADOC

        result = described_class.call(input)

        expect(result).to include("{% youtube dQw4w9WgXcQ %}")
        expect(result).to include("{% embed https://dev.to/ben/announcing-something %}")
      end

      it "preserves liquid variables {{ some_var }} without escaping" do
        input = "Value is {{ site.title }} in production."
        expect(described_class.call(input).strip).to eq(input)
      end

      it "restores Liquid tags in document metadata front matter" do
        input = <<~ADOC
          = Guide to {% tag_name %} and {{ var }}
          :description: Info about {{ site.title }}
          :published: true

          Body text.
        ADOC

        result = described_class.call(input, front_matter: true)

        expect(result).to include("title: Guide to {% tag_name %} and {{ var }}")
        expect(result).to include("description: Info about {{ site.title }}")
      end
    end

    context "with Document Header and Front Matter" do
      it "extracts document title and attributes into YAML Front Matter" do
        input = <<~ADOC
          = Building Reliable Services
          :author: Jane Developer
          :tags: ruby, rails, webdev
          :published: true

          Intro paragraph goes here.
        ADOC

        result = described_class.call(input, front_matter: true)

        expect(result).to start_with("---\n")
        expect(result).to include("title: Building Reliable Services")
        expect(result).to include("author: Jane Developer")
        expect(result).to include("tags: ruby, rails, webdev")
        expect(result).to include("published: 'true'")
        expect(result).to include("Intro paragraph goes here.")
      end

      it "renders an ATX H1 heading if front matter is disabled" do
        input = <<~ADOC
          = Pure Markdown Title

          Paragraph content.
        ADOC

        result = described_class.call(input, front_matter: false)

        expect(result).not_to include("---")
        expect(result).to start_with("# Pure Markdown Title")
      end
    end
  end
end
