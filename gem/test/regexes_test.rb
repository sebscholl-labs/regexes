# frozen_string_literal: true

require 'test_helper'

# Tests for what lib/regexes.rb holds: composition, literals and registration, and that every named pattern is
# defined by section in lib/regexes/patterns/ (where each is tested, in test/regexes/patterns/).
class RegexesTest < RegexesTestCase
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

  # ── Literals ────────────────────────────────────────────────────────────────────────────────────────────

  test 'a literal matches its text' do
    assert_match Regexes.literal('b+').whole, 'b+'
  end

  test 'a literal takes every character for itself' do
    refute_match Regexes.literal('b+').whole, 'bb'
  end

  test 'a literal dot is a dot, never any character' do
    refute_match Regexes.literal('.ns.cloudflare.com').trailing, 'xnsxcloudflarexcom'
  end

  test 'a literal escapes every character a regex gives meaning to' do
    text = '.*+?^$|()[]{}\\/-# '

    assert_match Regexes.literal(text).whole, text
  end

  test 'a literal of one character is one unit, repeated without a group' do
    assert_equal '\.+', Regexes.literal('.').one_or_more.source
  end

  test 'a literal of several characters is grouped when repeated' do
    assert_equal %w[abab], 'ababa'.scan(Regexes.literal('ab').one_or_more)
  end

  test 'a literal refuses an empty text' do
    assert_raises(ArgumentError) { Regexes.literal('') }
  end

  # ── Registration ────────────────────────────────────────────────────────────────────────────────────────
  #
  # Registering changes Regexes for the rest of the run, so each test registers a name of its own.

  test 'a registered pattern is called by its name' do
    Regexes.register(:registered_order_reference, /ORD-[0-9]{6}/)

    assert_match Regexes.registered_order_reference.whole, 'ORD-004211'
  end

  test 'register takes the name as a string too' do
    Regexes.register('registered_from_string', /x/)

    assert_respond_to Regexes, :registered_from_string
  end

  test 'register returns the registered pattern' do
    pattern = Regexes.register(:registered_returned, /x/)

    assert_same pattern, Regexes.registered_returned
  end

  test 'a registered pattern is an expression, with every variation' do
    Regexes.register(:registered_ticket, /T[0-9]+/)

    assert_equal %w[T1 T22], 'T1, T22 and x'.scan(Regexes.registered_ticket.not_followed_by(Regexes.letters))
  end

  test 'a registered pattern is frozen' do
    assert_predicate Regexes.register(:registered_frozen, /x/), :frozen?
  end

  test 'a registered pattern is the same object every time' do
    Regexes.register(:registered_same, /x/)

    assert_same Regexes.registered_same, Regexes.registered_same
  end

  test 'a registered alternation stays one unit inside a sequence' do
    Regexes.register(:registered_prefix, /ORD|REF/)

    refute_match Regexes.sequence(Regexes.registered_prefix, Regexes.digits).whole, 'ORD'
  end

  test 'a registered pattern keeps its case-insensitive option' do
    assert_match Regexes.register(:registered_insensitive, /ord/i).whole, 'ORD'
  end

  test 'a registered extended pattern keeps a trailing comment out of the way' do
    assert_match Regexes.register(:registered_extended, /a b # the letters/x).whole, 'ab'
  end

  test 'a pattern registered from a string matches that source' do
    assert_match Regexes.register(:registered_source, '[0-9]{3}').whole, '123'
  end

  test 'a registered expression is kept as it is' do
    expression = Regexes.sequence(Regexes.letters, Regexes.digits)

    assert_same expression, Regexes.register(:registered_expression, expression)
  end

  test 'registered lists the names registered, in order' do
    Regexes.register(:registered_listed_first, /x/)
    Regexes.register(:registered_listed_second, /x/)

    assert_equal %i[registered_listed_first registered_listed_second],
                 Regexes.registered.grep(/\Aregistered_listed_/)
  end

  test 'registered is frozen' do
    assert_predicate Regexes.registered, :frozen?
  end

  test 'register refuses the name of a named pattern' do
    assert_raises(ArgumentError, match: /already exists/) { Regexes.register(:uuid, /x/) }
  end

  test 'register refuses a name Regexes answers to as a module' do
    assert_raises(ArgumentError, match: /already exists/) { Regexes.register(:name, /x/) }
  end

  test 'register refuses a name already registered' do
    Regexes.register(:registered_twice, /x/)

    assert_raises(ArgumentError, match: /already exists/) { Regexes.register(:registered_twice, /y/) }
  end

  test 'register refuses a name that is not snake_case' do
    assert_raises(ArgumentError, match: /snake_case/) { Regexes.register(:OrderReference, /x/) }
  end

  {
    'a caret'                  => /^x/,
    'a dollar'                 => /x$/,
    'the start of the text'    => /\Ax/,
    'the end of the text'      => /x\z/,
    'the end before a newline' => /x\Z/,
    'a whole expression'       => Regexes.digits.whole,
    'a string'                 => '\Ax'
  }.each do |anchor, pattern|
    test "register refuses a pattern anchored with #{anchor}" do
      assert_raises(ArgumentError, match: /anchored/) { Regexes.register(:registered_anchored, pattern) }
    end
  end

  test 'register takes an escaped dollar at the end as a dollar' do
    assert_match Regexes.register(:registered_price, /[0-9]+\$/).whole, '5$'
  end

  test 'register refuses what is not a pattern' do
    assert_raises(ArgumentError, match: /not a Regexp or String/) { Regexes.register(:registered_number, 42) }
  end

  # ── The catalog ─────────────────────────────────────────────────────────────────────────────────────────

  test 'only composition, literals and registration are defined outside the sections under patterns/' do
    outside = (Regexes.instance_methods(false) - Regexes.registered).reject do |name|
      Regexes.instance_method(name).source_location.first.include?('/regexes/patterns/')
    end

    assert_equal %i[either literal register registered sequence], outside.sort
  end
end
