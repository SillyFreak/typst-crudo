/// Returns an array of line ranges; each range is a pair of numbers representing the lower
/// (inclusive) and upper (exclusive) bound of the range.
/// There is no one to one correspondence between the requested `regions` and the returned ranges:
///
/// - if a region contains region markers, those markers will be excluded, resulting in multiple
///   ranges for that region;
/// - if a region appears multiple times in the `raw-block`, each appearance will have its own
///   range(s).
///
/// The resulting ranges can be used with #ref-fn("lines()") (although see @@extract() as a
/// shortcut), @@ranges-within(), or with libraries such as
/// #link("https://typst.app/universe/package/codly")[codly] or
/// #link("https://typst.app/universe/package/zebraw")[zebraw].
/// See @regions for more examples on using regions.
///
/// -> array
#let ranges(
  /// a single `raw` element or (multi line) string
  /// -> content | str
  raw-block,
  /// a single or array of region names, or `none` to get all lines that don't indicate regions.
  /// Prefixing a region with `!` excludes the region instead of excluding it.
  /// -> none | str | array
  regions,
) = {
  import "lib.typ": r2l

  let lines = r2l(raw-block).first()
  assert(
    if type(regions) == array {
      regions.all(x => type(x) == str)
    } else {
      type(regions) in (type(none), str)
    },
    message: "region must be none, a string or an array of strings",
  )
  if type(regions) == str {
    regions = (regions,)
  }

  let (regions, excluded-regions) = if regions == none {
    // all  included, no exclusions
    (none, ())
  } else {
    assert(regions.all(x => x.match(regex(`^!?[-\w]+$`.text)) != none), message: "regions must consist of word characters")

    let excluded-regions = regions.filter(x => x.starts-with("!")).map(x => x.slice(1))
    if regions.len() == excluded-regions.len() {
      // only exclusions, so include all
      (none, excluded-regions)
    } else {
      // both inclusions and exclusions
      let regions = regions.filter(x => not x.starts-with("!"))
      (regions, excluded-regions)
    }
  }

  let ranges = ()
  let current-regions = ()
  let current-start = -1
  for (index, line) in lines.enumerate(start: 1) {
    let indicator = line.match(regex(`^\s*//\s*@region((?:\s+(?:start|end):[-\w]+)*)\s*$`.text))
    if indicator != none {
      if current-start not in (none, -1) {
        // the region is ending or interrupted; push a range
        ranges.push((current-start, index))
        current-start = none
      }

      // update the list of current ranges
      for indicator in indicator.captures.first().trim().split() {
        let (kind, name) = indicator.split(":")
        if kind == "start" {
          assert(name not in current-regions, message: "can't start already open region: " + name)
          current-regions.push(name)
        } else {
          assert(name in current-regions, message: "can't end non-open region: " + name)
          current-regions = current-regions.filter(x => x != name)
        }
      }

      // indicate that we hit an indicator and a new range may start
      current-start = -1
    } else if current-start == -1 {
      // check if we're in a range that we're interested in
      let is-included = regions == none or regions.any(x => x in current-regions)
      let is-excluded = excluded-regions.any(x => x in current-regions)
      if is-included and not is-excluded {
        current-start = index
      } else {
        // no; don't check until the next indicator
        current-start = none
      }
    }
  }
  assert.eq(current-regions, (), message: "an unclosed region was encountered: " + current-regions.join(", "))
  if current-start not in (none, -1) {
    // a range was open at the end. this must only happen if all lines were requested
    // (this should already be true because we checked that no range is open, but check anyway)
    assert(regions == none, message: "an unclosed region was encountered")
    ranges.push((current-start, lines.len() + 1))
    current-start = none
  }
  assert(ranges != (), message: "no lines were matched; did you misspell the selected regions?")

  ranges
}

