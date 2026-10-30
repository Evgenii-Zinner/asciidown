# frozen_string_literal: true

require_relative "constants"

class Asciidown
  # Helper functions for identifying and formatting AsciiDoc headings, list items,
  # block titles, image macros, and element attribute lists.
  module BlockHelpers
    include Constants

    module_function

    def is_heading(str, accept_all, block_attrs)
      space_idx = str.index(" ")
      return nil unless space_idx&.positive? && space_idx <= 6

      marker = ["=", "==", "===", "====", "=====", "======"][space_idx - 1]
      return nil unless marker && str.start_with?(marker)

      title = str[(space_idx + 1)..]
      return nil if title.nil? || title.empty?

      title = title.lstrip if title[0] == " "
      return nil if title.empty?

      [marker, title] if accept_all || (block_attrs && block_attrs[1] == "discrete")
    end

    def is_any_list_item(chr0, str)
      if LIST_MARKERS[chr0] && (m = ListItemRx.match(str))
        return [m[1], m[2], nil, nil]
      end

      if (str.end_with?("::") || str.include?(":: ")) && (m = DlistItemRx.match(str))
        [m[1], m[3], m[3], m[2]]
      end
    end

    def write_block_title(buffer, block_title, block_attrs, state)
      id = block_attrs&.dig("id")
      indent = block_title[:indent]
      text = block_title[:text]
      title = Substitutors.apply_subs(text, state, block_title[:subs])
      if id
        state.refs[id] = { title: title, reftext: block_attrs["reftext"] }
        anchor = "<a name=\"#{id}\"></a>"
      else
        anchor = ""
      end
      buffer << "#{indent}#{anchor}**#{title}**"
      buffer << ""
    end

    def handle_image(target, attrlist, state)
      attrs = parse_attrlist(attrlist)
      alt = attrs[1] || target
      imagesdir = state["imagesdir"] ? "#{state['imagesdir']}/" : ""
      "![#{alt}](#{imagesdir}#{target})"
    end

    def parse_attrlist(attrlist)
      attrs = {}
      return attrs if attrlist.nil? || attrlist.empty?

      if attrlist.include?("=")
        attrlist.scan(ElementAttributeRx) do |k, _, qv, uv|
          attrs[k] = qv || uv
        end
      else
        parts = attrlist.split(",").map(&:strip)
        parts.each_with_index { |p, i| attrs[i + 1] = p }
        if (shorthand = attrs[1])
          shorthand.split(StyleShorthandMarkersRx).each_slice(2) do |val, marker|
            attrs["id"] = val if marker == "#"
            attrs["role"] = val if marker == "."
          end
        end
      end
      attrs
    end
  end
end
