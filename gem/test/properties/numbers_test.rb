# frozen_string_literal: true

require 'test_helper'
require 'json'

# The number patterns against the numbers themselves: every port, JSON's own parser, and coordinates generated
# over and past their ranges.
class RegexesNumbersPropertiesTest < RegexesTestCase
  # The seed every generated text comes from, so a failure repeats.
  SEED = 20_261_121

  test 'port number accepts exactly 0 to 65535, without leading zeros' do
    texts = (0..70_000).map(&:to_s) + (0..999).map { format('0%d', it) }

    assert_equal((0..65_535).map(&:to_s), texts.grep(Regexes.port_number.whole))
  end

  test 'json number agrees with the JSON parser on texts built from its grammar' do
    texts = json_texts

    assert_equal(texts.select { json_number?(it) }, texts.grep(Regexes.json_number.whole))
  end

  test 'latitude accepts exactly the decimals from -90 to 90' do
    texts = coordinate_texts(0..120)

    assert_equal(texts.select { Float(it).abs <= 90 }, texts.grep(Regexes.latitude.whole))
  end

  test 'longitude accepts exactly the decimals from -180 to 180' do
    texts = coordinate_texts(0..240)

    assert_equal(texts.select { Float(it).abs <= 180 }, texts.grep(Regexes.longitude.whole))
  end

  test 'decimal with two places accepts exactly the amounts written to the cent' do
    texts = coordinate_texts(0..20).map { it.delete_prefix('-') }

    assert_equal texts.grep(/\A[0-9]+\.[0-9]{2}\z/), texts.grep(Regexes.unsigned_decimal(places: 2).whole)
  end

  private

  # @return [Array<String>] texts made of a JSON number's parts, each present or not, valid or slightly not
  def json_texts
    signs     = ['', '-', '+', '--']
    integers  = ['0', '7', '42', '01', '00', '']
    fractions = ['', '.5', '.25', '.', '.x']
    exponents = ['', 'e5', 'E-7', 'e+10', 'e', 'E+', 'e05']
    signs.product(integers, fractions, exponents).map(&:join).uniq
  end

  # @param text [String] a text
  # @return [Boolean] whether JSON reads it as one number
  def json_number?(text)
    JSON.parse("[#{text}]").then { it.size == 1 && it.first.is_a?(Numeric) }
  rescue JSON::ParserError
    false
  end

  # @param whole [Range<Integer>] the whole degrees to try
  # @return [Array<String>] each whole number of degrees in the range, either sign, written bare and with
  #   fractions of zeros and of other digits
  def coordinate_texts(whole)
    random = Random.new(SEED)
    whole.flat_map do |degrees|
      [degrees.to_s, "#{degrees}.0", "#{degrees}.00", "#{degrees}.#{random.rand(1..99_999)}"].flat_map { [it, "-#{it}"] }
    end
  end
end
