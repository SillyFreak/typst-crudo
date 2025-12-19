#let ranges(
  /// a single `raw` element or (multi line) string
  /// -> content | str
  raw-block,
  /// a single or array of region names, or `none` to get all lines that don't indicate regions
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
    assert(regions.all(x => x.match(regex(`^!?\w+$`.text)) != none), message: "regions must consist of word characters")

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
    let indicator = line.match(regex(`^\s*//\s*@region((?:\s+(?:start|end):\w+)*)\s*$`.text))
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

#let extract(
  /// a single `raw` element or (multi line) string
  /// -> content | str
  raw-block,
  /// a single or array of region names, or `none` to get all lines that don't indicate regions
  /// -> none | str | array
  regions,
) = {
  import "lib.typ": lines

  lines(raw-block, ..ranges(raw-block, regions).map(((a, b)) => range(a, b)))
}

#let ranges-within(
  outer-ranges,
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
  let outer-i = 0
  // if we e.g. start with outer range (2, 5), then 2 lines have already been skipped
  // subtract 1 since we use 1-based indices
  let skipped-lines = outer-ranges.first().first() - 1
  for (inner-a, inner-b) in inner-ranges {
    let (outer-a, outer-b) = outer-ranges.at(outer-i)

    while inner-a >= outer-b {
      // the inner range is in a subsequent outer range
      outer-i += 1
      assert(outer-i < outer-ranges.len(), message: "inner ranges can't lie beyond the last outer range")
      let old-outer-b = outer-b
      (outer-a, outer-b) = outer-ranges.at(outer-i)
      skipped-lines += outer-a - old-outer-b
    }

    // now we're in the right range. the outer range must fully contain the inner one:
    // if there was an indicator that interrupted the outer range, it must also have interrupted the inner range
    assert(inner-b <= outer-b, message: "each inner range must be fully contained in one outer range")
    inner-a -= skipped-lines
    inner-b -= skipped-lines
    if ranges.len() != 0 and ranges.last().last() == inner-a {
      // after removing skipped lines, the new range joins with the previous one
      ranges.last().last() = inner-b
    } else {
      ranges.push((inner-a, inner-b))
    }
  }

  ranges
}