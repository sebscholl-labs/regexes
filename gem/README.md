> **You are reading the gem package readme.** The repository also contains
> [`site/`](../site), the docs site. See the [root README](../README.md) for
> the layout overview.

# regexes

[![Gem Version](https://img.shields.io/gem/v/regexes)](https://rubygems.org/gems/regexes)
[![CI](https://github.com/sebscholl-labs/regexes/actions/workflows/ci.yml/badge.svg)](https://github.com/sebscholl-labs/regexes/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/sebscholl-labs/regexes)](https://github.com/sebscholl-labs/regexes/releases)
[![License](https://img.shields.io/github/license/sebscholl-labs/regexes)](https://github.com/sebscholl-labs/regexes/blob/main/LICENSE.txt)
[![Ruby](https://img.shields.io/badge/Ruby-%3E%3D%204.0-red)](https://rubygems.org/gems/regexes)

Regular expressions named for what they match, each with the variations it allows. Every pattern is a
frozen `Regexp`, so it goes anywhere a Regexp does: `gsub`, `match?`, `scan`, `case`, `validates format:`.

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

Regexes.lowercase_alphanumeric.excluded.one_or_more        # => /[^a-z0-9]+/
Regexes.lowercase_letters.excluded.one_or_more.leading     # => /\A[^a-z]+/
Regexes.uuid.whole.match?('01890a5d-ac96-774b-bcce-b302099a8057')  # => true

'northwind  erp!!'.gsub(Regexes.lowercase_alphanumeric.excluded.one_or_more, '_')  # => "northwind_erp_"
```

## Named patterns

| Kind                    | Patterns |
|-------------------------|----------|
| Sets of characters      | `lowercase_letters` `letters` `digits` `lowercase_alphanumeric` `alphanumeric` `word_characters` `hex_digits` `whitespace` `space_or_tab` `newline` `slash` `hyphen` |
| Characters and breaks   | `any_character` `line_break` `folded_line_break` `unfolded_line_break` |
| Numbers and identifiers | `integer` `uuid` `identifier` |
| Times                   | `utc_offset` `iso8601_date` `iso8601_time` `iso8601_date_time` |
| Addresses               | `http_scheme` `dns_label` `domain_name` `email_address` |
| Text                    | `markdown_code_span` |

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
