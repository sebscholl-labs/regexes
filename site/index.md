---
layout: home
hero:
  name: regexes
  text: The regex you need, already written
  tagline: Patterns named for what they match — UUIDs, IP addresses, ISO 8601 times, IBANs — each a frozen Regexp that chains anchors, repetition and captures, tested against Ruby's own parsers and runs the same in JavaScript.
  actions:
    - theme: brand
      text: Quick Start
      link: /getting-started/
    - theme: alt
      text: Named Patterns
      link: /reference/patterns
features:
  - title: Named, not written inline
    details: "Regexes.uuid instead of a 36-character literal pasted into the third file that needs one."
  - title: Variations that chain
    details: "excluded, one_or_more, leading, whole, case_insensitive — each a new frozen pattern, the original untouched."
  - title: Still a Regexp
    details: "Every pattern is a Regexp subclass, so it goes into gsub, scan, match?, case and validates format: as it is."
---

## A taste

The patterns worth naming are the ones that are easy to get almost right.

**The IPv4 regex everyone writes finds addresses that aren't there.**

```ruby
log = 'Retry 10.0.0.1, not 1.2.3.456'

log.scan(/\d{1,3}(?:\.\d{1,3}){3}/)   # => ["10.0.0.1", "1.2.3.456"]
log.scan(Regexes.ipv4_address)         # => ["10.0.0.1"]
```

**IPv6 has nine compressed forms and an embedded IPv4 one.** Nobody writes it from memory.

```ruby
Regexes.ipv6_address.whole.match?('::ffff:192.0.2.1')  # => true
Regexes.ipv6_address.whole.match?('1::2::3')           # => false
```

**`^` and `$` are line anchors in Ruby,** so a validation written with them lets a second line through.

```ruby
"ok\nevil".match?(/^[a-z]+$/)                                  # => true
Regexes.lowercase_letters.one_or_more.whole.match?("ok\nevil")  # => false
```

**A date's fields have ranges,** and `\d{2}` doesn't know them.

```ruby
Regexes.iso8601_date_time.whole.match?('2026-11-21T14:30:05+05:30')  # => true
Regexes.iso8601_date_time.whole.match?('2026-13-21T25:61')           # => false
```

**Parts come back by name,** in the standard's own terms.

```ruby
version = Regexes.semantic_version.match('2.1.3-rc.1+sha.5114f85')
version[:prerelease]  # => "rc.1"
version[:build]       # => "sha.5114f85"

Regexes.http_url.match('http://[::1]:8080/a?b=c#d')[:host]  # => "[::1]"
```

**The same pattern runs in the browser** and in a JSON Schema, translated rather than copied by hand.

```ruby
Regexes.e164_phone_number.whole.ecma_source
# => "^(?<![0-9+])\\+[1-9][0-9]{1,14}(?![0-9])$"
```
