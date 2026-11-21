---
paths:
  - "gem/lib/**/*.rb"
---

# Patterns: one shape, one name, one constant

## Where things go

| Kind | Location | Example |
|---|---|---|
| A named pattern | `gem/lib/regexes.rb`, under its section's heading | `Regexes.uuid` |
| A way to vary or build expressions | `gem/lib/regexes/expression.rb` (every expression) or `character_class.rb` (sets only) | `#one_or_more`, `#excluded` |
| Composition of several expressions | `gem/lib/regexes.rb`, under `Composition` | `Regexes.sequence` |

Nothing in `lib/` knows of an application: no product names, no provider names, no national
formats (see the naming conventions in `CLAUDE.md`).

## The shape of a named pattern

Every named pattern is a frozen constant built once at load, and an endless method of the same name
that returns it. `Regexes/PatternNaming` enforces the name and the shape:

```ruby
  UUID = Expression.new('[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')

  # +Regexes.uuid+ matches +01890a5d-ac96-774b-bcce-b302099a8057+, with its hyphens.
  #
  # @return [Expression] a UUID in its hyphenated form, of any version and either case
  def uuid = UUID
```

- **The constant** is an `Expression` (a value) or a `CharacterClass` (a set). Pass `single: true`
  when the body is already one unit a quantifier applies to whole (a group or an alternation in
  parentheses), so repeating it doesn't add a group.
- **Build from what exists.** A pattern made of others interpolates their `source`
  (`ISO8601_DATE_TIME` is built from `ISO8601_DATE`, `ISO8601_TIME` and `UTC_OFFSET`), so a fix to
  one reaches all.
- **No alternation at the top of the body.** Wrap alternatives in `(?:…)` and pass `single: true`,
  so the body can be followed, preceded or put in a sequence as it is (`UTC_OFFSET`, `LINE_BREAK`).
- **No anchors in the body.** `\A`, `\z`, `^` and `$` are the caller's, through `.leading`,
  `.trailing` and `.whole`. A lookahead that bounds a length (as `DOMAIN_NAME`'s does) is fine.
- **The doc comment** opens with an example in `+…+` of what it matches and what it refuses, says
  where it stops (what it doesn't check: a checksum, the calendar), names the standard it follows
  with its section, and lists its captures. `@return` says what one match is, in a phrase.
- **Captures** are named, in the standard's terms (`local`, `domain`), never numbered.

## Keeping tests and docs in step

A new or changed pattern lands with, in the same commit:

1. its row in `CASES` in `gem/test/regexes_test.rb`, covering the cases `.claude/rules/tests.md`
   lists, and a test per named capture;
2. its line in the patterns table of `gem/README.md`;
3. its row on `site/reference/patterns.md`, with what it matches, what it refuses and where it stops;
4. a `gem/CHANGELOG.md` entry under `## Unreleased`.

`bundle exec rake` and `npm run build` in `site/` must pass.

## Expression and CharacterClass

- A variation returns a new frozen `Expression` built through `varied` or `repeated`; it never
  changes the receiver and never reaches into `@body` of another expression. Use `embedded` to place
  one expression inside another, so its options travel with it.
- A variation that only makes sense for a set lives in `CharacterClass` and returns a
  `CharacterClass`; once repeated or anchored, a set is a plain `Expression`.
- Every new variation gets a row in `test/properties/variations_test.rb`'s chains when it can apply to
  every set, so it is checked against the regex written out by hand.
