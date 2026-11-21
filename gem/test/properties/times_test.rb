# frozen_string_literal: true

require 'test_helper'
require 'date'
require 'time'

# The ISO 8601 and RFC 3339 patterns over every value of each field, and one either side of its range: each
# accepted exactly when every field is in range.
class RegexesTimesPropertiesTest < RegexesTestCase
  # Every two-digit text from 00 to 99.
  TWO_DIGITS = (0..99).map { format('%02d', it) }.freeze

  test 'iso8601 date accepts exactly the months 01 to 12 and the days 01 to 31' do
    texts = TWO_DIGITS.product(TWO_DIGITS).map { |month, day| "2026-#{month}-#{day}" }

    assert_equal(texts.select { |text| in_range?(text[5, 2], 1..12) && in_range?(text[8, 2], 1..31) },
                 texts.grep(Regexes.iso8601_date.whole))
  end

  test 'iso8601 year month accepts exactly the months 01 to 12' do
    texts = TWO_DIGITS.map { "2026-#{it}" }

    assert_equal(texts.select { in_range?(it[5, 2], 1..12) }, texts.grep(Regexes.iso8601_year_month.whole))
  end

  test 'iso8601 time accepts exactly the hours 00 to 23 and the minutes 00 to 59' do
    texts = TWO_DIGITS.product(TWO_DIGITS).map { |hour, minute| "#{hour}:#{minute}" }

    assert_equal(texts.select { |text| in_range?(text[0, 2], 0..23) && in_range?(text[3, 2], 0..59) },
                 texts.grep(Regexes.iso8601_time.whole))
  end

  test 'iso8601 time accepts exactly the seconds 00 to 60' do
    texts = TWO_DIGITS.map { "12:00:#{it}" }

    assert_equal(texts.select { in_range?(it[6, 2], 0..60) }, texts.grep(Regexes.iso8601_time.whole))
  end

  test 'utc offset accepts exactly the hours 00 to 23 and the minutes 00 to 59, either sign, with or without a colon' do
    texts = %w[+ -].product(TWO_DIGITS, TWO_DIGITS, ['', ':']).map { |sign, hour, minute, colon| "#{sign}#{hour}#{colon}#{minute}" }

    assert_equal(texts.select { |text| in_range?(text[1, 2], 0..23) && in_range?(text[-2, 2], 0..59) },
                 texts.grep(Regexes.utc_offset.whole))
  end

  test 'rfc3339 timestamp accepts exactly the times in range, to the second' do
    texts = TWO_DIGITS.product(%w[00 59 60 61]).map { |hour, second| "2026-11-21T#{hour}:30:#{second}Z" }

    assert_equal(texts.select { |text| in_range?(text[11, 2], 0..23) && in_range?(text[17, 2], 0..60) },
                 texts.grep(Regexes.rfc3339_timestamp.whole))
  end

  test 'every date Ruby writes in ISO 8601 is an iso8601 date' do
    texts = (Date.new(2024, 1, 1)..Date.new(2024, 12, 31)).map(&:iso8601)

    assert_equal texts, texts.grep(Regexes.iso8601_date.whole)
  end

  test 'every time Ruby writes in RFC 3339 is an rfc3339 timestamp and an iso8601 date and time' do
    times = Array.new(200) do |index|
      Time.at(index * 7_919_731, in: format('%<hours>+03d:%<minutes>02d', hours: (index % 27) - 13, minutes: (index % 4) * 15))
    end
    texts = times.map { it.xmlschema(3) }

    assert_equal [texts, texts], [texts.grep(Regexes.rfc3339_timestamp.whole), texts.grep(Regexes.iso8601_date_time.whole)]
  end

  private

  # @param digits [String] a field's two digits
  # @param range [Range<Integer>] the values it may hold
  # @return [Boolean] whether its value is in the range
  def in_range?(digits, range) = range.cover?(Integer(digits, 10))
end
