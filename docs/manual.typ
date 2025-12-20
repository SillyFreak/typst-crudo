#import "template.typ" as template: *
#import "/src/lib.typ" as crudo

#show: manual(
  package-meta: toml("/typst.toml").package,
  title: "Crudo",
  subtitle: [
    _Crudo_ lets you take slices from raw blocks and more: slice, filter, transform and join the lines of raw blocks.
    _Crudo_ can also extract named regions out of source files, to display them without having to hardcode linenumbers.
  ],
  date: datetime(year: 2024, month: 9, day: 28),

  // logo: rect(width: 5cm, height: 5cm),
  // abstract: [
  //   A PACKAGE for something
  // ],

  scope: (crudo: crudo),
)

= Introduction

`raw` elements display source code line by line, but Typst doesn't provide a lot of convenience for handling them in this way:
you need to extract the `raw.text` to do anything with it, and then transform it back.
But also if you read in a source file for displaying code, manipulating the resulting string as multiple lines is not too convenient.
_Crudo_ gives you a few extra tools to make this easier.

== `raw` elements as lists of lines

`raw` elements feel like lists of lines; it's common to want to extract spcific lines, join multiple ones together, etc. As values, though, `raw` elements don't behave this way.

While a package can't add methods such as `raw.slice()` to an element, we can at least provide functions to help with common tasks. The module reference describes these utility functions:

- #ref-fn("r2l()") and #ref-fn("l2r()") are the building blocks the others build on: _raw-to-lines_ and _lines-to-raw_ conversions.
- #ref-fn("transform-text()") and #ref-fn("transform()") are one layer above and allow arbitrarily transforming the text content, viewed as a single string or an array of strings, respectively.
- #ref-fn("read()") reads a text file and puts it in a raw element with the provided `raw` properties.
- #ref-fn("map()"), #ref-fn("filter()") and #ref-fn("slice()") are analogous to their `array` counterparts.
- #ref-fn("lines()") is similar to `slice()` but allows more advanced line selections in a single step.
- #ref-fn("join()") combines multiple `raw` elements and is convenient e.g. to add preambles to code snippets.

All functions that accept raw elements as parameters alternatively accept simple strings. In these cases, a string `code` behaves like `raw(code)`, i.e. it's not a `block` element and has no `lang` set on it. This is mostly useful with #ref-fn("join()"), which takes multiple raw elements, but the other functions don't disallow this usage.

== Handling regions in code files <regions>

_Crudo_ also contains utilities for identifying and extracting ranges of code from source files.
Let's assume you have the following source file (any language will work; we're not using Typst for the example to avoid making things too meta):

#let code = crudo.read("assets/regions/Account.java", properties: (block: true, lang: "java"))
#code

You can already see that this file contains a few special comments of the form `// @region ...`;
these can be processed by _Crudo_ to identify and extract ranges; for example, using the #ref-fn("regions.ranges()") function:

#man-style.show-example(
  in-raw: false,
  scale-preview: 100%,
  ratio: 1.1,
  scope: (crudo: crudo, code: code),
  ```typ
  <<<#let code = crudo.read("Account.java",
  <<<  properties: (block: true, lang: "java"))
  #crudo.regions.ranges(code, "basics") \
  #crudo.regions.ranges(code, "mutators") \
  #crudo.regions.ranges(code,
    ("mutators", "!withdraw-body"))
  ```
)

The result of #ref-fn("regions.ranges()") is an array of region bounds;
for example, the #(2, 9) means that lines 2 (inclusive) to 9 (exclusive) are part of the `basics` region.
A leading `!` can be used to exclude a regin.
Region indicators that may be embedded in a region are of course skipped, e.g. lines 15 and 21 for `withdraw-body` inside the `mutators` region.

These ranges can be further processed for use with #ref-fn("lines()") or packages such as #link("https://typst.app/universe/package/codly")[codly] or #link("https://typst.app/universe/package/zebraw")[zebraw]:

