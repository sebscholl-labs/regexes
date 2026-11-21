# regexes

A Ruby library of regular expressions named for what they match. Each is a frozen `Regexp`
(`Regexes::Expression`) with chainable variations (anchors, repetition, case), sets of characters
(`Regexes::CharacterClass`) can be excluded and extended, and `Regexes.sequence` / `Regexes.either`
compose them. No runtime dependencies. Published to RubyGems as `regexes`.

## Layout

Two independent packages, each with its own dependencies:

| Path | What it is |
|---|---|
| `gem/` | The published gem: `lib/`, `test/` (Minitest), gemspec, `CHANGELOG.md`, `.rubocop.yml` |
| `site/` | The VitePress docs at https://sebscholl-labs.github.io/regexes/, deployed from `main` by `docs.yml` |

## Commands

From `gem/`, matching CI (`.github/workflows/ci.yml`):

```sh
bundle exec rake test     # Minitest
bundle exec rake lint     # RuboCop; must be clean
bundle exec rake          # both
bundle exec ruby -Ilib:test test/expression_test.rb   # one file
```

From `site/`: `npm install && npm run build`.

Finish every gem change with `bundle exec rake` passing, and the site building when docs change.

## Rules that shape the code

- **Named for what it matches, not what it's used for.** `uuid`, `dns_label`, `space_or_tab`, never
  `slug_cleaner`. A pattern here is a shape that recurs. The grammar of one format (a bounce address,
  a log line) belongs in the caller's code, built from these.
- **Everything is frozen and built once.** Named patterns are constants built at load time; each
  variation returns a new frozen `Expression` and never changes the receiver.
- **Anchors are the text's, never a line's:** `\A` and `\z`, never `^` or `$`.
- **ASCII unless the name says otherwise.** `digits` is `[0-9]`, never `\d`; `whitespace` is the one
  that means any script's spaces.
- **Every named pattern is tested** in `gem/test/regexes_test.rb`'s `CASES` table, with texts it must
  match whole and texts it must refuse. A test there fails if a named pattern is missing from it.
- **One assertion per test** (`Minitest/MultipleAssertions: Max: 1`). Tests are declared with
  `test 'what it does' do` from `gem/test/test_helper.rb`, which refuses a duplicate name.
- **Ruby 4.0 is the floor** (`required_ruby_version`, RuboCop's `TargetRubyVersion`, CI).
- **YARD on every method**, public and private (`Style/DocumentationMethod`).
- When public behavior changes, update `gem/README.md` and the relevant `site/` page.

## Changelog and releases

- Add an entry to `gem/CHANGELOG.md` under a `## Unreleased` heading (create it at the top if
  missing), grouped as `### Added` / `### Changed` / `### Fixed`. Mark breaking changes
  **Breaking:** and include migration notes.
- A GitHub Release `vX.Y.Z` publishes the gem (`release.yml`).
- Don't bump the version or move entries out of Unreleased. Versioning and releases are done by a
  maintainer.
- Never tag, release or publish the gem.
