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
| `utc_offset` | `Z` `+05:30` `-0500` | `z` `+5:30` `05:00` |
| `iso8601_time` | `2026-11-21T14:30`, `2026-11-21 14:30:05.123Z`, `2026-11-21T14:30:05-05:00` | a date alone, `2026-11-21T14`, `21/11/2026 14:30` |

## Addresses

| Pattern | Matches | Refuses |
|---|---|---|
| `http_scheme` | `http://` `https://` | `HTTPS://` (use `.case_insensitive`), `ftp://` |
| `dns_label` | `acme` `mail-1` `a` `0` | `-acme` `acme-` `Acme` `ac_me` |
| `domain_name` | `acme.example` `mail.acme.co.uk` | `acme` `acme..example` `Acme.example` |
| `email_address` | `ada@acme.example` `a+b@x` | `ada` `@acme.example` `a da@x` `a@b@c` |

`email_address` checks only the shape: one `@` with something on either side and no whitespace.
Whether the address exists is for the mail to find out. It captures `local` and `domain`:

```ruby
match = Regexes.email_address.whole.match('ada@acme.example')
[match[:local], match[:domain]]  # => ["ada", "acme.example"]
```

## Text

| Pattern | Matches | Refuses |
|---|---|---|
| `backtick_code` | `` `get_order` `` `` `a b` `` | ` `` `, an unclosed backtick |

Markdown's inline code, its text captured as `code`:

```ruby
Regexes.backtick_code.match('call `get_order` now')[:code]  # => "get_order"
```
