///|
const DOT : Double = 7

///|
const STEP : Double = 44

///|
const LANE : Double = 44

///|
/// Shorter than a step, so a curve between lanes never runs through a commit on a lane it crosses.
const CURVE : Double = 36

///|
const GAP : Double = 8

///|
const LABEL_GAP : Double = 20

///|
const TAIL : Double = 20

///|
const NOTCH : Double = 7

///|
const TAG_GAP : Double = 6

///|
const HALF : Double = 0.7071067811865476

///|
fn class_name(commit_type : CommitType) -> String {
  match commit_type {
    Normal => "normal"
    Reverse => "reverse"
    Highlight => "highlight"
    Merge => "merge"
    CherryPick => "cherry-pick"
  }
}

///|
priv struct View {
  commit : GitCommit
  index : Int32
  lane : Int32
  mut m : Double
  label : @text.Label?
  tags : Array[@text.Label]
}

///|
fn flag(config : @types.Config, key : String, fallback : Bool) -> Bool {
  guard config.get("gitGraph") is Some(Object(section)) else { return fallback }
  match section.get(key) {
    Some(True) => true
    Some(False) => false
    _ => fallback
  }
}

///|
fn tag_width(tag : @text.Label) -> Double {
  NOTCH + 4 + tag.width + 6
}

///|
fn symbol(
  commit_type : CommitType,
  x : Double,
  y : Double,
  color : String,
) -> String {
  let at = "cx=\"\{@svg.num(x)}\" cy=\"\{@svg.num(y)}\""
  match commit_type {
    Highlight =>
      "<rect x=\"\{@svg.num(x - DOT - 1)}\" y=\"\{@svg.num(y - DOT - 1)}\" width=\"\{@svg.num(2.0 * DOT + 2.0)}\" height=\"\{@svg.num(2.0 * DOT + 2.0)}\" rx=\"2\" fill=\"\{color}\"/>"
    Merge =>
      "<circle \{at} r=\"\{DOT - 1}\" fill=\"var(--_bg)\" stroke=\"\{color}\" stroke-width=\"2\"/><circle \{at} r=\"2.5\" fill=\"\{color}\"/>"
    Reverse =>
      "<circle \{at} r=\"\{DOT}\" fill=\"\{color}\"/>" +
      "<path d=\"M\{@svg.num(x - 3)},\{@svg.num(y - 3)}l6,6M\{@svg.num(x - 3)},\{@svg.num(y + 3)}l6,-6\" fill=\"none\" stroke=\"var(--_bg)\" stroke-width=\"1.5\" stroke-linecap=\"round\"/>"
    CherryPick =>
      "<circle \{at} r=\"\{DOT}\" fill=\"\{color}\"/>" +
      "<path d=\"M\{@svg.num(x - 2.6)},\{@svg.num(y + 1)}L\{@svg.num(x + 0.8)},\{@svg.num(y - 4.2)}L\{@svg.num(x + 2.6)},\{@svg.num(y + 1)}\" fill=\"none\" stroke=\"var(--_bg)\" stroke-linejoin=\"round\"/>" +
      "<circle cx=\"\{@svg.num(x - 2.6)}\" cy=\"\{@svg.num(y + 2.2)}\" r=\"1.8\" fill=\"var(--_bg)\"/>" +
      "<circle cx=\"\{@svg.num(x + 2.6)}\" cy=\"\{@svg.num(y + 2.2)}\" r=\"1.8\" fill=\"var(--_bg)\"/>"
    Normal => "<circle \{at} r=\"\{DOT}\" fill=\"\{color}\"/>"
  }
}

///|
/// The box that holds everything drawn, grown as pieces are placed.
priv struct Bounds {
  mut min_x : Double
  mut min_y : Double
  mut max_x : Double
  mut max_y : Double
}

///|
fn Bounds::grow(
  self : Bounds,
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
) -> Unit {
  if x0 < self.min_x {
    self.min_x = x0
  }
  if y0 < self.min_y {
    self.min_y = y0
  }
  if x1 > self.max_x {
    self.max_x = x1
  }
  if y1 > self.max_y {
    self.max_y = y1
  }
}

///|
/// Draws a git graph.
pub fn render_git(
  model : GitModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  if !(model.direction is LR) {
    return draw(model, config, options, model.direction)
  }
  @common.turn_to_fit(options, down => {
    draw(model, config, options, if down { TB } else { LR })
  })
}

