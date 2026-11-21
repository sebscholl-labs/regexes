# frozen_string_literal: true

module Regexes
  # ── Network ───────────────────────────────────────────────────────────────────────────────────────────────

  label        = '[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?'
  any_label    = '[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
  octet        = '(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
  ipv4         = "#{octet}(?:\\.#{octet}){3}"
  h16          = '[0-9a-fA-F]{1,4}'
  ls32         = "(?:#{h16}:#{h16}|#{ipv4})"
  ipv6         = [
    "(?:#{h16}:){6}#{ls32}",
    "::(?:#{h16}:){5}#{ls32}",
    "(?:#{h16})?::(?:#{h16}:){4}#{ls32}",
    "(?:(?:#{h16}:){0,1}#{h16})?::(?:#{h16}:){3}#{ls32}",
    "(?:(?:#{h16}:){0,2}#{h16})?::(?:#{h16}:){2}#{ls32}",
    "(?:(?:#{h16}:){0,3}#{h16})?::#{h16}:#{ls32}",
    "(?:(?:#{h16}:){0,4}#{h16})?::#{ls32}",
    "(?:(?:#{h16}:){0,5}#{h16})?::#{h16}",
    "(?:(?:#{h16}:){0,6}#{h16})?::"
  ].join('|').then { "(?:#{it})" }
  pchar        = "(?:[A-Za-z0-9\\-._~!$&'()*+,;=:@]|%[0-9A-Fa-f]{2})"
  hex_pair     = '[0-9A-Fa-f]{2}'

  URI_SCHEME   = Expression.new('[A-Za-z][A-Za-z0-9+.-]*:')
  HTTP_SCHEME  = Expression.new('https?://')
  HTTP_URL     = Expression.new(
    "https?://(?<host>#{any_label}(?:\\.#{any_label})*|\\[#{ipv6}\\])(?::(?<port>[0-9]{1,5}))?" \
    "(?<path>(?:/#{pchar}*)*)(?:\\?(?<query>(?:#{pchar}|[/?])*))?(?:\\#(?<fragment>(?:#{pchar}|[/?])*))?"
  )
  DNS_LABEL    = Expression.new(label, single: true)
  DOMAIN_NAME  = Expression.new("(?=[a-z0-9.-]{1,253}(?![a-z0-9.-]))#{label}(?:\\.#{label})+")
  IPV4_ADDRESS = Expression.new("(?<![0-9])#{ipv4}(?![0-9])")
  IPV6_ADDRESS = Expression.new("(?<![0-9a-fA-F:])#{ipv6}(?![0-9a-fA-F:])")
  IP_ADDRESS   = Expression.new("(?:#{IPV4_ADDRESS.source}|#{IPV6_ADDRESS.source})", single: true)
  IPV4_CIDR    = Expression.new("(?<address>#{IPV4_ADDRESS.source})/(?<prefix_length>3[0-2]|[12]?[0-9])(?![0-9])")
  IPV6_CIDR    = Expression.new(
    "(?<address>#{IPV6_ADDRESS.source})/(?<prefix_length>12[0-8]|1[01][0-9]|[1-9]?[0-9])(?![0-9])"
  )
  MAC_ADDRESS  = Expression.new(
    "(?<![0-9A-Fa-f:-])(?:#{hex_pair}(?::#{hex_pair}){5}|#{hex_pair}(?:-#{hex_pair}){5})(?![0-9A-Fa-f:-])"
  )

  # +Regexes.uri_scheme.leading+ finds the +mailto:+ of +mailto:ada@acme.example+ and the +https:+ of a web link.
  # Either case, as RFC 3986 §3.1 allows, so +.leading+ is its usual use.
  #
  # @return [Expression] a URI's scheme and the colon that ends it
  def uri_scheme = URI_SCHEME

  # +Regexes.http_scheme.leading.case_insensitive+ tells a web link from a +cid:+ or +mailto:+ one.
  #
  # @return [Expression] +http://+ or +https://+, in lowercase
  def http_scheme = HTTP_SCHEME

  # +Regexes.http_url.whole+ matches +https://acme.example+, +http://[::1]:8080/a?b=c#d+ and
  # +https://en.wikipedia.org/wiki/Ruby_(programming_language)+, never +https://+, +ftp://acme.example+, one
  # with a space or with user and password before the host. Every character after the host is one RFC 3986
  # allows there, and a +%+ starts a valid escape. It captures +host+, +port+, +path+, +query+ and +fragment+.
  #
  # In prose, a sentence's full stop after a link is a character a path allows, so it is matched; trim
  # +Regexes.literal('.').trailing+ from what it finds there.
  #
  # @return [Expression] an http or https URL with a host
  def http_url = HTTP_URL

  # +Regexes.dns_label.whole+ matches +acme+ and +mail-1+, never +-acme+, +acme-+, +Acme+ or a label of more
  # than 63 characters (RFC 1035 §2.3.4). An internationalized label is matched in its ASCII form, +xn--…+.
  #
  # @return [Expression] one label of a domain name, lowercase: letters, digits and inner hyphens
  def dns_label = DNS_LABEL

  # +Regexes.domain_name.whole+ matches +acme.example+ and +mail.acme.co.uk+, never +acme+, +acme..example+,
  # +acme.example.+ (a trailing dot) or a name of more than 253 characters.
  #
  # @return [Expression] two or more lowercase {#dns_label}s joined by dots
  def domain_name = DOMAIN_NAME

  # +Regexes.ipv4_address.whole+ matches +192.168.0.1+ and +0.0.0.0+, never +256.1.1.1+, +1.2.3+ or +01.2.3.4+
  # (a leading zero, which some parsers read as octal). It never matches inside a longer run of digits.
  #
  # @return [Expression] an IPv4 address in dotted-decimal form
  def ipv4_address = IPV4_ADDRESS

  # +Regexes.ipv6_address.whole+ matches +2001:db8::1+, +::1+, +::+ and +::ffff:192.0.2.1+, never +1:::2+,
  # +1::2::3+ or one with a zone (+fe80::1%eth0+). Every form RFC 4291 §2.2 writes, in either case.
  #
  # @return [Expression] an IPv6 address
  def ipv6_address = IPV6_ADDRESS

  # @return [Expression] an {#ipv4_address} or an {#ipv6_address}
  def ip_address = IP_ADDRESS

  # +Regexes.ipv4_cidr.whole+ matches +10.0.0.0/8+ and +192.168.1.0/24+, never +10.0.0.0/33+. Whether host bits
  # are set is not checked. It captures +address+ and +prefix_length+.
  #
  # @return [Expression] an IPv4 network in CIDR notation: an address, a slash and a prefix length of 0 to 32
  def ipv4_cidr = IPV4_CIDR

  # +Regexes.ipv6_cidr.whole+ matches +2001:db8::/32+ and +::/0+, never +::/129+. It captures +address+ and
  # +prefix_length+.
  #
  # @return [Expression] an IPv6 network in CIDR notation: an address, a slash and a prefix length of 0 to 128
  def ipv6_cidr = IPV6_CIDR

  # +Regexes.mac_address.whole+ matches +00:1A:2B:3C:4D:5E+ and +00-1a-2b-3c-4d-5e+, never one mixing colons and
  # hyphens, or of five pairs.
  #
  # @return [Expression] a MAC address (EUI-48): six pairs of hex digits joined by colons or by hyphens
  def mac_address = MAC_ADDRESS
end
