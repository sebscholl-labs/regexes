# Changelog

## Unreleased

### Added

- The library, extracted from an application where it was written: `Regexes::Expression` (a frozen
  `Regexp` with anchors, repetition and case-insensitivity), `Regexes::CharacterClass` (a set of
  characters that can be excluded and extended), `Regexes.sequence` and `Regexes.either`, and the named
  patterns: sets of characters, line breaks, integers, UUIDs, identifiers, UTC offsets, ISO 8601 times,
  HTTP schemes, DNS labels, domain names, email addresses and Markdown code spans.
- `Regexes.iso8601_date` and `Regexes.iso8601_time` (the time of day), of which `iso8601_date_time` is built.

### Changed

- **Breaking:** `Regexes.iso8601_time` is renamed `iso8601_date_time`; `iso8601_time` is now the time of day
  alone. `Regexes.backtick_code` is renamed `markdown_code_span`.
- **Breaking:** `Regexes.email_address` matches what an HTML `type=email` input accepts (WHATWG) instead of
  any text around one `@`: quoted local parts, IP-literal domains and characters outside the WHATWG set are
  refused.
- **Breaking:** ISO 8601 fields are checked against their ranges (month, day, hour, minute, second, offset),
  so `2026-13-01` and `24:00` are refused.

### Fixed

- `Regexes.dns_label` refuses a label of more than 63 characters, and `Regexes.domain_name` a name of more
  than 253 (RFC 1035).

## 0.0.0 - 2026-11-21

- Reserved the name on RubyGems.