/// Uses @@ranges() combined with #ref-fn("lines()") to select a subset of lines from a code
/// snippet.
/// This function is equivalent to
///
/// ```typc
/// lines(raw-block, ..ranges(raw-block, regions).map(((a, b)) => range(a, b)))
/// ```
///
/// -> content
#let extract(
  /// a single `raw` element or (multi line) string
  /// -> content | str
  raw-block,
  /// a single or array of region names, or `none` to get all lines that don't indicate regions.
  /// Prefixing a region with `!` excludes the region instead of excluding it.
  /// -> none | str | array
  regions,
) = {
  import "lib.typ": lines

  lines(raw-block, ..ranges(raw-block, regions).map(((a, b)) => range(a, b)))
}

/// Translates the `inner-ranges` line numbers for use in a code block that has been reduced to only
/// contain the ranges from `outer-ranges`.
///
/// Let's say we have a code snippet with 20 lines and wanted to skip lines 1-2 and 11-12.
/// We would therefore specify `outer-ranges` as #((3, 11), (13, 21)) (upper bound is exclusive).
/// In the resulting snippet, we want to refer to lines 4 and 14-15, so we specify `inner-ranges` as
/// #((4, 5), (14, 16))---but because we're removing lines, we need to use different line numbers to
/// refer to these!
/// `ranges-within()` will give us the correct result ranges of #((2, 3), (10, 12)).
///
/// If the `inner-ranges` contain lines that are not contained in the `outer-ranges`, these will be
/// dropped.
/// See @highlighting-regions for more examples on using ranges within ranges.
///
/// -> array
#let ranges-within(
  /// an array of line ranges, as returned by @@ranges().
  /// This determines what lines are present in the resulting code snippet and what line numbers are
  /// skipped.
  ///  -> array
  outer-ranges,
  /// an array of line ranges, as returned by @@ranges().
  /// This determines what lines should be selected within the outer ranges.
  /// Lines not inside the outer ranges are skipped, and line numbers are changed to skip any lines
  /// that don't appear in the outer ranges.
  /// -> array
  inner-ranges,
) = {
  assert(
    type(outer-ranges) == array and outer-ranges.all(x => type(x) == array and x.len() == 2 and x.all(x => type(x) == int)),
    message: "outer-ranges must be an array of pairs of ints",
  )
  assert(
    type(inner-ranges) == array and inner-ranges.all(x => type(x) == array and x.len() == 2 and x.all(x => type(x) == int)),
    message: "inner-ranges must be an array of pairs of ints",
  )

  let ranges = ()
  let inner-i = 0
  let outer-i = 0
  // if we e.g. start with outer range (2, 5), then 2 lines have already been skipped
  // subtract 1 since we use 1-based indices
  let skipped-lines = outer-ranges.first().first() - 1
  while true {
    let (inner-a, inner-b) = inner-ranges.at(inner-i)
    let (outer-a, outer-b) = outer-ranges.at(outer-i)

    if outer-b <= inner-a  {
      // the inner range is beyond the current outer range
      outer-i += 1
      // the rest of the inner ranges are not part of something displayed
      if outer-i >= outer-ranges.len() { break }

      // process the skip and go to the next iteration
      let next-outer-a = outer-ranges.at(outer-i).first()
      skipped-lines += next-outer-a - outer-b
      continue
    }

    if inner-b <= outer-a {
      // the inner range was before the first/between two outer ranges
      inner-i += 1
      // if all inner ranges have been processed, we're done
      if inner-i >= inner-ranges.len() { break }
    }

    // the current inner overlaps the current outer range
    let a = calc.max(outer-a, inner-a) - skipped-lines
    let b = calc.min(outer-b, inner-b) - skipped-lines
    if ranges.len() != 0 and ranges.last().last() == a {
      // after removing skipped lines, the new range joins with the previous one
      ranges.last().last() = b
    } else {
      ranges.push((a, b))
    }

    if inner-b <= outer-b {
      // continue in the same outer range, after the current inner range
      outer-ranges.at(outer-i).first() = inner-b
    }
    if outer-b <= inner-b {
      // continue in the same inner range, after the current outer range
      inner-ranges.at(inner-i).first() = outer-b
    }
  }

  ranges
}