# regexes

[![Gem Version](https://img.shields.io/gem/v/regexes)](https://rubygems.org/gems/regexes)
[![CI](https://github.com/sebscholl-labs/regexes/actions/workflows/ci.yml/badge.svg)](https://github.com/sebscholl-labs/regexes/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/sebscholl-labs/regexes)](https://github.com/sebscholl-labs/regexes/releases)
[![License](https://img.shields.io/github/license/sebscholl-labs/regexes)](https://github.com/sebscholl-labs/regexes/blob/main/LICENSE.txt)
[![Ruby](https://img.shields.io/badge/Ruby-%3E%3D%204.0-red)](https://rubygems.org/gems/regexes)

`regexes` is a Ruby library of regular expressions named for what they match rather than what they are
used for: sets of characters, line breaks, UUIDs, ISO 8601 times, domain names, email addresses. Each is a
frozen `Regexp` that chains the variations every expression allows (anchored, repeated, case-insensitive)
and composes with others into larger patterns. No dependencies.

```ruby
Regexes.lowercase_alphanumeric.excluded.one_or_more   # => /[^a-z0-9]+/
```

## Repository layout

| Directory | Purpose | README |
|---|---|---|
| [`gem/`](./gem) | The published gem source: `lib/`, `test/`, gemspec, `CHANGELOG.md`. Everything that ends up on RubyGems lives here. | [`gem/README.md`](./gem/README.md) |
| [`site/`](./site) | The VitePress documentation site published to <https://sebscholl-labs.github.io/regexes/>. | [`site/`](./site) |

## Working in this repo

Each package is independent and uses its own dependencies.

```bash
# work on the gem
cd gem
bundle install
bundle exec rake          # full test + lint suite

# work on the docs site
cd site
npm install
npm run dev               # local VitePress server
```

## CI

Three GitHub workflows live in `.github/workflows/`:

| Workflow | Triggers | What it does |
|---|---|---|
| `ci.yml`      | push to `main`, every PR | Runs the gem's Minitest suite on Ruby 4.0, the RuboCop quality job, and builds the docs site |
| `release.yml` | a published GitHub Release | Re-runs the gem suite on the tagged commit, then publishes the gem to RubyGems.org via OIDC trusted publishing |
| `docs.yml`    | push to `main` | Builds the VitePress site from `site/` and deploys it to GitHub Pages |

## Contributing

- Bug or feature in the gem → PR against `gem/`. Tests live in `gem/test/` (Minitest).
  `bundle exec rake` runs them plus RuboCop.
- Documentation site → PR against `site/`. The build is `npm run build`.

## License

[MIT](./LICENSE.txt).
