#import "@preview/codly:1.3.0"
#import "@local/zebraw:0.6.1"

#import "/src/lib.typ" as crudo: regions

#set page(height: auto, margin: 1cm)
#show raw.where(block: true): set text(0.9em)

#let example(body, zebraw-args: (:), codly-args: (:)) = grid(
  columns: 2 * (1fr,),
  column-gutter: 1em,
  zebraw.zebraw(
    extend: false,  // hide empty headers and footers
    lang: false,  // hide language tag, I don't like the style
    background-color: (luma(255), luma(245)),
    inset: (top: 0.48em, bottom: 0.48em),
    smart-skip: false,
    ..zebraw-args,
  )[
    #show raw.where(block: true): block.with(
      stroke: luma(245) + 2pt,
      radius: 4pt,
    )
    #body
  ],

  codly.codly-init()[
    #codly.codly(..codly-args)
    #body
  ],
)

#let ex-java = crudo.read("RegionsExample.java", properties: (block: true, lang: "java"))

#example(ex-java)

#pagebreak()

#let ranges = none
#let lines = regions.ranges(ex-java, ranges)
#lines

#let highlights = ((10, 13), (23, 26))
#let highlight-lines = regions.ranges-within(lines, highlights).map(((a, b)) => range(a, b)).join()
#example(
  regions.extract(ex-java, ranges),
  zebraw-args: (highlight-lines: highlight-lines),
  codly-args: (highlighted-lines: highlight-lines),
)

#pagebreak()

#let highlight-lines = highlights.map(((a, b)) => range(a, b)).join()
#example(
  ex-java,
  zebraw-args: (
    line-range: lines,
    highlight-lines: highlight-lines,
  ),
  codly-args: (
    ranges: lines.map(((a, b)) => (a, b - 1)),
    highlighted-lines: highlight-lines,
  ),
)

#pagebreak()

#let ranges = "basics"
#let lines = regions.ranges(ex-java, ranges)
#lines

#example(
  regions.extract(ex-java, ranges)
)

#pagebreak()

#example(
  ex-java,
  zebraw-args: (line-range: lines),
  codly-args: (ranges: lines.map(((a, b)) => (a, b - 1))),
)

#pagebreak()

#let ranges = "!mutators"
#let lines = regions.ranges(ex-java, ranges)
#lines

#example(
  regions.extract(ex-java, ranges)
)

#pagebreak()

#example(
  ex-java,
  zebraw-args: (line-range: lines),
  codly-args: (ranges: lines.map(((a, b)) => (a, b - 1))),
)

#pagebreak()

#let ranges = ("all", "!mutators")
#let lines = regions.ranges(ex-java, ranges)
#lines

#example(
  regions.extract(ex-java, ranges)
)

#pagebreak()

#example(
  ex-java,
  zebraw-args: (line-range: lines),
  codly-args: (ranges: lines.map(((a, b)) => (a, b - 1))),
)
