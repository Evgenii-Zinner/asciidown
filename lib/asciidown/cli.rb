# frozen_string_literal: true

require "optparse"

class Asciidown
  # Command line interface for converting AsciiDoc files or STDIN to Markdown.
  class CLI
    def self.run(argv = ARGV)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv.dup
      @options = { front_matter: true }
    end

    def run
      parse_options!

      opts = @options.dup
      output_file = opts.delete(:output_file)

      input_text = read_input
      output_text = Asciidown.call(input_text, **opts)
      write_output(output_text, output_file)

      0
    rescue StandardError => e
      warn "asciidoc2md: #{e.message}"
      1
    end

    private

    def parse_options!
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: asciidoc2md [options] [file]"

        opts.on("-o", "--output FILE", "Write output to FILE instead of standard output") do |file|
          @options[:output_file] = file
        end

        opts.on("--[no-]front-matter", "Extract document header as YAML front matter (default: true)") do |fm|
          @options[:front_matter] = fm
        end

        opts.on("-v", "--version", "Show version") do
          puts "asciidown #{VERSION}"
          exit 0
        end

        opts.on("-h", "--help", "Show this help message") do
          puts opts
          exit 0
        end
      end

      parser.parse!(@argv)
    end

    def read_input
      if @argv.empty? || @argv.first == "-"
        $stdin.read
      else
        File.read(@argv.first)
      end
    end

    def write_output(text, output_file)
      if output_file
        File.write(output_file, text)
      else
        $stdout.print(text)
      end
    end
  end
end
