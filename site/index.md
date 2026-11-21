---
layout: home
hero:
  name: regexes
  text: Regular expressions named for what they match
  tagline: Frozen Regexp objects for the shapes that recur — sets of characters, UUIDs, times, domain names, email addresses — each chaining the variations every expression allows.
  actions:
    - theme: brand
      text: Quick Start
      link: /getting-started/
    - theme: alt
      text: Named Patterns
      link: /reference/patterns
features:
  - title: Named, not written inline
    details: "Regexes.uuid instead of a 36-character literal pasted into the third file that needs one."
  - title: Variations that chain
    details: "excluded, one_or_more, leading, whole, case_insensitive — each a new frozen pattern, the original untouched."
  - title: Still a Regexp
    details: "Every pattern is a Regexp subclass, so it goes into gsub, scan, match?, case and validates format: as it is."
---

## A taste

```ruby
require 'regexes'

Regexes.lowercase_alphanumeric.excluded.one_or_more     # => /[^a-z0-9]+/
Regexes.lowercase_letters.excluded.one_or_more.leading  # => /\A[^a-z]+/

'northwind  erp!!'.gsub(Regexes.lowercase_alphanumeric.excluded.one_or_more, '_')
# => "northwind_erp_"

Regexes.uuid.whole.match?('01890a5d-ac96-774b-bcce-b302099a8057')  # => true
```

Each line reads as what it matches. The written-out regex is what you'd get by hand, and the
chain is what you read in review.
