#import "@preview/tidy:0.3.0"

#import "template.typ": *

#import "../src/lib.typ" as crudo

#let package-meta = toml("../typst.toml").package
#let date = none
// #let date = datetime(year: ..., month: ..., day: ...)

#show: project.with(
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

This is a template for typst packages. It provides, for example, the #ref-fn("crudo.add()") function:

#{
  let lines = read("../gallery/test.typ").trim().split("\n")
  lines = lines.slice(4)
  raw(block: true, lang: "typ", lines.join("\n"))
}

= Module reference

== `crudo`

#{
  let module = tidy.parse-module(
    read("../src/lib.typ"),
    label-prefix: "crudo.",
    scope: scope,
  )
  tidy.show-module(
    module,
    sort-functions: none,
    style: tidy.styles.minimal,
  )
}
