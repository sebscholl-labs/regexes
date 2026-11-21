# Expressions

Every pattern is a `Regexes::Expression`, a subclass of `Regexp`. It goes anywhere a `Regexp` does,
equals the literal it stands for, and sets `Regexp.last_match` as usual.

```ruby
Regexes.lowercase_letters.excluded.one_or_more.leading == /\A[^a-z]+/  # => true
```

Each variation below returns a **new**, frozen expression. The one it came from is never changed,
so a pattern kept in a constant is safe to hand to any caller.

## Anchors

| Method | Writes | Matches |
|---|---|---|
| `leading` | `\A…` | only at the start of the text |
| `trailing` | `…\z` | only at the end of the text |
| `whole` | `\A…\z` | the whole text |

```ruby
'ab1cd'[Regexes.lowercase_letters.one_or_more.leading]   # => "ab"
'ab1cd'[Regexes.lowercase_letters.one_or_more.trailing]  # => "cd"
Regexes.lowercase_letters.one_or_more.whole.match?('abc1')  # => false
```

The anchors are the **text's**, never a line's. `^` and `$` would let a later line satisfy the
pattern, and `$` passes over a final newline:

```ruby
"1\nab"[Regexes.lowercase_letters.one_or_more.leading]  # => nil
"ab\n"[Regexes.lowercase_letters.one_or_more.trailing]  # => nil
```

A pattern that never matches inside a longer run, such as `uuid`, is bounded by lookarounds that refuse
the characters around it. At an end anchored to the text there is nothing left to refuse, so `leading`,
`trailing` and `whole` leave that end's boundary out, and the pattern matches exactly as before:

```ruby
Regexes.uuid.whole.source  # => "\\A[0-9a-fA-F]{8}-…-[0-9a-fA-F]{12}\\z"
```

`leading.trailing` is the same as `whole`. Each end holds one anchor, so anchoring an end again
replaces its anchor, and anchoring twice the same way is anchoring once. `leading?` and `trailing?` say
where an expression is anchored.

## Line anchors

When the text has lines — a mail header block, a Markdown document, a log — anchor to a line instead:

| Method | Matches |
|---|---|
| `line_leading` | only at the start of a line |
| `line_trailing` | only at the end of a line |
| `whole_line` | a whole line |

```ruby
"ab1\r\ncd2\nef".scan(Regexes.lowercase_letters.one_or_more.line_leading)  # => ["ab", "cd", "ef"]
"ab1\r\ncd2".scan(Regexes.digits.one_or_more.line_trailing)              # => ["1", "2"]
"ab1\ncd\n2ef".scan(Regexes.lowercase_letters.one_or_more.whole_line)     # => ["cd"]
```

A line ends in `\r\n`, `\r` or `\n` — the three breaks [`line_break`](/reference/patterns#characters-and-breaks)
matches — and `\r\n` is one break, never two. That's where these differ from `^` and `$`, which know only
`\n`: `$` ends a line between the `\r` and the `\n`, and `^` never starts one after a lone `\r`.
`line_leading?` and `line_trailing?` say where an expression is anchored to a line.

## Repetition

| Method | Writes |
|---|---|
| `one_or_more` | `+` |
| `zero_or_more` | `*` |
| `optional` | `?` |
| `exactly(n)` | `{n}` |
| `at_least(n)` | `{n,}` |
| `between(min, max)` | `{min,max}` |

```ruby
'abc1de'.scan(Regexes.lowercase_letters.one_or_more)  # => ["abc", "de"]
'12345'.scan(Regexes.digits.exactly(2))               # => ["12", "34"]
"a\n\nb\n\n\n\nc".gsub(Regexes.newline.at_least(3), "\n\n")  # => "a\n\nb\n\nc"
```

Repeating an expression repeats **all** of it. One made of several units is grouped first, so
`ab` repeated is `abab`, never `abb`:

```ruby
Regexes.sequence(Regexes.letters, Regexes.letters).at_least(2)
# => /(?:[A-Za-z][A-Za-z]){2,}/
```

An anchored expression — to the text or to a line — can't be repeated, since only one stretch can
start it. Repeat first, then anchor:

```ruby
Regexes.lowercase_letters.leading.one_or_more
# ArgumentError: /\A[a-z]/ is anchored: repeat it first, then anchor it
```

Counts must be whole numbers, and `between` refuses a minimum above its maximum.

## Case

`case_insensitive` matches letters of either case and keeps any anchors:

```ruby
Regexes.http_scheme.leading.case_insensitive.match?('HTTPS://acme.example')  # => true
```

Applying it before or after repeating and anchoring gives the same expression.

## Captures

`captured(name)` captures what the expression matches under a name, read back with `match[name]`:

```ruby
date = Regexes.sequence(Regexes.digits.exactly(4).captured(:year), Regexes.hyphen,
                        Regexes.digits.exactly(2).captured(:month))

date.match('2026-11')[:month]  # => "11"
```

Anchors stay outside the capture, so it holds only the text matched. A captured expression is one unit:
repeating it repeats the capture without another group around it. A name is a letter or underscore, then
letters, digits and underscores; anything else raises `ArgumentError`.

## Lookarounds

Four variations match only where something else does or doesn't come right before or after, without
taking it:

| Method | Writes | Matches only where `other` |
|---|---|---|
| `followed_by(other)` | `…(?=other)` | comes next |
| `not_followed_by(other)` | `…(?!other)` | doesn't come next |
| `preceded_by(other)` | `(?<=other)…` | comes before |
| `not_preceded_by(other)` | `(?<!other)…` | doesn't come before |

```ruby
"a\n b\nc".gsub(Regexes.newline.followed_by(Regexes.space_or_tab), '')       # => "a b\nc"
'https:// http://'.scan(Regexes.literal('http').not_followed_by(Regexes.literal('s')))  # => ["http"]
'$5 6'.scan(Regexes.digits.one_or_more.preceded_by(Regexes.literal('$')))   # => ["5"]
```

Two things to know:

- **A repeated expression gives back what it took until the lookaround passes.** `digits.one_or_more`
  not followed by `%` still matches the `5` of `50%`. Exclude what it repeats as well —
  `not_followed_by(Regexes.either(Regexes.digits, Regexes.literal('%')))` — to refuse the whole run.
- **Ruby looks behind only for what has a known length** (or alternatives each of one). `preceded_by` a
  repeated expression raises `RegexpError`.

Next: [Sets of Characters](/concepts/character-sets).
