---
paths:
  - "gem/test/**/*"
  - "gem/Rakefile"
---

# Tests: one class per file, mirrored paths, one assertion per test

These rules have no exceptions beyond the ones listed here. Each is enforced by a project cop in
`gem/rubocop/cop/regexes/`, run by `bundle exec rake lint`:

| Rule | Cop |
|---|---|
| One test class per file | `Regexes/OneTestClassPerFile` |
| Mirror the lib tree | `Regexes/MirroredTestPath` |
| One assertion per test | `Regexes/OneAssertionPerTest` |

Enforce new rules like these with a cop, not with runtime hooks in the test suite.

## Declaring a test

Every test class inherits `RegexesTestCase` (`test/support/regexes_test_case.rb`) and declares tests
with `test 'what it shows' do … end`. The description is the method name as written, and a second
test with the same description raises at load, so a generated test can never silently replace
another.

## One test class per file

A test file defines exactly one top-level class, its test class, never wrapped in `module Regexes`.
Helpers and shared setup go in `test/support/` (required from `test_helper.rb`). Constants nested
inside the test class, such as a `CASES` table, are fine.

## Mirror the lib tree

Each test file mirrors the file under test, with a `_test.rb` suffix. The class is named after the
path, with `::` and `/` removed and `Test` appended:

| Under test | Test file | Test class |
|---|---|---|
| `lib/regexes.rb` | `test/regexes_test.rb` | `RegexesTest` |
| `lib/regexes/expression.rb` | `test/regexes/expression_test.rb` | `RegexesExpressionTest` |
| `lib/regexes/character_class.rb` | `test/regexes/character_class_test.rb` | `RegexesCharacterClassTest` |

Put a test in the file of the code that **owns the behavior**, not the entry point it calls through.
`sequence` and `either` are defined in `lib/regexes.rb`, so their tests are in `regexes_test.rb`;
what a set's `excluded` does is `CharacterClass`'s, so it's in `character_class_test.rb` even when
reached through `Regexes.digits`.

The only directories that don't mirror `lib/`, excluded from that cop in `.rubocop.yml`:

- `test/support/`: the base class and helpers.
- `test/properties/`: generated suites that check a property across the whole library rather than
  one file, such as every chain of variations on every set (`variations_test.rb`).

## Every named pattern has a case table

`test/regexes_test.rb` holds `CASES`: for each named pattern, texts it must match whole and texts
it must refuse whole. A test there fails if a named pattern is missing from it. Every row gets, for
free: one test per text, `.whole` refusing its first match with a line feed after or a space before
(the `^`/`$` mistake), the same object every time, and frozen.

A row covers, where they apply: typical examples; the shortest and longest allowed and one past
each; every range edge (`00`, `23`, `24`); each part missing or malformed; the wrong case; a
lookalike from another script; and the empty string. Texts in one row must differ, or the
generated test names collide.

## One assertion per test

A test makes exactly **one** top-level `assert_*` / `refute_*` call.
`Regexes/OneAssertionPerTest` checks `def test_*`, `define_method` blocks and `test` blocks.

The cop sees only the test body, so it can't catch an assertion inside a loop
(`items.each { assert ... }`), which runs many times but counts once. Avoid it:

- **Several facts about one result** become several tests, each one line.
- **A small table of cases** becomes one test per row, generated at class level (as `CASES` is).
- **A property over a large range** is one assertion over the whole collection, which reports every
  failing value at once: `assert_equal expected, texts.map { it.scan(pattern) }`.
- **An error and its message** are two tests: `assert_raises(ArgumentError) { … }` in one, and
  `assert_raises(ArgumentError, match: /repeat it first/) { … }` in the other.
- Don't hide assertions in helpers. A helper arranges or computes; the test asserts.

## Running

From `gem/`:

```sh
bundle exec rake test                                    # everything
bundle exec ruby -Ilib:test test/regexes/expression_test.rb   # one file
bundle exec ruby -Ilib:test test/regexes_test.rb -n /uuid/    # tests whose name mentions uuid
```
