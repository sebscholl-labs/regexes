# frozen_string_literal: true

module Regexes
  # ── Times ─────────────────────────────────────────────────────────────────────────────────────────────────
  #
  # Each field is checked against its range (month 01–12, day 01–31, hour 00–23, minute 00–59, second 00–60,
  # for a leap second), never against the calendar. A pattern that starts or ends with a digit never matches
  # inside a longer run of digits.

  year      = '[0-9]{4}'
  month     = '(?:0[1-9]|1[0-2])'
  day       = '(?:0[1-9]|[12][0-9]|3[01])'
  hour      = '(?:[01][0-9]|2[0-3])'
  minute    = '[0-5][0-9]'
  second    = '(?:[0-5][0-9]|60)'
  fraction  = '(?:\.[0-9]+)'
  offset    = "(?:Z|[+-]#{hour}:?#{minute})"
  date      = "#{year}-#{month}-#{day}"
  time      = "#{hour}:#{minute}(?::#{second}#{fraction}?)?"
  quantity  = '[0-9]+'
  before    = '(?<![0-9])'
  after     = '(?![0-9])'

  UTC_OFFSET         = Expression.new(offset, single: true)
  ISO8601_DATE       = Expression.new("#{before}#{date}#{after}")
  ISO8601_YEAR_MONTH = Expression.new("#{before}#{year}-#{month}#{after}")
  ISO8601_TIME       = Expression.new("#{before}#{time}#{after}")
  ISO8601_DATE_TIME  = Expression.new("#{before}#{date}[T ]#{time}(?:#{offset}|#{after})")
  ISO8601_DURATION   = Expression.new(
    "P(?=[0-9]|T[0-9])(?:#{quantity}Y)?(?:#{quantity}M)?(?:#{quantity}W)?(?:#{quantity}D)?" \
    "(?:T(?=[0-9])(?:#{quantity}H)?(?:#{quantity}M)?(?:#{quantity}#{fraction}?S)?)?"
  )
  RFC3339_TIMESTAMP  = Expression.new(
    "#{before}#{date}[Tt ]#{hour}:#{minute}:#{second}#{fraction}?(?:[Zz]|[+-]#{hour}:#{minute})"
  )

  # +Regexes.utc_offset+ matches +Z+, +-05:00+ and +-0500+: hours to 23, minutes to 59.
  #
  # @return [Expression] how far a time is from UTC, as ISO 8601 writes it
  def utc_offset = UTC_OFFSET

  # +Regexes.iso8601_date.whole+ matches +2026-11-21+, never +2026-13-01+, +2026-11-32+ or +20261121+.
  # +2026-02-30+ is a date's shape.
  #
  # @return [Expression] a calendar date as ISO 8601's extended format writes it
  def iso8601_date = ISO8601_DATE

  # +Regexes.iso8601_year_month.whole+ matches +2026-11+, never +2026-13+ or +202611+: a billing period, a
  # report's month.
  #
  # @return [Expression] a year and month as ISO 8601's extended format writes them
  def iso8601_year_month = ISO8601_YEAR_MONTH

  # +Regexes.iso8601_time.whole+ matches +14:30+, +14:30:05+ and +23:59:60.5+ (a leap second), never +24:00+,
  # +14:60+ or +1430+. It is the time of day alone, without an offset: a date and time is {#iso8601_date_time}.
  #
  # @return [Expression] a time of day as ISO 8601's extended format writes it, seconds and fraction optional
  def iso8601_time = ISO8601_TIME

  # +Regexes.iso8601_date_time.whole+ matches +2026-11-21T14:30+, +2026-11-21 14:30:05.123Z+ and
  # +2026-11-21T14:30:05-05:00+, never a date alone. A space may stand for the +T+, as RFC 3339 allows.
  #
  # @return [Expression] an {#iso8601_date} and an {#iso8601_time}, then an optional {#utc_offset}
  def iso8601_date_time = ISO8601_DATE_TIME

  # +Regexes.iso8601_duration.whole+ matches +P1Y2M10D+, +PT1H30M+, +P2W+ and +PT0.5S+, never +P+, +PT+, +P1H+
  # (hours need the +T+) or +P1DT+. Each component is a count of whole units, only the seconds take a fraction.
  #
  # @return [Expression] a duration as ISO 8601 writes it: +P+, the years, months, weeks and days, then +T+ and
  #   the hours, minutes and seconds
  def iso8601_duration = ISO8601_DURATION

  # +Regexes.rfc3339_timestamp.whole+ matches +2026-11-21T14:30:05Z+ and +2026-11-21T14:30:05.123+05:30+, never
  # one without seconds or an offset, or with +-0500+ (RFC 3339 wants the colon). The +T+ and +Z+ may be
  # lowercase and the +T+ a space, as its §5.6 allows.
  #
  # @return [Expression] an internet timestamp (RFC 3339): a date and time to the second, and its offset
  def rfc3339_timestamp = RFC3339_TIMESTAMP
end
