# frozen_string_literal: true

module Regexes
  # ── Codes ─────────────────────────────────────────────────────────────────────────────────────────────────
  #
  # Codes that are only a set and a count are written with the set: an ISO 3166 alpha-2 country code is
  # +Regexes.uppercase_letters.exactly(2)+, an ISO 4217 currency code +Regexes.uppercase_letters.exactly(3)+. The
  # codes here have parts. None is checked against the list of codes assigned, nor a checksum.

  alphanumeric_before = '(?<![A-Za-z0-9])'
  alphanumeric_after  = '(?![A-Za-z0-9])'
  subtag_before       = '(?<![A-Za-z0-9-])'
  subtag_after        = '(?![A-Za-z0-9-])'

  E164_PHONE_NUMBER = Expression.new('(?<![0-9+])\+[1-9][0-9]{1,14}(?![0-9])')
  IBAN              = Expression.new(
    "#{alphanumeric_before}(?<country_code>[A-Z]{2})(?<check_digits>[0-9]{2})(?<bban>[A-Z0-9]{11,30})" \
    "#{alphanumeric_after}"
  )
  BIC               = Expression.new(
    "#{alphanumeric_before}(?<business_party_prefix>[A-Z0-9]{4})(?<country_code>[A-Z]{2})" \
    "(?<business_party_suffix>[A-Z0-9]{2})(?<branch_identifier>[A-Z0-9]{3})?#{alphanumeric_after}"
  )
  LANGUAGE_TAG      = Expression.new(
    "#{subtag_before}(?<language>[A-Za-z]{2,3}(?:-[A-Za-z]{3}){0,3}|[A-Za-z]{5,8})" \
    '(?:-(?<script>[A-Za-z]{4}))?' \
    '(?:-(?<region>[A-Za-z]{2}|[0-9]{3}))?' \
    '(?:-(?:[A-Za-z0-9]{5,8}|[0-9][A-Za-z0-9]{3}))*' \
    '(?:-[0-9A-WYZa-wyz](?:-[A-Za-z0-9]{2,8})+)*' \
    "(?:-[Xx](?:-[A-Za-z0-9]{1,8})+)?#{subtag_after}"
  )
  HEX_COLOR         = Expression.new('#(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})(?![0-9a-fA-F])')

  # +Regexes.e164_phone_number.whole+ matches <tt>+14155552671</tt> and <tt>+442071838750</tt>, never one without
  # the plus, with spaces, with a +0+ after the plus, or of more than 15 digits (ITU-T E.164). It never matches
  # inside a longer run of digits.
  #
  # @return [Expression] a phone number in E.164 form: a plus, then up to 15 digits, the first not 0
  def e164_phone_number = E164_PHONE_NUMBER

  # +Regexes.iban.whole+ matches +DE89370400440532013000+ and +GB82WEST12345698765432+, never one with spaces
  # (its printed form), lowercase letters, or a length outside 15 to 34. The check digits are not verified.
  # It captures +country_code+, +check_digits+ and +bban+ (ISO 13616).
  #
  # @return [Expression] an IBAN in its electronic form
  def iban = IBAN

  # +Regexes.bic.whole+ matches +DEUTDEFF+ and +DEUTDEFF500+, never +DEUTDEF+ or a lowercase one. It captures
  # +business_party_prefix+, +country_code+, +business_party_suffix+ and +branch_identifier+ (ISO 9362).
  #
  # @return [Expression] a business identifier code, or SWIFT code: 8 or 11 characters
  def bic = BIC

  # +Regexes.language_tag.whole+ matches +en+, +en-US+, +zh-Hant-TW+, +es-419+ and +sr-Latn-RS+, never +e+,
  # +en_US+ or +en-+. It captures +language+, +script+ and +region+ (BCP 47, RFC 5646 §2.1); variants,
  # extensions and private use are matched but not captured. A language may be 2 to 3 letters or 5 to 8, so
  # most short words have a tag's shape: validate a tag with +.whole+ rather than search prose for one.
  #
  # @return [Expression] a language tag, as HTTP's Accept-Language and HTML's +lang+ hold it
  def language_tag = LANGUAGE_TAG

  # +Regexes.hex_color.whole+ matches +#fff+, +#FFFFFF+, +#ffff+ and +#ff000080+, never +#ff+, +#fffff+ or +fff+.
  #
  # @return [Expression] a color in CSS hex notation: a hash and 3, 4, 6 or 8 hex digits
  def hex_color = HEX_COLOR
end
