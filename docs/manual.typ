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
A leading `!` can be used to exclude a region.
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
  >>>#import codly: codly, codly-init, no-codly
  <<<#import "@preview/codly:1.3.0": codly, codly-init
  >>>#import "@local/zebraw:0.6.1": zebraw
  <<<#import "@preview/zebraw:0.6.1": zebraw
  #let ranges = crudo.regions.ranges(code, "basics")
  #grid(
    columns: (1fr, 1fr, 1fr),
  >>>  no-codly(
    crudo.lines(code, ..ranges.map(((a, b)) => range(a, b))),
  >>>  ),
  <<<  codly-init[
  >>>  [
      #codly(ranges: ranges.map(((a, b)) => (a, b - 1)))
      #code
    ],
  >>>  no-codly(
    zebraw(line-range: ranges, code),
  >>>  ),
  )
  ```
)

There are some differences in the exact parameters:
- #ref-fn("lines()") expects arrays of individual lines (which we can construct using the `range()` function). This exact usage can be simplified by using the #ref-fn("regions.extract()") shorthand;
- codly uses an inclusive upper bound for ranges;
- zebraw uses exclusive upper bounds, so we don't need to change the ranges at all.

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
  >>>#import codly: codly, codly-init, no-codly
  >>>#import "@local/zebraw:0.6.1": zebraw
  #let ranges = crudo.regions.ranges(code, "mutators")
  #let highlights = crudo.regions.ranges(code, "withdraw-body")
  #let highlight-lines = highlights.map(((a, b)) => range(a, b)).join()
  #grid(
    columns: (1fr, 1fr),
  <<<  codly-init[
  >>>  [
      #codly(ranges: ranges.map(((a, b)) => (a, b - 1)),
          highlighted-lines: highlight-lines)
      #code
    ],
  >>>  no-codly(
    zebraw(line-range: ranges, highlight-lines: highlight-lines, code),
  >>>  ),
  )
  ```
)

As before, the displayed lines are limited to a specific region; a subregion is additionally highlighted.
Both libraries take an array of line numbers for highlights.
We create that by applying `range()` to each highlighted range, and joining all such ranges into a single array.

If you instead want to use the #ref-fn("lines()") approach (to not have gaps in the line numbers), there's a little more work to do:
the highlighted range is of the numbers #(16, 21) but the `raw` block returned by #ref-fn("lines()") will not contain these lines (or have different code in these lines).
The #ref-fn("regions.ranges-within()") function can handle this situation for you:
it transforms a list of line number ranges into what they should be inside a snippet that has some lines skipped.
Below is an example:

#man-style.show-example(
  in-raw: false,
  dir: ttb,
  scale-preview: 100%,
  no-codly: false,
  scope: (crudo: crudo, code: code, codly: codly),
  ```typ
  >>>#show: pad.with(x: -6mm)
  >>>#set text(0.8em)
  >>>#import codly: codly, codly-init, no-codly
  #let ranges = crudo.regions.ranges(code, "mutators")
  #let highlights = crudo.regions.ranges-within(ranges,
      crudo.regions.ranges(code, "withdraw-body"))
  #let highlight-lines = highlights.map(((a, b)) => range(a, b)).join()
  <<<#codly-init[
  >>>#[
    #codly(highlighted-lines: highlight-lines)
    #crudo.lines(code, ..ranges.map(((a, b)) => range(a, b)))
  ]
  ```
)

== Documenting evolving code snippets <history>

For explanatory texts it is often useful to develop a code snippet in multiple steps, where early code is later replaced by a more capable version.
#footnote[
  In particular, this feature is inspired by #link("http://www.craftinginterpreters.com/")[_Crafting Interpreters_ by Robert Nystrom].
  For example, in #link("http://www.craftinginterpreters.com/statements-and-state.html#executing-statements")["Executing statements"] right at the end, the `interpreter.interpret(statements);` line replaces a previous one.
  In the #link("https://github.com/munificent/craftinginterpreters/blob/4a840f70f69c6ddd17cfef4f6964f8e1bcd8c3d4/java/com/craftinginterpreters/lox/Lox.java#L100-L105")[accompanying source code on Github], you can see how both the old and new source code is modelled using history-aware regions.
]
Using the region feature shown above for that can quickly get out of hand.
Consider this code as an example:

#let code = crudo.read("assets/history/bad.rs", properties: (block: true, lang: "rust"))
#code

This code file doesn't really consist of multiple parts that are explained separately, but different stages of development.
The `main()` function declaration should always be presented, and individual parts of the implementation should be shown.
To do so, the example on the next page always skips _all but one_ of the implementation snippets.
It gets worse when there are multiple parts of the code that evolve:
the set of regions will grow, and which regions belong together becomes increasingly complex.
Through this complexity, the advantage of not having to hardcode line numbers vanishes.

An additional downside is this:
when executed, it would run _all parts of the logic_ (the `todo!()`s notwithstanding), not just the latest one.
Not even the final form of the code can be tested!

