# frozen_string_literal: true

module Regexes
  # ── Sets of characters ────────────────────────────────────────────────────────────────────────────────────
  #
  # Each matches one character of its set, and is named for the set (plural). ASCII unless the name says
  # otherwise.

  LOWERCASE_LETTERS      = CharacterClass.new('a-z')
  UPPERCASE_LETTERS      = CharacterClass.new('A-Z')
  LETTERS                = CharacterClass.new('A-Za-z')
  DIGITS                 = CharacterClass.new('0-9')
  LOWERCASE_ALPHANUMERIC = CharacterClass.new('a-z0-9')
  UPPERCASE_ALPHANUMERIC = CharacterClass.new('A-Z0-9')
  ALPHANUMERIC           = CharacterClass.new('A-Za-z0-9')
  WORD_CHARACTERS        = CharacterClass.new('A-Za-z0-9_')
  BINARY_DIGITS          = CharacterClass.new('01')
  OCTAL_DIGITS           = CharacterClass.new('0-7')
  HEX_DIGITS             = CharacterClass.new('0-9a-fA-F')
  BASE32_DIGITS          = CharacterClass.new('A-Z2-7')
  BASE58_DIGITS          = CharacterClass.new('1-9A-HJ-NP-Za-km-z')
  BASE64_DIGITS          = CharacterClass.new('A-Za-z0-9+/')
  BASE64URL_DIGITS       = CharacterClass.new('A-Za-z0-9\-_')
  WHITESPACE             = CharacterClass.new('[:space:]')
  ASCII_WHITESPACE       = CharacterClass.new(' \t\n\v\f\r')
  SPACE_OR_TAB           = CharacterClass.new(' \t')
  NEWLINE                = CharacterClass.new('\n')
  SLASH                  = CharacterClass.new('/')
  HYPHEN                 = CharacterClass.new('\-')
  DASHES                 = CharacterClass.new('\p{Pd}')
  APOSTROPHES            = CharacterClass.new("'`\u00B4\u02BC\u2018\u2019")
  DOUBLE_QUOTES          = CharacterClass.new("\"\u201C\u201D\u201E\u201F")
  UNICODE_LETTERS        = CharacterClass.new('\p{L}')
  UNICODE_DIGITS         = CharacterClass.new('\p{Nd}')
  COMBINING_MARKS        = CharacterClass.new('\p{M}')
  CONTROL_CHARACTERS     = CharacterClass.new('\p{Cc}')
  FORMAT_CHARACTERS      = CharacterClass.new('\p{Cf}')

  # +Regexes.lowercase_letters+ matches the +a+ of +A1a+.
  #
  # @return [CharacterClass] one lowercase ASCII letter, +a+ to +z+
  def lowercase_letters = LOWERCASE_LETTERS

  # +Regexes.uppercase_letters+ matches the +A+ of +A1a+. +Regexes.uppercase_letters.exactly(2)+ is the shape of
  # an ISO 3166 alpha-2 country code, and +.exactly(3)+ of an ISO 4217 currency code.
  #
  # @return [CharacterClass] one uppercase ASCII letter, +A+ to +Z+
  def uppercase_letters = UPPERCASE_LETTERS

  # @return [CharacterClass] one ASCII letter of either case
  def letters = LETTERS

  # +Regexes.digits.between(12, 19)+ is the shape of a payment card number, its digits run together.
  #
  # @return [CharacterClass] one ASCII digit, +0+ to +9+ (never another script's: that is {#unicode_digits})
  def digits = DIGITS

  # +Regexes.lowercase_alphanumeric+ matches the +a+ and the +1+ of +A1a+.
  #
  # @return [CharacterClass] one lowercase ASCII letter or ASCII digit
  def lowercase_alphanumeric = LOWERCASE_ALPHANUMERIC

  # +Regexes.uppercase_alphanumeric.between(1, 16)+ is a short code such as a voucher's.
  #
  # @return [CharacterClass] one uppercase ASCII letter or ASCII digit
  def uppercase_alphanumeric = UPPERCASE_ALPHANUMERIC

  # @return [CharacterClass] one ASCII letter of either case or ASCII digit
  def alphanumeric = ALPHANUMERIC

  # @return [CharacterClass] one ASCII letter, ASCII digit or underscore: what +\w+ matches in Ruby
  def word_characters = WORD_CHARACTERS

  # @return [CharacterClass] one binary digit, +0+ or +1+
  def binary_digits = BINARY_DIGITS

  # @return [CharacterClass] one octal digit, +0+ to +7+
  def octal_digits = OCTAL_DIGITS

  # +Regexes.hex_digits.exactly(64)+ is a SHA-256 digest written in hex, and +.exactly(32)+ a UUID written
  # without its hyphens.
  #
  # @return [CharacterClass] one hexadecimal digit, +0+ to +9+ and +a+ to +f+ of either case
  def hex_digits = HEX_DIGITS

  # @return [CharacterClass] one digit of RFC 4648 base32: +A+ to +Z+ and +2+ to +7+, in uppercase
  def base32_digits = BASE32_DIGITS

  # Base58 leaves out the characters easy to misread: +0+, +O+, +I+ and +l+.
  #
  # @return [CharacterClass] one digit of the base58 alphabet Bitcoin defined, which others since share
  def base58_digits = BASE58_DIGITS

  # @return [CharacterClass] one digit of RFC 4648 base64: letters, digits, +++ and +/+ (never the +=+ padding)
  def base64_digits = BASE64_DIGITS

  # @return [CharacterClass] one digit of RFC 4648 base64url: letters, digits, +-+ and +_+, safe in a URL
  def base64url_digits = BASE64URL_DIGITS

  # Text copied from a web page holds no-break and wide spaces; this matches them, where {#ascii_whitespace}
  # does not.
  #
  # @return [CharacterClass] one whitespace character of any script: spaces, tabs, line breaks, and the
  #   no-break and wide spaces
  def whitespace = WHITESPACE

  # @return [CharacterClass] one ASCII whitespace character: space, tab, line feed, vertical tab, form feed or
  #   carriage return, what +\s+ matches in Ruby
  def ascii_whitespace = ASCII_WHITESPACE

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

  # +text.gsub(Regexes.dashes, '-')+ turns the en and em dashes a word processor types into hyphens.
  #
  # @return [CharacterClass] one dash of any kind Unicode names one (its Pd category): the hyphen-minus, the
  #   hyphen, the en and em dashes, and the rest
  def dashes = DASHES

  # +name.gsub(Regexes.apostrophes, "'")+ makes +O’Brien+ and +O`Brien+ one name.
  #
  # @return [CharacterClass] one character typed for an apostrophe: +'+, the curly quotes +‘+ and +’+, the
  #   modifier letter +ʼ+, the backtick and the acute accent
  def apostrophes = APOSTROPHES

  # @return [CharacterClass] one double quotation mark: +"+ and the curly +“+, +”+, +„+ and +‟+
  def double_quotes = DOUBLE_QUOTES

  # @return [CharacterClass] one letter of any script (Unicode's L category), as +é+, +ß+, +ж+ and +中+
  def unicode_letters = UNICODE_LETTERS

  # @return [CharacterClass] one decimal digit of any script (Unicode's Nd category), as +٣+ and +३+ as well as
  #   +3+
  def unicode_digits = UNICODE_DIGITS

  # +text.unicode_normalize(:nfd).gsub(Regexes.combining_marks, '')+ takes the accents off +café+.
  #
  # @return [CharacterClass] one combining mark (Unicode's M category): an accent or other mark that joins the
  #   character before it
  def combining_marks = COMBINING_MARKS

  # @return [CharacterClass] one control character (Unicode's Cc category): C0 (+\x00+ to +\x1F+), DEL and C1,
  #   which includes the tab and line breaks
  def control_characters = CONTROL_CHARACTERS

  # +text.gsub(Regexes.format_characters, '')+ takes out the invisible characters pasted text carries.
  #
  # @return [CharacterClass] one invisible formatting character (Unicode's Cf category): the zero-width joiner
  #   and non-joiner, the byte order mark, the soft hyphen and the direction marks
  def format_characters = FORMAT_CHARACTERS
end
