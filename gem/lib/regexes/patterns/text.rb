# frozen_string_literal: true

module Regexes
  # ── Text ──────────────────────────────────────────────────────────────────────────────────────────────────

  # A pattern written two ways (a name in braces or bare) captures the name once, in a lookahead before the two,
  # so no capture's name is used twice and ECMAScript can read it.
  name        = '[A-Za-z_][A-Za-z0-9_]*'
  destination = '[^()\s]+(?:\([^()\s]*\)[^()\s]*)*'
  tag_name    = '[^{}\s](?:[^{}]*[^{}\s])?'
  sigil       = '[#^/!&>]'
  blank       = '[ \t]*'
  line_break  = '(?:\r\n|\r|\n)'
  # One character of a code span: anything but a line break, or a line break that doesn't end a paragraph.
  span_char   = "(?:[^\\r\\n]|#{line_break}(?![ \\t]*(?:\\r|\\n|\\z)))"

  MARKDOWN_CODE_SPAN       = Expression.new(
    "(?<!`)(?<fence>`+)(?!`)(?<code>(?:(?!(?<!`)\\k<fence>(?!`))#{span_char})+)(?<!`)\\k<fence>(?!`)"
  )
  MARKDOWN_CODE_BLOCK      = Expression.new(
    "(?<fence>(?<marker>[`~])\\k<marker>{2,})[ \\t]*(?<language>[^\\s`]+)?[^`\\r\\n]*#{line_break}" \
    "(?<code>(?:[^\\r\\n]*#{line_break})*?) {0,3}\\k<fence>\\k<marker>*[ \\t]*(?=\\r|\\n|\\z)"
  )
  MARKDOWN_LINK            = Expression.new("\\[(?<text>[^\\[\\]\\n]+)\\]\\((?<destination>#{destination})\\)")
  RUBY_FORMAT_REFERENCE    = Expression.new(
    "(?<!%)%(?=[{<](?<name>#{name}))(?:\\{#{name}\\}|<#{name}>[-+ 0#]*[0-9]*(?:\\.[0-9]+)?[A-Za-z])"
  )
  MUSTACHE_TAG             = Expression.new(
    "\\{\\{(?=(?:\\{|#{blank}(?<sigil>#{sigil})?)#{blank}(?<name>#{tag_name}))" \
    "(?:\\{#{blank}#{tag_name}#{blank}\\}|#{blank}#{sigil}?#{blank}#{tag_name}#{blank})\\}\\}"
  )
  SHELL_VARIABLE_REFERENCE = Expression.new("(?<!\\\\)\\$(?=\\{?(?<name>#{name}))(?:\\{#{name}\\}|#{name})")
  FILE_EXTENSION           = Expression.new('\.(?<extension>[A-Za-z0-9]+)')
  EMOJI                    = Expression.new(
    '(?=\p{Extended_Pictographic}|\p{Regional_Indicator}|[0-9#*]️?⃣)\X'
  )

  # Markdown's inline code, a code span in CommonMark's terms (§6.1): +`get_order`+, and +``a ` b``+, whose fence of
  # two backticks lets it hold one. It closes at the first run of exactly as many backticks as opened it, and may
  # run over a line break but never a blank line, which ends the paragraph. It captures +code+, as written: the
  # one space CommonMark strips from each end when both are there is kept; and +fence+, the backticks.
  #
  # @return [Expression] text between two runs of the same number of backticks, never empty
  def markdown_code_span = MARKDOWN_CODE_SPAN

  # +Regexes.markdown_code_block.line_leading+ matches a fenced code block (CommonMark §4.5): a line of three or
  # more backticks or tildes and an optional info string, the code's lines, and a line closing it with at least as
  # many of the same character. It captures +language+, the first word of the info string (+ruby+ of
  # <tt>```ruby</tt>), nil when there is none; +code+, the lines between the fences, each with its line break; and
  # +fence+ and +marker+, which close it. A block never closed (which CommonMark lets run to the end of the
  # document) and an opening fence indented are not matched; +.line_leading+ requires the fence to start a line.
  #
  # @return [Expression] a fenced code block, from its opening fence to its closing one
  def markdown_code_block = MARKDOWN_CODE_BLOCK

  # +Regexes.markdown_link+ matches +[the docs](https://acme.example/docs)+ and
  # +[Ruby](https://en.wikipedia.org/wiki/Ruby_(programming_language))+ (one level of parentheses), never a link
  # with a title (+[a](b "t")+), an image's +![+ before it, or a reference link (+[a][1]+) — though an image's
  # link part is matched from its +[+. It captures +text+ and +destination+ (CommonMark §6.3).
  #
  # @return [Expression] an inline Markdown link: text in brackets, then its destination in parentheses
  def markdown_link = MARKDOWN_LINK

  # +Regexes.ruby_format_reference+ finds +%{name}+ and +%<count>d+ in a string for +Kernel#format+ or I18n,
  # never the escaped +%%{name}+. It captures +name+.
  #
  # @return [Expression] a named reference in a Ruby format string: +%{name}+, or +%<name>+ and its format
  def ruby_format_reference = RUBY_FORMAT_REFERENCE

  # +Regexes.mustache_tag+ finds +{{name}}+, +{{{html}}}+, +{{#items}}+ and +{{/items}}+ in a template, as
  # Mustache, Handlebars and i18next write them. It captures +name+, and +sigil+ for a section, inverted
  # section, end, comment, unescaped or partial tag.
  #
  # @return [Expression] a tag in a Mustache template
  def mustache_tag = MUSTACHE_TAG

  # +Regexes.shell_variable_reference+ finds +$HOME+ and +${PORT}+, never the escaped +\$HOME+ or the expansions
  # +${PORT:-3000}+ and +$1+. It captures +name+.
  #
  # @return [Expression] a reference to a variable as a POSIX shell, Docker Compose or a +.env+ file writes it
  def shell_variable_reference = SHELL_VARIABLE_REFERENCE

  # +Regexes.file_extension.trailing+ finds the +.gz+ of +backup.tar.gz+ and nothing in +README+. It captures
  # +extension+, without the dot.
  #
  # @return [Expression] a dot and the letters and digits after it: a file name's extension
  def file_extension = FILE_EXTENSION

  # +Regexes.emoji+ finds +👍🏽+, +👨‍👩‍👧+ and +🇩🇪+ each whole, with their skin tones, joiners and paired flags, and
  # the keycap +1️⃣+. A character Unicode marks pictographic counts, so +©+ and +™+ do; a plain digit does not.
  #
  # @return [Expression] one emoji, as the one character a reader sees
  def emoji = EMOJI
end