#man-style.show-example(
  in-raw: false,
  dir: ttb,
  scale-preview: 95%,
  no-codly: false,
  scope: (crudo: crudo, code: code, codly: codly),
  ```typ
  >>>#show: pad.with(x: -2mm)
  >>>#set text(0.8em)
  <<<#import "@preview/codly:1.3.0"
  >>>#import "@local/zebraw:0.6.1"
  <<<#import "@preview/zebraw:0.6.1"
  #let ranges = crudo.regions.ranges(code, "basics")
  #grid(
    columns: (1fr, 1fr, 1fr),
  >>>  codly.no-codly(
    crudo.lines(code, ..ranges.map(((a, b)) => range(a, b))),
  >>>  ),
  <<<  codly.codly-init[
  >>>  [
      #codly.codly(ranges: ranges.map(((a, b)) => (a, b - 1)))
      #code
    ],
  >>>  codly.no-codly(
    zebraw.zebraw(line-range: ranges, code),
  >>>  ),
  )
  ```
)

There are some differences in the exact parameters:
- #ref-fn("lines()") expects arrays of individual lines (which we can construct using the `range()` function). This exact usage can be simplified by using the #ref-fn("regions.extract()") shorthand;
- codly uses an inclusive upper bound for ranges;
- zebraw uses exclusive upper bounds and we don't need to change the ranges at all.

An important difference between the first and the latter two examples is line numbering:
if we used one of the two code block libraries to format the first code snippet, we'd see line numbers from 1 to 11.
This is because we are producing a new `raw` element with just a subset of the lines, and any subsequent formatting is not aware of the missing lines.
In contrast, the latter two examples keep the original `raw` element, and instruct the library to only render some of those.
The libraries are aware of the actual line numbers and will preserve them.

=== Highlighting regions <highlighting-regions>

Identifying region ranges can of course not only be used to filter lines, but also for highlighting certain ranges.
Here is again an example using both codly and zebraw:

#man-style.show-example(
  in-raw: false,
  dir: ttb,
  scale-preview: 100%,
  no-codly: false,
  scope: (crudo: crudo, code: code, codly: codly),
  ```typ
  >>>#show: pad.with(x: -2mm)
  >>>#set text(0.8em)
  <<<#import "@preview/codly:1.3.0"
  >>>#import "@local/zebraw:0.6.1"
  <<<#import "@preview/zebraw:0.6.1"
  #let ranges = crudo.regions.ranges(code, "mutators")
  #let highlights = crudo.regions.ranges(code, "withdraw-body")
  #let highlight-lines = highlights.map(((a, b)) => range(a, b)).join()
  #grid(
    columns: (1fr, 1fr),
  <<<  codly.codly-init[
  >>>  [
      #codly.codly(ranges: ranges.map(((a, b)) => (a, b - 1)),
          highlighted-lines: highlight-lines)
      #code
    ],
  >>>  codly.no-codly(
    zebraw.zebraw(line-range: ranges, highlight-lines: highlight-lines, code),
  >>>  ),
  )
  ```
)

As before, the displayed lines are limited to a specific region; a subregion is additionally highlighted.
Both libraries take an array of line numbers for highlights.
We create that by applying `range()` to each highlighted range, and joining all such ranges into a single array.

If you instead want to use the #ref-fn("lines()") approach (to not have gaps in the line numbers), there's a little more work to do:
the highlighted range is of the numbers #(16, 21) but the `raw` block returned by #ref-fn("lines()") will not contain these lines, or have different code in these lines.
The #ref-fn("regions.ranges-within()") function can handle this situation for you:

#man-style.show-example(
  in-raw: false,
  dir: ttb,
  scale-preview: 100%,
  no-codly: false,
  scope: (crudo: crudo, code: code, codly: codly),
  ```typ
  >>>#show: pad.with(x: -6mm)
  >>>#set text(0.8em)
  <<<#import "@preview/codly:1.3.0"
  >>>#import "@local/zebraw:0.6.1"
  <<<#import "@preview/zebraw:0.6.1"
  #let ranges = crudo.regions.ranges(code, "mutators")
  #let highlights = crudo.regions.ranges-within(ranges,
      crudo.regions.ranges(code, "withdraw-body"))
  #let highlight-lines = highlights.map(((a, b)) => range(a, b)).join()
  <<<#codly.codly-init[
  >>>#[
    #codly.codly(highlighted-lines: highlight-lines)
    #crudo.lines(code, ..ranges.map(((a, b)) => range(a, b)))
  ]
  ```
)

= Module reference

#module(
  read("/src/lib.typ"),
  name: none,
  label-prefix: none,
)

#module(
  read("/src/regions.typ"),
  scope: (ref-fn: ref-fn),
  name: "regions",
)

#module(
  read("/src/history.typ"),
  name: "history",
)
