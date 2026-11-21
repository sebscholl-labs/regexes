# frozen_string_literal: true

require 'test_helper'

# Tests for what each named pattern matches, whole, and what it refuses, and that each is built once.
class RegexesTest < Regexes::TestCase
  # Each pattern, with texts it must match whole and texts it must not.
  CASES = {
    lowercase_letters:      [%w[a z], ['A', '1', 'é', '']],
    letters:                [%w[a Z], %w[1 _ é]],
    digits:                 [%w[0 9], ['a', "\u0663", '']],
    lowercase_alphanumeric: [%w[a 0], %w[A _ -]],
    alphanumeric:           [%w[a Z 0], %w[_ -]],
    word_characters:        [%w[a Z 0 _], ['-', ' ', 'é']],
    hex_digits:             [%w[0 a F], %w[g G]],
    whitespace:             [[' ', "\t", "\n", "\r", "\u00A0", "\u3000"], %w[a _]],
    space_or_tab:           [[' ', "\t"], ["\n", "\r", "\u00A0"]],
    newline:                [["\n"], ["\r", ' ']],
    slash:                  [['/'], ['\\', '|']],
    hyphen:                 [['-'], ['_', "\u2013"]],
    any_character:          [['a', ' ', 'é'], ["\n", '', 'ab']],
    line_break:             [["\r\n", "\r", "\n"], ["\n\n", ' ', "\r\n\r\n"]],
    integer:                [%w[0 42 -7], ['4.2', '1e3', '+1', '-', '']],
    uuid:                   [%w[01890a5d-ac96-774b-bcce-b302099a8057 01890A5D-AC96-774B-BCCE-B302099A8057],
                             %w[01890a5dac96774bbcceb302099a8057 01890a5d-ac96-774b-bcce-b302099a805 x1890a5d-ac96-774b-bcce-b302099a8057]],
    identifier:             [%w[get_order Tag2 x], %w[2tag get-order _x]],
    utc_offset:             [%w[Z +05:30 -0500], %w[z +5:30 05:00]],
    iso8601_time:           [['2026-11-21T14:30', '2026-11-21 14:30:05.123Z', '2026-11-21T14:30:05-05:00'],
                             ['2026-11-21', '2026-11-21T14', '21/11/2026 14:30', '2026-11-21T14:30:05+5']],
    http_scheme:            [%w[http:// https://], %w[HTTPS:// ftp:// http: https//]],
    dns_label:              [%w[acme mail-1 a 0], ['-acme', 'acme-', 'Acme', 'ac_me', 'acme.example', '']],
    domain_name:            [%w[acme.example mail.acme.co.uk 1.example], %w[acme acme..example .acme.example Acme.example]],
    email_address:          [%w[ada@acme.example a+b@x], ['ada', '@acme.example', 'ada@', 'a da@x', 'a@b@c']],
    backtick_code:          [['`get_order`', '`a b`'], %w[`` `open get_order`]]
  }.freeze

  CASES.each do |name, (matches, refuses)|
    matches.each do |text|
      test "#{name} matches #{text.inspect} whole" do
        assert_match Regexes.public_send(name).whole, text
      end
    end

    refuses.each do |text|
      test "#{name} refuses #{text.inspect} whole" do
        refute_match Regexes.public_send(name).whole, text
      end
    end

    test "#{name} is the same object every time" do
      assert_same Regexes.public_send(name), Regexes.public_send(name)
    end

    test "#{name} is frozen" do
      assert_predicate Regexes.public_send(name), :frozen?
    end
  end

  test 'a folded line break is a CRLF before a space or tab, which it leaves' do
    assert_equal 'Subject: a b', "Subject: a\r\n b".gsub(Regexes.folded_line_break, '')
  end

  test 'an unfolded line break is a CRLF that ends a header' do
    assert_equal ["Subject: a\r\n b", 'To: c'], "Subject: a\r\n b\r\nTo: c".split(Regexes.unfolded_line_break)
  end

  test 'an email address captures its local part and its domain' do
    match = Regexes.email_address.whole.match('ada@acme.example')

    assert_equal %w[ada acme.example], [match[:local], match[:domain]]
  end

  test 'backtick code captures the code' do
    assert_equal 'get_order', Regexes.backtick_code.match('call `get_order` now')[:code]
  end

  test 'three or more newlines are the gap between paragraphs left too far apart' do
    assert_equal "a\n\nb\n\nc", "a\n\nb\n\n\n\nc".gsub(Regexes.newline.at_least(3), "\n\n")
  end

  test 'every pattern named in the library is tested here' do
    named = Regexes.instance_methods(false) - %i[sequence either folded_line_break unfolded_line_break]

    assert_equal named.sort, CASES.keys.sort
  end
end
