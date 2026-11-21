# frozen_string_literal: true

module Regexes
  # ── Characters and breaks ─────────────────────────────────────────────────────────────────────────────────

  ANY_CHARACTER      = Expression.new('.', single: true)
  LINE_BREAK         = Expression.new('(?:\r\n|\r|\n)', single: true)
  UNICODE_LINE_BREAK = Expression.new('\R', single: true)
  PARAGRAPH_BREAK    = Expression.new("#{LINE_BREAK.source}(?:[ \\t]*#{LINE_BREAK.source})+")

  # +Regexes.any_character.between(1, 255)+ takes text up to 255 characters at a time.
  #
  # @return [Expression] one character, any but a line feed
  def any_character = ANY_CHARACTER

  # +text.split(Regexes.line_break)+ splits lines however they end.
  #
  # @return [Expression] one line break, however it is written: +\r\n+, +\r+ or +\n+, the CRLF taken whole
  def line_break = LINE_BREAK

  # @return [Expression] one line break as Unicode defines them: {#line_break}'s three, the vertical tab, the
  #   form feed, the next line (+U+0085+) and the line and paragraph separators (+U+2028+, +U+2029+)
  def unicode_line_break = UNICODE_LINE_BREAK

  # +text.split(Regexes.paragraph_break)+ splits paragraphs, and +text.gsub(Regexes.paragraph_break, "\n\n")+
  # closes up paragraphs left too far apart.
  #
  # @return [Expression] two or more line breaks, with nothing between them but spaces and tabs: the end of a
  #   paragraph and the blank lines after it
  def paragraph_break = PARAGRAPH_BREAK
end
