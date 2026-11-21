# frozen_string_literal: true

module Regexes
  # Raised when an expression uses what ECMAScript has no faithful equivalent for, so translating it would give a
  # pattern that matches something else.
  class UntranslatableError < StandardError; end

  # Translates an expression's Ruby source into ECMAScript's, for +new RegExp(source, flags)+ in JavaScript and
  # for a JSON Schema +pattern+ (see {Expression#ecma_source}).
  #
  # It rewrites what the two write differently: the text's anchors (+\A+, +\z+ become +^+, +$+, which without
  # the +m+ flag anchor to the text in ECMAScript, with no allowance for a final line feed); the dot, which in
  # ECMAScript also refuses +\r+ and the line separators; Ruby's POSIX +[:space:]+ and +\R+; and escapes Ruby
  # allows of characters that need none, which ECMAScript's +u+ mode refuses. What has no equivalent raises
  # {UntranslatableError}: +\X+, atomic groups, inline options, a name captured twice, and Ruby's line anchors.
  module Ecma
    extend self

    # What a Ruby escape outside a character class becomes in ECMAScript, where it differs.
    ESCAPES        = {
      'A' => '^',
      'z' => '$',
      'R' => '(?:\r\n|[\n\v\f\r\x85  ])',
      's' => '[ \t\n\v\f\r]'
    }.freeze
    # What a Ruby escape inside a character class becomes in ECMAScript, where it differs.
    CLASS_ESCAPES  = { 's' => ' \t\n\v\f\r' }.freeze
    # Escapes both write alike: the shorthands both define as Ruby does, and the escapes of characters that
    # mean something in a pattern.
    KEPT           = 'dDwWbBnrtfv0123456789^$\\.*+?()[]{}|/'
    # Escapes ECMAScript has no faithful equivalent for, and why.
    UNTRANSLATABLE = {
      'X' => 'a grapheme cluster (\X)',
      'Z' => 'the end of the text or before its final line feed (\Z)',
      'h' => "Ruby's hex digit (\\h)",
      'H' => "Ruby's non-hex digit (\\H)",
      'G' => 'the end of the last match (\G)',
      'K' => 'a match reset (\K)',
      'g' => 'a subexpression call (\g)'
    }.freeze
    # Group openings both write alike.
    GROUPS         = ['(?:', '(?=', '(?!', '(?<=', '(?<!'].freeze
    # A named capture's opening.
    NAMED_GROUP    = /\A\(\?<([A-Za-z_][A-Za-z0-9_]*)>/
    # A quantifier in braces, which ECMAScript writes as Ruby does; any other brace is a literal to escape.
    QUANTIFIER     = /\A\{[0-9]+(?:,[0-9]*)?\}/
    # A Unicode escape: four hex digits, or any number in braces.
    UNICODE_ESCAPE = /\A\\u(?:[0-9a-fA-F]{4}|\{[0-9a-fA-F]+\})/
    # A back-reference to a named capture, which ECMAScript writes as Ruby does.
    BACK_REFERENCE = /\A\\k<[A-Za-z_][A-Za-z0-9_]*>/

    # @param expression [Expression] an expression
    # @return [String] its source as ECMAScript writes it
    # @raise [UntranslatableError] when it uses what ECMAScript has no faithful equivalent for
    def source(expression) = Translation.new(expression.source).result

    # @param expression [Expression] an expression
    # @return [String] the flags its source needs in ECMAScript: +u+, and +i+ when it ignores case
    # @raise [UntranslatableError] when it is written in extended mode, or matches newlines with +.+
    def flags(expression)
      raise UntranslatableError, "#{expression.inspect} is extended (x), which ECMAScript can't read" if
        expression.options.anybits?(Regexp::EXTENDED)
      raise UntranslatableError, "#{expression.inspect} lets . match newlines (m), which this translation keeps out" if
        expression.options.anybits?(Regexp::MULTILINE)

      expression.options.anybits?(Regexp::IGNORECASE) ? 'iu' : 'u'
    end

    # One source being translated, a character at a time.
    class Translation
      # @param ruby [String] a Ruby regular expression's source
      def initialize(ruby)
        @ruby     = ruby
        @at       = 0
        @in_class = false
        @names    = []
        @result   = +''
      end

      # @return [String] the source as ECMAScript writes it, frozen
      # @raise [UntranslatableError] when it uses what ECMAScript has no faithful equivalent for
      def result
        step while @at < @ruby.length
        @result.freeze
      end

      private

      # Translates what starts at the current character, and moves past it.
      #
      # @return [void]
      def step
        character = @ruby[@at]
        case character
        when '\\' then escape
        when '[' then open_class
        when ']' then @in_class ? close_class : plain(character)
        when '(' then @in_class ? take(character) : group
        else plain(character)
        end
      end

      # @param character [String] a character with no special meaning here, or one translated as it is
      # @return [void]
      def plain(character)
        return take(character) if @in_class

        case character
        when '.' then put('[^\n]', 1)
        when '{' then brace
        when '}', ']' then put("\\#{character}", 1)
        when '^', '$' then untranslatable("Ruby's line anchor (#{character}); use line_leading or line_trailing")
        else take(character)
        end
      end

      # Copies a quantifier in braces as it is, and escapes a brace that starts none.
      #
      # @return [void]
      def brace = QUANTIFIER.match?(@ruby[@at..]) ? copy(QUANTIFIER) : put('\{', 1)

      # @return [void]
      def escape
        letter = @ruby[@at + 1]
        untranslatable(UNTRANSLATABLE.fetch(letter)) if UNTRANSLATABLE.key?(letter)

        case letter
        when 'p', 'P' then property
        when 'u' then copy(UNICODE_ESCAPE)
        when 'k' then back_reference
        when 'x' then put(@ruby[@at, 4], 4)
        else put(escaped(letter), 2)
        end
      end

      # Copies a back-reference to a named capture, which ECMAScript writes alike.
      #
      # @return [void]
      # @raise [UntranslatableError] when it refers to a capture by number
      def back_reference
        untranslatable('a back-reference by number (\k<1>)') unless BACK_REFERENCE.match?(@ruby[@at..])

        copy(BACK_REFERENCE)
      end

      # @param letter [String] the character after a backslash
      # @return [String] that escape as ECMAScript writes it here
      def escaped(letter)
        table = @in_class ? CLASS_ESCAPES : ESCAPES
        return table.fetch(letter) if table.key?(letter)
        return "\\#{letter}" if KEPT.include?(letter) || (@in_class && letter == '-')

        letter
      end

      # Copies a Unicode property escape, +\p{…}+, as it is: the names Ruby and ECMAScript share are written
      # alike.
      #
      # @return [void]
      def property
        close = @ruby.index('}', @at)
        put(@ruby[@at..close], close - @at + 1)
      end

      # @return [void]
      def open_class
        if @in_class
          return put('\p{White_Space}', 9) if @ruby[@at, 9] == '[:space:]'

          untranslatable('a nested character class or POSIX bracket')
        end

        @in_class = true
        take('[')
      end

      # @return [void]
      def close_class
        @in_class = false
        take(']')
      end

      # @return [void]
      def group
        opening = GROUPS.find { @ruby[@at, it.length] == it }
        return put(opening, opening.length) if opening
        return put('(', 1) unless @ruby[@at + 1] == '?'

        named_group
      end

      # Copies a named capture's opening, once for each name.
      #
      # @return [void]
      def named_group
        named = NAMED_GROUP.match(@ruby[@at..])
        untranslatable('an atomic group, inline options or a comment') unless named
        untranslatable("the capture name #{named[1]} used twice") if @names.include?(named[1])

        @names << named[1]
        copy(NAMED_GROUP)
      end

      # @param character [String] the current character, copied as it is
      # @return [void]
      def take(character) = put(character, 1)

      # @param pattern [Regexp] what starts at the current character, anchored at its start
      # @return [void]
      def copy(pattern)
        text = pattern.match(@ruby[@at..])[0]
        put(text, text.length)
      end

      # @param text [String] what to write
      # @param length [Integer] how many characters of the Ruby source it stands for
      # @return [void]
      def put(text, length)
        @result << text
        @at += length
      end

      # @param what [String] what can't be translated
      # @raise [UntranslatableError] always
      def untranslatable(what)
        raise UntranslatableError, "/#{@ruby}/ uses #{what}, which ECMAScript can't match the same way"
      end
    end
  end
end
