# frozen_string_literal: true

require 'test_helper'

# Tests for a set of characters: what it matches, the characters outside it, and one or more of it.
class RegexesCharacterClassTest < RegexesTestCase
  test 'is the set between brackets' do
    assert_equal '[a-z0-9]', Regexes.lowercase_alphanumeric.source
  end

  test 'matches one character of the set' do
    assert_equal %w[1 a], 'A1a'.scan(Regexes.lowercase_alphanumeric)
  end

  test 'matches nothing outside the set' do
    refute_match Regexes.lowercase_letters, 'ABC 123 _-é'
  end

  test 'excluded matches every character but the set' do
    assert_equal %w[A _ é], 'aA_1é'.scan(Regexes.lowercase_alphanumeric.excluded)
  end

  test 'excluded is a set too, written with a caret' do
    assert_equal '[^a-z0-9]', Regexes.lowercase_alphanumeric.excluded.source
  end

  test 'excluding the excluded gives back the set' do
    assert_equal Regexes.lowercase_letters, Regexes.lowercase_letters.excluded.excluded
  end

  test 'says whether it is excluded' do
    assert_predicate Regexes.lowercase_letters.excluded, :excluded?
  end

  test 'the set is not excluded' do
    refute_predicate Regexes.lowercase_letters, :excluded?
  end

  test 'keeps its members when excluded' do
    assert_equal 'a-z0-9', Regexes.lowercase_alphanumeric.excluded.members
  end

  test 'one or more matches as many in a row as there are, as one match' do
    assert_equal %w[abc de], 'abc1de'.scan(Regexes.lowercase_letters.one_or_more)
  end

  test 'one or more is the set with a plus' do
    assert_equal '[a-z]+', Regexes.lowercase_letters.one_or_more.source
  end

  test 'one or more of the excluded set becomes one underscore in a substitution' do
    assert_equal 'northwind_erp_', 'northwind  erp!!'.gsub(Regexes.lowercase_alphanumeric.excluded.one_or_more, '_')
  end

  test 'one or more is an expression, which can no longer be excluded' do
    refute_respond_to Regexes.lowercase_letters.one_or_more, :excluded
  end

  test 'anchoring the set itself matches one character there' do
    assert_equal 'Bc', 'aBc'.sub(Regexes.lowercase_letters.leading, '')
  end

  test 'including adds characters to the set' do
    assert_equal %w[a 1 _], 'a1_-'.scan(Regexes.lowercase_alphanumeric.including('_'))
  end

  test 'including keeps the set excluded, so the added characters are excluded too' do
    assert_equal %w[a ?], 'a/b?'.scan(Regexes.slash.excluded.including('b'))
  end

  test 'including keeps the set case-insensitive' do
    assert_match Regexes.lowercase_letters.case_insensitive.including('_').whole, 'A'
  end

  test 'a case-insensitive set is still a set, which can be excluded' do
    assert_equal %w[1], 'aA1'.scan(Regexes.lowercase_letters.case_insensitive.excluded)
  end

  test 'a set is repeated without a group around it' do
    assert_equal '[a-z]{2,}', Regexes.lowercase_letters.at_least(2).source
  end

  test 'a variation is frozen' do
    assert_predicate Regexes.lowercase_letters.excluded, :frozen?
  end
end
