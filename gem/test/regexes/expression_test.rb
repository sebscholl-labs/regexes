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
end
