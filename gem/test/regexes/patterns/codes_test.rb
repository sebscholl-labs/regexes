# frozen_string_literal: true

require 'test_helper'

# Tests for codes with parts: phone numbers, bank identifiers, language tags and colors.
class RegexesCodesTest < RegexesTestCase
  LONGEST_IBAN = "AB12#{'A' * 30}".freeze

  cases({
          e164_phone_number: [%w[+14155552671 +442071838750 +491512345678 +12 +123456789012345],
                              ['14155552671', '+1 415 555 2671', '+04155552671', '+1234567890123456', '+', '+1', '',
                               '+1-415-555-2671', '++14155552671']],
          iban:              [['DE89370400440532013000', 'GB82WEST12345698765432', 'NO9386011117947',
                               'MT84MALT011000012345MTLCAST001S', LONGEST_IBAN],
                              ['DE89 3704 0044 0532 0130 00', 'de89370400440532013000', 'DE8937040044', 'D189370400440532013000',
                               'DE8X370400440532013000', "#{LONGEST_IBAN}A", '']],
          bic:               [%w[DEUTDEFF DEUTDEFF500 NEDSZAJJXXX BOFAUS3N],
                              %w[DEUTDEF deutdeff DEUTDEFF5 DEUTDEFF50 DEUTDEFF5000 DEUT-DEFF DEUT1EFF] + ['']],
          language_tag:      [%w[en en-US zh-Hant-TW es-419 sr-Latn-RS de-CH-1901 en-US-x-twain ja-JP-u-ca-japanese],
                              ['e', 'en_US', 'en-', '-en', 'en US', '', 'e1', 'en-a', 'en-x', 'en--US']],
          hex_color:         [%w[#fff #FFFFFF #ffff #ff000080 #1a2B3c], ['#ff', '#fffff', '#fffffff', 'fff', '#ggg', '', '# fff', '#fffffffff']]
        }, defined_in: 'codes')

  # ── Captures ────────────────────────────────────────────────────────────────────────────────────────────

  {
    country_code: 'GB',
    check_digits: '82',
    bban:         'WEST12345698765432'
  }.each do |part, value|
    test "an IBAN captures its #{part}" do
      assert_equal value, Regexes.iban.match('GB82WEST12345698765432')[part]
    end
  end

  {
    business_party_prefix: 'DEUT',
    country_code:          'DE',
    business_party_suffix: 'FF',
    branch_identifier:     '500'
  }.each do |part, value|
    test "a BIC captures its #{part}" do
      assert_equal value, Regexes.bic.match('DEUTDEFF500')[part]
    end
  end

  test 'a BIC of eight characters captures no branch' do
    assert_nil Regexes.bic.match('DEUTDEFF')[:branch_identifier]
  end

  {
    language: 'zh',
    script:   'Hant',
    region:   'TW'
  }.each do |part, value|
    test "a language tag captures its #{part}" do
      assert_equal value, Regexes.language_tag.match('zh-Hant-TW')[part]
    end
  end

  test 'a language tag captures a numeric region' do
    assert_equal '419', Regexes.language_tag.match('es-419')[:region]
  end

  # ── In text ─────────────────────────────────────────────────────────────────────────────────────────────

  test 'a phone number is never found inside a longer run of digits' do
    assert_nil 'call +1234567890123456'[Regexes.e164_phone_number]
  end

  test 'a language tag is never found inside a longer word' do
    assert_empty found(Regexes.language_tag, 'abcdefghijk')
  end

  test 'a language tag is found whole in a header' do
    assert_equal %w[en-US de], found(Regexes.language_tag, 'en-US;q=0.9,de;q=0.8').grep_v(/\A[0-9q]/)
  end

  test 'a hex color is never cut from a longer run of hex digits' do
    assert_nil 'color: #fffff;'[Regexes.hex_color]
  end

  test 'two uppercase letters are the shape of a country code, three of a currency code' do
    assert_match Regexes.uppercase_letters.exactly(3).whole, 'EUR'
  end
end
