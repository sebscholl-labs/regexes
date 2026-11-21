# Changelog

## Unreleased

### Added

- The library, extracted from an application where it was written: `Regexes::Expression` (a frozen
  `Regexp` with anchors, repetition and case-insensitivity), `Regexes::CharacterClass` (a set of
  characters that can be excluded and extended), `Regexes.sequence` and `Regexes.either`, and the named
  patterns: sets of characters, line breaks, integers, UUIDs, identifiers, UTC offsets, ISO 8601 times,
  HTTP schemes, DNS labels, domain names, email addresses and Markdown code spans.
- `Regexes.iso8601_date` and `Regexes.iso8601_time` (the time of day), of which `iso8601_date_time` is built.
- Line anchors: `Expression#line_leading`, `#line_trailing` and `#whole_line`, which know `\r\n`, `\r` and
  `\n` as line breaks, and `#line_leading?` / `#line_trailing?`.
- `Expression#captured(name)`, a named capture around an expression.
- Lookarounds: `Expression#followed_by`, `#not_followed_by`, `#preceded_by` and `#not_preceded_by`.
- `Regexes.literal(text)`, text matched character for character.
- `Regexes.register(name, pattern)` adds an application's own pattern under a name, as a frozen expression with
  every variation; `Regexes.registered` lists the names added.
- Sets: `uppercase_letters`, `uppercase_alphanumeric`, `binary_digits`, `octal_digits`, `base32_digits`,
  `base58_digits`, `base64_digits`, `base64url_digits`, `ascii_whitespace`, `dashes`, `apostrophes`,
  `double_quotes`, `unicode_letters`, `unicode_digits`, `combining_marks`, `control_characters` and
  `format_characters`.
- Breaks: `unicode_line_break` and `paragraph_break`.
- Numbers: `unsigned_integer`, `positive_integer`, `decimal(places:)`, `unsigned_decimal(places:)`, `json_number`,
  `latitude`, `longitude` and `port_number`.
- Identifiers: `snake_case`, `screaming_snake_case`, `kebab_case`, `camel_case`, `pascal_case`, `ulid`,
  `semantic_version`, `media_type`, `json_web_token`, `base64` and `base64url`.
- Times: `iso8601_year_month`, `iso8601_duration` and `rfc3339_timestamp`.
- Network: `uri_scheme`, `http_url`, `ipv4_address`, `ipv6_address`, `ip_address`, `ipv4_cidr`, `ipv6_cidr` and
  `mac_address`.
- Mail: `message_id` and `header_field_name`.
- Codes: `e164_phone_number`, `iban`, `bic`, `language_tag` and `hex_color`.
- Text: `markdown_link`, `ruby_format_reference`, `mustache_tag`, `shell_variable_reference`, `file_extension` and
  `emoji`.

### Changed

- **Breaking:** `Regexes.iso8601_time` is renamed `iso8601_date_time`; `iso8601_time` is now the time of day
  alone. `Regexes.backtick_code` is renamed `markdown_code_span`.
- **Breaking:** `Regexes.email_address` matches what an HTML `type=email` input accepts (WHATWG) instead of
  any text around one `@`: quoted local parts, IP-literal domains and characters outside the WHATWG set are
  refused.
- **Breaking:** ISO 8601 fields are checked against their ranges (month, day, hour, minute, second, offset),
  so `2026-13-01` and `24:00` are refused.

- `Regexes.uuid`, and the ISO 8601 patterns that start or end with a digit, never match inside a longer run of
  hex digits or digits.

### Fixed

- `Regexes.dns_label` refuses a label of more than 63 characters, and `Regexes.domain_name` a name of more
  than 253 (RFC 1035).

## 0.0.0 - 2026-11-21

- Reserved the name on RubyGems.
