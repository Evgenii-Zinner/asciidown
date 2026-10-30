# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/asciidown"

RSpec.describe Asciidown do
  describe "tables" do
    it "converts AsciiDoc tables to pipe tables" do
      input = <<~ADOC
        |===
        | Endpoint | Method | Description

        | /api/v1/users | GET | List all users
        | /api/v1/posts | POST | Create post
        |===
      ADOC

      expected = <<~MD
        | Endpoint | Method | Description |
        | --- | --- | --- |
        | /api/v1/users | GET | List all users |
        | /api/v1/posts | POST | Create post |
      MD

      expect(described_class.call(input).strip).to eq(expected.strip)
    end

    it "preserves empty cells and escaped pipes without column shifting" do
      input = <<~ADOC
        |===
        | First | Middle | Last
        | John | | Doe
        | Escaped \\| Pipe | Mid | End
        |===
      ADOC

      expected = <<~MD
        | First | Middle | Last |
        | --- | --- | --- |
        | John |  | Doe |
        | Escaped \\| Pipe | Mid | End |
      MD

      expect(described_class.call(input).strip).to eq(expected.strip)
    end
  end
end
