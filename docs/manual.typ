#import "template.typ" as template: *
#import "/src/lib.typ" as crudo

#let package-meta = toml("/typst.toml").package
#let date = datetime(year: 2024, month: 9, day: 28)

#show: manual(
  title: "Crudo",
  // subtitle: "...",
  authors: package-meta.authors.map(a => a.split("<").at(0).trim()),
  abstract: [
    _Crudo_ lets you take slices from raw blocks and more: slice, filter, transform and join the lines of raw blocks.
  ],
  url: package-meta.repository,
  version: package-meta.version,
  date: date,
)

// the scope for evaluating expressions and documentation
#let scope = (crudo: crudo)

= Introduction

`raw` elements feel similar to arrays and strings in a lot of ways: they feel like lists of lines; it's common to want to extract spcific lines, join multiple ones together, etc. As values, though, `raw` elements don't behave this way.

While a package can't add methods such as `raw.slice()` to an element, we can at least provide functions to help with common tasks. The module reference describes these utility functions:

- #ref-fn("r2l()") and #ref-fn("l2r()") are the building blocks the others build on: _raw-to-lines_ and _lines-to-raw_ conversions.
- #ref-fn("transform()") is one layer above and allows arbitrarily transforming an array of strings.
- #ref-fn("map()"), #ref-fn("filter()") and #ref-fn("slice()") are analogous to their `array` counterparts.
- #ref-fn("lines()") is similar to `slice()` but allows more advanced line selections in a single step.
- #ref-fn("join()") combines multiple `raw` elements and is convenient e.g. to add preambles to code snippets.

All functions that accept raw elements as parameters alternatively accept simple strings. In these cases, a string `code` behaves like `raw(code)`, i.e. it's not a `block` element and has no `lang` set on it. This is mostly useful with #ref-fn("join()"), which takes multiple raw elements, but the other functions don't disallow this usage.

= Module reference

#module(
  read("/src/lib.typ"),
  name: "crudo",
  label-prefix: none,
  scope: scope,
)
