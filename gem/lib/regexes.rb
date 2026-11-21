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

  UTC_OFFSET        = Expression.new('(?:Z|[+-](?:[01][0-9]|2[0-3]):?[0-5][0-9])', single: true)
  ISO8601_DATE      = Expression.new('[0-9]{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])')
  ISO8601_TIME      = Expression.new('(?:[01][0-9]|2[0-3]):[0-5][0-9](?::(?:[0-5][0-9]|60)(?:\.[0-9]+)?)?')
  ISO8601_DATE_TIME = Expression.new("#{ISO8601_DATE.source}[T ]#{ISO8601_TIME.source}#{UTC_OFFSET.source}?")

  # +Regexes.utc_offset+ matches +Z+, +-05:00+ and +-0500+: hours to 23, minutes to 59.
  #
  # @return [Expression] how far a time is from UTC, as ISO 8601 writes it
  def utc_offset = UTC_OFFSET

  # +Regexes.iso8601_date.whole+ matches +2026-11-21+, never +2026-13-01+, +2026-11-32+ or +20261121+. Each
  # field is checked against its range, never against the calendar: +2026-02-30+ is a date's shape.
  #
  # @return [Expression] a calendar date as ISO 8601's extended format writes it
  def iso8601_date = ISO8601_DATE

  # +Regexes.iso8601_time.whole+ matches +14:30+, +14:30:05+ and +23:59:60.5+ (a leap second), never +24:00+,
  # +14:60+ or +1430+. It is the time of day alone: a date and time is {#iso8601_date_time}.
  #
  # @return [Expression] a time of day as ISO 8601's extended format writes it, seconds and fraction optional
  def iso8601_time = ISO8601_TIME

  # +Regexes.iso8601_date_time.whole+ matches +2026-11-21T14:30+, +2026-11-21 14:30:05.123Z+ and
  # +2026-11-21T14:30:05-05:00+, never a date alone. A space may stand for the +T+, as RFC 3339 allows.
  #
  # @return [Expression] an {#iso8601_date} and an {#iso8601_time}, then an optional {#utc_offset}
  def iso8601_date_time = ISO8601_DATE_TIME

  # ── Addresses ───────────────────────────────────────────────────────────────────────────────────────────

  HTTP_SCHEME   = Expression.new('https?://')
  DNS_LABEL     = Expression.new('[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?', single: true)
  DOMAIN_NAME   = Expression.new(
    "(?=[a-z0-9.-]{1,253}(?![a-z0-9.-]))#{DNS_LABEL.source}(?:\\.#{DNS_LABEL.source})+"
  )
  EMAIL_ADDRESS = Expression.new(
    "(?<local>[A-Za-z0-9.!\#$%&'*+/=?^_`{|}~-]+)" \
    '@(?<domain>[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*)'
  )

  # +Regexes.http_scheme.leading.case_insensitive+ tells a web link from a +cid:+ or +mailto:+ one.
  #
  # @return [Expression] +http://+ or +https://+, in lowercase
  def http_scheme = HTTP_SCHEME

  # +Regexes.dns_label.whole+ matches +acme+ and +mail-1+, never +-acme+, +acme-+, +Acme+ or a label of more
  # than 63 characters (RFC 1035 §2.3.4).
  #
  # @return [Expression] one label of a domain name, lowercase: letters, digits and inner hyphens
  def dns_label = DNS_LABEL

  # +Regexes.domain_name.whole+ matches +acme.example+ and +mail.acme.co.uk+, never +acme+, +acme..example+,
  # +acme.example.+ (a trailing dot) or a name of more than 253 characters.
  #
  # @return [Expression] two or more lowercase {#dns_label}s joined by dots
  def domain_name = DOMAIN_NAME

  # The address an HTML form's +type=email+ input accepts (WHATWG HTML §4.10.5.1.5), so a browser and a server
  # reach the same verdict: +ada@acme.example+, +a+b@x+. Like the browser, it allows a domain of one label
  # and dots anywhere in the local part. Whether the address exists is for the mail to find out. Its parts are
  # captured as +local+ and +domain+.
  #
  # @return [Expression] an email address, as +ada@acme.example+
  def email_address = EMAIL_ADDRESS

  # ── Text ────────────────────────────────────────────────────────────────────────────────────────────────

  MARKDOWN_CODE_SPAN = Expression.new('`(?<code>[^`]+)`')

  # Markdown's inline code, a code span in CommonMark's terms: +`get_order`+, its text captured as +code+. Only
  # the single-backtick form: a span opened by two backticks, to hold one, is not matched.
  #
  # @return [Expression] text between a pair of backticks, never empty
  def markdown_code_span = MARKDOWN_CODE_SPAN

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
