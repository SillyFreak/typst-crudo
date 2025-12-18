#let ranges(
  /// a single `raw` element or (multi line) string
  /// -> content | str
  raw-block,
  /// the step at which to show the file
  /// -> str
  current,
  /// an array of step names that appear in the file, establishing the order of modifications to
  /// determine what steps have come before `current`.
  /// -> array
  history,
) = {
  import "lib.typ": r2l

  let lines = r2l(raw-block).first()
  assert.eq(type(current), str, message: "current must be a string")
  assert.eq(type(history), array, message: "history must be an array of strings")
  assert(history.all(x => type(x) == str), message: "history must be an array of strings")
  assert(current.match(regex(`^!?\w+$`.text)) != none, message: "current must consist of word characters")
  assert(history.all(x => x.match(regex(`^!?\w+$`.text)) != none), message: "all history elements must consist of word characters")

  let current-index = history.position(x => x == current)
  assert(current-index != none, message: "the current step must be part of the history")
  let past = history.slice(0, current-index + 1)

  let ranges = ()
  let current-regions = ()
  let current-start = -1
  for (index, line) in lines.enumerate(start: 1) {
    let indicator = line.match(regex(`^\s*//\s*@(start|end):(\w+)$`.text))
    if indicator != none {
      if current-start not in (none, -1) {
        // the region is ending or interrupted; push a range
        ranges.push((current-start, index))
        current-start = none
      }

      // update the list of current ranges
      let (kind, name) = indicator.captures
      if kind == "start" {
        assert(name not in current-regions, message: "can't start already open region: " + name)
        current-regions.push(name)
      } else {
        assert(current-regions.last() == name, message: "can't end non-current region: " + name)
        _ = current-regions.pop()
      }

      // indicate that we hit an indicator and a new range may start
      current-start = -1
    } else if current-start == -1 {
      // check if we're in a range that we're interested in
      if current-regions.len() != 0 and current-regions.last() in past {
        current-start = index
      } else {
        // no; don't check until the next indicator
        current-start = none
      }
    }
  }
  assert.eq(current-regions, (), message: "an unclosed region was encountered: " + current-regions.join(", "))
  assert(ranges != (), message: "no lines were matched; did you misspell the selected regions?")

  ranges
}


#let extract(
  /// a single `raw` element or (multi line) string
  /// -> content | str
  raw-block,
  /// the step at which to show the file
  /// -> str
  current,
  /// an array of step names that appear in the file, establishing the order of modifications to
  /// determine what steps have come before `current`.
  /// -> array
  history,
) = {
  import "lib.typ": lines

  lines(raw-block, ..ranges(raw-block, current, history).map(((a, b)) => range(a, b)))
}
