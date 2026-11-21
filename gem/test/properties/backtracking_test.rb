# frozen_string_literal: true

require 'test_helper'

# Every named pattern, searched for and matched whole against long texts built to make a careless regular
# expression backtrack: a run of each character a pattern might take, and of each fragment it might take
# again and again, ending in one it won't. None may take longer than Regexp.timeout allows.
class RegexesBacktrackingPropertiesTest < RegexesTestCase
  # How long one match may take before it counts as runaway backtracking.
  LIMIT   = 1.0
  # How long each text is.
  LENGTH  = 5_000
  # What each text repeats: characters and fragments the named patterns take.
  REPEATS = ['a', 'A', '0', '9', 'f', '-', '.', ':', '@', '%', '_', ' ', "\t", "\n", "\r\n", '/', '+', '=', '#', '`',
             '{', '[', '(', '$', 'a.', '0.', 'a-', '0:', 'a@', '%2', '{{', 'eyJ', 'P1', '1Y', 'T1', 'ff:', '::',
             '1.1.', 'aA', "\u0301", "\u200D", "\u{1F44D}"].freeze
  # What ends each text: a character no named pattern takes after any of them.
  ENDING  = "\u0001"

  NAMED = (Regexes.instance_methods(false) - Regexes.registered - %i[sequence either literal register registered])
          .map { Regexes.public_send(it) }.freeze

  test 'no named pattern backtracks for long on a long near miss' do
    runaway = NAMED.product(REPEATS).reject do |pattern, fragment|
      text = (fragment * (LENGTH / fragment.length)) + ENDING
      within_limit? { pattern.match?(text) && pattern.whole.match?(text) }
    end

    assert_empty runaway
  end

  private

  # @yield the match to time
  # @return [Boolean] whether it finished within {LIMIT}
  def within_limit?
    previous       = Regexp.timeout
    Regexp.timeout = LIMIT
    yield
    true
  rescue Regexp::TimeoutError
    false
  ensure
    Regexp.timeout = previous
  end
end
