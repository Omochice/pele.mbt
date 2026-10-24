///|
/// Tracks: the room kept clear between a rank and the nearest track, the room between two tracks when the gap has to grow to hold them, and the most they spread to when it has room to spare.
let track_margin = 18.0

///|
let track_pitch = 10.0

///|
let track_spread = 14.0

///|
/// A curve is one plain S unless it runs more than this many times as far across as the gap is high, and so does another that it would run along.
/// Then each turns onto a level of its own to run across on.
let level_wide = 2.0

///|
/// The levels of a gap keep this far from its ranks, to leave room to turn in.
let level_margin = 28.0

///|
/// The room between two levels of a gap.
let level_pitch = 12.0

///|
/// The room a plain curve is taken to keep straight at each end of its gap.
let level_lead = 12.0

///|
/// Two plain curves that would pass nearer than this turn at levels of their own where one of them runs far across, since it stays near the other for a long way.
let level_clear = 8.0

///|
/// Two plain curves that would pass nearer than this turn at levels of their own otherwise.
let level_touch = 4.0

///|
/// Where the curves of a gap cross each other more often than they run alongside, each curve is one plain S, and the gap is made this many times as tall as its widest curve runs across.
let crossed_slope = 0.5

///|
/// Past this many edges across one gap, tracks are given out in a plain order: weighing every pair of edges against each other would take too long.
let max_weighed = 400

///|
let samples = 16

///|
/// The pieces of edges that each cross one gap: where they leave the rank above and reach the one below, the rank above, the bend they end at (or -1 at the edge's last node), and the track they run across on (or -1 when they have none).
/// Where only some pieces are given a level to turn onto, `wide` marks those that run far across, `levels` is how many tracks the group a piece belongs to takes, or 0 for a piece that needs none, and each piece's track counts from its group's first.
/// A piece that is not `wide` curves from the level above its own.
priv struct Pieces {
  from : Array[Double]
  to : Array[Double]
  rank : Array[Int32]
  lower : Array[Int32]
  track : Array[Int32]
  levels : Array[Int32]
  wide : Array[Bool]
}

