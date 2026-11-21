# frozen_string_literal: true

require 'test_helper'

# Tests for the network's shapes: URIs and URLs, domain names, IP and MAC addresses.
class RegexesNetworkTest < RegexesTestCase
  LONGEST_DOMAIN = "#{(['a' * 63] * 3).join('.')}.#{'b' * 61}".freeze
  WIKIPEDIA      = 'https://en.wikipedia.org/wiki/Ruby_(programming_language)'

  cases({
          uri_scheme:   [%w[https: mailto: urn: git+ssh: x-y.z+1: HTTPS:], ['https', '1http:', '+a:', '', ':', 'ht tp:', 'https://']],
          http_scheme:  [%w[http:// https://], ['HTTPS://', 'ftp://', 'http:', 'https//', '']],
          http_url:     [['https://acme.example', 'http://acme.example/', 'https://acme.example:8443/a/b?c=d&e=f#top',
                          'http://[::1]:8080/a?b=c#d', WIKIPEDIA, 'https://acme.example/caf%C3%A9', 'http://192.168.0.1/admin',
                          'https://ACME.EXAMPLE/Path', 'https://localhost:3000', 'https://acme.example/?', 'https://acme.example/#'],
                         ['https://', 'ftp://acme.example', 'https://acme example', 'https://user:pass@acme.example',
                          'https://acme.example/caf%ZZ', 'https://acme.example/<script>', 'https://acme.example/"q"',
                          '//acme.example', 'https:/acme.example', 'https://-acme.example', 'https://acme.example:123456',
                          'https://[1::2::3]/', '']],
          dns_label:    [['acme', 'mail-1', 'a', '0', 'xn--bcher-kva', 'a' * 63, "a#{'-' * 61}a"],
                         ['-acme', 'acme-', 'Acme', 'ac_me', 'acme.example', '', 'a' * 64, 'ac me', 'äcme']],
          domain_name:  [['acme.example', 'mail.acme.co.uk', '1.example', 'xn--bcher-kva.example', "#{'a' * 63}.example", LONGEST_DOMAIN],
                         ['acme', 'acme..example', '.acme.example', 'Acme.example', 'acme.example.', "#{'a' * 64}.example",
                          "#{LONGEST_DOMAIN}b", 'acme-.example', '-acme.example', 'ac_me.example', '']],
          ipv4_address: [%w[192.168.0.1 0.0.0.0 255.255.255.255 10.0.0.1 1.2.3.4 100.64.0.1 249.250.251.252],
                         ['256.1.1.1', '1.2.3', '01.2.3.4', '1.2.3.4.5', '1.2.3.04', '1.2.3. 4', '1.2.3.-4', '', '1..2.3',
                          '300.300.300.300', '1.2.3.4 ']],
          ipv6_address: [%w[2001:db8::1 ::1 :: ::ffff:192.0.2.1 2001:0db8:0000:0000:0000:ff00:0042:8329 fe80::1ff:fe23:4567:890a
                            1:2:3:4:5:6:7:8 1:2:3:4:5:6:1.2.3.4 1:: ::2:3:4:5:6:7:8 FE80::1 64:ff9b::192.0.2.33],
                         %w[1:::2 1::2::3 fe80::1%eth0 1:2:3:4:5:6:7:8:9 1:2:3:4:5:6:7 12345::1 g::1 ::ffff:256.0.0.1
                            1:2:3:4:5:6:7:1.2.3.4 : ::: [::1]] + ['']],
          ip_address:   [%w[192.168.0.1 ::1 2001:db8::1], ['256.1.1.1', '1::2::3', '']],
          ipv4_cidr:    [%w[10.0.0.0/8 192.168.1.0/24 0.0.0.0/0 1.2.3.4/32], ['10.0.0.0/33', '10.0.0.0', '10.0.0.0/', '10.0.0.0/08', '256.0.0.0/8', '']],
          ipv6_cidr:    [%w[2001:db8::/32 ::/0 ::1/128 fe80::/10], ['::/129', '2001:db8::', '2001:db8::/', '::/012', '1::2::3/64', '']],
          mac_address:  [%w[00:1A:2B:3C:4D:5E 00-1a-2b-3c-4d-5e ff:ff:ff:ff:ff:ff],
                         %w[00:1A:2B:3C:4D 00:1A:2B-3C:4D:5E 001A.2B3C.4D5E 001A2B3C4D5E 00:1A:2B:3C:4D:5E:6F 0:1A:2B:3C:4D:5E
                            00:1G:2B:3C:4D:5E] + ['']]
        }, defined_in: 'network')

  # ── Captures ────────────────────────────────────────────────────────────────────────────────────────────

  {
    host:     'acme.example',
    port:     '8443',
    path:     '/a/b',
    query:    'c=d&e=f',
    fragment: 'top'
  }.each do |part, value|
    test "an http URL captures its #{part}" do
      assert_equal value, Regexes.http_url.match('https://acme.example:8443/a/b?c=d&e=f#top')[part]
    end
  end

  test 'an http URL captures an IPv6 host with its brackets' do
    assert_equal '[::1]', Regexes.http_url.match('http://[::1]:8080/')[:host]
  end

  test 'an http URL without a port captures none' do
    assert_nil Regexes.http_url.match('https://acme.example/')[:port]
  end

  test 'an IPv4 network captures its address' do
    assert_equal '10.0.0.0', Regexes.ipv4_cidr.match('10.0.0.0/8')[:address]
  end

  test 'an IPv4 network captures its prefix length' do
    assert_equal '8', Regexes.ipv4_cidr.match('10.0.0.0/8')[:prefix_length]
  end

  test 'an IPv6 network captures its prefix length' do
    assert_equal '32', Regexes.ipv6_cidr.match('2001:db8::/32')[:prefix_length]
  end

  # ── In text ─────────────────────────────────────────────────────────────────────────────────────────────

  test 'an IPv4 address is never found inside a longer run of digits' do
    assert_equal %w[10.0.0.1], 'see 1.2.3.456 and 10.0.0.1'.scan(Regexes.ipv4_address)
  end

  test 'an IPv4 address ending a sentence is found without the full stop' do
    assert_equal '10.0.0.1', 'connect to 10.0.0.1.'[Regexes.ipv4_address]
  end

  test 'an IPv6 address is found whole, never a part of it' do
    assert_equal %w[2001:db8::1], 'from 2001:db8::1 today'.scan(Regexes.ipv6_address)
  end

  test 'a MAC address is never found inside a longer one' do
    assert_nil '00:1A:2B:3C:4D:5E:6F'[Regexes.mac_address]
  end

  test 'a URL in prose takes the full stop after it, which a path allows' do
    assert_equal 'https://acme.example/docs.', 'Read https://acme.example/docs.'[Regexes.http_url]
  end

  test 'a URL scheme leads a mailto link' do
    assert_equal 'mailto:', 'mailto:ada@acme.example'[Regexes.uri_scheme.leading]
  end

  test 'a domain name of 253 characters within longer text is not cut short to fit' do
    assert_nil "#{LONGEST_DOMAIN}b"[Regexes.domain_name.leading]
  end

  test 'a domain name in either case is read when asked to be' do
    assert_match Regexes.domain_name.case_insensitive.whole, 'Acme.Example'
  end
end
