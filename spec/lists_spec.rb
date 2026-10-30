# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/asciidown"

RSpec.describe Asciidown do
  describe "lists" do
    it "converts unordered bullet lists with nested indentation" do
      input = <<~ADOC
        * First bullet
        ** Sub bullet level 1
        *** Sub bullet level 2
        * Second bullet
      ADOC

      expected = <<~MD
        * First bullet
          * Sub bullet level 1
            * Sub bullet level 2
        * Second bullet
      MD

      expect(described_class.call(input).strip).to eq(expected.strip)
    end

    it "converts ordered numbered lists with nested indentation" do
      input = <<~ADOC
        . First step
        .. Sub step A
        .. Sub step B
        . Second step
      ADOC

      expected = <<~MD
        1. First step
          1. Sub step A
          2. Sub step B
        2. Second step
      MD

      expect(described_class.call(input).strip).to eq(expected.strip)
    end

    it "converts description lists into markdown formatted items" do
      input = <<~ADOC
        Ruby:: A dynamic, open source programming language with a focus on simplicity.
        Python:: An interpreted, high-level, general-purpose programming language.
      ADOC

      result = described_class.call(input)

      expect(result).to include("* **Ruby**")
      expect(result).to include("* **Python**")
    end

    it "attaches subsequent block to the list item using list continuation (+)" do
      input = <<~ADOC
        * First item
        +
        [source,ruby]
        ----
        puts "nested in list"
        ----
        * Second item
      ADOC

      result = described_class.call(input)

      expect(result).to include("* First item")
      expect(result).to include("puts \"nested in list\"")
      expect(result).to include("* Second item")
    end
  end
end
