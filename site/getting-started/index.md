# Quick Start

## Install

```bash
bundle add regexes
```

Requires Ruby 4.0 or newer. No runtime dependencies.

## Use a named pattern

```ruby
require 'regexes'

Regexes.integer                       # => /-?[0-9]+/
'order 42 of -7'.scan(Regexes.integer) # => ["42", "-7"]
```

A named pattern matches anywhere in the text. To match the whole text, anchor it:

```ruby
Regexes.integer.whole.match?('42')   # => true
Regexes.integer.whole.match?('4.2')  # => false
```

## Chain variations

Every variation returns a new frozen pattern, so chains read left to right:

```ruby
Regexes.lowercase_letters                          # => /[a-z]/
Regexes.lowercase_letters.one_or_more              # => /[a-z]+/
Regexes.lowercase_letters.one_or_more.whole        # => /\A[a-z]+\z/
Regexes.lowercase_letters.excluded.one_or_more     # => /[^a-z]+/
```

## Use it like any Regexp

```ruby
case input
when Regexes.uuid.whole       then :uuid
when Regexes.integer.whole    then :integer
end

validates :handle, format: { with: Regexes.lowercase_alphanumeric.one_or_more.whole }
```

## Build your own from the parts

```ruby
HANDLE = Regexes.sequence(Regexes.lowercase_letters, Regexes.word_characters.between(0, 23)).whole
HANDLE  # => /\A[a-z][A-Za-z0-9_]{0,23}\z/
```

A format that belongs to your application lives in your application as a named constant like
`HANDLE`, built from these.

Next: [Expressions](/concepts/expressions).
