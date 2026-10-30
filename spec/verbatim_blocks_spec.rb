# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/asciidown"

RSpec.describe Asciidown do
  describe "verbatim and code blocks" do
    it "converts source blocks with syntax highlighting language" do
      input = <<~ADOC
        [source,ruby]
        ----
        def calculate(a, b)
          a + b
        end
        ----
      ADOC

      expected = <<~MD
        ```ruby
        def calculate(a, b)
          a + b
        end
        ```
      MD

      expect(described_class.call(input).strip).to eq(expected.strip)
    end

    it "accepts extra attributes and special characters like # in source blocks" do
      input = <<~ADOC
        [source,c#,linenums]
        ----
        Console.WriteLine("Hello");
        ----
      ADOC

      expected = <<~MD
        ```c#
        Console.WriteLine("Hello");
        ```
      MD

      expect(described_class.call(input).strip).to eq(expected.strip)
    end

    it "chooses a fence longer than any internal backtick run" do
      input = <<~ADOC
        [source,markdown]
        ----
        ```ruby
        puts "hello"
        ```
        ----
      ADOC

      result = described_class.call(input).strip
      expect(result).to start_with("````markdown")
      expect(result).to end_with("````")
    end

    it "replaces callout numbers (<1>, <2>) in code blocks with unicode circled numbers" do
      input = <<~ADOC
        [source,javascript]
        ----
        const app = express(); <1>
        app.listen(3000); <2>
        ----
      ADOC

      result = described_class.call(input)

      expect(result).to include("const app = express(); ①")
      expect(result).to include("app.listen(3000); ②")
    end

    it "automatically increments callout numbers when <.> is used" do
      input = <<~ADOC
        [source,ruby]
        ----
        first_step <.>
        second_step <.>
        third_step <.>
        ----
      ADOC

      result = described_class.call(input)

      expect(result).to include("first_step ①")
      expect(result).to include("second_step ②")
      expect(result).to include("third_step ③")
    end

    it "emits buffered listing lines when input ends with an open listing block" do
      input = <<~ADOC
        [source,ruby]
        ----
        unclosed = true
        more_code = 1
      ADOC

      result = described_class.call(input)
      expect(result).to include("```ruby\nunclosed = true\nmore_code = 1\n```")
    end
  end
end
