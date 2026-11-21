# Naming

A library of named patterns is only as useful as its names are predictable. If you can guess the name
of the pattern you need, you'll use it instead of writing the regex again. Every name follows these
rules.

## 1. The shape, never its use

A pattern is named for what it matches, not for what one application does with it.

| Named for the shape | Not for a use |
|---|---|
| `kebab_case` | `slug` |
| `snake_case` | `username` |
| `uuid` | `message_id_local_part` |
| `space_or_tab` | `header_unfolder` |

A shape is found and reused. A use is written again the next time, slightly differently. The grammar
of one format — a bounce address, a log line, a handle — belongs in the code that owns it, as a named
constant built from these.

## 2. Sets are plural, values are singular

A set of characters matches one character, but is named for the set: `digits`, `hex_digits`,
`combining_marks`. A value is named for the one thing it matches: `uuid`, `integer`, `domain_name`.

```ruby
Regexes.digits       # => /[0-9]/      one character of the set
Regexes.integer      # => /-?[0-9]+/   one whole number
```

## 3. Qualifiers before the noun, in a fixed order

Case first, then script or standard, then the noun:

- `lowercase_alphanumeric`, `uppercase_letters` (case)
- `unicode_letters`, `iso8601_date`, `alpha2_country_code` (script or standard)

So there's one place to look: `lowercase_hex_digits`, never `hex_digits_lowercase`.

## 4. ASCII unless the name says otherwise

`digits` is `[0-9]`, `letters` is `[A-Za-z]`. A set that reaches past ASCII says so in its name:
`unicode_letters`. The one exception is `whitespace`, which matches any script's spaces, because text
copied from a web page carries no-break and wide spaces and that's what the bare word is reached for.

## 5. Variations never become names

Anything a variation can express is written as one, so the library never holds two names for one
thing:

| Written as a variation | Never a name |
|---|---|
| `Regexes.digits.excluded` | `non_digits` |
| `Regexes.whitespace.one_or_more` | `whitespace_run` |
| `Regexes.uuid.whole` | `whole_uuid` |
| `Regexes.slash.one_or_more.trailing` | `trailing_slash` |
| `Regexes.slash.excluded.one_or_more` | `path_segment` |

## 6. A standard is named only when formats compete

When several formats exist for the same noun, the standard goes in the name: `iso8601_date`,
`alpha2_country_code`, `e164_phone_number`. When there's one, the noun is enough: `uuid`, `iban`,
`bic`, `currency_code`.

## 7. Abbreviations only where they are the common name

`uuid`, `url`, `ipv4`, `iban`, `bic`, `e164`, `cidr` — the names people search for. Never `num`,
`addr` or `str`.

## 8. Captures take the standard's terms

`email_address` captures `local` and `domain`; a semantic version captures `major`, `minor`, `patch`.
The words are the ones the standard uses, so its documentation and yours agree.

## 9. Shape, never meaning

A pattern checks what a format looks like, including any range the format defines: a month is `01` to
`12`, an hour `00` to `23`, an IPv4 octet `0` to `255`. It never checks what needs more than the
characters: a checksum (an IBAN's mod-97, a card's Luhn digit), the calendar (`2026-02-30` is a date's
shape) or whether an address exists. Each pattern's documentation says exactly where it stops.

## 10. International standards only

National formats — a US routing number, a postal code, one country's IBAN layout — belong in the
application that needs them, built from these pieces.
