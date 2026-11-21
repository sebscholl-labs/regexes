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

  MARKDOWN_CODE_SPAN       = Expression.new('`(?<code>[^`]+)`')
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

  # Markdown's inline code, a code span in CommonMark's terms: +`get_order`+, its text captured as +code+. Only
  # the single-backtick form: a span opened by two backticks, to hold one, is not matched.
  #
  # @return [Expression] text between a pair of backticks, never empty
  def markdown_code_span = MARKDOWN_CODE_SPAN

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
