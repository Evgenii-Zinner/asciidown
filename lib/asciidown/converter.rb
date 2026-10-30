# frozen_string_literal: true

require_relative "constants"
require_relative "document_state"
require_relative "substitutors"
require_relative "block_helpers"

class Asciidown
  # Core state-machine conversion engine for parsing AsciiDoc lines into Markdown.
  class Converter
    include Constants

    def self.convert(asciidoc, state)
      new(asciidoc, state).convert
    end

    def initialize(asciidoc, state)
      @asciidoc = asciidoc
      @state = state
    end

    def convert
      lines = @asciidoc.split("\n")
      lines.pop if lines.last == ""

      accum = []
      in_container = false
      in_header = @asciidoc[0] == "=" || @asciidoc.include?("\n= ")
      in_para = false
      in_list = false
      in_table = nil
      indent = ""
      block_attrs = nil
      block_title = nil
      hardbreak_next = nil
      list_stack = []
      container_stack = []
      skip_stack = []
      verbatim = nil
      subs = nil
      next_line = nil

      idx = 0
      while idx < lines.length
        line = lines[idx]

        loop do
          grab = match = next_line = style = subs = nil

          if line.nil?
            break
          elsif skip_stack.any?
            if line == skip_stack.last
              skip_stack.pop
            elsif skip_stack.last == "endif::[]" && line.start_with?("if") && line =~ /^ifn?def::.+\[\]$/
              skip_stack.push("endif::[]")
            end
            line = nil
            break
          elsif line.empty? && (!in_container || !in_container[:verbatim])
            if in_table
              line = nil
              break
            end
            in_header = false
            in_para = false

            if in_list
              in_para = nil
              list_stack = []
              in_list = false
              indent = (in_container && in_container[:child_indent]) || ""
            else
              line = indent = (in_container && in_container[:child_indent]) || ""
              line = line.rstrip
            end
            block_attrs = block_title = verbatim &&= verbatim[:close]&.call
            break
          elsif ((grab = (line[0] == "\\")) || (line[0] == "i" && line[1] != "m")) &&
                ((grab && line == "\\endif::[]") || (line.end_with?("]") && line.include?("::") && (match = PreprocessorDirectiveRx.match(line)))) &&
                !(line = grab ? line[1..] : nil)
            if match[1]
              negated = match[2]
              name = match[3]
              text = match[4]
              drop = @state.key?(name) ? !negated.nil? : negated.nil?
              if text
                next if drop # redo

                line = text
              elsif !skip_stack.push(drop && "endif::[]")
                next # redo
              end
            end
          elsif in_container && in_container[:verbatim]
            if line == in_container[:delimiter]
              code_lines = in_container[:code_lines]
              max_backticks = code_lines.flat_map { |l| l.scan(/`+/).map(&:length) }.max || 0
              fence = "`" * [3, max_backticks + 1].max
              accum[in_container[:fence_idx]] = "#{in_container[:indent]}#{fence}#{in_container[:style]}".strip
              accum.concat(code_lines.map { |l| "#{in_container[:indent]}#{l}" })
              line = "#{in_container[:indent]}#{fence}"
              indent = in_container[:indent]
              in_list = in_container[:in_list]
              list_stack = in_container[:list_stack]
              in_container = container_stack.any? ? container_stack.pop : false
            elsif line.length.positive?
              current_line = Substitutors.apply_callouts(line, @state)
              in_container[:code_lines] << current_line
              line = nil
            end
            break
          elsif !in_header && DELIMS.key?(line)
            if in_para != false
              list_stack = []
              in_list = false
              indent = (in_container && in_container[:child_indent]) || ""
              in_para = false
            end

            opening = in_container == false || (line != in_container[:delimiter] && container_stack.push(in_container))
            if opening
              in_container = { delimiter: line, indent: indent, child_indent: indent, in_list: in_list,
                               list_stack: list_stack }
            end

            if (grab = DELIMS[line]) == "v" && (in_container[:verbatim] = true)
              in_container[:child_indent] = ""
              in_container[:subs] = [:callouts]
              in_container[:code_lines] = []
              in_container[:fence_idx] = accum.length
              @state.coseq = 1
              if block_attrs
                raw_style = block_attrs[1] || (line == "----" ? "source" : nil)
                style = if raw_style =~ /^source(?:\s*,\s*([a-zA-Z0-9_+#.-]+))?/
                          Regexp.last_match(1) || block_attrs[2] || @state["source-language"]
                        elsif raw_style == "source"
                          block_attrs[2] || @state["source-language"]
                        else
                          raw_style
                        end
                style = nil if %w[listing literal].include?(style)
                BlockHelpers.write_block_title(accum, block_title, block_attrs, @state) if block_title
              elsif line == "----"
                style = @state["source-language"]
              end
              in_container[:style] = style
              line = nil
            elsif grab == "p" && (in_container[:verbatim] = true)
              line = block_attrs && block_attrs[1] == "stem" ? "```math" : nil
              in_container[:cap] = "```" if line
              block_title = nil
            elsif !opening
              line = in_container[:cap]
              indent = in_container[:indent]
              in_list = in_container[:in_list]
              list_stack = in_container[:list_stack]
              in_table = block_title = nil
              in_container = container_stack.any? ? container_stack.pop : false
            elsif grab == "t"
              in_table = { header: block_attrs&.key?("header-option") || (!block_attrs&.key?("noheader-option") && nil) }
              if block_attrs && (grab = block_attrs["cols"])
                cols = grab.split(/,|;/)
                in_table[:div] = "| #{cols.map { |c| TDIV[c[/[<^>]/] || '']&.strip || '---' }.join(' | ')} |"
                in_table[:cols] = cols.length
              end
              line = nil
            elsif line == "____"
              indent = (in_container[:child_indent] += "> ")
              author_part = [block_attrs && block_attrs[2], block_attrs && block_attrs[3]].compact.map(&:strip).reject(&:empty?).join(", ")
              author_part = block_attrs[1] if author_part.empty? && block_attrs && block_attrs[1] && block_attrs[1] != "quote"
              in_container[:cap] = ">\n#{indent}— #{author_part}" if author_part && !author_part.empty?
              line = block_title ? BlockHelpers.write_block_title(accum, block_title, block_attrs, @state) : nil
            elsif line == "====" && block_attrs
              style = block_attrs[1]
              if ADMONS.key?(style) || %w[NOTE TIP IMPORTANT WARNING CAUTION].include?(style)
                title_part = block_title ? ": #{block_title[:text]}" : ""
                indent = (in_container[:child_indent] += "> ")
                line = "> **#{style.capitalize}#{title_part}:**"
                in_container[:cap] = nil
                block_title = nil
              elsif block_attrs.key?("collapsible-option")
                summary = block_title ? block_title[:text] : "Details"
                line = "<details>\n#{indent}<summary>#{summary}</summary>\n"
                in_container[:cap] = "</details>"
                block_title = nil
              else
                line = block_title ? BlockHelpers.write_block_title(accum, block_title, block_attrs, @state) : nil
              end
            else
              line = block_title ? BlockHelpers.write_block_title(accum, block_title, block_attrs, @state) : nil
            end
            block_attrs = nil
            list_stack = [] if opening
            break
          else
            chr0 = line[0]
            indented = (chr0 == " ")
            _line = indented ? line.lstrip : line
            _chr0 = _line[0]

            if in_para.nil? && _chr0
              in_para = false
              if BlockHelpers.is_any_list_item(_chr0, _line) && in_list
                accum.pop
              elsif !indented
                list_stack = []
                in_list = false
                indent = (in_container && in_container[:child_indent]) || ""
              end
            end

            if chr0 == "/" && line[1] == "/"
              if line == "////"
                skip_stack.push(line)
                in_para = false
              end
              line = nil
            elsif !in_para && chr0 == "=" && (match = BlockHelpers.is_heading(line, in_container == false, block_attrs))
              marker, title = match
              if in_header
                if marker.length > 1 || (block_attrs && block_attrs[1] == "discrete") || @state.key?("doctitle")
                  in_header = false
                  redo if accum.empty?
                else
                  @state["doctitle"] = title
                  auto_id = Substitutors.generate_id(title).tr(" ", "-") if block_attrs&.key?("id")
                end
              else
                title = Substitutors.apply_subs(title, @state, NORMAL_SUBS)
                auto_id = Substitutors.generate_id(title).tr(" ", "-")
                id = block_attrs&.dig("id") || (@state["idprefix"] + auto_id)
              end
              if id
                ref_obj = { auto_id: auto_id, reftext: block_attrs&.dig("reftext"), title: title }
                @state.refs[title] = ref_obj
                @state.refs[id] = ref_obj
              end
              block_attrs = block_title = nil
              line = "#{'#' * marker.length} #{title}"
            elsif !in_para && chr0 == ":" && (match = AttributeEntryRx.match(line))
              del = match[1]
              name = match[2]
              val = match[3] || ""
              line = nil
              if del
                @state.delete(name)
              else
                @state[name] = val.include?("{") ? Substitutors.apply_attributes(val, @state) : val
              end
            elsif chr0 == "[" && line.end_with?("]")
              block_attrs = BlockHelpers.parse_attrlist(line[1..-2])
              line = nil
              in_para = false
            elsif in_header
              if @state.key?("doctitle")
                if !@state.key?("author") && AuthorInfoLineRx.match?(line)
                  authors = line.split("; ").map { |author| author.split(" <")[0] }
                  @state["author"] = authors[0]
                  @state["authors"] = authors.join(", ")
                  line = nil
                elsif !@state.key?("revdate") && !@state.key?("revnumber") && (match = RevisionInfoLineRx.match?(line))
                  @state["revnumber"] = match[1] if match[1]
                  @state["revdate"] = match[2] || match[3] if match[2] || match[3]
                  line = nil
                else
                  in_header = false
                  redo if accum.empty?
                end
              else
                in_header = false
                redo if accum.empty?
              end
            elsif in_table
              cells = line.split(/(?<!\\)\|/, -1).map(&:strip)
              cells.shift if cells.first.to_s.empty?
              cells.pop if cells.last.to_s.empty?
              if in_table[:row]
                in_table[:row].concat(cells)
                break if in_table[:row].length < in_table[:cols]

                line = "| #{Substitutors.apply_subs(in_table[:row].shift(in_table[:cols]).join(' | '), @state, NORMAL_SUBS)} |"
              else
                in_table[:row] = []
                in_table[:cols] ||= cells.length
                cols = in_table[:cols]
                div = in_table[:div] || "| #{Array.new(cols, '---').join(' | ')} |"
                line = "| #{cells.join(' | ')} |\n#{indent}#{div}"
              end
            elsif line == "+" && in_list
              line = in_list[:indent]
              indent = in_list[:child_indent]
              verbatim = in_para = false
              accum << line.rstrip
              break
            elsif (!in_para || in_list) && (match = BlockHelpers.is_any_list_item(_chr0, _line))
              marker, text, desc, dlist = match
              if dlist
                text = "*#{marker}*"
                marker = "-"
                hardbreak_next = "pending" unless desc
              end
              ordered = marker.start_with?(".", "1") || marker.end_with?(".")
              if !in_list || in_list[:marker] != marker
                if list_stack.any? && (m_idx = list_stack.find_index { |entry| entry[:marker] == marker })
                  in_list = list_stack[m_idx]
                  list_stack = list_stack[0...m_idx]
                  indent = in_list[:indent]
                else
                  container_child = in_container ? in_container[:child_indent] : ""
                  indent = in_list ? (list_stack << in_list).last[:child_indent] : container_child
                  lindent = 2
                  in_list = { marker: marker, indent: indent, child_indent: indent + (" " * lindent),
                              numeral: ordered ? 0 : nil }
                end
              else
                indent = in_list[:indent]
              end
              in_para = true
              subs = NORMAL_SUBS
              line = (ordered ? "#{in_list[:numeral] += 1}. " : "* ") + text
            elsif in_para
              subs = NORMAL_SUBS
              accum[-1] += @state["markdown-line-break"] if (hardbreak_next || in_para == "hardbreaks") && accum.any?
            elsif chr0 == "." && line.length > 1 && line[1] != "."
              text = line.start_with?(".*") && line.end_with?("*") ? line[2..-2] : line[1..]
              block_title = { indent: indent, text: text, subs: NORMAL_SUBS }
              line = nil
            elsif chr0 && (match = line.index(": ")) && match < 10 && ADMONS.key?(style = line[0...match])
              body = line[(match + 2)..]
              in_para = true
              line = "> **#{style.capitalize}:** #{Substitutors.apply_subs(body, @state, NORMAL_SUBS)}"
            elsif chr0 == "i" && line.start_with?("image::") && (match = BlockImageMacroRx.match(line))
              line = BlockHelpers.handle_image(match[1], match[2], @state)
            elsif BREAKS.key?(line)
              line = BREAKS[line]
            else
              in_para = true
              subs = NORMAL_SUBS
            end

            break
          end
        end

        if line
          BlockHelpers.write_block_title(accum, block_title, block_attrs, @state) if block_title
          line = Substitutors.apply_subs(line, @state, subs) if subs
          accum << (indent.empty? || line.empty? ? line : "#{indent}#{line}")
          if next_line
            next_line = Substitutors.apply_subs(next_line, @state, NORMAL_SUBS)
            accum[-1] += @state["markdown-line-break"]
            accum << (indent.empty? ? next_line : "#{indent}#{next_line}")
          end
        elsif line == ""
          accum << (indent.empty? ? "" : indent.rstrip)
        end

        hardbreak_next = nil if hardbreak_next && hardbreak_next != "pending"
        hardbreak_next = "active" if hardbreak_next == "pending"
        idx += 1
      end

      if in_container && in_container[:verbatim]
        code_lines = in_container[:code_lines]
        max_backticks = code_lines.flat_map { |l| l.scan(/`+/).map(&:length) }.max || 0
        fence = "`" * [3, max_backticks + 1].max
        accum[in_container[:fence_idx]] = "#{in_container[:indent]}#{fence}#{in_container[:style]}".strip
        accum.concat(code_lines.map { |l| "#{in_container[:indent]}#{l}" })
        accum << "#{in_container[:indent]}#{fence}"
      end

      result = accum.join("\n").rstrip
      # Final internal cross-references replacement
      result.gsub(RewriteInternalXrefRx) do
        text = Regexp.last_match(1)
        id = Regexp.last_match(2)
        target = @state.refs[id] || @state.nrefs[id] || {}
        title = target[:title] || id
        reftext = target[:reftext] || title
        auto_id = target[:auto_id] || id.sub(/^#?_?/, "")
        "[#{text.empty? ? reftext : text}](##{auto_id})"
      end
    end
    # rubocop:enable Metrics/BlockLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize
  end
end
