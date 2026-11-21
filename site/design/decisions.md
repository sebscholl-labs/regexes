# Design Decisions

## Named for what it matches

A pattern is named for its shape (`uuid`, `dns_label`, `space_or_tab`), never for a use
(`slug_cleaner`, `header_unfolder`). A shape is found and reused; a use is written again inline the
next time, slightly differently.

## A shape that recurs, not a format

The library holds what recurs across code: a set of characters, a line break, an address. The grammar
of one format belongs in the code that owns it, as a named constant built from these. That keeps the
library small and every format in one place.

## Still a `Regexp`

`Expression` subclasses `Regexp` rather than wrapping one, so nothing needs unwrapping: `gsub`,
`scan`, `case`, `=~` and Rails' `validates format:` take it as it is, and it equals the literal it
stands for.

## Frozen, built once

Named patterns are built once as the library loads and frozen. Every variation returns a new frozen
expression, so a pattern kept in a constant can't be changed by a caller, and a named pattern is the
same object each time it's asked for.

## The text's anchors, never a line's

`leading`, `trailing` and `whole` write `\A` and `\z`. `^` and `$` match at any line, so a validation
written with them passes `"ok\n<script>"`. There is no method that writes them.

When a line is what's meant, `line_leading`, `line_trailing` and `whole_line` say so in their names, and
they're written with lookarounds that know all three line breaks. `$` alone ends a line between the `\r`
and the `\n` of a CRLF — the line break mail and HTTP use — and `^` never starts one after a lone `\r`.

## Registered patterns are shapes, unanchored

`Regexes.register` refuses a pattern with an anchor in it. One unanchored shape serves validation
(`.whole`), search (as it is) and parsing (`.leading`); an anchored one serves only the first, and gets
copied again, unanchored, the next time someone needs to search.

## Repeat, then anchor

Repeating an anchored expression is refused rather than guessed at: only one stretch of text can
start at `\A`, so `\A[a-z]+` is almost always what was meant by "leading letters, repeated". The error
says so.

## ASCII unless the name says otherwise

`digits` is `[0-9]`, never `\d`, which in some engines and encodings matches other scripts' digits.
`whitespace` is the one named pattern meant to catch any script's spaces, since text copied from a web
page carries no-break and wide spaces.

## Every variation, tested

The suite checks every chain of variations on every set of characters against the regex written out
by hand: the same source, the same matches on texts chosen to tell them apart, and frozen. That's
2,688 generated tests, which run in a fraction of a second.
