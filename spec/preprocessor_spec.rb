# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/asciidown"

RSpec.describe Asciidown do
  describe "preprocessors and comments" do
    it "skips line comments and block comments in the document body" do
      input = <<~ADOC
        First paragraph.

        // This is a private single-line comment

        ////
        This is a private
        multi-line comment block
        ////

        Second paragraph.
      ADOC

      result = described_class.call(input)

      expect(result).to include("First paragraph.")
      expect(result).to include("Second paragraph.")
      expect(result).not_to include("private")
    end

    it "preserves comment slashes inside code blocks as literal code" do
      input = <<~ADOC
        [source,javascript]
        ----
        // Line comment in JS code
        console.log("hello");
        ----
      ADOC

      result = described_class.call(input)
      expect(result).to include("// Line comment in JS code")
    end

    it "includes content when attribute is defined (ifdef)" do
      input = <<~ADOC
        :feature_enabled: true

        ifdef::feature_enabled[]
        Feature is active.
        endif::[]
      ADOC

      result = described_class.call(input)
      expect(result).to include("Feature is active.")
    end

    it "omits content when attribute is not defined (ifdef)" do
      input = <<~ADOC
        ifdef::unknown_feature[]
        Should not appear.
        endif::[]

        Visible text.
      ADOC

      result = described_class.call(input)
      expect(result).not_to include("Should not appear.")
      expect(result).to include("Visible text.")
    end

    it "handles ifndef (if not defined)" do
      input = <<~ADOC
        ifndef::missing_var[]
        Default fallback text.
        endif::[]
      ADOC

      result = described_class.call(input)
      expect(result).to include("Default fallback text.")
    end
  end
end
