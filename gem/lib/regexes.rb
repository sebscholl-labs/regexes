# frozen_string_literal: true

require 'regexes/version'
require 'regexes/expression'
require 'regexes/character_class'
require 'regexes/ecma'

# Regular expressions named for what they match rather than what they are used for, so one is found and reused
# instead of written again inline. Each is a +Regexp+ ({Expression}) with the variations every expression
# allows — anchored, repeated, case-insensitive, captured — and a set of characters can be excluded and added
# to ({CharacterClass}). They chain:
#
#   Regexes.lowercase_alphanumeric.excluded.one_or_more            # => /[^a-z0-9]+/
#   Regexes.lowercase_letters.excluded.one_or_more.leading         # => /\A[^a-z]+/
#   Regexes.sequence(Regexes.letters, Regexes.digits.at_least(2))  # => /[A-Za-z][0-9]{2,}/
#
# What lives here is a shape that recurs: a set of characters, a line break, a UUID, an address. The grammar
# of one format — a bounce address, a log line — belongs in a named constant in the code that owns the format,
# built from these. Each pattern is built once, frozen, as the library loads; a variation is built when asked
# for.
#
# The named patterns are defined by section in +regexes/patterns/+, loaded below in the order they build on
# each other; this file holds what composes them and what adds an application's own.
module Regexes
  extend self

  # ── Composition ─────────────────────────────────────────────────────────────────────────────────────────

  # +Regexes.sequence(Regexes.lowercase_letters, Regexes.word_characters.between(0, 23))+ is a handle: a
  # lowercase letter, then up to 23 more.
  #
  # @param parts [Array<Expression>] what must match, one after another
  # @return [Expression] each part, one after another
  def sequence(*parts) = Expression.new(parts.map(&:embedded).join)

  # +Regexes.either(Regexes.hyphen.one_or_more.leading, Regexes.hyphen.one_or_more.trailing)+ matches the
  # hyphens at either end of a name.
  #
  # @param alternatives [Array<Expression>] what may match, any one of them
  # @return [Expression] any one of the alternatives, as one unit
  def either(*alternatives) = Expression.new("(?:#{alternatives.map(&:embedded).join('|')})", single: true)

  # +Regexes.literal('.ns.cloudflare.com').trailing+ matches a Cloudflare nameserver, and +Regexes.literal('b+')+
  # matches the text +b++, never +bb+: every character stands for itself. It is the safe way to put a value into
  # a pattern, where interpolating it would let its dots and pluses match more than they say.
  #
  # @param text [String] the text to match, character for character
  # @return [Expression] an expression matching exactly +text+
  # @raise [ArgumentError] when +text+ is empty, which would match everywhere
  def literal(text)
    raise ArgumentError, 'literal(""): an empty literal matches everywhere' if text.empty?

    Expression.new(Regexp.escape(text), single: text.length == 1)
  end

  # ── Registration ────────────────────────────────────────────────────────────────────────────────────────

  # The lock around registration, so two threads can't register one name twice.
  REGISTRATION    = Mutex.new
  # A name a pattern may be registered under: snake_case, as every named pattern is.
  REGISTERED_NAME = /\A[a-z][a-z0-9]*(?:_[a-z0-9]+)*\z/
  # An anchor at the start or end of a pattern's source, which a registered pattern leaves to its caller.
  ANCHORED        = /\A(?:\\A|\^)|(?<!\\)(?:\\[zZ]|\$)\z/
  # The +Regexp+ options a registered pattern keeps; encoding flags are left to Ruby.
  KEPT_OPTIONS    = Regexp::IGNORECASE | Regexp::EXTENDED | Regexp::MULTILINE

  # Adds a pattern of an application's own, to be named, varied and composed as the library's are:
  #
  #   Regexes.register(:order_reference, /ORD-[0-9]{6}/)
  #   Regexes.order_reference.whole.match?('ORD-004211')   # => true
  #
  # The pattern is the shape alone, unanchored: anchor it where it's used, with +.whole+ or +.leading+. A
  # +Regexp+ or source +String+ is wrapped in a group, so an alternation in it stays one unit inside a sequence;
  # an {Expression} is kept as it is.
  #
  # @param name [Symbol, String] the name to call it by: snake_case, and not a name +Regexes+ already answers to
  # @param pattern [Regexp, String, Expression] what it matches
  # @return [Expression] the registered pattern, frozen
  # @raise [ArgumentError] when the name isn't snake_case or is taken, or the pattern is anchored
  def register(name, pattern)
    name       = name.to_sym
    expression = registrable(pattern)

    REGISTRATION.synchronize do
      check_registrable_name(name)
      define_method(name) { expression }
      (@registered ||= []) << name
    end

    expression
  end

  # @return [Array<Symbol>] the names registered with {.register}, in the order they were, frozen
  def registered = (@registered || []).dup.freeze

  private

  # @param name [Symbol] a name to register a pattern under
  # @return [void]
  # @raise [ArgumentError] when it isn't snake_case, or +Regexes+ already answers to it
  def check_registrable_name(name)
    raise ArgumentError, "register(#{name.inspect}): name a pattern in snake_case" unless REGISTERED_NAME.match?(name)
    raise ArgumentError, "register(#{name.inspect}): Regexes.#{name} already exists" if respond_to?(name, true)
  end

  # @param pattern [Regexp, String, Expression] a pattern to register
  # @return [Expression] it, as an expression
  # @raise [ArgumentError] when it is anchored, or of another type
  def registrable(pattern)
    source = pattern.is_a?(Regexp) ? pattern.source : pattern
    raise ArgumentError, "register: #{pattern.inspect} is not a Regexp or String" unless source.is_a?(String)
    raise ArgumentError, "register: #{pattern.inspect} is anchored; register the shape and anchor it where used" if
      ANCHORED.match?(source)

    return pattern if pattern.is_a?(Expression)

    options = pattern.is_a?(Regexp) ? pattern.options & KEPT_OPTIONS : 0
    Expression.new("(?:#{source}#{"\n" if options.anybits?(Regexp::EXTENDED)})", single: true, options:)
  end
end

require 'regexes/patterns/sets'
require 'regexes/patterns/breaks'
require 'regexes/patterns/numbers'
require 'regexes/patterns/identifiers'
require 'regexes/patterns/times'
require 'regexes/patterns/network'
require 'regexes/patterns/mail'
require 'regexes/patterns/codes'
require 'regexes/patterns/text'
