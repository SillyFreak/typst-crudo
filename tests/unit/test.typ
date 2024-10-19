#import "/src/lib.typ" as crudo

// the output is not relevant for this test
#set page(width: 0pt, height: 0pt)

#assert.eq(
  crudo.r2l(```txt
  first line
  second line
  ```),
  (
    ("first line", "second line"),
    (block: true, lang: "txt"),
  ),
)

#assert.eq(
  crudo.r2l(raw("first line\nsecond line")),
  (
    ("first line", "second line"),
    (:),
  ),
)

#assert.eq(
  crudo.r2l("first line\nsecond line"),
  (
    ("first line", "second line"),
    (:),
  ),
)

#assert.eq(
  crudo.l2r(("first line", "second line")),
  raw("first line\nsecond line"),
)

#assert.eq(
  crudo.l2r(
    ("first line", "second line"),
    block: true,
  ),
  raw("first line\nsecond line", block: true),
)

#assert.eq(
  crudo.read(
    properties: (block: true, lang: "md"),
    "example.md",
  ),
  raw("\n# Example\n\nLorem ipsum.", block: true, lang: "md"),
)

#assert.eq(
  crudo.transform(
    ```typc
    let foo() = {
      // some comment
      ... do something ...
    }
    ```,
    lines => lines.filter(l => {
      // only preserve non-comment lines
      not l.starts-with(regex("\s*//"))
    })
  ),
  raw("let foo() = {\n  ... do something ...\n}", block: true, lang: "typc"),
)

#assert.eq(
  crudo.map(
    ```typc
    let foo() = {
      // some comment
      ... do something ...
    }
    ```,
    line => line.trim()
  ),
  raw("let foo() = {\n// some comment\n... do something ...\n}", block: true, lang: "typc"),
)

#assert.eq(
  crudo.filter(
    ```typc
    let foo() = {
      // some comment
      ... do something ...
    }
    ```,
    l => not l.starts-with(regex("\s*//"))
  ),
  raw("let foo() = {\n  ... do something ...\n}", block: true, lang: "typc"),
)

#assert.eq(
  crudo.slice(
    ```typc
    let foo() = {
      // some comment
      ... do something ...
    }
    ```,
    1, 3,
  ),
  raw("  // some comment\n  ... do something ...", block: true, lang: "typc"),
)

#assert.eq(
  crudo.lines(
    ```typc
    let foo() = {
      // some comment
      ... do something ...
      // another comment
    }
    ```,
    "-2,4-,1", "2-3", range(3, 5), 5,
  ),
  raw("let foo() = {\n  // some comment\n  // another comment\n}\nlet foo() = {\n  // some comment\n  ... do something ...\n  ... do something ...\n  // another comment\n}", block: true, lang: "typc"),
)

#assert.eq(
  crudo.lines(
    zero-based: true,
    ```typc
    let foo() = {
      // some comment
      ... do something ...
      // another comment
    }
    ```,
    "-1,3-,0", "1-2", range(2, 4), 4,
  ),
  raw("let foo() = {\n  // some comment\n  // another comment\n}\nlet foo() = {\n  // some comment\n  ... do something ...\n  ... do something ...\n  // another comment\n}", block: true, lang: "typc"),
)

#assert.eq(
  crudo.join(
    ```java
    let foo() = {
      // some comment
      ... do something ...
    }
    ```,
    ```typc
    let bar() = {
      // some comment
      ... do something ...
    }
    ```,
    main: -1,
  ),
  raw("let foo() = {\n  // some comment\n  ... do something ...\n}\nlet bar() = {\n  // some comment\n  ... do something ...\n}", block: true, lang: "typc"),
)

#assert.eq(
  crudo.join(
    "// these strings don't",
    "// determine the properties",
    ```typ
    // this raw block does:
    // still Typst!
    ```,
  ),
  raw("// these strings don't\n// determine the properties\n// this raw block does:\n// still Typst!", block: true, lang: "typ"),
)
