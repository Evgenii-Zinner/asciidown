# frozen_string_literal: true

require_relative "constants"

class Asciidown
  # Handles inline text substitutions including quotes, attributes, macros, and callout numbers.
  module Substitutors
    include Constants

    module_function

    def apply_subs(str, state, subs = NORMAL_SUBS)
      return str unless str && str =~ /[{\x60\x27*_:<\[#]/

      subs.reduce(str) do |text, sub_type|
        case sub_type
        when :quotes then apply_quotes(text, state)
        when :attributes then apply_attributes(text, state)
        when :macros then apply_macros(text, state)
        when :callouts then apply_callouts(text, state)
        else text
        end
      end
    end

    def apply_quotes(str, state)
      res = str.dup
      if res.include?("<<")
        res.gsub!(XrefShorthandRx) do
          m = Regexp.last_match
          anchor = m[1].sub(/^#?_?/, "")
          label = m[2]
          label = anchor if label && label.empty?
          "[#{label || anchor}](##{anchor})"
        end
      end

      # Strip metadata in front of emphasis
      res.gsub!(EmphasisSpanMetaRx, "") if res.include?("]_")

      # Bold: StrongSpanRx
      res.gsub!(StrongSpanRx) { "**#{Regexp.last_match(1)[1..-2]}**" } if res.include?("*")

      # Italic: _text_ -> *text*
      res.gsub!(/(?<![\w\\])_(\S|\S.*?\S)_(?![\w\\])/, '*\1*') if res.include?("_")

      # Bold-Italic: ***text***
      res.gsub!(/\*\*_(.*?)_\*\*/, '***\1***') if res.include?("**_")
      res.gsub!(/\*\*\*(.*?)\*\*\*/, '***\1***') if res.include?("***")

      # Quoted spans: "`smart`"
      if res.include?("`") && (res.include?('"`') || res.include?("'`"))
        q = state.quotes_pair
        res.gsub!(QuotedSpanRx, "#{q[0]}\\2#{q[1]}")
      end

      # Marked / Strikethrough
      if res.include?("#")
        res.gsub!(MarkedSpanRx) do
          roles = Regexp.last_match(1)
          is_line_through = Regexp.last_match(2)
          content = Regexp.last_match(3)
          if roles
            s = state.strikethrough_pair
            is_line_through ? "#{s[0]}#{content}#{s[1]}" : content
          else
            "<mark>#{content}</mark>"
          end
        end
      end

      res
    end

    def apply_attributes(str, state)
      return str unless str.include?("{")

      str.gsub(AttributeRefRx) do |match|
        escaped = Regexp.last_match(1)
        name = Regexp.last_match(2)
        if escaped
          match[1..]
        else
          state[name] || match
        end
      end
    end

    def apply_macros(str, state)
      res = str.dup
      return res unless res.include?(":") || res.include?("[[")

      # Images: image:target[alt]
      if res.include?("image:")
        res.gsub!(InlineImageMacroRx) do
          BlockHelpers.handle_image(Regexp.last_match(1), Regexp.last_match(2), state)
        end
      end

      # Links: https://...[label] or link:...[label]
      if res.include?(":/") || res.include?("link:")
        res.gsub!(LinkMacroRx) do |m|
          esc = Regexp.last_match(1)
          scheme = Regexp.last_match(2) || ""
          url = Regexp.last_match(3)
          text = Regexp.last_match(5)
          bare_url = Regexp.last_match(6)

          if esc
            m[1..]
          elsif bare_url
            bare_url
          else
            full_url = "#{scheme}#{url}"
            label = text.nil? || text.empty? ? full_url : text
            "[#{label}](#{full_url})"
          end
        end
      end

      # Anchors [[id]]
      res.gsub!(InlineAnchorRx, '<a name="\1"></a>') if res.include?("[[")

      # Cross-references: xref:path#id[text]
      if res.include?("xref:")
        res.gsub!(XrefMacroRx) do |m|
          esc = Regexp.last_match(1)
          p = Regexp.last_match(2)
          ext = Regexp.last_match(3)
          id = Regexp.last_match(4) || Regexp.last_match(5)
          txt = Regexp.last_match(6)

          if esc
            m[1..]
          elsif p && (ext == "#" || (p += ext))
            "[#{txt || p}](#{p})"
          else
            "[#{txt || id}](#!#{id})"
          end
        end
      end

      res
    end

    def apply_callouts(str, state)
      return str unless str.end_with?(">")

      str.gsub(ConumRx) do
        sp = Regexp.last_match(1)
        chr = Regexp.last_match(2)
        num = (chr == "." ? (state.coseq += 1) - 1 : chr.to_i)
        "#{sp}#{CONUMS[num] || chr}"
      end
    end

    def generate_id(string)
      string.downcase.gsub(/[^\p{Ll}\d_ -]/u, "")
    end
  end
end
