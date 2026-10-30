# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/asciidown"

RSpec.describe Asciidown do
  describe "containers and admonitions" do
    it "converts single-line note and warning into blockquotes" do
      input = "NOTE: Always sanitize external input."
      expected = "> **Note:** Always sanitize external input."

      expect(described_class.call(input).strip).to eq(expected)
    end

    it "converts block admonition syntax [NOTE] and [WARNING]" do
      input = <<~ADOC
        [WARNING]
        ====
        Be careful with database migrations in production.
        ====
      ADOC

      result = described_class.call(input)
      expect(result).to include("> **Warning:**")
      expect(result).to include("Be careful with database migrations in production.")
    end

    it "converts blockquotes with optional author attribution" do
      input = <<~ADOC
        [quote, Matz, Ruby Creator]
        ____
        Ruby is designed to make programmers happy.

        Always prioritize developer happiness.
        ____
      ADOC

      result = described_class.call(input)

      expect(result).to include("> Ruby is designed to make programmers happy.")
      expect(result).to include(">\n> Always prioritize developer happiness.")
      expect(result).to include("> — Matz, Ruby Creator")
    end

    it "converts blockquotes without author attribution" do
      input = <<~ADOC
        ____
        Simplicity is a prerequisite for reliability.
        ____
      ADOC

      result = described_class.call(input)
      expect(result).to include("> Simplicity is a prerequisite for reliability.")
      expect(result).not_to include("—")
    end
  end
end
