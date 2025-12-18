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

#let ex-java = crudo.read("Example.java", properties: (block: true, lang: "java"))

#example(ex-java)

#pagebreak()

#let lines = regions.ranges(ex-java, none)
#lines

#example(
  crudo.lines(ex-java, ..lines.map(((a, b)) => range(a, b)))
)

#pagebreak()

#example(
  ex-java,
  zebraw-args: (line-range: lines),
  codly-args: (ranges: lines.map(((a, b)) => (a, b - 1))),
)

#pagebreak()

#let lines = regions.ranges(ex-java, "basics")
#lines

#example(
  crudo.lines(ex-java, ..lines.map(((a, b)) => range(a, b)))
)

#pagebreak()

#example(
  ex-java,
  zebraw-args: (line-range: lines),
  codly-args: (ranges: lines.map(((a, b)) => (a, b - 1))),
)

#pagebreak()

#let lines = regions.ranges(ex-java, "!mutators")
#lines

#example(
  crudo.lines(ex-java, ..lines.map(((a, b)) => range(a, b)))
)

#pagebreak()

#example(
  ex-java,
  zebraw-args: (line-range: lines),
  codly-args: (ranges: lines.map(((a, b)) => (a, b - 1))),
)
