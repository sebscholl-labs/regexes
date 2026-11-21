---
paths:
  - "gem/lib/**/*.rb"
---

# Patterns: one shape, one name, one constant

## Where things go

| Kind | Location | Example |
|---|---|---|
| A named pattern | `gem/lib/regexes/patterns/<section>.rb` | `Regexes.uuid` in `identifiers.rb` |
| A way to vary or build expressions | `gem/lib/regexes/expression.rb` (every expression) or `character_class.rb` (sets only) | `#one_or_more`, `#excluded` |
| Composition, literals, registration | `gem/lib/regexes.rb` | `Regexes.sequence`, `Regexes.register` |
| Translation into ECMAScript | `gem/lib/regexes/ecma.rb` | `Regexes::Ecma`, behind `Expression#ecma_source` |

The sections, loaded by `gem/lib/regexes.rb` in this order (each may build on those before it):
`sets`, `breaks`, `numbers`, `identifiers`, `times`, `network`, `mail`, `codes`, `text`. Each reopens
`module Regexes`; a fragment only one section uses is a local variable at the top of its file, never a
constant (which would be public, as `Regexes::H16`).

Nothing in `lib/` knows of an application: no product names, no provider names, no national formats
(see the naming conventions in `CLAUDE.md`).

## What gets a name

- A shape with parts or rules: `uuid`, `iban`, `semantic_version`.
- **Not** a set and a count, even a standard one. `Regexes.uppercase_letters.exactly(2)` is an ISO 3166
  country code; `Regexes.hex_digits.exactly(64)` a SHA-256 digest. They go in the set's doc comment and
  the reference page as examples (naming rule 5).
- **Not** a string operation (slugifying, trimming zeros, a case boundary): those aren't shapes.

## The shape of a named pattern

Every named pattern is a frozen constant built once at load, and an endless method of the same name
that returns it. `Regexes/PatternNaming` enforces the name and the shape:

```ruby
  UUID = Expression.new('(?<![0-9a-fA-F])[0-9a-fA-F]{8}-…-[0-9a-fA-F]{12}(?![0-9a-fA-F])')

  # +Regexes.uuid+ matches +01890a5d-ac96-774b-bcce-b302099a8057+, with its hyphens, of any version and either
  # case. It never matches inside a longer run of hex digits.
  #
  # @return [Expression] a UUID in its hyphenated form (RFC 9562)
  def uuid = UUID
```

A pattern with a parameter that is part of its standard shape (`decimal(places:)`) returns the constant
when called without it, and builds the variation in a private helper when called with it.

- **The constant** is an `Expression` (a value) or a `CharacterClass` (a set). Pass `single: true`
  when the body is already one unit a quantifier applies to whole (a group or an alternation in
  parentheses), so repeating it doesn't add a group.
- **Build from what exists.** A pattern made of others interpolates their `source` or the same local
  fragments (`ISO8601_DATE_TIME` from the date, time and offset fragments), so a fix to one reaches all.
- **No alternation at the top of the body.** Wrap alternatives in `(?:…)` and pass `single: true`,
  so the body can be followed, preceded or put in a sequence as it is (`UTC_OFFSET`, `LINE_BREAK`).
- **No anchors in the body.** `\A`, `\z`, `^` and `$` are the caller's, through `.leading`,
  `.trailing` and `.whole`. A lookahead that bounds a length (as `DOMAIN_NAME`'s does) is fine.
- **Token boundaries.** A value made of a fixed count of characters that could run on — digits, hex
  digits, a code's letters — is bounded by lookarounds of those characters
  (`(?<![0-9])…(?![0-9])`), so a search never finds one inside a longer run: `1.2.3.456` holds no
  IPv4 address. Leave out characters that commonly sit beside the value (a UUID's boundary has no `-`,
  so `order-<uuid>` is found), and don't bound open-ended values (`integer`, `email_address`).
- **Non-ASCII in a string literal is escaped** (`" "`, never the raw character): many are
  invisible or look like ASCII.
- **The doc comment** opens with an example in `+…+` of what it matches and what it refuses, says
  where it stops (what it doesn't check: a checksum, the calendar), names the standard it follows
  with its section, and lists its captures. `@return` says what one match is, in a phrase.
- **Captures** are named, in the standard's terms (`local`, `domain`, `id_left`), never numbered, and
  a name is captured once: a pattern written two ways captures in a lookahead before the two
  (`SHELL_VARIABLE_REFERENCE`), so ECMAScript can read it.
- **It translates.** `ecma_source` must work on it (`test/regexes/ecma_test.rb` lists the one named
  pattern that doesn't, `emoji`), so avoid what ECMAScript has no equivalent for: `\X`, `\h`, `\Z`,
  atomic groups, inline options, a capture name used twice.

## Keeping tests and docs in step

A new or changed pattern lands with, in the same commit:

1. its row in its section's `cases` table in `gem/test/regexes/patterns/<section>_test.rb`, covering
   the cases `.claude/rules/tests.md` lists, a test per named capture, and a search test when it has
   token boundaries;
2. a property suite in `gem/test/properties/` when Ruby has a parser to compare it with (IPAddr,
   JSON, `unpack1('m0')`) or its fields can be enumerated (times, ports);
3. its name in the section's row of the patterns table in `gem/README.md`;
4. its row on `site/reference/patterns.md`, with what it matches, what it refuses, where it stops and
   what it captures;
5. a `gem/CHANGELOG.md` entry under `## Unreleased`.

`bundle exec rake` and `npm run build` in `site/` must pass.

## Expression and CharacterClass

- A variation returns a new frozen `Expression` built through `varied`, `looking` or `repeated`; it
  never changes the receiver and never reaches into `@body` of another expression. Use `embedded` to
  place one expression inside another, so its options travel with it.
- A variation that only makes sense for a set lives in `CharacterClass` and returns a
  `CharacterClass`; once repeated or anchored, a set is a plain `Expression`.
- Every new variation gets a row in `test/properties/variations_test.rb`'s chains when it can apply to
  every set, so it is checked against the regex written out by hand.
