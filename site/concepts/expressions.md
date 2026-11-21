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

`leading.trailing` is the same as `whole`, and anchoring twice at one end is anchoring once.
`leading?` and `trailing?` say where an expression is anchored.

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

An anchored expression can't be repeated, since only one stretch of the text can start it.
Repeat first, then anchor:

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

Next: [Sets of Characters](/concepts/character-sets).
