# Sets of Characters

A `Regexes::CharacterClass` is an expression that matches any one character of a set. It has every
variation an [expression](/concepts/expressions) has, plus two of its own.

```ruby
Regexes.lowercase_alphanumeric         # => /[a-z0-9]/
'A1a'.scan(Regexes.lowercase_alphanumeric)  # => ["1", "a"]
```

## `excluded`

The set of every character **not** in this one, written with a caret:

```ruby
Regexes.lowercase_alphanumeric.excluded             # => /[^a-z0-9]/
'aA_1é'.scan(Regexes.lowercase_alphanumeric.excluded)  # => ["A", "_", "é"]
```

Excluding the excluded set gives back the set, and `excluded?` says which one you have.

## `including(characters)`

The set with more characters in it, written as they would be between brackets:

```ruby
'a1_-'.scan(Regexes.lowercase_alphanumeric.including('_'))  # => ["a", "1", "_"]
```

An excluded set stays excluded, so the added characters are excluded too:

```ruby
Regexes.slash.excluded.including('?')  # => /[^\/?]/ — matches neither / nor ?
```

## Sets stay sets until repeated

A set is one unit, so it repeats without a group around it (`[a-z]+`, never `(?:[a-z])+`).
Once repeated or anchored it becomes a plain expression, which can no longer be excluded:

```ruby
Regexes.lowercase_letters.one_or_more.respond_to?(:excluded)  # => false
```

`case_insensitive` keeps it a set:

```ruby
'aA1'.scan(Regexes.lowercase_letters.case_insensitive.excluded)  # => ["1"]
```

Next: [Composition](/concepts/composition).
