# frozen_string_literal: true

require 'regexes/version'
require 'regexes/expression'
require 'regexes/character_class'

# Regular expressions named for what they match rather than what they are used for, so one is found and reused
# instead of written again inline. Each is a +Regexp+ ({Expression}) with the variations every expression
# allows — anchored, repeated, case-insensitive — and a set of characters can be excluded and added to
# ({CharacterClass}). They chain:
#
#   Regexes.lowercase_alphanumeric.excluded.one_or_more            # => /[^a-z0-9]+/
#   Regexes.lowercase_letters.excluded.one_or_more.leading         # => /\A[^a-z]+/
#   Regexes.sequence(Regexes.letters, Regexes.digits.at_least(2))  # => /[A-Za-z][0-9]{2,}/
#
# What lives here is a shape that recurs: a set of characters, a line break, a UUID, an address. The grammar
# of one format — a bounce address, a log line — belongs in a named constant in the code that owns the format,
# built from these. Each pattern is built once, frozen, as the library loads; a variation is built when asked
# for.
module Regexes
  extend self

  # ── Sets of characters ──────────────────────────────────────────────────────────────────────────────────

  LOWERCASE_LETTERS      = CharacterClass.new('a-z')
  LETTERS                = CharacterClass.new('A-Za-z')
  DIGITS                 = CharacterClass.new('0-9')
  LOWERCASE_ALPHANUMERIC = CharacterClass.new('a-z0-9')
  ALPHANUMERIC           = CharacterClass.new('A-Za-z0-9')
  WORD_CHARACTERS        = CharacterClass.new('A-Za-z0-9_')
  HEX_DIGITS             = CharacterClass.new('0-9a-fA-F')
  WHITESPACE             = CharacterClass.new('[:space:]')
  SPACE_OR_TAB           = CharacterClass.new(' \t')
  NEWLINE                = CharacterClass.new('\n')
  SLASH                  = CharacterClass.new('/')
  HYPHEN                 = CharacterClass.new('\-')

  # +Regexes.lowercase_letters+ matches the +a+ of +A1a+.
  #
  # @return [CharacterClass] one lowercase ASCII letter, +a+ to +z+
  def lowercase_letters = LOWERCASE_LETTERS

  # @return [CharacterClass] one ASCII letter of either case
  def letters = LETTERS

  # @return [CharacterClass] one ASCII digit, +0+ to +9+ (never another script's digits, as +\d+ can be)
  def digits = DIGITS

  # +Regexes.lowercase_alphanumeric+ matches the +a+ and the +1+ of +A1a+.
  #
  # @return [CharacterClass] one lowercase ASCII letter or ASCII digit
  def lowercase_alphanumeric = LOWERCASE_ALPHANUMERIC

  # @return [CharacterClass] one ASCII letter of either case or ASCII digit
  def alphanumeric = ALPHANUMERIC

  # @return [CharacterClass] one ASCII letter, ASCII digit or underscore: what +\w+ matches in Ruby
  def word_characters = WORD_CHARACTERS

  # @return [CharacterClass] one hexadecimal digit, +0+ to +9+ and +a+ to +f+ of either case
  def hex_digits = HEX_DIGITS

  # @return [CharacterClass] one whitespace character of any script: spaces, tabs, line breaks, and the
  #   no-break and wide spaces a web page holds
  def whitespace = WHITESPACE

  # @return [CharacterClass] one space or tab: what RFC 5322 calls WSP, which folds a mail header
  def space_or_tab = SPACE_OR_TAB

  # +Regexes.newline.at_least(3)+ matches the blank lines between paragraphs left too far apart.
  #
  # @return [CharacterClass] one line feed, +\n+
  def newline = NEWLINE

  # +Regexes.slash.excluded.one_or_more+ matches one segment of a path.
  #
  # @return [CharacterClass] one forward slash
  def slash = SLASH

  # @return [CharacterClass] one hyphen-minus, +-+
  def hyphen = HYPHEN

  # ── Characters and breaks ───────────────────────────────────────────────────────────────────────────────

  ANY_CHARACTER       = Expression.new('.', single: true)
  LINE_BREAK          = Expression.new('(?:\r\n|\r|\n)', single: true)
  FOLDED_LINE_BREAK   = Expression.new('\r\n(?=[ \t])')
  UNFOLDED_LINE_BREAK = Expression.new('\r\n(?![ \t])')

  # +Regexes.any_character.between(1, 255)+ takes text up to 255 characters at a time.
  #
  # @return [Expression] one character, any but a line feed
  def any_character = ANY_CHARACTER

  # @return [Expression] one line break, however it is written: +\r\n+, +\r+ or +\n+
  def line_break = LINE_BREAK

  # A header that runs over several lines is folded: its line breaks are each followed by a space or tab, and
  # unfolding it removes them (RFC 5322 §2.2.3).
  #
  # @return [Expression] a CRLF followed by a space or tab, which it does not take
  def folded_line_break = FOLDED_LINE_BREAK

  # @return [Expression] a CRLF not followed by a space or tab: one that ends a header, never one inside it
  def unfolded_line_break = UNFOLDED_LINE_BREAK

  # ── Numbers and identifiers ─────────────────────────────────────────────────────────────────────────────

  INTEGER    = Expression.new('-?[0-9]+')
  UUID       = Expression.new('[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
  IDENTIFIER = Expression.new('[A-Za-z][A-Za-z0-9_]*')

  # +Regexes.integer.whole+ matches +42+ and +-7+, never +4.2+ or +1e3+.
  #
  # @return [Expression] a whole number, negative or not, in ASCII digits
  def integer = INTEGER

  # +Regexes.uuid+ matches +01890a5d-ac96-774b-bcce-b302099a8057+, with its hyphens.
  #
  # @return [Expression] a UUID in its hyphenated form, of any version and either case
  def uuid = UUID

  # +Regexes.identifier.whole+ matches +get_order+ and +Tag2+, never +2tag+ or +get-order+.
  #
  # @return [Expression] a letter, then letters, digits and underscores
  def identifier = IDENTIFIER

  # ── Times ───────────────────────────────────────────────────────────────────────────────────────────────

  UTC_OFFSET   = Expression.new('(?:Z|[+-][0-9]{2}:?[0-9]{2})', single: true)
  ISO8601_TIME = Expression.new(
    "[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}(?::[0-9]{2}(?:\\.[0-9]+)?)?#{UTC_OFFSET.source}?"
  )

  # +Regexes.utc_offset+ matches +Z+, +-05:00+ and +-0500+.
  #
  # @return [Expression] how far a time is from UTC, as ISO 8601 writes it
  def utc_offset = UTC_OFFSET

  # +Regexes.iso8601_time.whole+ matches +2026-11-21T14:30+, +2026-11-21 14:30:05.123Z+ and
  # +2026-11-21T14:30:05-05:00+, never a date alone.
  #
  # @return [Expression] a date and time as ISO 8601 writes it, seconds and offset optional
  def iso8601_time = ISO8601_TIME

  # ── Addresses ───────────────────────────────────────────────────────────────────────────────────────────

  HTTP_SCHEME   = Expression.new('https?://')
  DNS_LABEL     = Expression.new('[a-z0-9](?:[a-z0-9-]*[a-z0-9])?', single: true)
  DOMAIN_NAME   = Expression.new("#{DNS_LABEL.source}(?:\\.#{DNS_LABEL.source})+")
  EMAIL_ADDRESS = Expression.new('(?<local>[^@\s]+)@(?<domain>[^@\s]+)')

  # +Regexes.http_scheme.leading.case_insensitive+ tells a web link from a +cid:+ or +mailto:+ one.
  #
  # @return [Expression] +http://+ or +https://+, in lowercase
  def http_scheme = HTTP_SCHEME

  # +Regexes.dns_label.whole+ matches +acme+ and +mail-1+, never +-acme+, +acme-+ or +Acme+.
  #
  # @return [Expression] one label of a domain name, lowercase: letters, digits and inner hyphens
  def dns_label = DNS_LABEL

  # +Regexes.domain_name.whole+ matches +acme.example+ and +mail.acme.co.uk+, never +acme+ or +acme..example+.
  #
  # @return [Expression] two or more lowercase labels joined by dots
  def domain_name = DOMAIN_NAME

  # Only its shape: one +@+ with something on either side and no whitespace anywhere. Whether such an address
  # exists is for the mail to find out. Its parts are captured as +local+ and +domain+.
  #
  # @return [Expression] an email address, as +ada@acme.example+
  def email_address = EMAIL_ADDRESS

  # ── Text ────────────────────────────────────────────────────────────────────────────────────────────────

  BACKTICK_CODE = Expression.new('`(?<code>[^`]+)`')

  # Markdown's inline code: +`get_order`+, its text captured as +code+.
  #
  # @return [Expression] text between a pair of backticks, never empty
  def backtick_code = BACKTICK_CODE

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
end
