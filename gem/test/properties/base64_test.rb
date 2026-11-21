# frozen_string_literal: true

require 'test_helper'

# The base64 patterns against Ruby's strict decoder: what Ruby writes, and every short text of base64's
# characters, accepted exactly when the decoder reads it.
class RegexesBase64PropertiesTest < RegexesTestCase
  # The seed every generated text comes from, so a failure repeats.
  SEED = 20_261_121

  test 'base64 matches everything Ruby encodes' do
    texts = random_bytes.map { [it].pack('m0') }

    assert_equal texts, texts.grep(Regexes.base64.whole)
  end

  test 'base64url matches everything Ruby encodes, padded' do
    texts = random_bytes.map { [it].pack('m0').tr('+/', '-_') }

    assert_equal texts, texts.grep(Regexes.base64url.whole)
  end

  test 'base64url matches everything Ruby encodes, unpadded' do
    texts = random_bytes.map { [it].pack('m0').tr('+/', '-_').delete('=') }

    assert_equal texts, texts.grep(Regexes.base64url.whole)
  end

  test 'base64 agrees with the strict decoder on every text of up to four of its characters' do
    texts = short_texts(%w[A Q R g w / =])

    assert_equal(texts.select { decodes?(it) }, texts.grep(Regexes.base64.whole))
  end

  private

  # @return [Array<String>] byte strings of every length from 1 to 40, chosen at random but always the same
  def random_bytes
    random = Random.new(SEED)
    (1..40).flat_map { |length| Array.new(25) { random.bytes(length) } }
  end

  # @param characters [Array<String>] the characters to build from
  # @return [Array<String>] every text of one to four of them
  def short_texts(characters) = (1..4).flat_map { |length| characters.repeated_permutation(length).map(&:join) }

  # @param text [String] a text
  # @return [Boolean] whether Ruby's strict decoder reads it as base64, and it isn't empty
  def decodes?(text)
    return false if text.empty?

    text.unpack1('m0')
    true
  rescue ArgumentError
    false
  end
end
