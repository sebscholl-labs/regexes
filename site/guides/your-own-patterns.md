# Your Own Patterns

The library holds shapes that recur everywhere. Your application has shapes of its own — an order
reference, an internal ID, a national format — and `Regexes.register` folds them in, so they're named,
varied and composed exactly as the built-in ones are.

## Register a pattern

```ruby
# config/initializers/regexes.rb
Regexes.register(:order_reference, /ORD-[0-9]{6}/)
```

From then on:

```ruby
Regexes.order_reference.whole.match?('ORD-004211')   # => true
Regexes.order_reference.captured(:reference)          # every variation works
Regexes.sequence(Regexes.order_reference, Regexes.literal('/'), Regexes.digits.one_or_more)

validates :reference, format: { with: Regexes.order_reference.whole }
```

`register` returns the pattern, a frozen [expression](/concepts/expressions), and
`Regexes.registered` lists the names registered so far.

## What it takes

A pattern may be a `Regexp`, its source as a `String`, or an expression built from the library:

```ruby
Regexes.register(:ticket, /T-[0-9]+/i)                    # its options are kept
Regexes.register(:sku, '[A-Z]{3}-[0-9]{4}')               # a source string
Regexes.register(:handle, Regexes.sequence(Regexes.lowercase_letters,
                                           Regexes.word_characters.between(0, 23)))
```

A `Regexp` or `String` is wrapped in a group, so an alternation stays one unit when it's placed in a
sequence: `/ORD|REF/` followed by digits never means "ORD, or REF and digits". An expression is kept as
it is.

## What it refuses

- **A name that isn't snake_case**, or one `Regexes` already answers to: a built-in pattern, a name you
  registered before, or a method every module has (`name`, `hash`). Pick another name; nothing is
  replaced.
- **An anchored pattern.** Register the shape alone and anchor it where it's used: `^`, `$`, `\A`, `\z`
  or `\Z` at either end of the source, or an expression built with `.whole`, raises `ArgumentError`. One
  shape then serves validation (`.whole`), search (as it is) and parsing (`.leading`).

Both raise `ArgumentError` with a message saying which.

## Name it as the library would

A registered pattern sits beside the built-in ones, so name it by the same
[conventions](/design/naming): the shape, not its use (`order_reference`, not `checkout_validator`);
singular for a value, plural for a set; no variation in the name.

Registration changes `Regexes` for the whole process, so do it once, as the application boots.
