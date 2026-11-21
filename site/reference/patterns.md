# Named Patterns

Every named pattern is a module function on `Regexes` that returns the same frozen object each time.
The examples below are taken from the test suite, which checks each pattern against them with
`.whole`.

## Sets of characters

Each is a [`CharacterClass`](/concepts/character-sets).

| Pattern | Source | Matches | Refuses |
|---|---|---|---|
| `lowercase_letters` | `[a-z]` | `a` `z` | `A` `1` `é` |
| `letters` | `[A-Za-z]` | `a` `Z` | `1` `_` `é` |
| `digits` | `[0-9]` | `0` `9` | `a`, Arabic-Indic `٣` |
| `lowercase_alphanumeric` | `[a-z0-9]` | `a` `0` | `A` `_` `-` |
| `alphanumeric` | `[A-Za-z0-9]` | `a` `Z` `0` | `_` `-` |
| `word_characters` | `[A-Za-z0-9_]` | `a` `Z` `0` `_` | `-` space `é` |
| `hex_digits` | `[0-9a-fA-F]` | `0` `a` `F` | `g` `G` |
| `whitespace` | `[[:space:]]` | space, tab, `\n`, `\r`, no-break space, ideographic space | `a` `_` |
| `space_or_tab` | `[ \t]` | space, tab | `\n` `\r`, no-break space |
| `newline` | `[\n]` | `\n` | `\r`, space |
| `slash` | `[/]` | `/` | `\` `\|` |
| `hyphen` | `[\-]` | `-` | `_`, en dash `–` |

`digits` is ASCII only, never another script's digits as `\d` can be. `whitespace` is the one that
means any script's spaces; `space_or_tab` is what RFC 5322 calls WSP, which folds a mail header.

## Characters and breaks

| Pattern | Matches | Refuses |
|---|---|---|
| `any_character` | one character: `a`, space, `é` | `\n`, empty, `ab` |
| `line_break` | `\r\n`, `\r`, `\n` | `\n\n`, space |
| `folded_line_break` | a CRLF followed by a space or tab, which it doesn't take | |
| `unfolded_line_break` | a CRLF *not* followed by a space or tab | |

A header that runs over several lines is folded (RFC 5322 §2.2.3). Removing the folded breaks unfolds
it, and splitting on the unfolded ones separates headers:

```ruby
"Subject: a\r\n b".gsub(Regexes.folded_line_break, '')
# => "Subject: a b"

"Subject: a\r\n b\r\nTo: c".split(Regexes.unfolded_line_break)
# => ["Subject: a\r\n b", "To: c"]
```

## Numbers and identifiers

| Pattern | Matches | Refuses |
|---|---|---|
| `integer` | `0` `42` `-7` | `4.2` `1e3` `+1` `-` |
| `uuid` | `01890a5d-ac96-774b-bcce-b302099a8057`, either case | without hyphens, one digit short |
| `identifier` | `get_order` `Tag2` `x` | `2tag` `get-order` `_x` |

## Times

| Pattern | Matches | Refuses |
|---|---|---|
| `utc_offset` | `Z` `+05:30` `-0500` `-23:59` | `z` `+5:30` `+24:00` `+05:60` `+05` |
| `iso8601_date` | `2026-11-21` `0000-01-01` `9999-12-31` | `2026-13-01` `2026-11-32` `20261121` `2026-1-21` |
| `iso8601_time` | `14:30` `14:30:05` `23:59:60` `14:30:05.123` | `24:00` `14:60` `1430` `14:30:05,5` |
| `iso8601_date_time` | `2026-11-21T14:30`, `2026-11-21 14:30:05.123Z`, `2026-11-21T14:30:05-05:00` | a date alone, `2026-11-21T14`, `2026-11-21t14:30`, `21/11/2026 14:30` |

Each field is checked against its range — month `01`–`12`, day `01`–`31`, hour `00`–`23`, minute
`00`–`59`, second `00`–`60` (a leap second) — but never against the calendar: `2026-02-30` has a date's
shape. Only ISO 8601's extended format (with hyphens and colons) is matched, and a fraction of a
second is written with a dot, as RFC 3339 and Ruby's `Time.iso8601` require. `iso8601_date_time`
allows a space for the `T`, as RFC 3339 does.

## Addresses

| Pattern | Matches | Refuses |
|---|---|---|
| `http_scheme` | `http://` `https://` | `HTTPS://` (use `.case_insensitive`), `ftp://` |
| `dns_label` | `acme` `mail-1` `a` `0` `xn--bcher-kva` | `-acme` `acme-` `Acme` `ac_me`, 64 characters |
| `domain_name` | `acme.example` `mail.acme.co.uk` | `acme` `acme..example` `Acme.example` `acme.example.`, 254 characters |
| `email_address` | `ada@acme.example` `a+b@x` `ADA@ACME.EXAMPLE` | `ada` `@acme.example` `a da@x` `a@b@c` `"ada"@acme.example` |

A `dns_label` is at most 63 characters and a `domain_name` at most 253 (RFC 1035). Both are lowercase;
add `.case_insensitive` to accept either case. An internationalized name is matched in its ASCII form
(`xn--…`), as DNS carries it.

`email_address` is the address an HTML form's `type=email` input accepts (WHATWG HTML), so a browser and
your server reach the same verdict. Like the browser, it allows a domain of one label (`a+b@x`), dots
anywhere in the local part, and either case; it refuses quoted local parts and IP-literal domains. Whether
the address exists is for the mail to find out. It captures `local` and `domain`:

```ruby
match = Regexes.email_address.whole.match('ada@acme.example')
[match[:local], match[:domain]]  # => ["ada", "acme.example"]
```

## Text

| Pattern | Matches | Refuses |
|---|---|---|
| `markdown_code_span` | `` `get_order` `` `` `a b` `` | ` `` `, an unclosed backtick |

Markdown's inline code — a code span, in CommonMark's terms — its text captured as `code`. Only the
single-backtick form is matched:

```ruby
Regexes.markdown_code_span.match('call `get_order` now')[:code]  # => "get_order"
```
