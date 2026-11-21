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
bundle exec ruby -Ilib:test test/regexes/expression_test.rb   # one file
```

From `site/`: `npm install && npm run build`.

Finish every gem change with `bundle exec rake` passing, and the site building when docs change.

## Naming conventions

Every name is chosen by these rules; `site/design/naming.md` explains each with examples. A new
pattern that fits none of them is a sign it doesn't belong here.

1. **The shape, never its use or an application.** `kebab_case`, not `slug`; `uuid`, not
   `message_id_local`; `snake_case`, not `username`. The grammar of one format (a bounce address,
   a log line) belongs in the caller's code, built from these.
2. **Sets of characters are plural; whole values are singular.** `digits`, `hex_digits` match one
   character; `uuid`, `integer`, `domain_name` match one value.
3. **Qualifiers come before the noun, in a fixed order:** case (`lowercase_`, `uppercase_`), then
   script or standard (`unicode_`, `iso8601_`, `alpha2_`), then the noun.
4. **ASCII unless the name says otherwise.** `digits` is `[0-9]`; wider sets say so (`unicode_letters`).
   The one exception is `whitespace`, which is any script's spaces, because that's what the bare
   word is reached for.
5. **Variations never become names.** No `non_digits` (`digits.excluded`), `whitespace_run`
   (`.one_or_more`), `whole_uuid` or `trailing_slash`. A set plus a variation gets a docs example,
   not a name.
6. **A standard is named only when formats compete for the noun:** `iso8601_date`,
   `alpha2_country_code`, `e164_phone_number`; but `uuid`, `iban`, `bic`, `currency_code`.
7. **Abbreviations only where they are the common name:** uuid, url, ipv4, iban, bic, e164, cidr.
   Never `num`, `addr`, `str`.
8. **Captures take the standard's terms:** `email_address` → `local`, `domain`.
9. **Shape, never meaning.** A range the format defines is checked (month 01–12, octet 0–255); a
   checksum, a calendar (Feb 30) or reachability is not. Each pattern's docs say where it stops.
10. **International standards only.** National formats belong in the application, built from these.

## Rules that shape the code

Detailed rules live in `.claude/rules/` and load when you touch the files they cover: `patterns.md`
(where a pattern goes, its shape, keeping tests and docs in step) and `tests.md` (one test class
per file, test paths mirror `lib/`, one assertion per test, what a case table covers). The project
cops in `gem/rubocop/cop/regexes/` enforce what a machine can check of both.

- **Everything is frozen and built once.** Named patterns are constants built at load time; each
  variation returns a new frozen `Expression` and never changes the receiver.
- **Anchors are the text's, never a line's:** `\A` and `\z`, never `^` or `$`.
- **ASCII unless the name says otherwise.** `digits` is `[0-9]`, never `\d`; `whitespace` is the one
  that means any script's spaces.
- **Every named pattern is tested** in `gem/test/regexes_test.rb`'s `CASES` table, with texts it must
  match whole and texts it must refuse. A test there fails if a named pattern is missing from it.
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
