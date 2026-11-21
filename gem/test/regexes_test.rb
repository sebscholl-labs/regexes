# frozen_string_literal: true

require 'test_helper'

# Tests for what each named pattern matches, whole, and what it refuses, and that each is built once.
class RegexesTest < RegexesTestCase
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
    utc_offset:             [%w[Z +05:30 -0500 +00:00 -23:59 +1400],
                             %w[z +5:30 05:00 +24:00 +05:60 +05 +05:3 UTC]],
    iso8601_date:           [%w[2026-11-21 0000-01-01 9999-12-31 2026-02-30 2026-10-10 2026-09-09],
                             %w[2026-00-01 2026-13-01 2026-11-00 2026-11-32 20261121 26-11-21 2026-1-21 2026-11-2
                                2026/11/21 2026-11-21T14:30 +2026-11-21] + ['']],
    iso8601_time:           [%w[14:30 00:00 23:59 14:30:05 23:59:60 14:30:05.1 14:30:05.123456789],
                             %w[24:00 14:60 14:30:61 1430 14 4:30 14:3 14:30:5 14:30. 14:30:05. 14:30:05,5
                                14:30Z T14:30] + ['']],
    iso8601_date_time:      [['2026-11-21T14:30', '2026-11-21 14:30:05.123Z', '2026-11-21T14:30:05-05:00',
                              '2026-11-21T00:00:00Z', '2026-11-21T23:59:60+0530'],
                             ['2026-11-21', '2026-11-21T14', '21/11/2026 14:30', '2026-11-21T14:30:05+5',
                              '2026-11-21T24:00', '2026-13-21T14:30', '2026-11-21t14:30', '2026-11-21T14:30z',
                              '2026-11-21  14:30', '2026-11-21T14:30:05 Z']],
    http_scheme:            [%w[http:// https://], %w[HTTPS:// ftp:// http: https//]],
    dns_label:              [['acme', 'mail-1', 'a', '0', 'xn--bcher-kva', 'a' * 63, "a#{'-' * 61}a"],
                             ['-acme', 'acme-', 'Acme', 'ac_me', 'acme.example', '', 'a' * 64, 'ac me', 'äcme']],
    domain_name:            [['acme.example', 'mail.acme.co.uk', '1.example', 'xn--bcher-kva.example',
                              "#{'a' * 63}.example", "#{(['a' * 63] * 3).join('.')}.#{'b' * 61}"],
                             ['acme', 'acme..example', '.acme.example', 'Acme.example', 'acme.example.',
                              "#{'a' * 64}.example", "#{(['a' * 63] * 3).join('.')}.#{'b' * 62}",
                              'acme-.example', '-acme.example', 'ac_me.example', '']],
    email_address:          [%w[ada@acme.example a+b@x ada.lovelace@acme.example ADA@ACME.EXAMPLE a@mail.acme.co.uk
                                user!#$%&'*+/=?^_`{|}~-@x .a@x a..b@x a@1.2.3.4],
                             ['ada', '@acme.example', 'ada@', 'a da@x', 'a@b@c', 'ada@acme..example',
                              'ada@-acme.example', 'ada@acme-.example', 'ada@acme.example.', 'ada@acme_x.example',
                              '"ada"@acme.example', 'ada@[127.0.0.1]', 'adä@acme.example', 'ada@äcme.example',
                              "ada@#{'a' * 64}.example", 'ada(x)@acme.example', '']],
    markdown_code_span:     [['`get_order`', '`a b`', '` `', '`<b>`'], ['``', '`open get_order', 'get_order', '```']]
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

    test "#{name} whole refuses its first match with a line feed after it" do
      refute_match Regexes.public_send(name).whole, "#{matches.first}\n"
    end

    test "#{name} whole refuses its first match with a space before it" do
      refute_match Regexes.public_send(name).whole, " #{matches.first}"
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

  test 'an email address in text is found without the words around it' do
    assert_equal 'ada@acme.example', 'write to ada@acme.example today'[Regexes.email_address]
  end

  test 'a domain name of 253 characters within longer text is not cut short to fit' do
    assert_nil "#{(['a' * 63] * 3).join('.')}.#{'b' * 62}"[Regexes.domain_name.leading]
  end

  test 'a markdown code span captures the code' do
    assert_equal 'get_order', Regexes.markdown_code_span.match('call `get_order` now')[:code]
  end

  test 'three or more newlines are the gap between paragraphs left too far apart' do
    assert_equal "a\n\nb\n\nc", "a\n\nb\n\n\n\nc".gsub(Regexes.newline.at_least(3), "\n\n")
  end

  # ── Composition ─────────────────────────────────────────────────────────────────────────────────────────

  test 'a sequence reads as it would written out' do
    assert_equal(/[a-z][A-Za-z0-9_]{0,23}/, Regexes.sequence(Regexes.lowercase_letters,
                                                             Regexes.word_characters.between(0, 23)))
  end

  test 'a sequence matches its parts one after another' do
    handle = Regexes.sequence(Regexes.lowercase_letters, Regexes.word_characters.between(0, 3)).whole

    assert_equal([true, true, false, false], %w[a abcd abcde 1abc].map { handle.match?(it) })
  end

  test 'a case-insensitive part stays so inside a case-sensitive sequence' do
    link = Regexes.sequence(Regexes.http_scheme.case_insensitive, Regexes.lowercase_letters.one_or_more)

    assert_equal([true, false], ['HTTP://acme', 'http://ACME'].map { link.match?(it) })
  end

  test 'a sequence keeps an anchored part anchored' do
    refute_match Regexes.sequence(Regexes.digits.leading, Regexes.letters), 'x1a'
  end

  test 'either matches any one of its alternatives' do
    ends = Regexes.either(Regexes.hyphen.one_or_more.leading, Regexes.hyphen.one_or_more.trailing)

    assert_equal 'acme-mail', '--acme-mail-'.gsub(ends, '')
  end

  test 'either is one unit, so repeating it repeats the choice' do
    assert_equal %w[abab], 'abab'.scan(Regexes.either(Regexes.sequence(Regexes.letters, Regexes.letters)).one_or_more)
  end

  test 'either can be anchored whole' do
    digit_or_letter = Regexes.either(Regexes.digits, Regexes.letters).whole

    assert_equal([true, true, false], %w[1 a 1a].map { digit_or_letter.match?(it) })
  end

  test 'a composition is an expression, with all its variations' do
    assert_kind_of Regexes::Expression, Regexes.sequence(Regexes.letters)
  end

  # ── The catalog ─────────────────────────────────────────────────────────────────────────────────────────

  test 'every pattern named in the library is tested here' do
    named = Regexes.instance_methods(false) - %i[sequence either folded_line_break unfolded_line_break]

    assert_equal named.sort, CASES.keys.sort
  end
end
