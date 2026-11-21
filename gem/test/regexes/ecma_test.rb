# frozen_string_literal: true

require 'test_helper'

# Tests for translating an expression into ECMAScript: what is rewritten, what is kept, and what is refused.
class RegexesEcmaTest < RegexesTestCase
  # ── Rewritten ───────────────────────────────────────────────────────────────────────────────────────────

  {
    'the start of the text'                      => [Regexes.digits.leading, '^[0-9]'],
    'the end of the text'                        => [Regexes.digits.trailing, '[0-9]$'],
    'a whole expression'                         => [Regexes.digits.one_or_more.whole, '^[0-9]+$'],
    'a line start'                               => [Regexes.digits.line_leading, '(?:^|(?<=\n)|(?<=\r)(?!\n))[0-9]'],
    'the dot, which in ECMAScript refuses more'  => [Regexes.any_character, '[^\n]'],
    "Ruby's POSIX space"                         => [Regexes.whitespace, '[\p{White_Space}]'],
    "Ruby's line break escape"                   => [Regexes.unicode_line_break, '(?:\r\n|[\n\v\f\r\x85  ])'],
    "Ruby's whitespace escape, outside a class"  => [Regexes.register(:ecma_spaced, /a\sb/), '(?:a[ \t\n\v\f\r]b)'],
    "Ruby's whitespace escape, inside a class"   => [Regexes.register(:ecma_spaced_set, /[\s,]/), '(?:[ \t\n\v\f\r,])'],
    'an escaped space and hash, which need none' => [Regexes.literal('a b#'), 'a b#'],
    'an escaped hyphen outside a class'          => [Regexes.literal('a-b'), 'a-b'],
    'a brace that starts no quantifier'          => [Regexes.register(:ecma_brace, /a{b}/), '(?:a\{b\})'],
    'a closing bracket outside a class'          => [Regexes.register(:ecma_bracket, 'a]'), '(?:a\])']
  }.each do |what, (expression, ecma)|
    test "rewrites #{what}" do
      assert_equal ecma, expression.ecma_source
    end
  end

  # ── Kept ────────────────────────────────────────────────────────────────────────────────────────────────

  {
    'a quantifier in braces'           => [Regexes.digits.between(2, 6), '[0-9]{2,6}'],
    'an escaped hyphen inside a class' => [Regexes.hyphen, '[\-]'],
    'a Unicode property'               => [Regexes.unicode_letters, '[\p{L}]'],
    'a named capture'                  => [Regexes.digits.captured(:year), '(?<year>[0-9])'],
    'lookarounds'                      => [Regexes.digits.preceded_by(Regexes.literal('$')).not_followed_by(Regexes.letters),
                                           '(?<=\$)[0-9](?![A-Za-z])'],
    'an escaped dot'                   => [Regexes.literal('.'), '\.'],
    'the shorthand digits and word'    => [Regexes.register(:ecma_shorthands, /\d\w/), '(?:\d\w)']
  }.each do |what, (expression, ecma)|
    test "keeps #{what} as it is" do
      assert_equal ecma, expression.ecma_source
    end
  end

  test 'a named back-reference is kept as it is' do
    assert_equal '(?:(?<fence>`+)a\k<fence>)', Regexes.register(:ecma_back_reference, '(?<fence>`+)a\k<fence>').ecma_source
  end

  test 'a back-reference by number is refused' do
    assert_raises(Regexes::UntranslatableError) { Regexes.register(:ecma_numbered, '(a)\k<1>').ecma_source }
  end

  test 'a Unicode escape in braces is kept whole' do
    assert_equal '(?:\u{1F44D})', Regexes.register(:ecma_unicode, '\u{1F44D}').ecma_source
  end

  test 'the source is frozen' do
    assert_predicate Regexes.uuid.ecma_source, :frozen?
  end

  # ── Flags ───────────────────────────────────────────────────────────────────────────────────────────────

  test 'the flags are Unicode' do
    assert_equal 'u', Regexes.uuid.ecma_flags
  end

  test 'the flags ignore case when the expression does' do
    assert_equal 'iu', Regexes.http_scheme.case_insensitive.ecma_flags
  end

  test 'extended mode is refused' do
    assert_raises(Regexes::UntranslatableError) { Regexes.register(:ecma_extended, /a # b/x).ecma_flags }
  end

  test 'a dot that matches newlines is refused' do
    assert_raises(Regexes::UntranslatableError) { Regexes.register(:ecma_dotall, /a.b/m).ecma_flags }
  end

  # ── Refused ─────────────────────────────────────────────────────────────────────────────────────────────

  {
    'a grapheme cluster'               => Regexes.emoji,
    'a name captured twice'            => Regexes.sequence(Regexes.digits.captured(:n), Regexes.digits.captured(:n)),
    'an atomic group'                  => Regexes.register(:ecma_atomic, /(?>ab)/),
    'inline options'                   => Regexes.sequence(Regexes.letters.case_insensitive, Regexes.digits),
    "Ruby's line start"                => Regexes.register(:ecma_caret, 'a|^b'),
    "Ruby's hex digit"                 => Regexes.register(:ecma_hex, /\h/),
    'the end before a final line feed' => Regexes.register(:ecma_end, /a(?=\Z)/),
    'a nested class'                   => Regexes.register(:ecma_nested, '[a[b]]')
  }.each do |what, expression|
    test "refuses #{what}" do
      assert_raises(Regexes::UntranslatableError) { expression.ecma_source }
    end
  end

  test 'says what it refused' do
    assert_raises(Regexes::UntranslatableError, match: /grapheme cluster/) { Regexes.emoji.ecma_source }
  end

  # ── The library ─────────────────────────────────────────────────────────────────────────────────────────

  test 'every named pattern but emoji translates' do
    named        = Regexes.instance_methods(false) - Regexes.registered - %i[sequence either literal register registered]
    untranslated = named.reject do |name|
      Regexes.public_send(name).whole.ecma_source
    rescue Regexes::UntranslatableError
      false
    end

    assert_equal %i[emoji], untranslated
  end
end
