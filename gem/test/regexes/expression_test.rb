# frozen_string_literal: true

require 'test_helper'

# Tests for an expression's anchors, and that it goes wherever a Regexp does.
class RegexesExpressionTest < RegexesTestCase
  test 'leading matches only at the start' do
    assert_equal 'ab', 'ab1cd'[Regexes.lowercase_letters.one_or_more.leading]
  end

  test 'leading matches nothing when the start does not match' do
    assert_nil '1cd'[Regexes.lowercase_letters.one_or_more.leading]
  end

  test 'leading is anchored with \A, never ^, so a later line does not count' do
    assert_nil "1\nab"[Regexes.lowercase_letters.one_or_more.leading]
  end

  test 'trailing matches only at the end' do
    assert_equal 'cd', 'ab1cd'[Regexes.lowercase_letters.one_or_more.trailing]
  end

  test 'trailing is anchored with \z, never $, so a final newline does not count' do
    assert_nil "ab\n"[Regexes.lowercase_letters.one_or_more.trailing]
  end

  test 'whole matches the whole text' do
    assert_match Regexes.lowercase_letters.one_or_more.whole, 'abc'
  end

  test 'whole refuses text with anything else in it' do
    refute_match Regexes.lowercase_letters.one_or_more.whole, 'abc1'
  end

  test 'whole leaves out a boundary of one set at the start, where nothing comes before' do
    bounded = Regexes.digits.exactly(3).not_preceded_by(Regexes.letters)

    assert_equal '\\A[0-9]{3}\\z', bounded.whole.source
  end

  test 'whole leaves out a boundary of one set at the end, where nothing comes after' do
    bounded = Regexes.digits.exactly(3).not_followed_by(Regexes.letters)

    assert_equal '\\A[0-9]{3}\\z', bounded.whole.source
  end

  test 'leading keeps the boundary at the end it leaves open' do
    bounded = Regexes.digits.exactly(3).not_preceded_by(Regexes.letters).not_followed_by(Regexes.letters)

    assert_equal '\\A[0-9]{3}(?![A-Za-z])', bounded.leading.source
  end

  test 'a line anchor keeps the boundary, since a line starts after a character' do
    bounded = Regexes.digits.exactly(3).not_preceded_by(Regexes.letters)

    assert_includes bounded.whole_line.source, '(?<![A-Za-z])'
  end

  test 'whole keeps a lookbehind of more than one character' do
    bounded = Regexes.digits.exactly(3).not_preceded_by(Regexes.literal('ab'))

    assert_equal '\\A(?<!ab)[0-9]{3}\\z', bounded.whole.source
  end

  test 'leading and trailing together are whole' do
    assert_equal Regexes.lowercase_letters.one_or_more.whole, Regexes.lowercase_letters.one_or_more.leading.trailing
  end

  test 'anchoring twice at one end is anchoring once' do
    assert_equal '\A[a-z]+', Regexes.lowercase_letters.one_or_more.leading.leading.source
  end

  test 'says where it is anchored' do
    leading = Regexes.lowercase_letters.one_or_more.leading

    assert_equal [true, false], [leading.leading?, leading.trailing?]
  end

  test 'an unanchored expression is anchored nowhere' do
    repeated = Regexes.lowercase_letters.one_or_more

    assert_equal [false, false], [repeated.leading?, repeated.trailing?]
  end

  test 'drops what comes before the first letter' do
    assert_equal 'erp', '42 erp'.sub(Regexes.lowercase_letters.excluded.one_or_more.leading, '')
  end

  test 'is a Regexp' do
    assert_kind_of Regexp, Regexes.lowercase_letters.one_or_more.whole
  end

  test 'equals the literal it stands for' do
    assert_equal(/\A[^a-z]+/, Regexes.lowercase_letters.excluded.one_or_more.leading)
  end

  test 'works in a case statement' do
    text = 'abc'
    kind = case text
           when Regexes.lowercase_letters.one_or_more.whole then :letters
           else :other
           end

    assert_equal :letters, kind
  end

  test 'sets the last match like any Regexp' do
    Regexes.lowercase_letters.one_or_more =~ '12ab'

    assert_equal 'ab', Regexp.last_match(0)
  end

  test 'repeating an expression of several units repeats all of it' do
    assert_equal %w[abab], 'ababb'.scan(Regexes.sequence(Regexes.letters, Regexes.letters).at_least(2))
  end

  test 'repeating a group repeats the group' do
    assert_equal "\r\n\r\n", "\r\n\r\n"[Regexes.line_break.at_least(2)]
  end

  test 'repeating an anchored expression is refused' do
    assert_raises(ArgumentError, match: /repeat it first/) { Regexes.lowercase_letters.leading.one_or_more }
  end

  test 'between refuses a fewest more than the most' do
    assert_raises(ArgumentError) { Regexes.digits.between(3, 1) }
  end

  test 'between, exactly and at least refuse what is not a whole number' do
    assert_raises(ArgumentError) { Regexes.digits.at_least('2; drop') }
  end

  test 'exactly takes that many and no fewer' do
    assert_equal %w[12 34], '12345'.scan(Regexes.digits.exactly(2))
  end

  test 'optional takes it or nothing' do
    assert_match Regexes.sequence(Regexes.hyphen.optional, Regexes.digits.one_or_more).whole, '7'
  end

  test 'case-insensitive keeps its anchors' do
    refute_match Regexes.http_scheme.leading.case_insensitive, 'see HTTPS://acme.example'
  end

  test 'case-insensitive matches either case' do
    assert_match Regexes.http_scheme.leading.case_insensitive, 'HTTPS://acme.example'
  end

  test 'is frozen' do
    assert_predicate Regexes.lowercase_letters.one_or_more.leading, :frozen?
  end

  test 'anchoring leaves the expression it came from as it was' do
    repeated = Regexes.lowercase_letters.one_or_more
    repeated.leading

    assert_equal '[a-z]+', repeated.source
  end

  test 'anchoring an end again replaces its anchor' do
    assert_equal Regexes.digits.whole_line.leading, Regexes.digits.leading.line_trailing
  end

  # ── Line anchors ────────────────────────────────────────────────────────────────────────────────────────

  test 'line leading finds the start of every line' do
    assert_equal %w[ab cd ef], "ab1\ncd2\nef".scan(Regexes.lowercase_letters.one_or_more.line_leading)
  end

  test 'line leading treats CRLF as one line break' do
    assert_equal %w[ab cd], "ab1\r\ncd2".scan(Regexes.lowercase_letters.one_or_more.line_leading)
  end

  test 'line leading treats a lone carriage return as a line break' do
    assert_equal %w[ab cd], "ab1\rcd2".scan(Regexes.lowercase_letters.one_or_more.line_leading)
  end

  test 'line leading never starts a line between the CR and the LF of one break' do
    assert_equal ['', ''], "a\r\nb".scan(Regexes.newline.zero_or_more.line_leading)
  end

  test 'line leading matches at the start of the text' do
    assert_equal 'ab', 'ab1'[Regexes.lowercase_letters.one_or_more.line_leading]
  end

  test 'line leading refuses the middle of a line' do
    assert_nil '1ab'[Regexes.lowercase_letters.one_or_more.line_leading]
  end

  test 'line trailing finds the end of every line' do
    assert_equal %w[1 2 3], "ab1\ncd2\nef3".scan(Regexes.digits.one_or_more.line_trailing)
  end

  test 'line trailing ends a line before a CRLF' do
    assert_equal %w[1 2], "ab1\r\ncd2".scan(Regexes.digits.one_or_more.line_trailing)
  end

  test 'line trailing ends a line before a lone carriage return' do
    assert_equal %w[1 2], "ab1\rcd2".scan(Regexes.digits.one_or_more.line_trailing)
  end

  test 'line trailing never ends a line between the CR and the LF of one break' do
    assert_equal 'ab', "ab\r\n"[Regexes.lowercase_letters.including('\r').one_or_more.line_trailing.leading]
  end

  test 'line trailing matches at the end of the text' do
    assert_equal '1', 'ab1'[Regexes.digits.one_or_more.line_trailing]
  end

  test 'whole line matches only a line with nothing else on it' do
    assert_equal %w[cd], "ab1\ncd\n2ef".scan(Regexes.lowercase_letters.one_or_more.whole_line)
  end

  test 'whole line matches a text of one line' do
    assert_match Regexes.lowercase_letters.one_or_more.whole_line, 'abc'
  end

  test 'says where it is anchored to a line' do
    line = Regexes.digits.line_leading

    assert_equal [true, false, false, false], [line.line_leading?, line.line_trailing?, line.leading?, line.trailing?]
  end

  test 'a whole line is anchored to a line at both ends' do
    line = Regexes.digits.whole_line

    assert_equal [true, true], [line.line_leading?, line.line_trailing?]
  end

  test 'repeating an expression anchored to a line is refused' do
    assert_raises(ArgumentError, match: /repeat it first/) { Regexes.digits.line_leading.one_or_more }
  end

  # ── Captures ────────────────────────────────────────────────────────────────────────────────────────────

  test 'captured reads what it matched by name' do
    assert_equal '2026', Regexes.digits.exactly(4).captured(:year).match('in 2026')[:year]
  end

  test 'captured takes a string name too' do
    assert_equal '2026', Regexes.digits.exactly(4).captured('year').match('in 2026')[:year]
  end

  test 'captured matches what the expression did' do
    assert_equal %w[12 34], '12 34'.scan(Regexes.digits.one_or_more.captured(:number)).flatten
  end

  test 'captured keeps anchors outside the capture' do
    assert_equal '\A(?<year>[0-9]{4})\z', Regexes.digits.exactly(4).whole.captured(:year).source
  end

  test 'captured keeps the case-insensitive option' do
    assert_equal 'ABC', Regexes.lowercase_letters.one_or_more.case_insensitive.captured(:word).match('ABC')[:word]
  end

  test 'a captured expression is one unit, repeated without another group' do
    assert_equal '(?<pair>[0-9][0-9])+', Regexes.sequence(Regexes.digits, Regexes.digits).captured(:pair).one_or_more.source
  end

  test 'a capture inside a sequence is read from the whole match' do
    date = Regexes.sequence(Regexes.digits.exactly(4).captured(:year), Regexes.hyphen,
                            Regexes.digits.exactly(2).captured(:month))

    assert_equal '11', date.match('2026-11')[:month]
  end

  test 'captured refuses a name that cannot name a capture' do
    assert_raises(ArgumentError) { Regexes.digits.captured('2nd year') }
  end

  test 'captured says why it refused the name' do
    assert_raises(ArgumentError, match: /can't name a capture/) { Regexes.digits.captured('a-b') }
  end

  # ── Lookarounds ─────────────────────────────────────────────────────────────────────────────────────────

  test 'followed by matches only where the other comes next' do
    assert_equal "a b\nc", "a\n b\nc".gsub(Regexes.newline.followed_by(Regexes.space_or_tab), '')
  end

  test 'followed by does not take what follows' do
    assert_equal 'http', 'http://'[Regexes.literal('http').followed_by(Regexes.literal('://'))]
  end

  test 'not followed by matches only where the other does not come next' do
    assert_equal %w[http], 'https:// http://'.scan(Regexes.literal('http').not_followed_by(Regexes.literal('s')))
  end

  test 'not followed by gives back repeated characters until it passes' do
    assert_equal %w[7 5], '7 days 50%'.scan(Regexes.digits.one_or_more.not_followed_by(Regexes.literal('%')))
  end

  test 'not followed by refuses the whole run when what it repeats is excluded too' do
    beside = Regexes.either(Regexes.digits, Regexes.literal('%'))

    assert_equal %w[7], '7 days 50%'.scan(Regexes.digits.one_or_more.not_followed_by(beside))
  end

  test 'preceded by matches only where the other comes before' do
    assert_equal %w[5], '$5 6'.scan(Regexes.digits.one_or_more.preceded_by(Regexes.literal('$')))
  end

  test 'preceded by does not take what comes before' do
    assert_equal '5', '$5'[Regexes.digits.preceded_by(Regexes.literal('$'))]
  end

  test 'not preceded by matches only where the other does not come before' do
    assert_equal %w[ada], 'ada @acme'.scan(Regexes.lowercase_letters.one_or_more.not_preceded_by(Regexes.literal('@')).not_preceded_by(Regexes.lowercase_letters))
  end

  test 'preceded by refuses what Ruby cannot look behind' do
    assert_raises(RegexpError) { Regexes.digits.preceded_by(Regexes.letters.one_or_more) }
  end

  test 'a lookaround keeps the anchors' do
    assert_equal '\A[0-9](?=x)\z', Regexes.digits.whole.followed_by(Regexes.literal('x')).source
  end

  test 'a lookaround keeps the case-insensitive option' do
    assert_match Regexes.literal('http').case_insensitive.followed_by(Regexes.literal(':')), 'HTTP:'
  end

  test 'an expression with a lookaround is grouped when repeated' do
    assert_equal '(?:[0-9](?=x))+', Regexes.digits.followed_by(Regexes.literal('x')).one_or_more.source
  end

  test 'a case-insensitive lookahead stays so inside a case-sensitive expression' do
    assert_match Regexes.literal('a').followed_by(Regexes.literal('b').case_insensitive), 'aB'
  end
end
