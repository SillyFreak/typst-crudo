// make the PDF reproducible to ease version control
#set document(date: none)

// #import "/src/lib.typ"
#import "@preview/crudo:0.1.0"

#import "@preview/codly:1.0.0": *

#set page(width: 10cm, height: auto, margin: 5mm)

#show: codly-init
#codly()

From

#let preamble = ```typ
#import "@preview/crudo:0.1.0"

```
#preamble

and

#let example = ````typ
#crudo.r2l(```c
int main() {
  return 0;
}
```)
````
#example

we get

#let full-example = crudo.join(preamble, example)
#full-example

If you execute that, you get

#eval(full-example.text, mode: "markup")
