> **You are reading the gem package readme.** The repository also contains
> [`site/`](../site), the docs site. See the [root README](../README.md) for
> the layout overview.

# regexes

[![Gem Version](https://img.shields.io/gem/v/regexes)](https://rubygems.org/gems/regexes)
[![CI](https://github.com/sebscholl-labs/regexes/actions/workflows/ci.yml/badge.svg)](https://github.com/sebscholl-labs/regexes/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/sebscholl-labs/regexes)](https://github.com/sebscholl-labs/regexes/releases)
[![License](https://img.shields.io/github/license/sebscholl-labs/regexes)](https://github.com/sebscholl-labs/regexes/blob/main/LICENSE.txt)
[![Ruby](https://img.shields.io/badge/Ruby-%3E%3D%204.0-red)](https://rubygems.org/gems/regexes)

**The regex you need, already written.** Patterns named for what they match — UUIDs, IP addresses,
ISO 8601 times, IBANs — each a frozen `Regexp` that chains anchors, repetition and captures, tested against
Ruby's own parsers, and runs the same in JavaScript. Every pattern goes anywhere a Regexp does: `gsub`,
`match?`, `scan`, `case`, `validates format:`.

Full documentation: <https://sebscholl-labs.github.io/regexes/>

## Installation

```bash
bundle add regexes
```

or:

```bash
gem install regexes
```

## Usage

```ruby
require 'regexes'

# Search finds whole values: the usual IPv4 regex finds 1.2.3.456 here.
'Retry 10.0.0.1, not 1.2.3.456'.scan(Regexes.ipv4_address)   # => ["10.0.0.1"]

# Validate with .whole: \A and \z, never Ruby's line anchors ^ and $.
Regexes.lowercase_letters.one_or_more.whole.match?("ok\nevil")  # => false

# Every form IPv6 writes, and every field range ISO 8601 defines.
Regexes.ipv6_address.whole.match?('::ffff:192.0.2.1')            # => true
Regexes.iso8601_date_time.whole.match?('2026-13-21T25:61')       # => false

# Parts come back by name, in the standard's terms.
Regexes.semantic_version.match('2.1.3-rc.1+sha.5114f85')[:build]  # => "sha.5114f85"
Regexes.http_url.match('http://[::1]:8080/a?b=c#d')[:host]        # => "[::1]"

# Patterns chain, and compose into your own.
Regexes.digits.excluded.one_or_more                               # => /[^0-9]+/
Regexes.sequence(Regexes.lowercase_letters, Regexes.word_characters.between(0, 23)).whole
```

## Named patterns

| Section | Patterns |
|---|---|
| Sets of characters | `lowercase_letters` `uppercase_letters` `letters` `digits` `lowercase_alphanumeric` `uppercase_alphanumeric` `alphanumeric` `word_characters` `binary_digits` `octal_digits` `hex_digits` `base32_digits` `base58_digits` `base64_digits` `base64url_digits` `whitespace` `ascii_whitespace` `space_or_tab` `newline` `slash` `hyphen` `dashes` `apostrophes` `double_quotes` `unicode_letters` `unicode_digits` `combining_marks` `control_characters` `format_characters` |
| Characters and breaks | `any_character` `line_break` `unicode_line_break` `paragraph_break` |
| Numbers | `integer` `unsigned_integer` `positive_integer` `decimal(places:)` `unsigned_decimal(places:)` `json_number` `latitude` `longitude` `port_number` |
| Identifiers | `identifier` `snake_case` `screaming_snake_case` `kebab_case` `camel_case` `pascal_case` `uuid` `ulid` `semantic_version` `media_type` `json_web_token` `base64` `base64url` |
| Times | `utc_offset` `iso8601_date` `iso8601_year_month` `iso8601_time` `iso8601_date_time` `iso8601_duration` `rfc3339_timestamp` |
| Network | `uri_scheme` `http_scheme` `http_url` `dns_label` `domain_name` `ipv4_address` `ipv6_address` `ip_address` `ipv4_cidr` `ipv6_cidr` `mac_address` |
| Mail | `email_address` `message_id` `header_field_name` `folded_line_break` `unfolded_line_break` |
| Codes | `e164_phone_number` `iban` `bic` `language_tag` `hex_color` |
| Text | `markdown_code_span` `markdown_code_block` `markdown_link` `ruby_format_reference` `mustache_tag` `shell_variable_reference` `file_extension` `emoji` |

Each checks shape, never meaning (no checksums, no calendar), and one made of a fixed count of digits or
letters never matches inside a longer run, so searching text finds whole values. Codes that are only a set and
a count are written as one: a country code is `Regexes.uppercase_letters.exactly(2)`. The
[reference](https://sebscholl-labs.github.io/regexes/reference/patterns) says what each matches, refuses and
captures.

Names follow [a fixed set of conventions](https://sebscholl-labs.github.io/regexes/design/naming), so the
one you need can be guessed.

## Variations

Every pattern chains these. Each returns a new frozen pattern and leaves the original as it was.

- **Anchors:** `leading` (`\A`), `trailing` (`\z`), `whole` (both) anchor to the text, never a line.
  `line_leading`, `line_trailing` and `whole_line` anchor to a line, ended by `\r\n`, `\r` or `\n`.
- **Repetition:** `one_or_more`, `zero_or_more`, `optional`, `exactly(n)`, `at_least(n)`, `between(min, max)`.
  Repeating a multi-part pattern groups it first, so `ab` repeated is `abab`. Repeat before anchoring.
- **Case:** `case_insensitive`.
- **Captures:** `captured(:name)`, read back with `match[:name]`.
- **Lookarounds:** `followed_by(other)`, `not_followed_by(other)`, `preceded_by(other)`, `not_preceded_by(other)`.
- **Sets only:** `excluded` (`[^…]`) and `including(characters)`.

## Composition

```ruby
handle = Regexes.sequence(Regexes.lowercase_letters, Regexes.word_characters.between(0, 23)).whole
ends   = Regexes.either(Regexes.hyphen.one_or_more.leading, Regexes.hyphen.one_or_more.trailing)

'--acme-mail-'.gsub(ends, '')  # => "acme-mail"
```

A case-insensitive part stays case-insensitive inside a case-sensitive sequence. `Regexes.literal(text)`
matches text character for character, the safe way to put a value into a pattern:

```ruby
Regexes.literal('.ns.cloudflare.com').trailing   # dots that mean dots
```

## In JavaScript and JSON Schema

Every pattern but `emoji` translates into ECMAScript, for the browser, a mobile app or a JSON Schema
`pattern`:

```ruby
Regexes.uuid.whole.ecma_source   # => "^(?<![0-9a-fA-F])[0-9a-fA-F]{8}-…$"
Regexes.uuid.whole.ecma_flags    # => "u"
```

What the two languages write differently is rewritten (`\A` becomes `^`, the dot `[^\n]`); what ECMAScript
can't match the same way (`Regexes.emoji`'s grapheme clusters) raises `Regexes::UntranslatableError`. The test
suite runs every translated pattern in Node against Ruby.

## Your own patterns

Register a shape of your application's and it's named, varied and composed like the built-in ones:

```ruby
Regexes.register(:order_reference, /ORD-[0-9]{6}/)

Regexes.order_reference.whole.match?('ORD-004211')  # => true
Regexes.registered                                   # => [:order_reference]
```

Register the shape unanchored, under a snake_case name nothing else uses; anything else raises
`ArgumentError`.

## Development

```sh
bin/setup
bundle exec rake          # tests + RuboCop
bin/console               # IRB with regexes loaded
```

## License

[MIT](./LICENSE.txt)
