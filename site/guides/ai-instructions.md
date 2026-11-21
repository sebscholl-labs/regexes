# Instructions for AI Assistants

This page is written for a coding assistant working in a Ruby project that has `regexes` in its Gemfile,
or adding it. Follow it whenever the task involves a regular expression: writing one, reviewing one, or
replacing one. The [reference](/reference/patterns) is the source of truth for what each pattern matches.

## Procedure

1. **Name the shape.** Say what the text is, not what the code does with it: "an IPv4 address", not
   "the thing we check before connecting".
2. **Find it.** Look it up in the [reference](/reference/patterns), by section: sets of characters,
   breaks, numbers, identifiers, times, network, mail, codes, text. Use only a name the reference lists.
   Never guess one: `Regexes.ipv4` and `Regexes.non_digits` don't exist.
3. **If it's a set and a count, write it as one.** A country code is `Regexes.uppercase_letters.exactly(2)`,
   a currency code `.exactly(3)`, a SHA-256 digest `Regexes.hex_digits.exactly(64)`. These have no names
   on purpose.
4. **Vary it for the job:**
   - to **validate** a whole value: `.whole`;
   - to **search** text: use it as it is, unanchored;
   - to **parse** a value at the start of a text: `.leading`;
   - to **read a part**: a capture the reference lists (`match[:host]`), or `.captured(:name)`;
   - to match **per line**: `.line_leading`, `.line_trailing`, `.whole_line`.
5. **Compose** larger shapes with `Regexes.sequence` and `Regexes.either`, and put fixed text in with
   `Regexes.literal`.
6. **If the shape is the application's own** (an order reference, a national format), register it once
   at boot and use it by name: `Regexes.register(:order_reference, /ORD-[0-9]{6}/)`.
7. **For JavaScript or a JSON Schema,** translate: `pattern.whole.ecma_source` and `pattern.ecma_flags`.
8. **Verify** with the examples the reference gives for the pattern: what it matches and what it refuses.

## Rules

- **Never write `^` or `$` to validate.** In Ruby they are line anchors: `/^[a-z]+$/` accepts
  `"ok\nevil"`. Use `.whole` (`\A…\z`). For lines, use the line anchors.
- **Never interpolate a value into a pattern.** `/#{suffix}\z/` lets the value's dots and pluses match more
  than they say. Use `Regexes.literal(suffix).trailing`.
- **Never write a set's complement by hand.** "Anything but digits" is `Regexes.digits.excluded`.
- **Don't reach for `\d`, `\w`, `\s`.** Use the named sets: `digits`, `word_characters`, `whitespace`
  (any script's spaces) or `ascii_whitespace` (Ruby's `\s`).
- **Repeat, then anchor.** `Regexes.digits.leading.one_or_more` raises; write
  `Regexes.digits.one_or_more.leading`.
- **A pattern checks shape, not meaning.** `iban` doesn't verify check digits, `iso8601_date` accepts
  `2026-02-30`. Check meaning in code after the match.
- **Patterns are frozen.** Every variation returns a new pattern; keep them in constants freely.
- **Don't register a pattern the library has,** and register only unanchored shapes under snake_case
  names: `register` raises otherwise.

## Recipes

| Need | Write |
|---|---|
| Keep only the digits of a phone number | `phone.gsub(Regexes.digits.excluded, '')` |
| Collapse runs of whitespace, including no-break spaces | `text.gsub(Regexes.whitespace.one_or_more, ' ')` |
| Trim a trailing slash | `url.sub(Regexes.slash.one_or_more.trailing, '')` |
| Split a list on commas and spaces | `list.split(Regexes.either(Regexes.literal(','), Regexes.whitespace).one_or_more)` |
| Validate a country code | `Regexes.uppercase_letters.exactly(2).whole` |
| Validate money to the cent | `Regexes.unsigned_decimal(places: 2).whole` |
| Find a UUID in a path | `path[Regexes.uuid]` |
| Validate an email in a model | `validates :email, format: { with: Regexes.email_address.whole }` |
| Close up blank lines | `text.gsub(Regexes.paragraph_break, "\n\n")` |
| Unfold a mail header | `header.gsub(Regexes.folded_line_break, '')` |
| Read a fenced code block's language and code | `markdown.match(Regexes.markdown_code_block.line_leading)` → `[:language]`, `[:code]` |
| An application's own format, with a part | `Regexes.sequence(Regexes.literal('ORD-'), Regexes.digits.exactly(6).captured(:number)).whole` |
| A JSON Schema `pattern` | `Regexes.e164_phone_number.whole.ecma_source` |

## Replacing a raw regex

When the task is to replace a hand-written regex with the library:

1. Read what the regex is **for** (validation, search, parsing) and what shape it means.
2. Find the named pattern and the variation (steps 2 to 4 above).
3. Compare the two on the regex's own tests, and on the reference's examples for the pattern. A raw
   regex is often wrong at the edges (it accepts `1.2.3.456`, `2026-13-01`, a second line): say which
   edge cases change, rather than reproduce the old behavior silently.
4. Replace any `^`/`$` in a validation with `.whole`, and any interpolation with `Regexes.literal`.

## API

**Variations**, on every pattern, each returning a new frozen pattern:

| Method | Does |
|---|---|
| `leading`, `trailing`, `whole` | anchor to the start, end or all of the text (`\A`, `\z`) |
| `line_leading`, `line_trailing`, `whole_line` | anchor to a line, ended by `\r\n`, `\r` or `\n` |
| `one_or_more`, `zero_or_more`, `optional` | repeat |
| `exactly(n)`, `at_least(n)`, `between(min, max)` | repeat a number of times |
| `case_insensitive` | match letters of either case |
| `captured(name)` | capture under a name |
| `followed_by(x)`, `not_followed_by(x)` | match only where `x` does or doesn't come next |
| `preceded_by(x)`, `not_preceded_by(x)` | match only where `x` does or doesn't come before (fixed-length `x`) |
| `ecma_source`, `ecma_flags` | the pattern for JavaScript and JSON Schema |

**Sets only:** `excluded` (every character not in the set) and `including(characters)`.

**Module functions:** `Regexes.sequence(*parts)`, `Regexes.either(*alternatives)`, `Regexes.literal(text)`,
`Regexes.register(name, pattern)`, `Regexes.registered`.

**Errors:** `ArgumentError` for a bad variation or registration; `Regexes::UntranslatableError` from
`ecma_source` for what ECMAScript can't match the same way (only `emoji` among the named patterns).

## Changing the library itself

When working in the `regexes` repository rather than using the gem, follow its `CLAUDE.md` and
`.claude/rules/`: the [naming conventions](/design/naming), one constant and one endless method per
pattern, a row in its section's case table, and the reference page updated in the same commit.
