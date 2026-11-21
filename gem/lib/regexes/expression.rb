# frozen_string_literal: true

module Regexes
  # A regular expression with the variations every expression allows: anchored at the start of the text, at
  # its end, or both ({#leading}, {#trailing}, {#whole}); repeated ({#one_or_more}, {#zero_or_more},
  # {#optional}, {#exactly}, {#at_least}, {#between}); and matching letters of either case
  # ({#case_insensitive}). It is a +Regexp+, so it goes wherever one does (+gsub+, +match?+, +case+,
  # +validates format:+) as it is.
  #
  # Each variation is a new expression, frozen like the one it came from, so a pattern kept in a constant is
  # never changed by a caller. Anchoring twice at the same end is the same as anchoring once.
  #
  # Repeating an expression repeats all of it: one that is more than a single unit is grouped first
  # (+(?:ab)++), so +ab+ repeated is +abab+, never +abb+. An anchored expression cannot be repeated, since only
  # one stretch of the text starts it; anchor after repeating.
  class Expression < Regexp
    # @param body [String] the expression's source, without anchors
    # @param leading [Boolean] whether it must match at the start of the text
    # @param trailing [Boolean] whether it must match at the end of the text
    # @param single [Boolean] whether the body is one unit a quantifier applies to whole: a set, or a group
    # @param options [Integer] +Regexp+ options, such as +Regexp::IGNORECASE+
    def initialize(body, leading: false, trailing: false, single: false, options: 0)
      @body     = body
      @leading  = leading
      @trailing = trailing
      @single   = single
      super("#{'\A' if leading}#{body}#{'\z' if trailing}", options)
      freeze
    end

    # ── Anchors ─────────────────────────────────────────────────────────────────────────────────────────────

    # +Regexes.lowercase_letters.one_or_more.leading+ matches the +ab+ of +ab1+, never the +cd+ of +1cd+. The
    # start is the text's (+\A+), never a line's (+^+), so a later line cannot satisfy it.
    #
    # @return [Expression] the expression, matching only at the start of the text
    def leading = varied(leading: true)

    # +Regexes.lowercase_letters.one_or_more.trailing+ matches the +cd+ of +1cd+, never the +ab+ of +ab1+.
    # The end is the text's (+\z+), never a line's (+$+), so a final newline is not passed over.
    #
    # @return [Expression] the expression, matching only at the end of the text
    def trailing = varied(trailing: true)

    # +Regexes.lowercase_letters.one_or_more.whole+ matches +abc+, never +abc1+.
    #
    # @return [Expression] the expression, matching only the whole of the text
    def whole = varied(leading: true, trailing: true)

    # @return [Boolean] whether it matches only at the start of the text
    def leading? = @leading

    # @return [Boolean] whether it matches only at the end of the text
    def trailing? = @trailing

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

    # ── Composition ─────────────────────────────────────────────────────────────────────────────────────────

    # The expression as a part of a larger one ({Regexes.sequence}, {Regexes.either}): its source as it is
    # when it has no options, so the larger one reads as it would written out, or with its options carried
    # along (+(?i-mx:…)+) when it has some, so a case-insensitive part stays so inside a case-sensitive whole.
    #
    # @return [String]
    def embedded = options.zero? ? source : to_s

    protected

    # @return [String] the body, as one unit a quantifier applies to whole
    def unit = @single ? @body : "(?:#{@body})"

    private

    # @param changes [Hash{Symbol => Object}] what differs from this expression
    # @return [Expression] this expression with the changes
    def varied(**changes)
      Expression.new(@body,
                     leading:  @leading,
                     trailing: @trailing,
                     single:   @single,
                     options:,
                     **changes)
    end

    # @param quantifier [String] the quantifier, as written after a unit
    # @return [Expression] the expression repeated
    # @raise [ArgumentError] when it is anchored
    def repeated(quantifier)
      raise ArgumentError, "#{inspect} is anchored: repeat it first, then anchor it" if @leading || @trailing

      Expression.new("#{unit}#{quantifier}", options:)
    end
  end
end
