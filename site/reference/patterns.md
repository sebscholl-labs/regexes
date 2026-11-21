# Named Patterns

Every named pattern is a method on `Regexes` that returns the same frozen
[expression](/concepts/expressions) each time. The examples are taken from the test suite, which checks
each pattern against them with `.whole`, and every pattern against long texts built to make it backtrack.

A pattern checks shape, never meaning: the ranges a format defines (a month's `01`–`12`, an octet's
`0`–`255`) but no checksum, no calendar, no list of assigned codes. A pattern made of a fixed count of
digits or letters never matches inside a longer run of them, so searching text finds whole values: `1.2.3.456`
holds no IPv4 address, `12026-11-21` no date.

The sections follow the library's files: [sets](#sets-of-characters), [breaks](#characters-and-breaks),
[numbers](#numbers), [identifiers](#identifiers), [times](#times), [network](#network), [mail](#mail),
[codes](#codes) and [text](#text).

## Sets of characters

Each matches one character and is a [`CharacterClass`](/concepts/character-sets), so it can be excluded
and extended. ASCII unless the name says otherwise.

| Pattern | Source | Matches | Refuses |
|---|---|---|---|
| `lowercase_letters` | `[a-z]` | `a` `z` | `A` `1` `é` |
| `uppercase_letters` | `[A-Z]` | `A` `Z` | `a` `1` `É` |
| `letters` | `[A-Za-z]` | `a` `Z` | `1` `_` `é` `ß` |
| `digits` | `[0-9]` | `0` `9` | `a`, Arabic-Indic `٣`, full-width `１` |
| `lowercase_alphanumeric` | `[a-z0-9]` | `a` `0` | `A` `_` `-` |
| `uppercase_alphanumeric` | `[A-Z0-9]` | `A` `0` | `a` `_` `-` |
| `alphanumeric` | `[A-Za-z0-9]` | `a` `Z` `0` | `_` `-` `é` |
| `word_characters` | `[A-Za-z0-9_]` | `a` `Z` `0` `_` | `-` space `é` |
| `binary_digits` | `[01]` | `0` `1` | `2` |
| `octal_digits` | `[0-7]` | `0` `7` | `8` `9` |
| `hex_digits` | `[0-9a-fA-F]` | `0` `a` `F` | `g` `G` |
| `base32_digits` | `[A-Z2-7]` | `A` `Z` `2` `7` | `a` `0` `1` `8` |
| `base58_digits` | `[1-9A-HJ-NP-Za-km-z]` | `1` `A` `z` | `0` `O` `I` `l` |
| `base64_digits` | `[A-Za-z0-9+/]` | `A` `z` `0` `+` `/` | `-` `_` `=` |
| `base64url_digits` | `[A-Za-z0-9\-_]` | `A` `z` `0` `-` `_` | `+` `/` `=` |
| `whitespace` | `[[:space:]]` | space, tab, line breaks, no-break space, ideographic space | `a`, zero-width space |
| `ascii_whitespace` | `[ \t\n\v\f\r]` | space, tab, line feed, vertical tab, form feed, carriage return | no-break space |
| `space_or_tab` | `[ \t]` | space, tab | `\n` `\r`, no-break space |
| `newline` | `[\n]` | `\n` | `\r`, space |
| `slash` | `[/]` | `/` | `\` `\|` |
| `hyphen` | `[\-]` | `-` | `_`, en dash `–`, minus `−` |
| `dashes` | `[\p{Pd}]` | `-` `‐` `–` `—` | minus `−`, `_` `~` |
| `apostrophes` | | `'` `` ` `` `´` `ʼ` `‘` `’` | `"` `″` |
| `double_quotes` | | `"` `“` `”` `„` `‟` | `'` `«` `»` |
| `unicode_letters` | `[\p{L}]` | `a` `é` `ß` `ж` `中` `ا` | `1` `٣` `_`, a combining accent |
| `unicode_digits` | `[\p{Nd}]` | `0` `٣` `३` `０` | `a` `½` `Ⅳ` |
| `combining_marks` | `[\p{M}]` | combining acute, diaeresis | `a`, a precomposed `é` |
| `control_characters` | `[\p{Cc}]` | NUL, tab, line feed, DEL, next line | space, zero-width space |
| `format_characters` | `[\p{Cf}]` | zero-width space and joiner, byte order mark, soft hyphen, direction marks | space, a combining accent |

`digits` is ASCII only, never another script's digits as `\d` can be in other engines; `unicode_digits`
is the one that takes them. `whitespace` takes the no-break and wide spaces pasted text carries, where
`ascii_whitespace` (Ruby's `\s`) does not. `space_or_tab` is what RFC 5322 calls WSP, which folds a mail
header.

Some codes are only a set and a count, and are written that way rather than named:

| Shape | Written |
|---|---|
| ISO 3166 alpha-2 country code | `Regexes.uppercase_letters.exactly(2)` |
| ISO 3166 alpha-3 country code, ISO 4217 currency code | `Regexes.uppercase_letters.exactly(3)` |
| Payment card number, digits run together | `Regexes.digits.between(12, 19)` |
| UUID without hyphens | `Regexes.hex_digits.exactly(32)` |
| SHA-256 digest in hex | `Regexes.hex_digits.exactly(64)` |
| A path segment | `Regexes.slash.excluded.one_or_more` |

Some sets clean text:

```ruby
'café'.unicode_normalize(:nfd).gsub(Regexes.combining_marks, '')  # => "cafe"
"a–b—c".gsub(Regexes.dashes, '-')                      # => "a-b-c"
text.gsub(Regexes.format_characters, '')                          # invisible characters out
```

## Characters and breaks

| Pattern | Matches | Refuses |
|---|---|---|
| `any_character` | one character: `a`, space, `é`, `\r` | `\n`, empty, `ab` |
| `line_break` | `\r\n`, `\r`, `\n` | `\n\n`, `\n\r`, space |
| `unicode_line_break` | `line_break`'s three, `\v`, `\f`, next line, line and paragraph separators | space, tab, `\n\n` |
| `paragraph_break` | `\n\n`, `\r\n\r\n`, `\n \t\n`, `\n\n\n` | `\n`, `\n a\n` |

`line_break` takes a CRLF whole, so `text.split(Regexes.line_break)` splits lines however they end. A
`paragraph_break` is two or more line breaks with nothing but spaces and tabs between them:

```ruby
"one\n\ntwo\n \n\nthree".split(Regexes.paragraph_break)  # => ["one", "two", "three"]
"a\n\n\n\nb".gsub(Regexes.paragraph_break, "\n\n")        # => "a\n\nb"
```

## Numbers

| Pattern | Matches | Refuses |
|---|---|---|
| `integer` | `42` `0` `-7` `007` | `4.2` `1e3` `+1` `1,000` |
| `unsigned_integer` | `42` `0` `007` | `-7` `4.2` |
| `positive_integer` | `1` `42` `100` | `0` `007` `-7` |
| `decimal` | `42` `-7.5` `0.25` | `.5` `5.` `1e3` `+1.5` `1,5` |
| `unsigned_decimal` | `42` `0.25` | `-7.5` `.5` |
| `json_number` | `0` `-12.5` `6.02e23` `1E-7` | `01` `.5` `1.` `NaN` `+1` `0x1F` |
| `latitude` | `51.5074` `-90` `90.0` `0` | `90.1` `91` `05` `+45` |
| `longitude` | `-0.1278` `180` `-179.99` | `180.5` `181` `0180` |
| `port_number` | `0` `443` `65535` | `65536` `0443` `-1` |

`decimal` and `unsigned_decimal` take `places:` to fix the digits after the point — an exact count, or
a range that may start at zero to make the point optional:

```ruby
Regexes.unsigned_decimal(places: 2)      # => /[0-9]+(?:\.[0-9]{2})/       money to the cent: 12.50
Regexes.unsigned_decimal(places: 0..6)   # => /[0-9]+(?:\.[0-9]{1,6})?/    up to six places: 12, 12.5
Regexes.decimal(places: 0)               # => /-?[0-9]+/
```

`json_number` agrees with Ruby's JSON parser on every text the test suite builds from its grammar, and
`port_number` is checked on every number from 0 to 70,000.

## Identifiers

| Pattern | Matches | Refuses |
|---|---|---|
| `identifier` | `get_order` `Tag2` `x` | `2tag` `get-order` `_x` |
| `snake_case` | `order` `line_item` `user_2fa` | `lineItem` `line__item` `_line` `line_` |
| `screaming_snake_case` | `MAX_RETRIES` `HTTP2` | `Max_Retries` `MAX__RETRIES` |
| `kebab_case` | `order-history` `2026-review` | `Order-History` `order--history` `-order` |
| `camel_case` | `lineItem` `getHTTPResponse` `order` | `LineItem` `line_item` |
| `pascal_case` | `LineItem` `HTTPServer` `A` | `lineItem` `Line_Item` |
| `uuid` | `01890a5d-ac96-774b-bcce-b302099a8057`, either case | without hyphens, in braces, a digit short or long |
| `ulid` | `01ARZ3NDEKTSV4RRFFQ69G5FAV` | lowercase, with `I` `L` `O` `U`, starting above `7` |
| `semantic_version` | `1.0.0` `2.1.3-rc.1` `1.0.0+build.5` | `1.0` `v1.0.0` `01.0.0` `1.0.0-01` |
| `media_type` | `text/html` `application/vnd.api+json` | `text` `text/html; charset=utf-8` |
| `json_web_token` | three base64url parts, header and payload starting `eyJ` | two parts, `abc.def.ghi` |
| `base64` | `QUJD` `QUI=` `QQ==` | `QUJ` `QU=I` `QR==` |
| `base64url` | `QUJD` `QUI` `QUI=` | `QU+J` `Q` `QR` |

`kebab_case` lets a word start with a digit, as a URL's slug often does; `snake_case` starts with a letter,
as an identifier does. `ulid` is uppercase, as its spec writes it; add `.case_insensitive` to read either.

`base64` and `base64url` are canonical: `QR==` is refused because its last digit carries bits the padding
says aren't there. So what they match, Ruby's strict decoder (`unpack1('m0')`) decodes — checked on every
text of up to four base64 characters.

Captures:

| Pattern | Captures |
|---|---|
| `semantic_version` | `major` `minor` `patch` `prerelease` `build` |
| `media_type` | `type` `subtype` |
| `json_web_token` | `header` `payload` `signature` |

```ruby
Regexes.semantic_version.match('2.1.3-rc.1')[:prerelease]  # => "rc.1"
```

## Times

| Pattern | Matches | Refuses |
|---|---|---|
| `utc_offset` | `Z` `+05:30` `-0500` `-23:59` | `z` `+5:30` `+24:00` `+05:60` `+05` |
| `iso8601_date` | `2026-11-21` `0000-01-01` `9999-12-31` | `2026-13-01` `2026-11-32` `20261121` `2026-1-21` |
| `iso8601_year_month` | `2026-11` | `2026-13` `202611` |
| `iso8601_time` | `14:30` `14:30:05` `23:59:60` `14:30:05.123` | `24:00` `14:60` `1430` `14:30:05,5` |
| `iso8601_date_time` | `2026-11-21T14:30`, `2026-11-21 14:30:05.123Z`, `2026-11-21T14:30:05-05:00` | a date alone, `2026-11-21T14`, `2026-11-21t14:30` |
| `iso8601_duration` | `P1Y2M10D` `PT1H30M` `P2W` `PT0.5S` | `P` `PT` `P1H` `P1DT` `P1.5Y` |
| `rfc3339_timestamp` | `2026-11-21T14:30:05Z`, `2026-11-21T14:30:05.123+05:30`, `2026-11-21t14:30:05z` | without seconds or offset, `…-0500` |

Each field is checked against its range — month `01`–`12`, day `01`–`31`, hour `00`–`23`, minute
`00`–`59`, second `00`–`60` (a leap second) — but never against the calendar: `2026-02-30` has a date's
shape. The test suite checks every value of every field, and one past each end.

Only ISO 8601's extended format (with hyphens and colons) is matched, and a fraction of a second is
written with a dot, as RFC 3339 and Ruby's `Time.iso8601` require. `iso8601_date_time` allows a space for
the `T`, as RFC 3339 does; `rfc3339_timestamp` is stricter where RFC 3339 is — seconds and an offset with
its colon required — and looser where it is: a lowercase `t` and `z`. In a duration, only the seconds take
a fraction.

## Network

| Pattern | Matches | Refuses |
|---|---|---|
| `uri_scheme` | `https:` `mailto:` `git+ssh:` `HTTPS:` | `https` `1http:` `https://` |
| `http_scheme` | `http://` `https://` | `HTTPS://` (use `.case_insensitive`), `ftp://` |
| `http_url` | `https://acme.example`, `http://[::1]:8080/a?b=c#d`, a Wikipedia link with parentheses | `https://`, `ftp://…`, a space, `user:pass@`, `%ZZ` |
| `dns_label` | `acme` `mail-1` `xn--bcher-kva` | `-acme` `acme-` `Acme` `ac_me`, 64 characters |
| `domain_name` | `acme.example` `mail.acme.co.uk` | `acme` `acme..example` `Acme.example` `acme.example.`, 254 characters |
| `ipv4_address` | `192.168.0.1` `0.0.0.0` `255.255.255.255` | `256.1.1.1` `1.2.3` `01.2.3.4` |
| `ipv6_address` | `2001:db8::1` `::1` `::` `::ffff:192.0.2.1` | `1:::2` `1::2::3` `fe80::1%eth0` |
| `ip_address` | either | |
| `ipv4_cidr` | `10.0.0.0/8` `192.168.1.0/24` | `10.0.0.0/33` `10.0.0.0/08` |
| `ipv6_cidr` | `2001:db8::/32` `::/0` | `::/129` `::/012` |
| `mac_address` | `00:1A:2B:3C:4D:5E` `00-1a-2b-3c-4d-5e` | colons and hyphens mixed, five pairs |

A `dns_label` is at most 63 characters and a `domain_name` at most 253 (RFC 1035). Both are lowercase; add
`.case_insensitive` to accept either case. An internationalized name is matched in its ASCII form (`xn--…`),
as DNS carries it.

`http_url` takes after the host only the characters RFC 3986 allows there, and a `%` only where it starts a
valid escape. A sentence's full stop after a link is a character a path allows, so it is matched; trim it
when reading links from prose. User and password before the host are refused.

`ipv4_address` refuses a leading zero, which some parsers read as octal. `ipv6_address` takes every form RFC
4291 writes, compressed or not, with an embedded IPv4 address, in either case, but no zone. Both agree with
Ruby's IPAddr on thousands of addresses it writes and near misses made from them.

Captures:

| Pattern | Captures |
|---|---|
| `http_url` | `host` `port` `path` `query` `fragment` |
| `ipv4_cidr`, `ipv6_cidr` | `address` `prefix_length` |

## Mail

| Pattern | Matches | Refuses |
|---|---|---|
| `email_address` | `ada@acme.example` `a+b@x` `ADA@ACME.EXAMPLE` | `ada` `a da@x` `a@b@c` `"ada"@acme.example` `ada@[127.0.0.1]` |
| `message_id` | `<01890a5d@acme.example>` `<a.b@[127.0.0.1]>` | without its angle brackets or its `@`, `<a..b@x>` |
| `header_field_name` | `Subject` `X-Original-To` `DKIM-Signature` | `Sub ject` `Subject:` |
| `folded_line_break` | a CRLF before a space or tab, which it doesn't take | |
| `unfolded_line_break` | a CRLF *not* before a space or tab | |

`email_address` is the address an HTML form's `type=email` input accepts (WHATWG HTML), so a browser and
your server reach the same verdict. Like the browser, it allows a domain of one label (`a+b@x`), dots
anywhere in the local part, and either case; it refuses quoted local parts and IP-literal domains. Whether
the address exists is for the mail to find out.

A header that runs over several lines is folded (RFC 5322 §2.2.3). Removing the folded breaks unfolds it,
and splitting on the unfolded ones separates headers:

```ruby
"Subject: a\r\n b".gsub(Regexes.folded_line_break, '')                  # => "Subject: a b"
"Subject: a\r\n b\r\nTo: c".split(Regexes.unfolded_line_break)           # => ["Subject: a\r\n b", "To: c"]
```

Captures:

| Pattern | Captures |
|---|---|
| `email_address` | `local` `domain` |
| `message_id` | `id_left` `id_right` |

## Codes

| Pattern | Matches | Refuses |
|---|---|---|
| `e164_phone_number` | `+14155552671` `+442071838750` | without the plus, with spaces, `+0…`, more than 15 digits |
| `iban` | `DE89370400440532013000` `GB82WEST12345698765432` | with spaces, lowercase, shorter than 15 or longer than 34 |
| `bic` | `DEUTDEFF` `DEUTDEFF500` | `DEUTDEF` `deutdeff` `DEUTDEFF5` |
| `language_tag` | `en` `en-US` `zh-Hant-TW` `es-419` `de-CH-1901` | `en_US` `en-` `e` |
| `hex_color` | `#fff` `#FFFFFF` `#ffff` `#ff000080` | `#ff` `#fffff` `fff` |

An IBAN's check digits are not verified, nor a code checked against those assigned. An IBAN is matched in
its electronic form, without the spaces it's printed with. A language tag's language may be 2 to 3 letters
or 5 to 8, so most short words have a tag's shape: validate tags with `.whole` rather than search prose for
them.

Captures:

| Pattern | Captures |
|---|---|
| `iban` | `country_code` `check_digits` `bban` |
| `bic` | `business_party_prefix` `country_code` `business_party_suffix` `branch_identifier` |
| `language_tag` | `language` `script` `region` |

## Text

::: v-pre
| Pattern | Matches | Refuses |
|---|---|---|
| `markdown_code_span` | `` `get_order` `` `` `a b` `` | ` `` `, an unclosed backtick |
| `markdown_link` | `[the docs](https://acme.example/docs)`, a destination with one level of parentheses | with a title, `[a][1]`, `[](b)` |
| `ruby_format_reference` | `%{name}` `%<count>d` `%<price>.2f` | `%%{name}` `%{}` `%<n>` |
| `mustache_tag` | `{{name}}` `{{{html}}}` `{{#items}}` `{{/items}}` `{{ user.name }}` | `{name}` `{{}}` `{{ }}` |
| `shell_variable_reference` | `$HOME` `${PORT}` | `\$HOME` `${PORT:-3000}` `$1` |
| `file_extension` | `.gz` `.rb` `.MP4` | `gz` `.tar.gz` (whole) |
| `emoji` | `👍` `👍🏽` `👨‍👩‍👧` `🇩🇪` `1️⃣` `©` | `a` `1` `#`, two emoji |
:::

`emoji` takes each emoji as the one character a reader sees — with its skin tone, its joiners, a flag's
pair of regional indicators. A character Unicode marks pictographic counts, so `©` and `™` do; a plain digit
does not. `file_extension` is usually wanted at the end of a name:

```ruby
Regexes.file_extension.trailing.match('backup.tar.gz')[:extension]  # => "gz"
```

Captures:

| Pattern | Captures |
|---|---|
| `markdown_code_span` | `code` |
| `markdown_link` | `text` `destination` |
| `ruby_format_reference` | `name` |
| `mustache_tag` | `name` `sigil` |
| `shell_variable_reference` | `name` |
| `file_extension` | `extension` |
