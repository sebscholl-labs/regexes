# JavaScript and JSON Schema

A pattern your Ruby validates with is often needed elsewhere: in the browser, in a React Native app, in a
JSON Schema an API publishes. Copying the regex by hand is how the two drift apart — and Ruby and
ECMAScript don't read every regex the same way. `ecma_source` and `ecma_flags` translate it.

```ruby
pattern = Regexes.uuid.whole

pattern.ecma_source  # => "^[0-9a-fA-F]{8}-…-[0-9a-fA-F]{12}$"
pattern.ecma_flags   # => "u"
```

```js
const uuid = new RegExp(source, flags);
uuid.test('01890a5d-ac96-774b-bcce-b302099a8057');  // true
```

## In a JSON Schema

A JSON Schema `pattern` searches the value, as an unanchored expression does, so give it a `.whole`
expression's source:

```ruby
{
  type: 'string',
  pattern: Regexes.e164_phone_number.whole.ecma_source
}
```

The anchors it writes are `^` and `$`, which in ECMAScript — without the `m` flag — anchor to the whole
value. A validator that runs schema patterns through Ruby's `Regexp` reads `^` and `$` as line anchors
instead, and lets `"+14155552671\nanything"` through; validate with a JSON Schema library in ECMAScript mode
(json_schemer's `regexp_resolver: 'ecma'`), or keep the Ruby expression for Ruby.

A schema carries no flags. A pattern whose `ecma_flags` holds `i` (it ignores case) can't be written into a
schema as it is.

## What changes

The two languages write some things differently, and the translation rewrites them:

| Ruby | ECMAScript | Why |
|---|---|---|
| `\A` `\z` | `^` `$` | ECMAScript's, without `m`, anchor to the text |
| `.` | `[^\n]` | ECMAScript's dot also refuses `\r` and the line separators |
| `[[:space:]]` | `\p{White_Space}` | ECMAScript has no POSIX brackets |
| `\R` | `(?:\r\n\|[\n\v\f\r\x85  ])` | ECMAScript has no line break escape |
| `\s` | `[ \t\n\v\f\r]` | ECMAScript's `\s` takes every script's spaces |
| `\#`, `\ `, a lone `{` | `#`, ` `, `\{` | ECMAScript's `u` mode refuses escapes that mean nothing, and requires them where Ruby doesn't |

The flags are always `u` — for the Unicode property escapes several patterns use, and its strict escapes —
and `iu` when the expression ignores case.

## What can't be translated

Where ECMAScript has no faithful equivalent, `ecma_source` raises `Regexes::UntranslatableError` rather than
hand back a pattern that matches something else:

- a grapheme cluster, `\X` — which is why `Regexes.emoji` can't be translated;
- a capture name used twice (a back-reference to a name, `\k<fence>`, is kept, as ECMAScript reads it alike;
  one by number is refused), atomic groups, and inline options such as a case-insensitive part inside a
  case-sensitive sequence;
- Ruby's `^`, `$` and `\Z`, and the hex escape `\h`;
- extended mode (`x`), and a dot that matches newlines (`m`).

Every other named pattern translates. The test suite runs each one in Node on every text of its case table
and checks that JavaScript reaches the same verdict as Ruby, whole and in a search.

Lookbehind, which many patterns use for their [token boundaries](/design/decisions#searching-finds-whole-values),
needs ES2018: every current browser and Node has it.
