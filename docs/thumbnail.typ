#import "/src/lib.typ" as crudo

#import "@preview/codly:1.2.0": *

#set page(height: auto, margin: 5mm, fill: none)

// style thumbnail for light and dark theme
// #let theme = sys.inputs.at("theme", default: "light")
// #set text(white) if theme == "dark"
#set page(fill: auto)

#set text(22pt)

#show: codly-init
#codly()

From

#let preamble = ```typ
#import "@preview/crudo:0.1.1"

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
