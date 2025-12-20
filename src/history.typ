/// Returns an array of line ranges; each range is a pair of numbers representing the lower
/// (inclusive) and upper (exclusive) bound of the range.
/// The ranges that are returned are specified via the `current` step, which must be an element of
/// the specified `history`.
/// The lines that are returned are those that come in the history before or at `current`, but have
/// not been removed through an `@before` tag.
///
/// The resulting ranges can be used with #ref-fn("lines()") (although see @@extract() as a
/// shortcut), @@ranges-within, or with libraries such as
/// #link("https://typst.app/universe/package/codly")[codly] or
/// #link("https://typst.app/universe/package/zebraw")[zebraw].
/// See @history for more examples on using histories.
///
/// -> array
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
  assert(current.match(regex(`^!?[-\w]+$`.text)) != none, message: "current must consist of word characters")
  assert(history.all(x => x.match(regex(`^!?[-\w]+$`.text)) != none), message: "all history elements must consist of word characters")

  let current-index = history.position(x => x == current)
  assert(current-index != none, message: "the current step must be part of the history")
  let past = history.slice(0, current-index + 1)

  let ranges = ()
  let current-regions = ()
  let current-start = -1
  let only-before = none
  for (index, line) in lines.enumerate(start: 1) {
    let indicator = line.match(regex(
      `^\s*//\s*@(start|end):([-\w]+)\s*$`.text + "|" +
      `^\s*/\*\s*@before:([-\w]+)\s*$`.text + "|" +
      `^\s*\*/\s*$`.text))

    let indicator = if indicator != none {
      if indicator.captures.at(0) != none {
        ("regular", ..indicator.captures.slice(0, 2))
      } else if indicator.captures.at(2) != none {
        ("before", "start", ..indicator.captures.slice(2, 3))
      } else if only-before != none {
        ("before", "end")
      }
    }
    if indicator != none {
      if current-start not in (none, -1) {
        // the region is ending or interrupted; push a range
        ranges.push((current-start, index))
        current-start = none
      }

      // update the list of current ranges
      let (kind, pos, ..data) = indicator
      if (kind, pos) == ("regular", "start") {
        let (name,) = data
        assert(name not in current-regions, message: "can't start already open region: " + name)
        current-regions.push(name)
      } else if (kind, pos) == ("regular", "end") {
        let (name,) = data
        assert(current-regions.last() == name, message: "can't end non-current region: " + name)
        _ = current-regions.pop()
      } else if (kind, pos) == ("before", "start") {
        let (name,) = data
        only-before = name
      } else if (kind, pos) == ("before", "end") {
        only-before = none
      } else {
        panic()
      }

      // indicate that we hit an indicator and a new range may start
      current-start = -1
    } else if current-start == -1 {
      // check if we're in a range that we're interested in
      if (
        current-regions.len() != 0 and
        current-regions.last() in past and
        (only-before == none or not only-before in past)
      ) {
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

/// Uses @@ranges() combined with #ref-fn("lines()") to select a subset of lines from a code
/// snippet.
/// This function is equivalent to
///
/// ```typc
/// lines(raw-block, ..ranges(raw-block, current, history).map(((a, b)) => range(a, b)))
/// ```
///
/// -> content
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

#import "regions.typ": ranges-within

/// This is a re-export of #ref-fn("regions.ranges-within()") since that function is also appropriate for the ranges produced by this module.
///
/// -> function
#let ranges-within = ranges-within