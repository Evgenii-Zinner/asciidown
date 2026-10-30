# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/asciidown"

RSpec.describe Asciidown do
  describe "section titles" do
    it "converts nested section headings from level 1 to level 5" do
      input = <<~ADOC
        = Title

        == Major Section

        === Subsection

        ==== Sub-subsection

        ===== Deep Section

        ====== Deepest Section

        ======= Normal Paragraph
      ADOC

      result = described_class.call(input, front_matter: false)

      expected = <<~MD
        # Title

        ## Major Section

        ### Subsection

        #### Sub-subsection

        ##### Deep Section

        ###### Deepest Section

        ======= Normal Paragraph
      MD

      expect(result.strip).to eq(expected.strip)
    end

    it "processes document that starts with section title" do
      input = <<~ADOC
        == First Steps

        Getting started content.
      ADOC

      expected = <<~MD
        ## First Steps

        Getting started content.
      MD

      expect(described_class.call(input).strip).to eq(expected.strip)
    end

    it "converts line with heading marker only as paragraph text" do
      input = "=="
      expect(described_class.call(input).strip).to eq(input)
    end

    it "trims multiple spaces following heading marker" do
      input = "==    Heading with Leading Spaces"
      expected = "## Heading with Leading Spaces"

      expect(described_class.call(input).strip).to eq(expected)
    end

    it "clears block attributes after processing section title" do
      input = <<~ADOC
        [,java]
        == Section Title

        ----
        plain listing block
        ----
      ADOC

      expected = <<~MD
        ## Section Title

        ```
        plain listing block
        ```
      MD

      expect(described_class.call(input).strip).to eq(expected.strip)
    end

    it "applies inline substitutions and attribute references to section titles" do
      input = <<~ADOC
        :framework: Ruby on Rails
        :homepage: https://rubyonrails.org

        == *Building* apps with {framework} on {homepage}[official site]

        Intro body text.
      ADOC

      result = described_class.call(input)

      expect(result).to include("## **Building** apps with Ruby on Rails on [official site](https://rubyonrails.org)")
      expect(result).to include("Intro body text.")
    end
  end
end
