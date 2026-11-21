# Composition

Two module functions build one expression from several. Both return an
[expression](/concepts/expressions), with all its variations.

## `Regexes.sequence(*parts)`

Each part, one after another. It reads as it would written out:

```ruby
Regexes.sequence(Regexes.lowercase_letters, Regexes.word_characters.between(0, 23))
# => /[a-z][A-Za-z0-9_]{0,23}/
```

An anchored part stays anchored inside the sequence.

## `Regexes.either(*alternatives)`

Any one of the alternatives, as one unit:

```ruby
ends = Regexes.either(Regexes.hyphen.one_or_more.leading, Regexes.hyphen.one_or_more.trailing)
'--acme-mail-'.gsub(ends, '')  # => "acme-mail"
```

Because it is one unit, repeating it repeats the choice, and anchoring it anchors the whole choice:

```ruby
digit_or_letter = Regexes.either(Regexes.digits, Regexes.letters).whole
%w[1 a 1a].map { digit_or_letter.match?(it) }  # => [true, true, false]
```

## `Regexes.literal(text)`

Text matched character for character, every character standing for itself:

```ruby
Regexes.literal('b+')                                   # => /b\+/
Regexes.literal('.ns.cloudflare.com').trailing          # a Cloudflare nameserver, dots and all
```

It's the safe way to put a value into a pattern. Interpolating one (`/#{suffix}\z/`) lets its dots, pluses
and brackets match more than they say; a literal can't. An empty literal raises `ArgumentError`, since it
would match everywhere.

## Options travel with their part

A case-insensitive part stays case-insensitive inside a case-sensitive whole. It is embedded with its
options carried along (`(?i-mx:…)`), while a part with no options is embedded as its plain source:

```ruby
link = Regexes.sequence(Regexes.http_scheme.case_insensitive, Regexes.lowercase_letters.one_or_more)

link.match?('HTTP://acme')  # => true
link.match?('http://ACME')  # => false
```

## Where your own formats go

The library holds shapes that recur. The grammar of one format — a bounce address, a log line, a
handle — belongs in the code that owns it, as a named constant built from these:

```ruby
class Handle
  FORMAT = Regexes.sequence(Regexes.lowercase_letters, Regexes.word_characters.between(0, 23)).whole
end
```
