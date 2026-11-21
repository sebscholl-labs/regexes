# frozen_string_literal: true

require 'test_helper'

module Regexes
  # Tests for building one expression of several: one part after another, and any one of several.
  class CompositionTest < TestCase
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
      assert_kind_of Expression, Regexes.sequence(Regexes.letters)
    end
  end
end