///|
fn draw(
  model : GitModel,
  config : @types.Config,
  options : @types.RenderOptions,
  direction : GitDirection,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.75).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let show_branches = flag(config, "showBranches", true)
  let show_commit_label = flag(config, "showCommitLabel", true)
  let rotate = flag(config, "rotateCommitLabel", true)
  let parallel = flag(config, "parallelCommits", false)
  let vertical = !(direction is LR)
  let flip = direction is BT
  let lane_of : Map[String, Int32] = Map([])
  for index, name in model.lanes {
    lane_of.set(name, index)
  }
  let lane_count = model.lanes.length()
  let medium = (size * 0.875).round()
  // Mermaid writes branch names, tags, and commit ids as plain text, so tags in them show as written.
  let names = model.lanes.map(name => {
    @common.plain_label(
      Some(if show_branches { name } else { "" }),
      measurer,
      medium,
      4000,
    )
  })
  let views : Array[View] = []
  let by_id : Map[String, View] = Map([])
  let ordered = model.commits.values().collect()
  ordered.sort_by_key(commit => commit.seq)
  for commit in ordered {
    let labelled = show_commit_label &&
      !(commit.commit_type is CherryPick) &&
      (!(commit.commit_type is Merge) || commit.custom_id)
    let tags = []
    for tag in commit.tags {
      let label = @common.plain_label(Some(tag), measurer, small, 4000)
      if !label.lines.is_empty() {
        tags.push(label)
      }
    }
    let view : View = {
      commit,
      index: views.length(),
      lane: lane_of.get(commit.branch).unwrap_or(0),
      m: 0,
      label: if labelled {
        Some(@common.plain_label(Some(commit.id), measurer, small, 4000))
      } else {
        None
      },
      tags,
    }
    views.push(view)
    by_id.set(commit.id, view)
  }
  // Room each commit needs: along the main axis on either side, and across it towards the
  // previous lane (`lo`) and the next one (`hi`).
  // Tags sit on one side of a lane and ids on the other.
  let half = Array::make(views.length(), 0.0)
  let tag_half = Array::make(views.length(), 0.0)
  let lo = Array::make(lane_count, DOT)
  let hi = Array::make(lane_count, DOT)
  for k, view in views {
    let tags = view.tags
    let mut tags_main = 0.0
    let mut tags_cross = 0.0
    for tag in tags {
      let w = tag_width(tag)
      if vertical {
        tags_main = @util.js_max(tags_main, tag.height)
        tags_cross += w + 4
      } else {
        tags_main = @util.js_max(tags_main, w)
        tags_cross += tag.height + 3
      }
    }
    let mut label_main = 0.0
    let mut label_cross = 0.0
    if view.label is Some(label) && !label.lines.is_empty() {
      if rotate {
        label_cross = 3 + HALF * (label.width + label.height)
      } else {
        label_main = if vertical { label.height } else { label.width }
        label_cross = 6 + (if vertical { label.width } else { label.height })
      }
    }
    half[k] = @util.js_max(@util.js_max(DOT, tags_main / 2), label_main / 2)
    tag_half[k] = tags_main / 2
    let tag_side = DOT +
      (if tags.is_empty() { 0 } else { TAG_GAP + tags_cross })
    let label_side = DOT + label_cross
    let lane = view.lane
    lo[lane] = @util.js_max(
      lo[lane],
      if vertical {
        label_side
      } else {
        tag_side
      },
    )
    hi[lane] = @util.js_max(
      hi[lane],
      if vertical {
        tag_side
      } else {
        label_side
      },
    )
  }
  // In a left-to-right graph the tags stand over their commit.
  // A connector that comes down from a lane above joins the commit's lane this far before the
  // commit, clear of the tags, and the commit is placed far enough along to leave room for that.
  let lead = Array::make(views.length(), 0.0)
  if !vertical {
    for k, view in views {
      if tag_half[k] == 0 {
        continue
      }
      for id in view.commit.parents {
        if by_id.get(id) is Some(parent) && parent.lane < view.lane {
          lead[k] = tag_half[k] + 4
        }
      }
    }
  }
  fn space(p : Int32, k : Int32) -> Double {
    @util.js_max(
      @util.js_max(STEP, half[p] + half[k] + GAP),
      if lead[k] > 0 {
        half[p] + CURVE + lead[k]
      } else {
        0
      },
    )
  }

  for k, view in views {
    if !parallel {
      view.m = if k == 0 { 0 } else { views[k - 1].m + space(k - 1, k) }
      continue
    }
    // Mermaid's `parallelCommits`: a commit sits one step after its furthest parent, so branches
    // that grow side by side share positions instead of taking turns.
    let mut m = 0.0
    for id in view.commit.parents {
      guard by_id.get(id) is Some(parent) && parent.index < k else { continue }
      m = @util.js_max(m, parent.m + space(parent.index, k))
    }
    view.m = m
  }
  let mut end = 0.0
  for view in views {
    end = @util.js_max(end, view.m)
  }
  let cross = Array::make(lane_count, 0.0)
  for i in 0..<lane_count {
    let name = names[i]
    let reach = if name.lines.is_empty() {
      0.0
    } else if vertical {
      name.width / 2 + 8
    } else {
      name.height / 2 + 2
    }
    lo[i] = @util.js_max(lo[i], reach)
    hi[i] = @util.js_max(hi[i], reach)
    if i > 0 {
      cross[i] = cross[i - 1] + @util.js_max(LANE, hi[i - 1] + lo[i] + GAP)
    }
  }
  fn px(m : Double, c : Double) -> Double {
    if vertical {
      c
    } else {
      m
    }
  }

  fn py(m : Double, c : Double) -> Double {
    if vertical {
      if flip {
        -m
      } else {
        m
      }
    } else {
      c
    }
  }

  fn point(m : Double, c : Double) -> String {
    "\{@svg.num(px(m, c))},\{@svg.num(py(m, c))}"
  }

  let inf = @double.infinity
  let bounds : Bounds = { min_x: inf, min_y: inf, max_x: -inf, max_y: -inf, }
  let branches = @svg.Markup::new()
  if show_branches {
    for i in 0..<lane_count {
      let name = names[i]
      let color = @svg.series_color(i)
      let c = cross[i]
      let w = name.width + 16
      let h = name.height + 4
      let span = if vertical { h } else { w }
      let from = if name.lines.is_empty() {
        -LABEL_GAP
      } else {
        -LABEL_GAP - span
      }
      let cx = px(from + span / 2, c)
      let cy = py(from + span / 2, c)
      bounds.grow(
        px(-LABEL_GAP, c),
        py(-LABEL_GAP, c),
        px(-LABEL_GAP, c),
        py(-LABEL_GAP, c),
      )
      bounds.grow(
        px(end + TAIL, c),
        py(end + TAIL, c),
        px(end + TAIL, c),
        py(end + TAIL, c),
      )
      branches.write("<g class=\"pele-branch\" data-id=\"")
      @svg.write_esc_text(branches, model.lanes[i])
      branches.write(
        "\"><path class=\"pele-lane\" d=\"M\{point(-LABEL_GAP, c)}L\{point(end + TAIL, c)}\" stroke=\"\{color}\" stroke-dasharray=\"2 4\"/>",
      )
      if !name.lines.is_empty() {
        bounds.grow(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2)
        branches.write(
          "<rect x=\"\{@svg.num(cx - w / 2)}\" y=\"\{@svg.num(cy - h / 2)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\" fill=\"\{color}\"\{@svg.ROUNDED}/>",
        )
        @svg.write_label(
          branches, name, cx, cy, " class=\"pele-label\" fill=\"var(--_bg)\"",
        )
      }
      branches.write("</g>")
    }
  }
  // Positions of the commits on each lane, to tell whether a connector may run along it.
  let taken : Array[Array[Double]] = Array::makei(lane_count, _ => [])
  for view in views {
    taken[view.lane].push(view.m)
  }
  if parallel {
    for list in taken {
      list.sort()
    }
  }
  fn busy(lane : Int32, from : Double, to : Double) -> Bool {
    let list = taken[lane]
    let mut low = 0
    let mut high = list.length()
    while low < high {
      let mid = (low + high) >> 1
      if list[mid] <= from {
        low = mid + 1
      } else {
        high = mid
      }
    }
    low < list.length() && list[low] < to
  }

  let curves = @svg.Markup::new()
  let lines = @svg.Markup::new()
  for view in views {
    let commit = view.commit
    let c2 = cross[view.lane]
    let m2 = view.m
    for j in 0..<commit.parents.length() {
      guard by_id.get(commit.parents[j]) is Some(parent) &&
        parent.index != view.index else {
        continue
      }
      let c1 = cross[parent.lane]
      let m1 = parent.m
      if parent.lane == view.lane {
        lines.write(
          "<path class=\"pele-edge\" d=\"M\{point(m1, c1)}L\{point(m2, c2)}\" stroke=\"\{@svg.series_color(view.lane)}\"/>",
        )
        continue
      }
      let merged = j > 0 && commit.commit_type is Merge
      let picked = j > 0 && !merged
      let d = StringBuilder()
      d.write_string("M\{point(m1, c1)}")
      if m2 <= m1 {
        let mid = (m1 + m2) / 2
        d.write_string("C\{point(mid, c1)} \{point(mid, c2)} \{point(m2, c2)}")
      } else if !merged && !busy(view.lane, m1, m2) {
        // Leaves the parent at once and runs along the child's lane.
        let s = @util.js_min(CURVE, m2 - m1)
        d.write_string(
          "C\{point(m1 + s / 2, c1)} \{point(m1 + s / 2, c2)} \{point(m1 + s, c2)}L\{point(m2, c2)}",
        )
      } else {
        // Turns in just before the child, or before its tags when it comes from their side.
        let to = if parent.lane < view.lane && m2 - lead[view.index] > m1 {
          m2 - lead[view.index]
        } else {
          m2
        }
        let mut s = @util.js_min(CURVE, to - m1)
        let mut along = c1
        if !merged || busy(parent.lane, m1, m2) {
          // Neither lane is free to run along.
          // Between two lanes, past the ids of one and before the tags of the next, a strip stays empty, and the connector takes that.
          along = if c1 > c2 {
            c2 + hi[view.lane] + GAP / 2
          } else {
            c2 - lo[view.lane] - GAP / 2
          }
          s = @util.js_min(CURVE, (to - m1) / 2)
          d.write_string(
            "C\{point(m1 + s / 2, c1)} \{point(m1 + s / 2, along)} \{point(m1 + s, along)}",
          )
        }
        d.write_string(
          "L\{point(to - s, along)}C\{point(to - s / 2, along)} \{point(to - s / 2, c2)} \{point(to, c2)}",
        )
        if to < m2 {
          d.write_string("L\{point(m2, c2)}")
        }
      }
      let class_suffix = if merged {
        " pele-edge-merge"
      } else if picked {
        " pele-edge-cherry-pick"
      } else {
        ""
      }
      let color = @svg.series_color(
        if merged {
          parent.lane
        } else {
          view.lane
        },
      )
      let dash = if picked { " stroke-dasharray=\"4 3\"" } else { "" }
      curves.write(
        "<path class=\"pele-edge\{class_suffix}\" d=\"\{d.to_string()}\" stroke=\"\{color}\"\{dash}/>",
      )
    }
  }
  let commits = @svg.Markup::new()
  for view in views {
    let commit = view.commit
    let x = px(view.m, cross[view.lane])
    let y = py(view.m, cross[view.lane])
    let commit_type = commit.custom_type.unwrap_or(commit.commit_type)
    bounds.grow(x - DOT - 1, y - DOT - 1, x + DOT + 1, y + DOT + 1)
    // Merges and cherry-picks carry a message Mermaid makes up; only a written one is worth showing.
    let written = commit.commit_type.index() < CommitType::Merge.index() &&
      commit.message != ""
    let body = @svg.Markup::new()
    if written {
      body.write("<title>")
      @svg.write_esc_text(body, commit.message)
      body.write("</title>")
    }
    body.write(symbol(commit_type, x, y, @svg.series_color(view.lane)))
    if view.label is Some(label) && !label.lines.is_empty() {
      let w = label.width
      let h = label.height
      fn back(cx : Double, cy : Double) -> String {
        "<rect x=\"\{@svg.num(cx - w / 2 - 2)}\" y=\"\{@svg.num(cy - h / 2 + 2)}\" width=\"\{@svg.num(w + 4)}\" height=\"\{@svg.num(h - 4)}\" rx=\"3\" fill=\"var(--_bg)\"/>"
      }

      if rotate {
        // The text ends beside the commit and trails back the way the history came.
        let k = HALF * h / 2
        let ax = if vertical { x - DOT - 3 - k } else { x + 3 }
        let ay = if vertical { y } else { y + DOT + 3 + k }
        let reach = HALF * w + k
        bounds.grow(
          ax - reach,
          if flip {
            ay - reach
          } else {
            ay - k
          },
          ax + k,
          if flip {
            ay + k
          } else {
            ay + reach
          },
        )
        body.write(
          "<g class=\"pele-commit-label\" transform=\"rotate(\{if flip { 45 } else { -45 }} \{@svg.num(ax)} \{@svg.num(ay)})\">" +
          back(ax - w / 2, ay),
        )
        @svg.write_label(body, label, ax - w / 2, ay, "")
        body.write("</g>")
      } else {
        let cx = if vertical { x - DOT - 6 - w / 2 } else { x }
        let cy = if vertical { y } else { y + DOT + 6 + h / 2 }
        bounds.grow(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2)
        body.write("<g class=\"pele-commit-label\">\{back(cx, cy)}")
        @svg.write_label(body, label, cx, cy, "")
        body.write("</g>")
      }
    }
    // Beside the lane the tags form a row; above it they stack, the first one furthest out.
    let tags = view.tags
    let mut offset = DOT + TAG_GAP
    let mut t = if vertical { 0 } else { tags.length() - 1 }
    while t >= 0 && t < tags.length() {
      let tag = tags[t]
      let w = tag_width(tag)
      let h = tag.height
      let left = if vertical { x + offset } else { x - w / 2 }
      let cy = if vertical { y } else { y - offset - h / 2 }
      offset += if vertical { w + 4 } else { h + 3 }
      bounds.grow(left, cy - h / 2, left + w, cy + h / 2)
      body.write(
        "<g class=\"pele-tag\">" +
        "<path d=\"M\{@svg.num(left)},\{@svg.num(cy)}L\{@svg.num(left + NOTCH)},\{@svg.num(cy - h / 2)}H\{@svg.num(left + w)}V\{@svg.num(cy + h / 2)}H\{@svg.num(left + NOTCH)}Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/>" +
        "<circle cx=\"\{@svg.num(left + NOTCH)}\" cy=\"\{@svg.num(cy)}\" r=\"1.5\" fill=\"var(--_b)\"/>",
      )
      @svg.write_label(
        body,
        tag,
        left + NOTCH + 4 + tag.width / 2,
        cy,
        " fill=\"var(--_fg)\"",
      )
      body.write("</g>")
      t += if vertical { 1 } else { -1 }
    }
    let merge = if commit.commit_type is Merge && !(commit_type is Merge) {
      " pele-commit-merge"
    } else {
      ""
    }
    commits.write(
      "<g class=\"pele-commit pele-commit-\{class_name(commit_type)}\{merge}\" data-id=\"",
    )
    @svg.write_esc_text(commits, commit.id)
    commits.write_group("\">", body, "</g>")
  }
  if bounds.min_x > bounds.max_x {
    bounds.grow(0, 0, 0, 0)
  }
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    4000,
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 16 } else { 0 }
  let inner = @util.js_max(bounds.max_x - bounds.min_x, title.width)
  let width = (inner + 2 * pad).ceil()
  let height = (bounds.max_y - bounds.min_y + title_height + 2 * pad).ceil()
  let dx = pad - bounds.min_x + (inner - (bounds.max_x - bounds.min_x)) / 2
  let dy = pad + title_height - bounds.min_y
  let content = @svg.Markup::new()
  @svg.write_label(
    content,
    title,
    width / 2,
    pad + title.height / 2,
    " class=\"pele-title\" font-weight=\"var(--_tw)\"",
  )
  content.write("<g transform=\"translate(\{@svg.num(dx)},\{@svg.num(dy)})\">")
  if !branches.is_empty() {
    content.write_group(
      "<g class=\"pele-branches\" fill=\"none\" font-size=\"\{medium}\">",
      branches,
      "</g>",
    )
  }
  if !curves.is_empty() || !lines.is_empty() {
    let edges = @svg.Markup::new()
    edges.write_markup(curves)
    edges.write_markup(lines)
    content.write_group(
      "<g class=\"pele-edges\" fill=\"none\" stroke-width=\"2\" stroke-linecap=\"round\">",
      edges, "</g>",
    )
  }
  if !commits.is_empty() {
    content.write_group(
      "<g class=\"pele-commits\" font-size=\"\{small}\" fill=\"var(--_m)\">",
      commits,
      "</g>",
    )
  }
  content.write("</g>")
  {
    svg: @svg.markup_document(
      "gitGraph",
      width,
      height,
      size,
      options,
      model.acc_title,
      model.acc_descr,
      content,
    ),
    width,
    height,
    links: [],
  }
}
