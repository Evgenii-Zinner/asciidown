# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/asciidown"

RSpec.describe Asciidown do
  describe "inline text formatting" do
    [
      ["*bold text*", "**bold text**"],
      ["_italic text_", "*italic text*"],
      ["*_bold italic_*", "***bold italic***"],
      ["[.line-through]#deleted#", "~~deleted~~"],
      ["#highlighted#", "<mark>highlighted</mark>"],
      ['"`quoted text`"', "<q>quoted text</q>"],
      ["snake_case_variable", "snake_case_variable"],
      ["Use \\*escaped* asterisks.", "Use \\*escaped* asterisks."]
    ].each do |input, expected|
      it "converts #{input.inspect} to #{expected.inspect}" do
        expect(described_class.call(input).strip).to eq(expected)
      end
    end

    it "does not format within-word asterisks" do
      input = "*foo*bar"
      expect(described_class.call(input).strip).to eq(input)
    end

    it "drops boxed role in front of styled bold or italic" do
      input = "[.custom]*styled bold* and [.custom]_styled italic_"
      expected = "**styled bold** and *styled italic*"
      expect(described_class.call(input).strip).to eq(expected)
    end
  end
end
