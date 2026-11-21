# frozen_string_literal: true

module Regexes
  # ── Identifiers ───────────────────────────────────────────────────────────────────────────────────────────

  base64_digit    = '[A-Za-z0-9+/]'
  base64url_digit = '[A-Za-z0-9_-]'
  before_two_pads = '[AQgw]'
  before_one_pad  = '[AEIMQUYcgkosw048]'
  restricted      = '[A-Za-z0-9][A-Za-z0-9!#$&^_.+-]{0,126}'
  semver_part     = '(?:0|[1-9][0-9]*)'
  semver_label    = '(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'

  IDENTIFIER           = Expression.new('[A-Za-z][A-Za-z0-9_]*')
  SNAKE_CASE           = Expression.new('[a-z][a-z0-9]*(?:_[a-z0-9]+)*')
  SCREAMING_SNAKE_CASE = Expression.new('[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)*')
  KEBAB_CASE           = Expression.new('[a-z0-9]+(?:-[a-z0-9]+)*')
  CAMEL_CASE           = Expression.new('[a-z][a-z0-9]*(?:[A-Z][a-z0-9]*)*')
  PASCAL_CASE          = Expression.new('(?:[A-Z][a-z0-9]*)+', single: true)
  UUID                 = Expression.new(
    '(?<![0-9a-fA-F])[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}(?![0-9a-fA-F])'
  )
  ULID                 = Expression.new('(?<![0-9A-Za-z])[0-7][0-9A-HJKMNP-TV-Z]{25}(?![0-9A-Za-z])')
  SEMANTIC_VERSION     = Expression.new(
    "(?<major>#{semver_part})\\.(?<minor>#{semver_part})\\.(?<patch>#{semver_part})" \
    "(?:-(?<prerelease>#{semver_label}(?:\\.#{semver_label})*))?" \
    '(?:\+(?<build>[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'
  )
  MEDIA_TYPE           = Expression.new("(?<type>#{restricted})/(?<subtype>#{restricted})")
  JSON_WEB_TOKEN       = Expression.new(
    "(?<header>eyJ#{base64url_digit}*)\\.(?<payload>eyJ#{base64url_digit}*)\\.(?<signature>#{base64url_digit}*)"
  )
  BASE64               = Expression.new(
    "(?:#{base64_digit}{4})*" \
    "(?:#{base64_digit}#{before_two_pads}==|#{base64_digit}{2}#{before_one_pad}=|#{base64_digit}{4})"
  )
  BASE64URL            = Expression.new(
    "(?:#{base64url_digit}{4})*" \
    "(?:#{base64url_digit}#{before_two_pads}(?:==)?|#{base64url_digit}{2}#{before_one_pad}=?|#{base64url_digit}{4})"
  )

  # +Regexes.identifier.whole+ matches +get_order+ and +Tag2+, never +2tag+ or +get-order+.
  #
  # @return [Expression] a letter, then letters, digits and underscores
  def identifier = IDENTIFIER

  # +Regexes.snake_case.whole+ matches +order+, +line_item+ and +user_2fa+, never +lineItem+, +line__item+,
  # +_line+ or +line_+.
  #
  # @return [Expression] lowercase words of letters and digits, the first starting with a letter, joined by
  #   single underscores
  def snake_case = SNAKE_CASE

  # +Regexes.screaming_snake_case.whole+ matches +MAX_RETRIES+ and +HTTP2+, never +Max_Retries+ or +MAX__RETRIES+.
  #
  # @return [Expression] uppercase words of letters and digits, the first starting with a letter, joined by single
  #   underscores: a constant's name, an environment variable's
  def screaming_snake_case = SCREAMING_SNAKE_CASE

  # +Regexes.kebab_case.whole+ matches +order-history+ and +2026-review+, never +Order-History+, +order--history+
  # or +-order+. Unlike {#snake_case}, a word may start with a digit, as a URL's slug often does.
  #
  # @return [Expression] lowercase words of letters and digits joined by single hyphens
  def kebab_case = KEBAB_CASE

  # +Regexes.camel_case.whole+ matches +lineItem+, +getHTTPResponse+ and +order+, never +LineItem+ or
  # +line_item+.
  #
  # @return [Expression] a lowercase letter, then letters and digits, each later word starting uppercase
  def camel_case = CAMEL_CASE

  # +Regexes.pascal_case.whole+ matches +LineItem+, +HTTPServer+ and +A+, never +lineItem+ or +Line_Item+.
  #
  # @return [Expression] words of letters and digits, each starting uppercase: a class's name
  def pascal_case = PASCAL_CASE

  # +Regexes.uuid+ matches +01890a5d-ac96-774b-bcce-b302099a8057+, with its hyphens, of any version and either
  # case. It never matches inside a longer run of hex digits. Without its hyphens, a UUID is
  # +Regexes.hex_digits.exactly(32)+.
  #
  # @return [Expression] a UUID in its hyphenated form (RFC 9562)
  def uuid = UUID

  # +Regexes.ulid.whole+ matches +01ARZ3NDEKTSV4RRFFQ69G5FAV+, never one with +I+, +L+, +O+ or +U+ in it, or a
  # first character above +7+. Uppercase, as the spec writes it; add +.case_insensitive+ to read either.
  #
  # @return [Expression] a ULID: 26 digits of Crockford's base32
  def ulid = ULID

  # +Regexes.semantic_version.whole+ matches +1.0.0+, +2.1.3-rc.1+ and +1.0.0+build.5+, never +1.0+, +v1.0.0+
  # or +01.0.0+. It captures +major+, +minor+, +patch+, +prerelease+ and +build+ (SemVer 2.0.0).
  #
  # @return [Expression] a semantic version
  def semantic_version = SEMANTIC_VERSION

  # +Regexes.media_type.whole+ matches +text/html+, +application/vnd.api+json+ and +image/svg+xml+, never
  # +text+ or +text/html; charset=utf-8+ (its parameters are not matched). It captures +type+ and +subtype+
  # (RFC 6838 §4.2).
  #
  # @return [Expression] a media type, or MIME type: a type, a slash and a subtype
  def media_type = MEDIA_TYPE

  # A JSON Web Token's three parts in base64url, joined by dots, the header and payload each the encoding of a
  # JSON object (so starting +eyJ+), the signature empty when unsigned. Whether it decodes, and whether its
  # signature holds, is for a JWT library. It captures +header+, +payload+ and +signature+ (RFC 7519).
  #
  # @return [Expression] a JSON Web Token in its compact form
  def json_web_token = JSON_WEB_TOKEN

  # +Regexes.base64.whole+ matches +QUJD+ and +QUI=+, never +QUJ+ (a length no padding fixes), +QU=I+, or +QR==+
  # (its last digit carries bits the padding says aren't there). It is canonical base64, so what it matches
  # Ruby's strict decoder (+unpack1('m0')+) decodes.
  #
  # @return [Expression] text in RFC 4648 base64, padded to a multiple of four, never empty
  def base64 = BASE64

  # +Regexes.base64url.whole+ matches +QUJD+, +QUI+ and +QUI=+, never +QU+J+, +Q+ or +QR+. Canonical, as {#base64}
  # is.
  #
  # @return [Expression] text in RFC 4648 base64url, padded or not, never empty
  def base64url = BASE64URL
end
