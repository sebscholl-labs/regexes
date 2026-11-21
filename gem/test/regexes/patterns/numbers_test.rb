# frozen_string_literal: true

require 'test_helper'

# Tests for numbers: whole and decimal, JSON's, coordinates and ports.
class RegexesNumbersTest < RegexesTestCase
  cases({
          integer:          [%w[42 0 -7 007 -0 123456789012345678901234567890], ['4.2', '1e3', '+1', '-', '', '1,000', '1 000', "\u0663", '--1']],
          unsigned_integer: [%w[42 0 007], ['-7', '4.2', '', '+1']],
          positive_integer: [%w[1 42 9 10 100], ['0', '007', '-7', '01', '']],
          decimal:          [%w[42 -7.5 0.25 0 -0.0 1.000001], ['.5', '5.', '1e3', '+1.5', '1,5', '', '-', '1.2.3']],
          unsigned_decimal: [%w[42 0.25 0], ['-7.5', '.5', '5.', '']],
          json_number:      [%w[0 -12.5 6.02e23 1E-7 -0 1e+5 0.5], ['01', '.5', '1.', 'NaN', 'Infinity', '+1', '', '-', '1e', '0x1F', '-01', '1.e5']],
          latitude:         [%w[51.5074 -90 90 0 -0 89.999999 90.0 90.000 45 8.5], ['90.1', '91', '-90.5', '100', '05', '', '1e1', '+45', '45.']],
          longitude:        [%w[-0.1278 180 -180 179.99 0 99 100 180.0 9.5], ['180.5', '181', '-181', '200', '0180', '05', '', '1e2']],
          port_number:      [%w[443 0 1 65535 65534 65000 9999 10000 64999 655], ['65536', '65540', '65600', '66000', '0443', '-1', '70000', '99999', '100000', '00', '']]
        }, defined_in: 'numbers')

  # ── Decimal places ──────────────────────────────────────────────────────────────────────────────────────

  {
    2    => [%w[12.50 0.00 -3.10], %w[12.5 12 12.500 .50]],
    0..6 => [%w[12 12.5 12.123456], %w[12.1234567 12.]],
    0    => [%w[12 -3], %w[12.0 12.]],
    1..2 => [%w[12.5 12.50], %w[12 12.500]]
  }.each do |places, (matches, refuses)|
    matches.each do |text|
      test "decimal with places #{places} matches #{text}" do
        assert_match Regexes.decimal(places:).whole, text
      end
    end

    refuses.each do |text|
      test "decimal with places #{places} refuses #{text}" do
        refute_match Regexes.decimal(places:).whole, text
      end
    end
  end

  test 'decimal places of two are written as one count' do
    assert_equal '-?[0-9]+(?:\.[0-9]{2})', Regexes.decimal(places: 2).source
  end

  test 'decimal places that may be none leave the point optional' do
    assert_equal '-?[0-9]+(?:\.[0-9]{1,6})?', Regexes.decimal(places: 0..6).source
  end

  test 'unsigned decimal with places refuses a sign' do
    refute_match Regexes.unsigned_decimal(places: 2).whole, '-1.00'
  end

  test 'unsigned decimal with places matches money to the cent' do
    assert_match Regexes.unsigned_decimal(places: 2).whole, '1.00'
  end

  test 'decimal without places is the named pattern' do
    assert_same Regexes::DECIMAL, Regexes.decimal(places: nil)
  end

  [-1, 3..1, '2', 1.5, -1..2].each do |places|
    test "decimal refuses places of #{places.inspect}" do
      assert_raises(ArgumentError, match: /not a count of digits/) { Regexes.decimal(places:) }
    end
  end

  # ── In text ─────────────────────────────────────────────────────────────────────────────────────────────

  test 'a port number is never found inside a longer run of digits' do
    assert_equal %w[443], 'ports 443 and 655360'.scan(Regexes.port_number)
  end

  test 'a port number is found after a host' do
    assert_equal '8080', 'localhost:8080'[Regexes.port_number.preceded_by(Regexes.literal(':'))]
  end
end
