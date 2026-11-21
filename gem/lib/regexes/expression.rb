# frozen_string_literal: true

module Regexes
  # A regular expression with the variations every expression allows: anchored at the start or end of the text
  # ({#leading}, {#trailing}, {#whole}) or of a line ({#line_leading}, {#line_trailing}, {#whole_line});
  # repeated ({#one_or_more}, {#zero_or_more}, {#optional}, {#exactly}, {#at_least}, {#between}); matching
  # letters of either case ({#case_insensitive}); captured under a name ({#captured}); and matching only where
  # something else does or doesn't come before or after it ({#followed_by}, {#not_followed_by},
  # {#preceded_by}, {#not_preceded_by}). It is a +Regexp+, so it goes wherever one does (+gsub+, +match?+,
  # +case+, +validates format:+) as it is.
  #
  # Each variation is a new expression, frozen like the one it came from, so a pattern kept in a constant is
  # never changed by a caller. Each end has at most one anchor: anchoring an end again replaces its anchor, so
  # anchoring twice the same way is anchoring once.
  #
  # Repeating an expression repeats all of it: one that is more than a single unit is grouped first
  # (+(?:ab)++), so +ab+ repeated is +abab+, never +abb+. An anchored expression cannot be repeated, since only
  # one stretch of the text (or of a line) starts it; anchor after repeating.
  #
  # A body never holds an alternation at its top level: one is wrapped in +(?:…)+ and built with +single: true+,
  # so a body can be followed, preceded or placed in a sequence as it is.
  class Expression < Regexp
    # What each kind of anchor writes at the start. A line starts at the start of the text, after a line feed,
    # and after a carriage return that no line feed follows, so +\r\n+, +\r+ and +\n+ each end one line.
    STARTS          = {
      text: '\A',
      line: '(?:\A|(?<=\n)|(?<=\r)(?!\n))'
    }.freeze
    # What each kind of anchor writes at the end. A line ends at the end of the text, before a carriage return,
    # and before a line feed that no carriage return comes before.
    ENDS            = {
      text: '\z',
      line: '(?:(?=\r|\z)|(?<!\r)(?=\n))'
    }.freeze
    # What a capture's name may be: what Ruby allows as one, and what +MatchData#[]+ reads by.
    CAPTURE_NAME    = /\A[A-Za-z_][A-Za-z0-9_]*\z/
    # A negative lookbehind of one bracketed set, opening a body. It refuses one character before the match,
    # so at the start of the text, where there is none, it always holds.
    EDGE_LOOKBEHIND = /\A\(\?<!\[(?:\\.|[^\]\\])+\]\)/
    # A negative lookahead of one bracketed set, closing a body. It refuses one character after the match, so
    # at the end of the text it always holds.
    EDGE_LOOKAHEAD  = /\(\?!\[(?:\\.|[^\]\\])+\]\)\z/

    # @param body [String] the expression's source, without anchors
    # @param start [Symbol, nil] where it must match from: +:text+ (the text's start), +:line+ (a line's) or nil
    # @param finish [Symbol, nil] where it must match to: +:text+ (the text's end), +:line+ (a line's) or nil
    # @param single [Boolean] whether the body is one unit a quantifier applies to whole: a set, or a group
    # @param options [Integer] +Regexp+ options, such as +Regexp::IGNORECASE+
    def initialize(body, start: nil, finish: nil, single: false, options: 0)
      @body   = body
      @start  = start
      @finish = finish
      @single = single
      super("#{STARTS.fetch(start) if start}#{edged(body, start, finish)}#{ENDS.fetch(finish) if finish}", options)
      freeze
    end

    # ── Anchors ─────────────────────────────────────────────────────────────────────────────────────────────

    # +Regexes.lowercase_letters.one_or_more.leading+ matches the +ab+ of +ab1+, never the +cd+ of +1cd+. The
    # start is the text's (+\A+), never a line's (+^+), so a later line cannot satisfy it.
    #
    # @return [Expression] the expression, matching only at the start of the text
    def leading = varied(start: :text)

    # +Regexes.lowercase_letters.one_or_more.trailing+ matches the +cd+ of +1cd+, never the +ab+ of +ab1+.
    # The end is the text's (+\z+), never a line's (+$+), so a final newline is not passed over.
    #
    # @return [Expression] the expression, matching only at the end of the text
    def trailing = varied(finish: :text)

    # +Regexes.lowercase_letters.one_or_more.whole+ matches +abc+, never +abc1+.
    #
    # @return [Expression] the expression, matching only the whole of the text
    def whole = varied(start: :text, finish: :text)

    # +Regexes.lowercase_letters.one_or_more.line_leading+ finds +ab+ and +cd+ in +"ab1\r\ncd2"+: the start of
    # each line, whether lines end in +\r\n+, +\r+ or +\n+. Unlike +^+, it never finds a line between the
    # +\r+ and the +\n+ of one line break.
    #
    # @return [Expression] the expression, matching only at the start of a line
    def line_leading = varied(start: :line)

    # +Regexes.digits.one_or_more.line_trailing+ finds +1+ and +2+ in +"ab1\r\ncd2"+: the end of each line.
    # Unlike +$+, it ends a line before a +\r\n+ or a lone +\r+, never only before a +\n+.
    #
    # @return [Expression] the expression, matching only at the end of a line
    def line_trailing = varied(finish: :line)

    # +Regexes.lowercase_letters.one_or_more.whole_line+ finds +cd+ in +"ab1\ncd"+, never +ab+.
    #
    # @return [Expression] the expression, matching only a whole line
    def whole_line = varied(start: :line, finish: :line)

    # @return [Boolean] whether it matches only at the start of the text
    def leading? = @start == :text

    # @return [Boolean] whether it matches only at the end of the text
    def trailing? = @finish == :text

    # @return [Boolean] whether it matches only at the start of a line
    def line_leading? = @start == :line

    # @return [Boolean] whether it matches only at the end of a line
    def line_trailing? = @finish == :line

    # ── Repetition ──────────────────────────────────────────────────────────────────────────────────────────

    # +Regexes.lowercase_letters.one_or_more+ matches +abc+ in +abc1+ as one match, not three.
    #
    # @return [Expression] one or more of it in a row, as many as there are
    def one_or_more = repeated('+')

    # @return [Expression] none or more of it in a row, as many as there are
    def zero_or_more = repeated('*')

    # @return [Expression] it, or nothing
    def optional = repeated('?')

    # @param count [Integer] how many
    # @return [Expression] exactly +count+ of it in a row
    def exactly(count) = repeated("{#{Integer(count)}}")

    # +Regexes.newline.at_least(3)+ matches three or more newlines in a row, never two.
    #
    # @param count [Integer] the fewest
    # @return [Expression] +count+ or more of it in a row, as many as there are
    def at_least(count) = repeated("{#{Integer(count)},}")

    # +Regexes.any_character.between(1, 255)+ takes up to 255 characters at a time.
    #
    # @param min [Integer] the fewest
    # @param max [Integer] the most
    # @return [Expression] from +min+ to +max+ of it in a row, as many as there are
    # @raise [ArgumentError] when +min+ is more than +max+
    def between(min, max)
      raise ArgumentError, "between(#{min}, #{max}): the fewest is more than the most" if Integer(min) > Integer(max)

      repeated("{#{min},#{max}}")
    end

    # ── Case ────────────────────────────────────────────────────────────────────────────────────────────────

    # +Regexes.http_scheme.case_insensitive+ matches +HTTPS://+ as well as +https://+.
    #
    # @return [Expression] the expression, matching letters of either case
    def case_insensitive = varied(options: options | IGNORECASE)

    # ── Captures ────────────────────────────────────────────────────────────────────────────────────────────

    # +Regexes.digits.one_or_more.captured(:year)+ matches what it did, and +match[:year]+ reads it. Anchors
    # stay outside the capture, so it holds only the text matched.
    #
    # @param name [Symbol, String] the capture's name: a letter or underscore, then letters, digits and
    #   underscores
    # @return [Expression] the expression, its match captured under +name+
    # @raise [ArgumentError] when +name+ can't name a capture
    def captured(name)
      raise ArgumentError, "#{name.inspect} can't name a capture: use letters, digits and _" unless
        CAPTURE_NAME.match?(name.to_s)

      Expression.new("(?<#{name}>#{@body})", start: @start, finish: @finish, single: true, options:)
    end

    # ── Lookarounds ─────────────────────────────────────────────────────────────────────────────────────────

    # +Regexes.newline.followed_by(Regexes.space_or_tab)+ matches a line feed that a space or tab comes after,
    # and takes only the line feed.
    #
    # @param other [Expression] what must come right after it
    # @return [Expression] the expression, matching only where +other+ comes next, which it doesn't take
    def followed_by(other) = looking("#{@body}(?=#{other.embedded})")

    # +Regexes.literal('http').not_followed_by(Regexes.literal('s'))+ matches the +http+ of +http://+, never of
    # +https://+.
    #
    # A repeated expression gives back what it took until the lookaround passes: +digits.one_or_more+ not followed
    # by +%+ still matches the +5+ of +50%+. Exclude what it repeats too
    # (+not_followed_by(Regexes.either(Regexes.digits, Regexes.literal('%')))+) to refuse the whole run.
    #
    # @param other [Expression] what must not come right after it
    # @return [Expression] the expression, matching only where +other+ doesn't come next
    def not_followed_by(other) = looking("#{@body}(?!#{other.embedded})")

    # +Regexes.digits.one_or_more.preceded_by(Regexes.literal('$'))+ matches the +5+ of +$5+, and takes only
    # the digits. Ruby allows only what has a known length, or alternatives each of one, before a match.
    #
    # @param other [Expression] what must come right before it
    # @return [Expression] the expression, matching only where +other+ comes before, which it doesn't take
    # @raise [RegexpError] when +other+ can match texts of different lengths in a way Ruby can't look behind
    def preceded_by(other) = looking("(?<=#{other.embedded})#{@body}")

    # +Regexes.lowercase_letters.one_or_more.not_preceded_by(Regexes.literal('@'))+ matches the +ada+ of
    # +ada+, never the +acme+ of +@acme+.
    #
    # @param other [Expression] what must not come right before it
    # @return [Expression] the expression, matching only where +other+ doesn't come before
    # @raise [RegexpError] when +other+ can match texts of different lengths in a way Ruby can't look behind
    def not_preceded_by(other) = looking("(?<!#{other.embedded})#{@body}")

    # ── Composition ─────────────────────────────────────────────────────────────────────────────────────────

    # The expression as a part of a larger one ({Regexes.sequence}, {Regexes.either}): its source as it is
    # when it has no options, so the larger one reads as it would written out, or with its options carried
    # along (+(?i-mx:…)+) when it has some, so a case-insensitive part stays so inside a case-sensitive whole.
    #
    # @return [String]
    def embedded = options.zero? ? source : to_s

    # ── ECMAScript ──────────────────────────────────────────────────────────────────────────────────────────

    # The expression as ECMAScript writes it, for JavaScript (+new RegExp(source, flags)+, with {#ecma_flags})
    # and for a JSON Schema +pattern+. Anchors become +^+ and +$+, which there anchor to the text:
    #
    #   Regexes.uuid.whole.ecma_source   # => "^[0-9a-fA-F]{8}-…-[0-9a-fA-F]{12}$"
    #
    # A JSON Schema +pattern+ searches, as an unanchored expression does, so give it a +.whole+ expression's.
    #
    # @return [String] the source, frozen
    # @raise [UntranslatableError] when it uses what ECMAScript has no faithful equivalent for (+\X+, a name
    #   captured twice, atomic groups, inline options), rather than translate it into something else
    def ecma_source = Ecma.source(self)

    # @return [String] the flags {#ecma_source} needs: +u+ (Unicode, for its property escapes and strict
    #   escapes), and +i+ when the expression ignores case
    # @raise [UntranslatableError] when it is in extended mode or lets +.+ match newlines
    def ecma_flags = Ecma.flags(self)

    protected

    # @return [String] the body, as one unit a quantifier applies to whole
    def unit = @single ? @body : "(?:#{@body})"

    private

    # The body as written between the anchors: a boundary at an end anchored to the text is left out, since
    # nothing lies past that end for it to refuse. Searching keeps every boundary; the match is the same.
    #
    # @param body [String] the expression's source, without anchors
    # @param start [Symbol, nil] the start's anchor, as for {#initialize}
    # @param finish [Symbol, nil] the end's anchor, as for {#initialize}
    # @return [String] the body without the boundaries its text anchors make redundant
    def edged(body, start, finish)
      body = body.sub(EDGE_LOOKBEHIND, '') if start == :text
      body = body.sub(EDGE_LOOKAHEAD, '') if finish == :text
      body
    end

    # @param changes [Hash{Symbol => Object}] what differs from this expression
    # @return [Expression] this expression with the changes
    def varied(**changes)
      Expression.new(@body,
                     start:   @start,
                     finish:  @finish,
                     single:  @single,
                     options:,
                     **changes)
    end

    # @param body [String] the body with a lookaround before or after it
    # @return [Expression] an expression of that body, anchored as this one is
    def looking(body) = Expression.new(body, start: @start, finish: @finish, options:)

    # @param quantifier [String] the quantifier, as written after a unit
    # @return [Expression] the expression repeated
    # @raise [ArgumentError] when it is anchored
    def repeated(quantifier)
      raise ArgumentError, "#{inspect} is anchored: repeat it first, then anchor it" if @start || @finish

      Expression.new("#{unit}#{quantifier}", options:)
    end
  end
end
