# frozen_string_literal: true

require 'test_helper'
require 'ipaddr'

# The IP address patterns against Ruby's own parser, IPAddr, over thousands of texts: addresses it writes in every
# form, and near misses made from them. The pattern and the parser must agree on each.
class RegexesIpAddressesPropertiesTest < RegexesTestCase
  # The seed every generated text comes from, so a failure repeats.
  SEED = 20_261_121

  test 'ipv4 address agrees with IPAddr on every octet from -1 to 300 in each place' do
    texts = (-1..300).flat_map { |octet| ["#{octet}.0.0.1", "1.#{octet}.0.1", "1.0.#{octet}.1", "1.0.0.#{octet}"] }

    assert_equal accepted_ipv4(texts), texts.grep(Regexes.ipv4_address.whole)
  end

  test 'ipv4 address agrees with IPAddr on zero-padded octets' do
    texts = %w[01.2.3.4 1.02.3.4 1.2.003.4 1.2.3.00 00.0.0.0 0.0.0.0 10.0.0.10 100.0.0.0]

    assert_equal accepted_ipv4(texts), texts.grep(Regexes.ipv4_address.whole)
  end

  test 'ipv6 address matches every address IPAddr writes, compressed' do
    texts = random_ipv6.map(&:to_s)

    assert_equal texts, texts.grep(Regexes.ipv6_address.whole)
  end

  test 'ipv6 address matches every address IPAddr writes, in full' do
    texts = random_ipv6.map(&:to_string)

    assert_equal texts, texts.grep(Regexes.ipv6_address.whole)
  end

  test 'ipv6 address matches every IPv4-mapped address IPAddr writes' do
    texts = random_ipv4.map { IPAddr.new(it).ipv4_mapped.to_s }

    assert_equal texts, texts.grep(Regexes.ipv6_address.whole)
  end

  test 'ipv6 address agrees with IPAddr on near misses' do
    texts = near_misses(random_ipv6.map(&:to_s))

    assert_equal accepted_ipv6(texts), texts.grep(Regexes.ipv6_address.whole)
  end

  test 'ip address takes both families IPAddr writes' do
    texts = random_ipv4.first(50) + random_ipv6.first(50).map(&:to_s)

    assert_equal texts, texts.grep(Regexes.ip_address.whole)
  end

  private

  # @return [Array<String>] IPv4 addresses, chosen at random but always the same
  def random_ipv4
    random = Random.new(SEED)
    Array.new(500) { Array.new(4) { random.rand(256) }.join('.') }
  end

  # @return [Array<IPAddr>] IPv6 addresses, chosen at random but always the same, many with runs of zeros
  def random_ipv6
    random = Random.new(SEED)
    Array.new(1_000) do
      groups = Array.new(8) { random.rand(3).zero? ? 0 : random.rand(0x10000) }
      IPAddr.new(groups.reduce(0) { |address, group| (address << 16) | group }, Socket::AF_INET6)
    end
  end

  # @param texts [Array<String>] valid addresses
  # @return [Array<String>] each with one character added, removed or changed, at a place chosen at random
  def near_misses(texts)
    random = Random.new(SEED)
    texts.flat_map do |text|
      place = random.rand(text.length)
      [text.dup.insert(place, ':'), text.dup.insert(place, '0'), replaced(text, place, ''), replaced(text, place, 'g'),
       "#{text}:"]
    end.uniq
  end

  # @param text [String] a text
  # @param place [Integer] the index of one of its characters
  # @param with [String] what to put there instead
  # @return [String] the text with that character replaced
  def replaced(text, place, with) = text[0, place] + with + text[(place + 1)..]

  # @param texts [Array<String>] texts to parse
  # @return [Array<String>] those IPAddr reads as an IPv4 address
  def accepted_ipv4(texts) = texts.select { parsed(it)&.ipv4? }

  # @param texts [Array<String>] texts to parse
  # @return [Array<String>] those IPAddr reads as an IPv6 address, written without brackets, zone or prefix
  def accepted_ipv6(texts) = texts.select { it.match?(/\A[0-9a-fA-F:.]+\z/) && parsed(it)&.ipv6? }

  # @param text [String] a text to parse
  # @return [IPAddr, nil] the address IPAddr reads in it, or nil when it reads none
  def parsed(text)
    IPAddr.new(text)
  rescue IPAddr::Error
    nil
  end
end
