# frozen_string_literal: true

require 'test_helper'

# Tests for identifiers: names in each case convention, UUIDs and ULIDs, versions, media types, tokens and
# base64.
class RegexesIdentifiersTest < RegexesTestCase
  JWT = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'

  cases({
          identifier:           [%w[get_order Tag2 x X_1], ['2tag', 'get-order', '_x', '', 'a b', 'é']],
          snake_case:           [%w[order line_item user_2fa a a1_b2], ['lineItem', 'line__item', '_line', 'line_', 'Line_item', '2fa', '', 'line-item']],
          screaming_snake_case: [%w[MAX_RETRIES HTTP2 A A1_B2], ['Max_Retries', 'MAX__RETRIES', '_MAX', 'MAX_', '2X', '']],
          kebab_case:           [%w[order-history 2026-review a 1 a-1-b], ['Order-History', 'order--history', '-order', 'order-', 'order_history', '']],
          camel_case:           [%w[lineItem getHTTPResponse order a1B2 x], ['LineItem', 'line_item', 'line-item', '1abc', '']],
          pascal_case:          [%w[LineItem HTTPServer A Order2], ['lineItem', 'Line_Item', '2Line', 'Line-Item', '']],
          uuid:                 [%w[01890a5d-ac96-774b-bcce-b302099a8057 01890A5D-AC96-774B-BCCE-B302099A8057
                                    00000000-0000-0000-0000-000000000000 ffffffff-ffff-ffff-ffff-ffffffffffff],
                                 %w[01890a5dac96774bbcceb302099a8057 01890a5d-ac96-774b-bcce-b302099a805
                                    x1890a5d-ac96-774b-bcce-b302099a8057 {01890a5d-ac96-774b-bcce-b302099a8057}
                                    01890a5d-ac96-774b-bcce-b302099a80577 01890a5d_ac96_774b_bcce_b302099a8057] + ['']],
          ulid:                 [%w[01ARZ3NDEKTSV4RRFFQ69G5FAV 7ZZZZZZZZZZZZZZZZZZZZZZZZZ 00000000000000000000000000],
                                 %w[8ZZZZZZZZZZZZZZZZZZZZZZZZZ 01arz3ndektsv4rrffq69g5fav 01ARZ3NDEKTSV4RRFFQ69G5FA
                                    01ARZ3NDEKTSV4RRFFQ69G5FAVX 01ARZ3NDEKTSV4RRFFQ69G5FAI 01ARZ3NDEKTSV4RRFFQ69G5FAL
                                    01ARZ3NDEKTSV4RRFFQ69G5FAO 01ARZ3NDEKTSV4RRFFQ69G5FAU] + ['']],
          semantic_version:     [%w[1.0.0 2.1.3-rc.1 1.0.0+build.5 1.0.0-alpha+001 1.0.0-0.3.7 1.0.0-x.7.z.92
                                    1.0.0-alpha.beta 0.0.0 10.20.30 1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay
                                    1.0.0+0.build.1-rc.10000aaa-kk-0.1 99999999999999999999999.999999999999999999.99999999999999999],
                                 %w[1.0 v1.0.0 01.0.0 1.01.0 1.0.01 1.0.0-01 1.0.0- 1.0.0+ 1.0.0-alpha..1 1.0.0+build..1
                                    1.2.3.4 1.0.0-alpha_beta] + ['']],
          media_type:           [%w[text/html application/vnd.api+json image/svg+xml application/octet-stream TEXT/HTML multipart/form-data],
                                 ['text', 'text/html; charset=utf-8', '/html', 'text/', 'text /html', 'text/html/x', '']],
          json_web_token:       [[JWT, 'eyJhbGciOiJub25lIn0.eyJzdWIiOiIxIn0.'],
                                 ['abc.def.ghi', 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0', "#{JWT} ", 'eyJ.eyJ.sig+/', 'Bearer eyJ.eyJ.x', '']],
          base64:               [%w[QUJD QUI= QQ== QUJDRA== aGVsbG8gd29ybGQ= +/+/], ['QUJ', 'QU=I', 'QR==', 'QUJ=', 'Q===', '=', '', 'QUJD=', 'QU JD', 'QUJD-']],
          base64url:            [%w[QUJD QUI QUI= QQ QQ== _-_-], ['QU+J', 'Q', 'QR', 'QUJ=', 'QUJDR', '', 'QU/J']]
        }, defined_in: 'identifiers')

  # ── Captures ────────────────────────────────────────────────────────────────────────────────────────────

  {
    major:      '2',
    minor:      '1',
    patch:      '3',
    prerelease: 'rc.1',
    build:      'sha.5114f85'
  }.each do |part, value|
    test "a semantic version captures its #{part}" do
      assert_equal value, Regexes.semantic_version.match('2.1.3-rc.1+sha.5114f85')[part]
    end
  end

  test 'a media type captures its type' do
    assert_equal 'application', Regexes.media_type.match('application/vnd.api+json')[:type]
  end

  test 'a media type captures its subtype' do
    assert_equal 'vnd.api+json', Regexes.media_type.match('application/vnd.api+json')[:subtype]
  end

  {
    header:    'eyJhbGciOiJIUzI1NiJ9',
    payload:   'eyJzdWIiOiIxIn0',
    signature: 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'
  }.each do |part, value|
    test "a JSON web token captures its #{part}" do
      assert_equal value, Regexes.json_web_token.match(JWT)[part]
    end
  end

  # ── In text ─────────────────────────────────────────────────────────────────────────────────────────────

  test 'a UUID is found after a hyphen, as in a prefixed id' do
    assert_equal '01890a5d-ac96-774b-bcce-b302099a8057', 'order-01890a5d-ac96-774b-bcce-b302099a8057'[Regexes.uuid]
  end

  test 'a UUID is never found inside a longer run of hex digits' do
    assert_nil 'a01890a5d-ac96-774b-bcce-b302099a8057'[Regexes.uuid]
  end

  test 'a ULID is never found inside a longer word' do
    assert_nil 'x01ARZ3NDEKTSV4RRFFQ69G5FAV'[Regexes.ulid]
  end

  test 'a ULID in lowercase is read when asked to be' do
    assert_match Regexes.ulid.case_insensitive.whole, '01arz3ndektsv4rrffq69g5fav'
  end

  test 'a JSON web token is found after Bearer' do
    assert_equal JWT, "Bearer #{JWT}"[Regexes.json_web_token]
  end

  test 'a UUID without hyphens is thirty-two hex digits' do
    assert_match Regexes.hex_digits.exactly(32).whole, '01890a5dac96774bbcceb302099a8057'
  end
end
