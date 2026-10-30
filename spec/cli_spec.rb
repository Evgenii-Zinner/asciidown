# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require_relative "../lib/asciidown"

RSpec.describe Asciidown::CLI do
  describe ".run" do
    it "prints version and exits 0 on --version" do
      expect do
        expect { described_class.run(["--version"]) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end.to output(/asciidown #{Asciidown::VERSION}/).to_stdout
    end

    it "prints help and exits 0 on --help" do
      expect do
        expect { described_class.run(["--help"]) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end.to output(/Usage: asciidoc2md/).to_stdout
    end

    it "reads from a file and outputs markdown to stdout" do
      temp_in = Tempfile.new(["article", ".adoc"])
      temp_in.write("= Title\n\nParagraph")
      temp_in.close

      expect do
        status = described_class.run([temp_in.path])
        expect(status).to eq(0)
      end.to output(/# Title|title: Title/).to_stdout

      temp_in.unlink
    end

    it "writes output to a file when -o option is passed" do
      temp_in = Tempfile.new(["article", ".adoc"])
      temp_out = Tempfile.new(["output", ".md"])
      temp_in.write("== Subheading\n\nParagraph text.")
      temp_in.close
      temp_out.close

      status = described_class.run(["-o", temp_out.path, temp_in.path])
      expect(status).to eq(0)

      content = File.read(temp_out.path)
      expect(content).to include("## Subheading")
      expect(content).to include("Paragraph text.")

      temp_in.unlink
      temp_out.unlink
    end
  end
end
