# frozen_string_literal: true

class Asciidown
  module Constants
    ADMONS = {
      "CAUTION" => "🔥",
      "IMPORTANT" => "❗",
      "NOTE" => "📌",
      "TIP" => "💡",
      "WARNING" => "⚠️"
    }.freeze

    ATTRIBUTES = {
      "empty" => "",
      "idprefix" => "_",
      "idseparator" => "_",
      "markdown-line-break" => "\\",
      "markdown-strikethrough" => "~~",
      "nbsp" => "&#160;",
      "quotes" => "<q> </q>",
      "sp" => " ",
      "vbar" => "|",
      "zwsp" => "&#8203;"
    }.freeze

    BREAKS = {
      "'''" => "---",
      "***" => "---",
      "---" => "---",
      "<<<" => nil,
      "toc::[]" => nil
    }.freeze

    CONUMS = (1..19).to_h { |i| [i, [0x2460 + i - 1].pack("U*")] }.freeze

    DELIMS = {
      "----" => "v",
      "...." => "v",
      "====" => "c",
      "|===" => "t",
      "--" => "c",
      "****" => "c",
      "____" => "c",
      "++++" => "p"
    }.freeze

    LIST_MARKERS = %w[1 2 3 4 5 6 7 8 9 * . < -].to_h { |c| [c, true] }.freeze
    NORMAL_SUBS = %i[quotes attributes macros].freeze
    TDIV = { "" => "| --- ", "<" => "| :-- ", "^" => "| :-: ", ">" => "| --: " }.freeze

    AttributeEntryRx = /^:(!)?([^:-][^:]*):(?:$| (.+))/
    AttributeRefRx = /(\\)?\{([\p{Ll}\d_][\p{Ll}\d_-]*)\}/u
    AuthorInfoLineRx = /^(?:[\p{Alpha}\d_]+(?: +[\p{Alpha}\d_]+){0,2}(?: +<([^>]+)>)?(?:; |$))+$/u
    BlockAnchorRx = /^\[([\p{L}_][\p{Alpha}\d_\-:.]*)(?:, ?(.+))?\]$/u
    BlockImageMacroRx = /^image::([^\s\[]+)\[(.*?)\]$/
    CellDelimiterRx = /(?<!\\)\| */
    ConumRx = /(^| )<([.1-9]|1\d)>(?=(?: <(?:[.1-9]|1\d)>)*$)/
    DlistItemRx = %r{^(?!//)(\S.*?)(:{2,4})(?: (.+))?($)}
    ElementAttributeRx = /(?:^|, *)(?:(\w[\w-]*)=)?(?:("|')(.+?)\2|([^,]+|))/
    EmphasisSpanMetaRx = /(?<![\p{L}\d_\\])\[[^\[\]]+\](?=_(?:\S|\S.*?\S)_(?![\p{L}\d_]))/u
    InlineAnchorRx = /\[\[([\p{L}_][\p{Alpha}\d_\-:.]*)\]\]/u
    InlineImageMacroRx = /image:([^\s\[]+)\[(.*?)\]/
    InlineStemMacroRx = /stem:\[(.*?[^\\])\]/
    LinkMacroRx = %r{(\\)?(?:(?:link:(?!:)|(?<![image:(\w])(https?://))([^\s\[\\]+)(\[(|.*?[^\\])\^?\])|(?<![image:(\w])(https?://)([^\s\[\])]+))}
    ListItemRx = /^(\*+|\.+|<(?:[.1-9]|1\d)>|-|\d+\.) +(.+)/
    MarkedSpanRx = /(?<![\p{L}\d_\\])(?:\[((\.line-through)|[^\[\]]+)\])?#(\S|\S.*?\S)#(?![\p{L}\d_])/u
    PreprocessorDirectiveRx = /^\\?(?:(if)(n)?def|include)::([^\[]+)\[(.+)?\]$/
    QuotedSpanRx = /("|')`(\S|\S.*?\S)`\1/
    RevisionInfoLineRx = /^v(\d+(?:[-.]\w+)*)(?:, (\d+-\d+-\d+))?|(\d+-\d+-\d+)$/
    RewriteInternalXrefRx = /\[([^\[\]]*?)\]\(#!([^)]+)\)/
    StrongSpanRx = /(?<![\p{L}\d_\\])(?:\[[^\[\]]+\])?(\*(?:\S|\S.*?\S)\*)(?![\p{L}\d_])/u
    StyleShorthandMarkersRx = /([.#%])/
    XrefMacroRx = /(\\)?xref:(?![\s:`])(?:([^#\[\\]+)(#[^\s\[\\]*|\.adoc)|#([^\s\[\\]+)|([^#\[\\]+))\[(|.*?[^\\])\]/
    XrefShorthandRx = /<<([^\s,>][^,>]*)(?:, ?([^>]+))?>>/
  end
end
