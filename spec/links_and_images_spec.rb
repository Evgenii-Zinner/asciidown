# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/asciidown"

RSpec.describe Asciidown do
  describe "links, images, and cross references" do
    it "converts internal cross references with and without custom labels" do
      input = "See <<_prerequisites,Prereqs>> or visit <<_installation>>."
      expected = "See [Prereqs](#prerequisites) or visit [installation](#installation)."

      expect(described_class.call(input).strip).to eq(expected)
    end

    it "converts external links with and without labels" do
      input = "Visit https://forem.com[] or https://forem.com[Forem]."
      expected = "Visit [https://forem.com](https://forem.com) or [Forem](https://forem.com)."

      expect(described_class.call(input).strip).to eq(expected)
    end

    it "converts link macro with relative path and label" do
      input = "Read link:/docs/getting-started[Getting Started Guide]."
      expected = "Read [Getting Started Guide](/docs/getting-started)."

      expect(described_class.call(input).strip).to eq(expected)
    end

    it "converts block images and inline images" do
      input = <<~ADOC
        image::https://dev.to/logo.png[DEV Logo]

        Inline badge: image:https://img.shields.io/badge[Status]
      ADOC

      result = described_class.call(input)

      expect(result).to include("![DEV Logo](https://dev.to/logo.png)")
      expect(result).to include("![Status](https://img.shields.io/badge)")
    end

    it "converts inline anchor [[id]] to html anchor tag" do
      input = "[[section-anchor]] This is an anchored line."
      result = described_class.call(input)

      expect(result).to include("<a name=\"section-anchor\"></a>")
    end

    it "converts thematic breaks" do
      ["'''", "***", "---"].each do |brk|
        expect(described_class.call("Before\n\n#{brk}\n\nAfter")).to include("---")
      end
    end
  end
end