///|
/// Gives every piece that does not run straight down a track across its gap, and counts the tracks of each gap.
/// Two pieces in one gap share a track only where they cannot be mistaken for each other: where they do not overlap, or where they leave from or arrive at the same point, as the branches of a tree do.
/// Which of two goes above the other is whichever makes them cross less.
/// With `curved`, the tracks are levels for curves to turn onto, and only the pieces that would run along or too near another get one: each group of those counts its tracks from its own first.
/// `room` is the height of the gap under each rank, and `tall` receives the height that a gap whose curves mostly cross each other should have instead of levels.
fn assign_tracks(
  pieces : Pieces,
  track_count : FixedArray[Int32],
  curved : Bool,
  room : FixedArray[Double],
  tall : FixedArray[Double],
) -> Unit {
  let from = pieces.from
  let to = pieces.to
  let track = pieces.track
  let levels = pieces.levels
  let wide = pieces.wide
  let total = from.length()
  let by_rank : Map[Int32, Array[Int32]] = Map([])
  for k in 0..<total {
    track.push(-1)
    levels.push(0)
    if (from[k] - to[k]).abs() < in_line {
      continue
    }
    match by_rank.get(pieces.rank[k]) {
      Some(list) => list.push(k)
      None => by_rank[pieces.rank[k]] = [k]
    }
  }
  if by_rank.length() == 0 {
    return
  }
  // The pieces are compared pair by pair, so where each begins and ends across the flow is worked out once.
  let lo_of = FixedArray::makei(total, k => @util.js_min(from[k], to[k]))
  let hi_of = FixedArray::makei(total, k => @util.js_max(from[k], to[k]))
  let within = fn(x : Double, k : Int32) {
    if x >= lo_of[k] - in_line && x <= hi_of[k] + in_line {
      1
    } else {
      0
    }
  }
  let mates = fn(a : Int32, b : Int32) {
    (from[a] - from[b]).abs() < in_line || (to[a] - to[b]).abs() < in_line
  }
  let overlap = fn(a : Int32, b : Int32) {
    lo_of[a] < hi_of[b] - in_line && lo_of[b] < hi_of[a] - in_line
  }
  // Whether a and b need tracks of their own.
  let clash = fn(a : Int32, b : Int32) { overlap(a, b) && !mates(a, b) }
  // Whether one of a and b could cross the other, depending on which is above.
  let meet = fn(a : Int32, b : Int32) {
    overlap(a, b) ||
    within(to[a], b) +
    within(from[b], a) +
    within(to[b], a) +
    within(from[a], b) >
    0
  }
  // How often a and b cross with a on the higher track: a's way down through b, and b's way down to itself through a.
  let crossings = fn(a : Int32, b : Int32) {
    within(to[a], b) + within(from[b], a)
  }
  // Pairs of list indices, smaller first.
  // Omitted pairs cannot meet or clash.
  let near_pairs = fn(list : Array[Int32]) {
    let by_lo = Array::makei(list.length(), i => i)
    sort_array(by_lo, fn(a, b) { lo_of[list[a]] - lo_of[list[b]] })
    let pairs = []
    for x in 0..<by_lo.length() {
      let i = by_lo[x]
      let reach = hi_of[list[i]] + 4 * in_line
      for y = x + 1
          y < by_lo.length() && lo_of[list[by_lo[y]]] <= reach
          y = y + 1 {
        let j = by_lo[y]
        pairs.push(if i < j { i } else { j })
        pairs.push(if i < j { j } else { i })
      }
    }
    pairs
  }

  // Gives the pieces of one gap in `list` their tracks, and each the number of tracks that the pieces it has to do with take between them, counting its own from the first of those.
  // Returns the number of tracks.
  // The pieces come without tracks.
  let lay = fn(list : Array[Int32]) -> Int32 {
    // A plain order to start from, and to keep where nothing says otherwise: the pieces that reach furthest go first, so that those of one fan nest.
    sort_array(list, fn(a, b) {
      or_else(
        hi_of[b] - lo_of[b] - (hi_of[a] - lo_of[a]),
        or_else(lo_of[a] - lo_of[b], (a - b).to_double()),
      )
    })
    let count = list.length()
    let above : Array[Array[Int32]] = []
    let group = FixedArray::makei(count, i => i)
    let find = fn(i : Int32) {
      let mut i = i
      while group[i] != i {
        group[i] = group[group[i]]
        i = group[i]
      }
      i
    }
    let weighed = count <= max_weighed
    // Dense gaps do not store quadratically many pairs.
    let pairs = if weighed { near_pairs(list) } else { [] }
    let clashes : Array[Array[Int32]] = if weighed {
      Array::makei(count, _ => [])
    } else {
      []
    }
    let mut p = 0
    while p < pairs.length() {
      let i = pairs[p]
      let j = pairs[p + 1]
      p += 2
      if !clash(list[i], list[j]) {
        continue
      }
      clashes[i].push(j)
      clashes[j].push(i)
    }
    let mut sequence = Array::makei(count, i => i)
    if weighed {
      // above[j] lists the pieces that should be above list[j].
      // The order follows as many of these as it can: a piece is placed once all that should be above it are, and when none is free, the one with the fewest still waiting.
      let waiting = FixedArray::make(count, 0)
      let after : Array[Array[Int32]] = []
      for _ in 0..<count {
        above.push([])
        after.push([])
      }
      let mut p = 0
      while p < pairs.length() {
        let i = pairs[p]
        let j = pairs[p + 1]
        p += 2
        let a = list[i]
        let b = list[j]
        if !meet(a, b) {
          continue
        }
        let ri = find(i)
        let rj = find(j)
        group[ri] = rj
        let ab = crossings(a, b)
        let ba = crossings(b, a)
        if ab == ba {
          continue
        }
        let first = if ab < ba { i } else { j }
        let second = if ab < ba { j } else { i }
        above[second].push(first)
        after[first].push(second)
        waiting[second] += 1
      }
      let placed = FixedArray::make(count, false)
      sequence = []
      for _done in 0..<count {
        let mut pick = -1
        for i in 0..<count {
          if placed[i] {
            continue
          }
          if pick < 0 || waiting[i] < waiting[pick] {
            pick = i
          }
          if waiting[i] == 0 {
            break
          }
        }
        placed[pick] = true
        sequence.push(pick)
        for j in after[pick] {
          waiting[j] -= 1
        }
      }
    }
    let taken : Set[Int32] = Set([])
    let on_track : Array[Array[Int32]] = []
    let mut rows = 0
    for at in sequence {
      let k = list[at]
      let mut t = 0
      if at < above.length() {
        for i in above[at] {
          if track[list[i]] >= t {
            t = track[list[i]] + 1
          }
        }
      }
      if weighed {
        taken.clear()
        for i in clashes[at] {
          taken.add(track[list[i]])
        }
        while taken.contains(t) {
          t += 1
        }
      } else {
        while t < on_track.length() &&
              on_track[t].iter().any(other => clash(k, other)) {
          t += 1
        }
        while on_track.length() <= t {
          on_track.push([])
        }
        on_track[t].push(k)
      }
      track[k] = t
      if t >= rows {
        rows = t + 1
      }
    }
    let first = FixedArray::make(count, rows)
    let last = FixedArray::make(count, -1)
    for i in 0..<count {
      let root = find(i)
      if track[list[i]] < first[root] {
        first[root] = track[list[i]]
      }
      if track[list[i]] > last[root] {
        last[root] = track[list[i]]
      }
    }
    for i in 0..<count {
      let root = find(i)
      levels[list[i]] = last[root] - first[root] + 1
      if curved {
        track[list[i]] -= first[root]
      }
    }
    rows
  }
  let line_a = FixedArray::make(2 * samples + 2, 0.0)
  let line_b = FixedArray::make(2 * samples + 2, 0.0)
  let sample = fn(k : Int32, h : Double, out : FixedArray[Double]) {
    let c = ease(to[k] - from[k], h)
    for i in 0..<=samples {
      let t = i.to_double() / samples.to_double()
      let u = 1.0 - t
      out[2 * i] = from[k] + (to[k] - from[k]) * t * t * (3.0 - 2.0 * t)
      out[2 * i + 1] = h *
        (3.0 * c * t * u * u + 3.0 * (1.0 - c) * t * t * u + t * t * t)
    }
  }
  let reaches = fn(
    points : FixedArray[Double],
    line : FixedArray[Double],
    limit : Double,
  ) {
    // Rounding error is allowed in the cheap distance check before the exact one.
    let bound = limit * limit * (1.0 + 1.0e-9)
    for i in 0..<=samples {
      let px = points[2 * i]
      let py = points[2 * i + 1]
      for j in 0..<samples {
        let dx = line[2 * j + 2] - line[2 * j]
        let dy = line[2 * j + 3] - line[2 * j + 1]
        let t = @util.js_max(
          0,
          @util.js_min(
            1,
            ((px - line[2 * j]) * dx + (py - line[2 * j + 1]) * dy) /
            or_else(dx * dx + dy * dy, 1),
          ),
        )
        let ex = px - line[2 * j] - t * dx
        let ey = py - line[2 * j + 1] - t * dy
        if ex * ex + ey * ey < bound && @util.js_hypot(ex, ey) < limit {
          return true
        }
      }
    }
    false
  }
  let near = fn(a : Int32, b : Int32, height : Double, limit : Double) {
    let h = @util.js_max(height / 2, height - 2 * level_lead)
    sample(a, h, line_a)
    sample(b, h, line_b)
    reaches(line_a, line_b, limit) || reaches(line_b, line_a, limit)
  }
  for r, all in by_rank {
    if !curved {
      track_count[r] = lay(all)
      continue
    }
    if all.length() > max_weighed {
      continue
    }
    // The pieces that turn onto levels: first those that run far across and have another such piece to be told apart from, then any two that would pass too near each other as plain curves.
    let far = all.filter(k => wide[k])
    ignore(lay(far))
    let level : Set[Int32] = Set([])
    for k in far {
      if levels[k] > 1 {
        level.add(k)
      }
    }
    let pairs = near_pairs(all)
    let mut p = 0
    while p < pairs.length() {
      let a = all[pairs[p]]
      let b = all[pairs[p + 1]]
      p += 2
      if (level.contains(a) && level.contains(b)) ||
        !clash(a, b) ||
        (from[a] < to[a]) != (from[b] < to[b]) {
        continue
      }
      if near(
          a,
          b,
          room[r],
          if wide[a] || wide[b] {
            level_clear
          } else {
            level_touch
          },
        ) {
        level.add(a)
        level.add(b)
      }
    }
    for k in far {
      track[k] = -1
      levels[k] = 0
    }
    if level.length() == 0 {
      continue
    }
    let mut crossing = 0
    let mut alongside = 0
    let beside : Set[Int32] = Set([])
    let mut p = 0
    while p < pairs.length() {
      let a = all[pairs[p]]
      let b = all[pairs[p + 1]]
      p += 2
      if level.contains(a) && level.contains(b) {
        if !overlap(a, b) {
          continue
        }
        if (from[a] < to[a]) != (from[b] < to[b]) {
          crossing += 1
        } else if !mates(a, b) {
          alongside += 1
        }
      } else if (level.contains(a) || level.contains(b)) && meet(a, b) {
        beside.add(a)
        beside.add(b)
      }
    }
    if crossing > alongside {
      for k in all {
        if (hi_of[k] - lo_of[k]) * crossed_slope > tall[r] {
          tall[r] = (hi_of[k] - lo_of[k]) * crossed_slope
        }
      }
      continue
    }
    // With them go the short pieces that could cross one of them, so that each has its place among the levels and crosses none.
    let members = all.filter(k => {
      level.contains(k) || (!wide[k] && beside.contains(k))
    })
    ignore(lay(members))
    let mut most = 0
    for k in members {
      if levels[k] > most {
        most = levels[k]
      }
    }
    track_count[r] = most
  }
}
