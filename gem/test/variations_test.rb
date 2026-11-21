# frozen_string_literal: true

require 'test_helper'

module Regexes
  # Every chain of variations the library allows, on every set of characters it names, checked against the
  # regular expression it stands for written out by hand: the same source, the same matches on texts chosen
  # to tell them apart, and frozen. A variation that composed wrongly — an anchor lost, a quantifier on the
  # wrong unit, a flag dropped — would differ from the written-out expression on one of them.
  class VariationsTest < TestCase
    # Each set, with its members as written between brackets.
    SETS        = {
      lowercase_letters:      'a-z',
      letters:                'A-Za-z',
      digits:                 '0-9',
      lowercase_alphanumeric: 'a-z0-9',
      alphanumeric:           'A-Za-z0-9',
      word_characters:        'A-Za-z0-9_',
      hex_digits:             '0-9a-fA-F',
      whitespace:             '[:space:]',
      space_or_tab:           ' \t',
      newline:                '\n',
      slash:                  '/',
      hyphen:                 '\-'
    }.freeze
    # Each repetition: the calls that make it, and the quantifier it writes.
    REPETITIONS = {
      none:         [[], ''],
      one_or_more:  [[[:one_or_more]], '+'],
      zero_or_more: [[[:zero_or_more]], '*'],
      optional:     [[[:optional]], '?'],
      exactly:      [[[:exactly, 2]], '{2}'],
      at_least:     [[[:at_least, 2]], '{2,}'],
      between:      [[[:between, 1, 3]], '{1,3}']
    }.freeze
    # Each anchoring: the calls that make it, and the anchors it writes before and after.
    ANCHORS     = {
      none:              [[], '', ''],
      leading:           [[[:leading]], '\A', ''],
      trailing:          [[[:trailing]], '', '\z'],
      whole:             [[[:whole]], '\A', '\z'],
      leading_trailing:  [[[:leading], [:trailing]], '\A', '\z'],
      trailing_leading:  [[[:trailing], [:leading]], '\A', '\z'],
      leading_twice:     [[[:leading], [:leading]], '\A', ''],
      whole_and_leading: [[[:whole], [:leading]], '\A', '\z']
    }.freeze
    # Texts that tell the chains apart: empty, every kind of character a set names, the same at either end
    # only, runs of each length, and line breaks where an anchor would be fooled by +^+ or +$+.
    TEXTS       = [
      '', 'a', 'A', 'z', '0', '9', '_', 'f', 'G', ' ', "\t", "\n", '/', '-', 'é', "\u00A0",
      'ab', 'abc1', '1abc', 'aB3_-', 'ABC', '--', '---', 'a/b/c', "a\nb", "\nab", "ab\n", "a\tb c",
      '12', '123', 'deadBEEF', '  x  ', "x\n\n\ny"
    ].freeze

    SETS.each do |name, members|
      [false, true].each do |excluded|
        [false, true].each do |insensitive|
          REPETITIONS.each do |repetition, (repeats, quantifier)|
            ANCHORS.each do |anchoring, (anchors, before, after)|
              chain    = [name, ('excluded' if excluded), repetition, anchoring, ('case_insensitive' if insensitive)]
              expected = Regexp.new("#{before}[#{'^' if excluded}#{members}]#{quantifier}#{after}",
                                    insensitive ? Regexp::IGNORECASE : 0)

              test "#{chain.compact.join(' ')} is #{expected.inspect}" do
                set     = Regexes.public_send(name)
                set     = set.excluded if excluded
                set     = set.case_insensitive if insensitive
                pattern = (repeats + anchors).reduce(set) { |chain, call| chain.public_send(*call) }

                assert_equal [expected, TEXTS.map { it.scan(expected) }, true],
                             [pattern, TEXTS.map { it.scan(pattern) }, pattern.frozen?]
              end
            end
          end
        end
      end
    end

    test 'case-insensitive after repeating and anchoring is the same as before' do
      before = Regexes.lowercase_letters.case_insensitive.one_or_more.whole
      after  = Regexes.lowercase_letters.one_or_more.whole.case_insensitive

      assert_equal before, after
    end

    test 'every set excluded twice is the set' do
      SETS.each_key { assert_equal Regexes.public_send(it), Regexes.public_send(it).excluded.excluded }
    end
  end
end
