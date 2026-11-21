# frozen_string_literal: true

require 'test_helper'

# Tests for single characters and the breaks between lines and paragraphs.
class RegexesBreaksTest < RegexesTestCase
  cases({
          any_character:      [['a', ' ', 'é', "\r"], ["\n", '', 'ab']],
          line_break:         [["\r\n", "\r", "\n"], ["\n\n", ' ', "\r\n\r\n", "\n\r", '']],
          unicode_line_break: [["\n", "\r\n", "\r", "\v", "\f", "\u0085", "\u2028", "\u2029"], [' ', "\t", 'a', "\n\n", '']],
          paragraph_break:    [["\n\n", "\r\n\r\n", "\n \t\n", "\n\n\n", "\r\r", "\n\r\n"], ["\n", ' ', "\n a\n", "\n\n a", '']]
        }, defined_in: 'breaks')

  test 'a line break takes a CRLF whole' do
    assert_equal ["\r\n", "\n"], "a\r\nb\nc".scan(Regexes.line_break)
  end

  test 'lines split however they end' do
    assert_equal %w[a b c d], "a\r\nb\rc\nd".split(Regexes.line_break)
  end

  test 'a unicode line break finds the line separator' do
    assert_equal %W[\u2028], "a\u2028b".scan(Regexes.unicode_line_break)
  end

  test 'paragraphs split however many blank lines are between them' do
    assert_equal %w[one two three], "one\n\ntwo\n \n\n  \nthree".split(Regexes.paragraph_break).map(&:strip)
  end

  test 'a single line break is not a paragraph break' do
    assert_equal ["one\ntwo"], "one\ntwo".split(Regexes.paragraph_break)
  end

  test 'paragraph breaks close up to one blank line' do
    assert_equal "a\n\nb", "a\n\n\n\nb".gsub(Regexes.paragraph_break, "\n\n")
  end
end