#man-style.show-example(
  in-raw: false,
  dir: ttb,
  no-codly: false,
  scale-preview: 100%,
  scope: (crudo: crudo, code: code),
  ```typ
  >>>#show: pad.with(x: -2mm)
  <<<#let code = crudo.read("greet.rs", properties: (block: true, lang: "rust"))
  #grid(
    columns: (1fr, 1.2fr),
    crudo.regions.extract(code, ("!parametric", "!localized")) +
    crudo.regions.extract(code, ("!simple", "!localized")),
    crudo.regions.extract(code, ("!simple", "!parametric")),
  )
  ```
)

To handle this kind of use case, _Crudo_ provides the `history` module.
The #ref-fn("history.ranges()") and #ref-fn("history.extract()") functions work similar to their region counterparts, but instead of taking any number of regions, they take the single current step and a complete list of the steps in the file's history as parameters.
The #ref-fn("history.ranges-within") function is a direct alias to #ref-fn("regions.ranges-within()"), as it's directly applicable to the history module as well.

Here's how to use the module for a direct comparison:

#let code = crudo.read("assets/history/greet.rs", properties: (block: true, lang: "rust"))

#man-style.show-example(
  in-raw: false,
  dir: ttb,
  no-codly: false,
  scale-preview: 100%,
  scope: (crudo: crudo, code: code),
  ```typ
  >>>#show: pad.with(x: -2mm)
  <<<#let code = crudo.read("greet.rs", properties: (block: true, lang: "rust"))
  #let history = ("simple", "parametric", "localized")
  #grid(
    columns: (1fr, 1.2fr),
    crudo.history.extract(code, "simple", history) +
    crudo.history.extract(code, "parametric", history),
    crudo.history.extract(code, "localized", history),
  )
  ```
)

And here is how the code is prepared to be used with the history module:

#code

There are some differences here:

- We are not declaring regions but steps; instead of writing `@region start:` we're just writing `@start:`.
  Each tag can also only start or end a single step, not multiple or both,
  and steps must be properly nested to reflect them happening sequentially.
    - There is also a region called `TODOs`; you can learn about that in @highlighting-history.

- The code as a whole is enclosed in a step.
  This is necessary: code outside a step would not be considered part of the history and wouldn't be picked up.

- There are also `@before:` tags, and these are wrapped in block comments.
  That means when running the annotated code, only the final version of the code is actually used.
  A `@before` tag's content will be removed from the enclosing step when the declared step is reached.
  For example, line 12 in the `@before:localized` tag will be displayed in the `parametric` step, but not later.

You may have also noticed that the `let name = todo!();` line is no longer duplicated;
achieving that with regions would have been way harder.

That `@before` tags are block comments also has its downsides, unfortunately:
when not using `extract` and instead using a code block library to limit the lines, the syntax highlighting will pick up on the code actually being a comment:

#man-style.show-example(
  in-raw: false,
  no-codly: false,
  scale-preview: 100%,
  scope: (crudo: crudo, code: code, codly: codly),
  ```typ
  >>>#show: pad.with(x: -2mm)
  >>>#import codly: codly, codly-init, no-codly
  >>>#let history = ("simple", "parametric", "localized")
  #let ranges = crudo.history.ranges(
      code, "simple", history)
  #codly(ranges:
      ranges.map(((a, b)) => (a, b - 1)))
  #code
  ```
)

The history module is therefore less useful for this kind of usage.

=== Highlighting regions inside evolving code snippets <highlighting-history>

While using histories is great, they don't readily support selecting regions for highlighting:
you can't easily select _only_ the current step, or a different subset of lines.
The #ref-fn("history.ranges()") function therefore slightly integrates with #ref-fn("regions.ranges()"), in that it _also_ ignores region indicators.
That lets you insert region indicators into your code files which won't be shown in code snippets, which you can then use for highlighting:

#man-style.show-example(
  in-raw: false,
  dir: ttb,
  scale-preview: 100%,
  no-codly: false,
  scope: (crudo: crudo, code: code, codly: codly),
  ```typ
  >>>#show: pad.with(x: -2mm)
  >>>#set text(0.8em)
  >>>#import codly: codly, codly-init, no-codly
  >>>#import "@local/zebraw:0.6.1": zebraw
  #let history = ("simple", "parametric", "localized")
  #let ranges = crudo.history.ranges(code, "parametric", history)
  #let highlights = crudo.regions.ranges(code, "TODOs")
  #let highlight-lines = highlights.map(((a, b)) => range(a, b)).join()
  #grid(
    columns: (1fr, 1fr),
  <<<  codly-init[
  >>>  [
      #codly(ranges: ranges.map(((a, b)) => (a, b - 1)),
          highlighted-lines: highlight-lines)
      #code
    ],
  >>>  no-codly(
    zebraw(line-range: ranges, highlight-lines: highlight-lines, code),
  >>>  ),
  )
  ```
)

The `TODOs` range contained more than just this one line (another one comes from the `localized` step), but the non-shown lines don't hurt during highlighting.
Likewise, #ref-fn("history.ranges-within") will ignore them as well.

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
  scope: (ref-fn: ref-fn),
  name: "history",
)
