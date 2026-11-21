# frozen_string_literal: true

require 'test_helper'

# Tests for the sets of characters: what each matches, one character at a time, and what it refuses.
class RegexesSetsTest < RegexesTestCase
  cases({
          lowercase_letters:      [%w[a z m], ['A', '1', 'é', '', ' ', 'ab']],
          uppercase_letters:      [%w[A Z M], ['a', '1', 'É', '', 'AB']],
          letters:                [%w[a Z], %w[1 _ é ß]],
          digits:                 [%w[0 9 5], ['a', "\u0663", "\uFF11", '', '10']],
          lowercase_alphanumeric: [%w[a 0 z 9], %w[A _ -]],
          uppercase_alphanumeric: [%w[A 0 Z 9], %w[a _ -]],
          alphanumeric:           [%w[a Z 0], %w[_ - é]],
          word_characters:        [%w[a Z 0 _], ['-', ' ', 'é']],
          binary_digits:          [%w[0 1], %w[2 a]],
          octal_digits:           [%w[0 7], %w[8 9]],
          hex_digits:             [%w[0 a F f 9], %w[g G]],
          base32_digits:          [%w[A Z 2 7], %w[a 0 1 8 9 =]],
          base58_digits:          [%w[1 9 A H J N P Z a k m z], %w[0 O I l + /]],
          base64_digits:          [%w[A z 0 + /], %w[- _ =]],
          base64url_digits:       [%w[A z 0 - _], %w[+ / =]],
          whitespace:             [[' ', "\t", "\n", "\r", "\v", "\f", "\u00A0", "\u3000", "\u2028"], ['a', '_', "\u200B"]],
          ascii_whitespace:       [[' ', "\t", "\n", "\v", "\f", "\r"], ["\u00A0", "\u3000", 'a']],
          space_or_tab:           [[' ', "\t"], ["\n", "\r", "\u00A0"]],
          newline:                [["\n"], ["\r", ' ']],
          slash:                  [['/'], ['\\', '|']],
          hyphen:                 [['-'], ['_', "\u2013", "\u2212"]],
          dashes:                 [['-', "\u2010", "\u2011", "\u2013", "\u2014", "\u2015"], ["\u2212", '_', '~', 'a']],
          apostrophes:            [["'", '`', "\u00B4", "\u02BC", "\u2018", "\u2019"], ['"', "\u2033", 'a']],
          double_quotes:          [['"', "\u201C", "\u201D", "\u201E", "\u201F"], ["'", "\u00AB", "\u00BB"]],
          unicode_letters:        [%w[a é ß ж 中 ا], ['1', "\u0663", '_', ' ', "\u0301"]],
          unicode_digits:         [['0', '9', "\u0663", "\u0969", "\uFF10"], ['a', "\u00BD", "\u2163"]],
          combining_marks:        [["\u0301", "\u0308", "\u20DD"], ['a', "\u00E9", ' ']],
          control_characters:     [["\u0000", "\t", "\n", "\u007F", "\u0085"], [' ', 'a', "\u200B"]],
          format_characters:      [["\u200B", "\u200D", "\uFEFF", "\u00AD", "\u200E"], [' ', 'a', "\u0301"]]
        }, defined_in: 'sets')

  test 'two uppercase letters are the shape of a country code' do
    assert_match Regexes.uppercase_letters.exactly(2).whole, 'DE'
  end

  test 'whitespace finds the no-break space of pasted text' do
    assert_equal [' ', "\u00A0"], "a b\u00A0c".scan(Regexes.whitespace)
  end

  test 'ASCII whitespace passes over the no-break space' do
    assert_equal [' '], "a b\u00A0c".scan(Regexes.ascii_whitespace)
  end

  test 'combining marks take the accents off decomposed text' do
    assert_equal 'cafe', 'café'.unicode_normalize(:nfd).gsub(Regexes.combining_marks, '')
  end

  test 'dashes turn typed dashes into hyphens' do
    assert_equal 'a-b-c', "a\u2013b\u2014c".gsub(Regexes.dashes, '-')
  end
end
