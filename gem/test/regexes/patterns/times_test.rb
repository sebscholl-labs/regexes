# frozen_string_literal: true

require 'test_helper'

# Tests for dates, times and durations as ISO 8601 and RFC 3339 write them.
class RegexesTimesTest < RegexesTestCase
  cases({
          utc_offset:         [%w[Z +05:30 -0500 +00:00 -23:59 +1400], %w[z +5:30 05:00 +24:00 +05:60 +05 +05:3 UTC] + ['']],
          iso8601_date:       [%w[2026-11-21 0000-01-01 9999-12-31 2026-02-30 2026-10-10 2026-09-09],
                               %w[2026-00-01 2026-13-01 2026-11-00 2026-11-32 20261121 26-11-21 2026-1-21 2026-11-2
                                  2026/11/21 2026-11-21T14:30 +2026-11-21 12026-11-21 2026-11-211] + ['']],
          iso8601_year_month: [%w[2026-11 0000-01 9999-12], %w[2026-13 2026-00 202611 26-11 2026-1 2026-11-21 12026-11] + ['']],
          iso8601_time:       [%w[14:30 00:00 23:59 14:30:05 23:59:60 14:30:05.1 14:30:05.123456789],
                               %w[24:00 14:60 14:30:61 1430 14 4:30 14:3 14:30:5 14:30. 14:30:05. 14:30:05,5
                                  14:30Z T14:30 114:30] + ['']],
          iso8601_date_time:  [['2026-11-21T14:30', '2026-11-21 14:30:05.123Z', '2026-11-21T14:30:05-05:00',
                                '2026-11-21T00:00:00Z', '2026-11-21T23:59:60+0530'],
                               ['2026-11-21', '2026-11-21T14', '21/11/2026 14:30', '2026-11-21T14:30:05+5',
                                '2026-11-21T24:00', '2026-13-21T14:30', '2026-11-21t14:30', '2026-11-21T14:30z',
                                '2026-11-21  14:30', '2026-11-21T14:30:05 Z', '']],
          iso8601_duration:   [%w[P1Y2M10D PT1H30M P2W PT0.5S P1Y2M10DT2H30M5S P0D PT36H P1M PT1M],
                               %w[P PT P1H P1DT 1Y P1.5Y PT1.5H P-1D p1d P1D2Y PT1S2M] + ['']],
          rfc3339_timestamp:  [['2026-11-21T14:30:05Z', '2026-11-21T14:30:05.123+05:30', '2026-11-21t14:30:05z',
                                '2026-11-21 14:30:05Z', '2026-11-21T23:59:60-00:00'],
                               ['2026-11-21T14:30Z', '2026-11-21T14:30:05', '2026-11-21T14:30:05-0500', '2026-11-21T24:00:00Z',
                                '2026-13-21T14:30:05Z', '2026-11-21T14:30:05+24:00', '']]
        }, defined_in: 'times')

  test 'a date is never found inside a longer run of digits' do
    assert_equal %w[2026-11-21], '12026-11-21 and 2026-11-21'.scan(Regexes.iso8601_date)
  end

  test 'a time is never found inside a longer run of digits' do
    assert_equal %w[14:30], '114:30 and 14:30'.scan(Regexes.iso8601_time)
  end

  test 'a date and time is found with its offset' do
    assert_equal '2026-11-21T14:30:05+05:30', 'at 2026-11-21T14:30:05+05:30.'[Regexes.iso8601_date_time]
  end

  test 'a date and time is found without an offset' do
    assert_equal '2026-11-21 14:30', 'on 2026-11-21 14:30, then'[Regexes.iso8601_date_time]
  end

  test 'a date in a sequence keeps its fields checked' do
    refute_match Regexes.sequence(Regexes.literal('due '), Regexes.iso8601_date).whole, 'due 2026-13-01'
  end
end
