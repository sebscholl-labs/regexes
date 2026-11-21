# frozen_string_literal: true

module Regexes
  # ── Numbers ───────────────────────────────────────────────────────────────────────────────────────────────

  INTEGER          = Expression.new('-?[0-9]+')
  UNSIGNED_INTEGER = Expression.new('[0-9]+')
  POSITIVE_INTEGER = Expression.new('[1-9][0-9]*')
  DECIMAL          = Expression.new('-?[0-9]+(?:\.[0-9]+)?')
  UNSIGNED_DECIMAL = Expression.new('[0-9]+(?:\.[0-9]+)?')
  JSON_NUMBER      = Expression.new('-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?')
  LATITUDE         = Expression.new('-?(?:90(?:\.0+)?|[1-8]?[0-9](?:\.[0-9]+)?)')
  LONGITUDE        = Expression.new('-?(?:180(?:\.0+)?|(?:1[0-7][0-9]|[1-9]?[0-9])(?:\.[0-9]+)?)')
  PORT_NUMBER      = Expression.new(
    '(?<![0-9])(?:6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[1-9][0-9]{0,3}|0)(?![0-9])'
  )

  # +Regexes.integer.whole+ matches +42+, +-7+ and +007+, never +4.2+, +1e3+ or +1,000+. Leading zeros are
  # allowed; {#positive_integer} refuses them.
  #
  # @return [Expression] a whole number, negative or not, in ASCII digits
  def integer = INTEGER

  # +Regexes.unsigned_integer.whole+ matches +0+, +42+ and +007+, never +-7+.
  #
  # @return [Expression] a whole number without a sign
  def unsigned_integer = UNSIGNED_INTEGER

  # +Regexes.positive_integer.whole+ matches +1+ and +42+, never +0+, +007+ or +-7+: a page number, a count.
  #
  # @return [Expression] a whole number of at least 1, written without leading zeros
  def positive_integer = POSITIVE_INTEGER

  # +Regexes.decimal.whole+ matches +42+, +-7.5+ and +0.25+, never +.5+, +5.+ or +1e3+. With +places:+, the
  # number of digits after the point is fixed: +decimal(places: 2)+ is money written to the cent (+12.50+),
  # +decimal(places: 0..6)+ a token amount of up to six places, the point left out when there are none.
  #
  # @param places [Integer, Range<Integer>, nil] how many digits must follow the point, or nil for any number
  # @return [Expression] a number in ASCII digits, negative or not, with an optional fraction after a point
  # @raise [ArgumentError] when +places+ is negative or not an Integer or Range of them
  def decimal(places: nil) = places.nil? ? DECIMAL : with_places('-?[0-9]+', places)

  # +Regexes.unsigned_decimal.whole+ matches +42+ and +0.25+, never +-7.5+. +places:+ is as for {#decimal}.
  #
  # @param places [Integer, Range<Integer>, nil] how many digits must follow the point, or nil for any number
  # @return [Expression] a number in ASCII digits, without a sign, with an optional fraction after a point
  # @raise [ArgumentError] when +places+ is negative or not an Integer or Range of them
  def unsigned_decimal(places: nil) = places.nil? ? UNSIGNED_DECIMAL : with_places('[0-9]+', places)

  # +Regexes.json_number.whole+ matches +0+, +-12.5+ and +6.02e23+, never +01+, +.5+, +1.+ or +NaN+ (RFC 8259
  # §6).
  #
  # @return [Expression] a number as JSON writes it
  def json_number = JSON_NUMBER

  # +Regexes.latitude.whole+ matches +51.5074+, +-90+ and +0+, never +90.1+ or +91+.
  #
  # @return [Expression] a latitude in decimal degrees, from -90 to 90
  def latitude = LATITUDE

  # +Regexes.longitude.whole+ matches +-0.1278+, +180+ and +-179.99+, never +180.5+ or +181+.
  #
  # @return [Expression] a longitude in decimal degrees, from -180 to 180
  def longitude = LONGITUDE

  # +Regexes.port_number.whole+ matches +0+, +443+ and +65535+, never +65536+ or +0443+. It never matches inside a
  # longer run of digits.
  #
  # @return [Expression] a TCP or UDP port number, 0 to 65535, without leading zeros
  def port_number = PORT_NUMBER

  private

  # @param whole [String] the source of the part before the point
  # @param places [Integer, Range<Integer>] how many digits must follow the point
  # @return [Expression] a number with that many digits after the point, the point left out when none may
  #   follow
  # @raise [ArgumentError] when +places+ is negative or not an Integer or Range of them
  def with_places(whole, places)
    min, max = places.is_a?(Range) ? [places.begin, places.end] : [places, places]
    raise ArgumentError, "places: #{places.inspect} is not a count of digits" unless counts?(min, max)

    fewest   = [min, 1].max
    count    = fewest == max ? max.to_s : "#{fewest},#{max}"
    fraction = max.zero? ? '' : "(?:\\.[0-9]{#{count}})#{'?' if min.zero?}"
    Expression.new("#{whole}#{fraction}")
  end

  # @param min [Object] the fewest digits asked for
  # @param max [Object] the most digits asked for
  # @return [Boolean] whether they are counts of digits: whole numbers, not negative, the fewest not above the most
  def counts?(min, max) = [min, max].all? { it.is_a?(Integer) && !it.negative? } && min <= max
end
