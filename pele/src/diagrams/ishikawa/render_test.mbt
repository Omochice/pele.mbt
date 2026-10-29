///|
fn svg(
  source : String,
  max_width? : Double,
  font_size? : Double,
  padding? : Double,
  direction_breakpoint? : Double,
) -> String {
  let options = {
    ..@types.RenderOptions::default(),
    max_width,
    font_size,
    padding,
    direction_breakpoint,
  }
  let result = @core.render([@ishikawa.ishikawa], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let svg = result.svg
  let marker = "aria-roledescription=\"ishikawa\">"
  let start = @util.index_of(svg, marker) + marker.length()
  "\{result.width}x\{result.height} \{@util.slice(svg, start)}"
}

///|
test "a lone effect is drawn as a head on its spine" {
  inspect(
    svg("ishikawa-beta\n  Just an effect\n"),
    content="202x64 <g transform=\"translate(42,32)\"><path class=\"pele-ishikawa-spine\" d=\"M-34,0H-7\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M0,0L-8,3.36L-8,-3.36Z\" fill=\"var(--_l)\" stroke=\"none\"/><g class=\"pele-ishikawa-head\" data-id=\"Just an effect\"><path d=\"M0,-24H127.14A24,24 0 0 1 127.14,24H0Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"63.57\" y=\"5.6\">Just an effect</tspan></text></g></g></svg>",
  )
}

///|
test "a diagram without an effect is only its frame" {
  inspect(svg("ishikawa-beta%% only a comment"), content="16x16 </svg>")
}

///|
test "a keyword alone on its line draws no head" {
  inspect(svg("ishikawa-beta\n"), content="16x16 </svg>")
}

///|
test "categories hang off the spine in pairs, one above and one below" {
  inspect(
    svg("ishikawa-beta\n  Late delivery\n    People\n    Process\n"),
    content="254x160 <g transform=\"translate(99.9,80)\"><path class=\"pele-ishikawa-spine\" d=\"M-62,0H-7\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M0,0L-8,3.36L-8,-3.36Z\" fill=\"var(--_l)\" stroke=\"none\"/><g class=\"pele-ishikawa-category\" data-id=\"People\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,-6.26L-53,-38\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-40.58,-5.65L-34.57,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-87.9\" y=\"-72\" width=\"69.81\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-53\" y=\"-49.4\" text-anchor=\"middle\">People</text></g><g class=\"pele-ishikawa-category\" data-id=\"Process\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,6.26L-53,38\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-34.57,8.66L-40.58,5.65Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-91.9\" y=\"38\" width=\"77.79\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-53\" y=\"60.6\" text-anchor=\"middle\">Process</text></g><g class=\"pele-ishikawa-head\" data-id=\"Late delivery\"><path d=\"M0,-24H121.82A24,24 0 0 1 121.82,24H0Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"60.91\" y=\"5.6\">Late delivery</tspan></text></g></g></svg>",
  )
}

///|
test "five categories slant away from the head by turns above and below" {
  inspect(
    svg("ishikawa-beta\n  E\n    One\n    Two\n    Three\n    Four\n    Five\n"),
    content="317x160 <g transform=\"translate(250.14,80)\"><path class=\"pele-ishikawa-spine\" d=\"M-226.02,0H-7\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M0,0L-8,3.36L-8,-3.36Z\" fill=\"var(--_l)\" stroke=\"none\"/><g class=\"pele-ishikawa-category\" data-id=\"One\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,-6.26L-53,-38\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-40.58,-5.65L-34.57,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-78.12\" y=\"-72\" width=\"50.24\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-53\" y=\"-49.4\" text-anchor=\"middle\">One</text></g><g class=\"pele-ishikawa-category\" data-id=\"Two\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,6.26L-53,38\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-34.57,8.66L-40.58,5.65Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-78.11\" y=\"38\" width=\"50.22\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-53\" y=\"60.6\" text-anchor=\"middle\">Two</text></g><g class=\"pele-ishikawa-category\" data-id=\"Three\"><path class=\"pele-ishikawa-bones\" d=\"M-119.15,-6.26L-135.02,-38\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-116.02,0L-122.6,-5.65L-116.59,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-165.91\" y=\"-72\" width=\"61.79\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-135.02\" y=\"-49.4\" text-anchor=\"middle\">Three</text></g><g class=\"pele-ishikawa-category\" data-id=\"Four\"><path class=\"pele-ishikawa-bones\" d=\"M-119.15,6.26L-135.02,38\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-116.02,0L-116.59,8.66L-122.6,5.65Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-161.46\" y=\"38\" width=\"52.9\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-135.02\" y=\"60.6\" text-anchor=\"middle\">Four</text></g><g class=\"pele-ishikawa-category\" data-id=\"Five\"><path class=\"pele-ishikawa-bones\" d=\"M-201.15,-6.26L-217.02,-38\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-198.02,0L-204.61,-5.65L-198.6,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-242.14\" y=\"-72\" width=\"50.22\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-217.02\" y=\"-49.4\" text-anchor=\"middle\">Five</text></g><g class=\"pele-ishikawa-head\" data-id=\"E\"><path d=\"M0,-24H34.67A24,24 0 0 1 34.67,24H0Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"17.34\" y=\"5.6\">E</tspan></text></g></g></svg>",
  )
}

///|
test "causes are level bones and sub-causes slanted twigs" {
  inspect(
    svg(
      "ishikawa-beta\n  E\n    Cat\n      Cause\n        Sub one\n        Sub two\n      Other\n",
    ),
    content="250x204 <g transform=\"translate(182.33,172)\"><path class=\"pele-ishikawa-spine\" d=\"M-62,0H-7\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M0,0L-8,3.36L-8,-3.36Z\" fill=\"var(--_l)\" stroke=\"none\"/><g class=\"pele-ishikawa-category\" data-id=\"Cat\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,-6.26L-99,-130M-47.75,-27.5H-65.75M-61.25,-54.5H-127.25M-105.25,-54.5L-118.75,-81.5M-83.25,-54.5L-110.25,-108.5\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-40.58,-5.65L-34.57,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-121.45\" y=\"-164\" width=\"44.9\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-99\" y=\"-141.4\" text-anchor=\"middle\">Cat</text><g class=\"pele-ishikawa-causes\" font-size=\"14\"><text x=\"-88.26\" y=\"-22.6\" text-anchor=\"middle\">Other</text><text x=\"-152.48\" y=\"-49.6\" text-anchor=\"middle\">Cause</text><text fill=\"var(--_m)\" x=\"-149.04\" y=\"-76.6\" text-anchor=\"middle\">Sub two</text><text fill=\"var(--_m)\" x=\"-141.32\" y=\"-103.6\" text-anchor=\"middle\">Sub one</text></g></g><g class=\"pele-ishikawa-head\" data-id=\"E\"><path d=\"M0,-24H34.67A24,24 0 0 1 34.67,24H0Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"17.34\" y=\"5.6\">E</tspan></text></g></g></svg>",
  )
}

///|
test "an outline nested deeper than twigs keeps its causes in order" {
  inspect(
    svg(
      "ishikawa-beta\n  E\n    A\n      a1\n        a11\n          a111\n            a1111\n          a112\n        a12\n      a2\n    B\n      b1\n      b2\n      b3\n    C\n    D\n      d1\n        d11\n        d12\n        d13\n      d2\n        d21\n",
    ),
    content="385x479 <g transform=\"translate(318.23,253)\"><path class=\"pele-ishikawa-spine\" d=\"M-205.91,0H-7\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M0,0L-8,3.36L-8,-3.36Z\" fill=\"var(--_l)\" stroke=\"none\"/><g class=\"pele-ishikawa-category\" data-id=\"A\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,-6.26L-139.5,-211M-47.75,-27.5H-65.75M-61.25,-54.5H-127.25M-105.25,-54.5L-118.75,-81.5M-83.25,-54.5L-150.75,-189.5M-110.25,-108.5H-128.25M-123.75,-135.5H-167.75M-145.75,-135.5L-159.25,-162.5\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-40.58,-5.65L-34.57,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-154.84\" y=\"-245\" width=\"30.67\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-139.5\" y=\"-222.4\" text-anchor=\"middle\">A</text><g class=\"pele-ishikawa-causes\" font-size=\"14\"><text x=\"-78.53\" y=\"-22.6\" text-anchor=\"middle\">a2</text><text x=\"-140.03\" y=\"-49.6\" text-anchor=\"middle\">a1</text><text fill=\"var(--_m)\" x=\"-135.43\" y=\"-76.6\" text-anchor=\"middle\">a12</text><text fill=\"var(--_m)\" x=\"-167.43\" y=\"-184.6\" text-anchor=\"middle\">a11</text><text fill=\"var(--_m)\" x=\"-148.82\" y=\"-103.6\" text-anchor=\"middle\">a112</text><text fill=\"var(--_m)\" x=\"-188.32\" y=\"-130.6\" text-anchor=\"middle\">a111</text><text fill=\"var(--_m)\" x=\"-183.71\" y=\"-157.6\" text-anchor=\"middle\">a1111</text></g></g><g class=\"pele-ishikawa-category\" data-id=\"B\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,6.26L-85.5,103M-47.75,27.5H-65.75M-61.25,54.5H-79.25M-74.75,81.5H-92.75\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-34.57,8.66L-40.58,5.65Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-100.84\" y=\"103\" width=\"30.67\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-85.5\" y=\"125.6\" text-anchor=\"middle\">B</text><g class=\"pele-ishikawa-causes\" font-size=\"14\"><text x=\"-78.53\" y=\"32.4\" text-anchor=\"middle\">b1</text><text x=\"-92.03\" y=\"59.4\" text-anchor=\"middle\">b2</text><text x=\"-105.53\" y=\"86.4\" text-anchor=\"middle\">b3</text></g></g><g class=\"pele-ishikawa-category\" data-id=\"C\"><path class=\"pele-ishikawa-bones\" d=\"M-181.04,-6.26L-196.91,-38\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-177.91,0L-184.49,-5.65L-178.48,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-212.69\" y=\"-72\" width=\"31.55\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-196.91\" y=\"-49.4\" text-anchor=\"middle\">C</text></g><g class=\"pele-ishikawa-category\" data-id=\"D\"><path class=\"pele-ishikawa-bones\" d=\"M-181.04,6.26L-269.91,184M-191.66,27.5H-279.66M-257.66,27.5L-271.16,54.5M-235.66,27.5L-262.66,81.5M-213.66,27.5L-254.16,108.5M-245.66,135.5H-289.66M-267.66,135.5L-281.16,162.5\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-177.91,0L-178.48,8.66L-184.49,5.65Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-285.69\" y=\"184\" width=\"31.55\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-269.91\" y=\"206.6\" text-anchor=\"middle\">D</text><g class=\"pele-ishikawa-causes\" font-size=\"14\"><text x=\"-292.45\" y=\"32.4\" text-anchor=\"middle\">d1</text><text fill=\"var(--_m)\" x=\"-287.84\" y=\"59.4\" text-anchor=\"middle\">d11</text><text fill=\"var(--_m)\" x=\"-279.34\" y=\"86.4\" text-anchor=\"middle\">d12</text><text fill=\"var(--_m)\" x=\"-270.84\" y=\"113.4\" text-anchor=\"middle\">d13</text><text x=\"-302.45\" y=\"140.4\" text-anchor=\"middle\">d2</text><text fill=\"var(--_m)\" x=\"-297.84\" y=\"167.4\" text-anchor=\"middle\">d21</text></g></g><g class=\"pele-ishikawa-head\" data-id=\"E\"><path d=\"M0,-24H34.67A24,24 0 0 1 34.67,24H0Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"17.34\" y=\"5.6\">E</tspan></text></g></g></svg>",
  )
}

///|
test "long text wraps" {
  inspect(
    svg(
      "ishikawa-beta\n  An effect described at such length that it has to be wrapped\n    A category with a name that is long as well\n      A cause that takes a good many words to state in full\n",
    ),
    content=(
      #|510x176 <g transform="translate(244.38,124)"><path class="pele-ishikawa-spine" d="M-62,0H-7" fill="none" stroke="var(--_l)"/><path class="pele-marker" d="M0,0L-8,3.36L-8,-3.36Z" fill="var(--_l)" stroke="none"/><g class="pele-ishikawa-category" data-id="A category with a name that is long as well"><path class="pele-ishikawa-bones" d="M-37.13,-6.26L-66,-64M-51.5,-35H-69.5" fill="none" stroke="var(--_l)"/><path class="pele-marker" d="M-34,0L-40.58,-5.65L-34.57,-8.66Z" fill="var(--_l)" stroke="none"/><rect x="-159.59" y="-116" width="187.18" height="52" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="-66" y="-94.9">A category with a name</tspan><tspan x="-66" y="-73.9">that is long as well</tspan></text><g class="pele-ishikawa-causes" font-size="14"><text text-anchor="middle" xml:space="preserve"><tspan x="-155.44" y="-39.1">A cause that takes a good</tspan><tspan x="-155.44" y="-21.1">many words to state in full</tspan></text></g></g><g class="pele-ishikawa-head" data-id="An effect described at such length that it has to be wrapped"><path d="M0,-43.5H213.36A43.5,43.5 0 0 1 213.36,43.5H0Z" fill="var(--_s)" stroke="var(--_b)" stroke-linejoin="round"/><text class="pele-label" font-weight="var(--_hw)" text-anchor="middle" xml:space="preserve"><tspan x="106.68" y="-15.4">An effect described at</tspan><tspan x="106.68" y="5.6">such length that it has to</tspan><tspan x="106.68" y="26.6">be wrapped</tspan></text></g></g></svg>
    ),
  )
}

///|
test "the front matter title is drawn above the diagram" {
  inspect(
    svg("---\ntitle: Root causes\n---\nishikawa-beta\n  Effect\n    Cause\n"),
    content="195x148 <text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"97.5\" y=\"25.6\">Root causes</tspan></text><g transform=\"translate(94.12,116)\"><path class=\"pele-ishikawa-spine\" d=\"M-62,0H-7\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M0,0L-8,3.36L-8,-3.36Z\" fill=\"var(--_l)\" stroke=\"none\"/><g class=\"pele-ishikawa-category\" data-id=\"Cause\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,-6.26L-53,-38\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-40.58,-5.65L-34.57,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-86.12\" y=\"-72\" width=\"66.24\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-53\" y=\"-49.4\" text-anchor=\"middle\">Cause</text></g><g class=\"pele-ishikawa-head\" data-id=\"Effect\"><path d=\"M0,-24H68.45A24,24 0 0 1 68.45,24H0Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"34.22\" y=\"5.6\">Effect</tspan></text></g></g></svg>",
  )
}

///|
test "the keyword may be written in short or in capitals" {
  inspect(
    svg("Ishikawa\n  Effect\n    Cause\n"),
    content="195x112 <g transform=\"translate(94.12,80)\"><path class=\"pele-ishikawa-spine\" d=\"M-62,0H-7\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M0,0L-8,3.36L-8,-3.36Z\" fill=\"var(--_l)\" stroke=\"none\"/><g class=\"pele-ishikawa-category\" data-id=\"Cause\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,-6.26L-53,-38\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-40.58,-5.65L-34.57,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-86.12\" y=\"-72\" width=\"66.24\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-53\" y=\"-49.4\" text-anchor=\"middle\">Cause</text></g><g class=\"pele-ishikawa-head\" data-id=\"Effect\"><path d=\"M0,-24H68.45A24,24 0 0 1 68.45,24H0Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"34.22\" y=\"5.6\">Effect</tspan></text></g></g></svg>",
  )
}

///|
test "text is escaped wherever it is shown" {
  inspect(
    svg(
      "ishikawa-beta\n  <img src=x onerror=alert(1)>\n    <script>a&b</script>\n      </text></g></svg><script>alert(1)</script>\n        \" onload=\"alert(1)\n",
    ),
    content=(
      #|318x150 <g transform="translate(261.96,118)"><path class="pele-ishikawa-spine" d="M-62,0H-7" fill="none" stroke="var(--_l)"/><path class="pele-marker" d="M0,0L-8,3.36L-8,-3.36Z" fill="var(--_l)" stroke="none"/><g class="pele-ishikawa-category" data-id="&lt;script&gt;a&amp;b&lt;/script&gt;"><path class="pele-ishikawa-bones" d="M-37.13,-6.26L-72,-76M-47.75,-27.5H-91.75M-69.75,-27.5L-83.25,-54.5" fill="none" stroke="var(--_l)"/><path class="pele-marker" d="M-34,0L-40.58,-5.65L-34.57,-8.66Z" fill="var(--_l)" stroke="none"/><rect x="-96.23" y="-110" width="48.46" height="34" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="-72" y="-87.4" text-anchor="middle">a&amp;b</text><g class="pele-ishikawa-causes" font-size="14"><text x="-175.35" y="-22.6" text-anchor="middle">&lt;/text&gt;&lt;/g&gt;&lt;/svg&gt;alert(1)</text><text fill="var(--_m)" x="-142.44" y="-49.6" text-anchor="middle">&quot; onload=&quot;alert(1)</text></g></g><g class="pele-ishikawa-head" data-id="&lt;img src=x onerror=alert(1)&gt;"><path d="M0,-24H24A24,24 0 0 1 24,24H0Z" fill="var(--_s)" stroke="var(--_b)" stroke-linejoin="round"/><text class="pele-label" font-weight="var(--_hw)" text-anchor="middle" xml:space="preserve"><tspan x="12" y="5.6"> </tspan></text></g></g></svg>
    ),
  )
}

///|
test "the font size and the padding are honored" {
  inspect(
    svg(
      "ishikawa-beta\n  Effect\n    Cause\n      Sub\n",
      font_size=20,
      padding=4,
    ),
    content="219x130 <g transform=\"translate(108.27,99)\"><path class=\"pele-ishikawa-spine\" d=\"M-62,0H-7\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M0,0L-8,3.36L-8,-3.36Z\" fill=\"var(--_l)\" stroke=\"none\"/><g class=\"pele-ishikawa-category\" data-id=\"Cause\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,-6.26L-61.5,-55M-49.25,-30.5H-67.25\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-40.58,-5.65L-34.57,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-100.4\" y=\"-95\" width=\"77.8\" height=\"40\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-61.5\" y=\"-68\" text-anchor=\"middle\">Cause</text><g class=\"pele-ishikawa-causes\" font-size=\"18\"><text x=\"-88.26\" y=\"-24.2\" text-anchor=\"middle\">Sub</text></g></g><g class=\"pele-ishikawa-head\" data-id=\"Effect\"><path d=\"M0,-27H79.56A27,27 0 0 1 79.56,27H0Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"39.78\" y=\"7\">Effect</tspan></text></g></g></svg>",
  )
}

///|
test "a diagram wider than maxWidth runs its causes down" {
  inspect(
    svg(
      "---\ntitle: Narrow\n---\nishikawa-beta\n  E\n    Cat\n      Cause\n        Sub one\n        Sub two\n      Other\n    Second\n",
      max_width=200,
    ),
    content="149x364 <text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"74.5\" y=\"25.6\">Narrow</tspan></text><path class=\"pele-edge\" d=\"M18,80V110H28\" fill=\"none\" stroke=\"var(--_b)\"/><path class=\"pele-edge\" d=\"M38,128V156.5H48\" fill=\"none\" stroke=\"var(--_b)\"/><path class=\"pele-edge\" d=\"M58,173V201.5H68\" fill=\"none\" stroke=\"var(--_b)\"/><path class=\"pele-edge\" d=\"M58,173V246.5H68\" fill=\"none\" stroke=\"var(--_b)\"/><path class=\"pele-edge\" d=\"M38,128V291.5H48\" fill=\"none\" stroke=\"var(--_b)\"/><path class=\"pele-edge\" d=\"M18,80V338H28\" fill=\"none\" stroke=\"var(--_b)\"/><g class=\"pele-node pele-ishikawa-head\" data-id=\"E\"><rect x=\"8\" y=\"44\" width=\"30.67\" height=\"36\" rx=\"12\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"23.34\" y=\"67.6\">E</tspan></text></g><g class=\"pele-node pele-ishikawa-category\" data-id=\"Cat\"><rect x=\"28\" y=\"92\" width=\"45.78\" height=\"36\" rx=\"4\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"50.89\" y=\"115.6\">Cat</tspan></text></g><g class=\"pele-node pele-ishikawa-cause\" data-id=\"Cause\"><text class=\"pele-label\" font-size=\"14\" x=\"78.23\" y=\"161.4\" text-anchor=\"middle\">Cause</text></g><g class=\"pele-node pele-ishikawa-cause\" data-id=\"Sub one\"><text class=\"pele-label\" font-size=\"14\" x=\"104.08\" y=\"206.4\" text-anchor=\"middle\">Sub one</text></g><g class=\"pele-node pele-ishikawa-cause\" data-id=\"Sub two\"><text class=\"pele-label\" font-size=\"14\" x=\"103.29\" y=\"251.4\" text-anchor=\"middle\">Sub two</text></g><g class=\"pele-node pele-ishikawa-cause\" data-id=\"Other\"><text class=\"pele-label\" font-size=\"14\" x=\"75.51\" y=\"296.4\" text-anchor=\"middle\">Other</text></g><g class=\"pele-node pele-ishikawa-category\" data-id=\"Second\"><rect x=\"28\" y=\"320\" width=\"77.79\" height=\"36\" rx=\"4\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"66.9\" y=\"343.6\">Second</tspan></text></g></svg>",
  )
}

///|
test "a diagram that fits maxWidth stays across" {
  inspect(
    svg("ishikawa-beta\n  E\n    A\n", max_width=600),
    content="144x112 <g transform=\"translate(76.34,80)\"><path class=\"pele-ishikawa-spine\" d=\"M-62,0H-7\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M0,0L-8,3.36L-8,-3.36Z\" fill=\"var(--_l)\" stroke=\"none\"/><g class=\"pele-ishikawa-category\" data-id=\"A\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,-6.26L-53,-38\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-40.58,-5.65L-34.57,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-68.34\" y=\"-72\" width=\"30.67\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-53\" y=\"-49.4\" text-anchor=\"middle\">A</text></g><g class=\"pele-ishikawa-head\" data-id=\"E\"><path d=\"M0,-24H34.67A24,24 0 0 1 34.67,24H0Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"17.34\" y=\"5.6\">E</tspan></text></g></g></svg>",
  )
}

///|
test "down is chosen only below the breakpoint" {
  inspect(
    svg(
      "ishikawa-beta\n  E\n    Category one\n      Cause that is rather long\n    Category two\n      Another long cause\n",
      max_width=300,
      direction_breakpoint=200,
    ),
    content="298x182 <g transform=\"translate(231.27,91)\"><path class=\"pele-ishikawa-spine\" d=\"M-62,0H-7\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M0,0L-8,3.36L-8,-3.36Z\" fill=\"var(--_l)\" stroke=\"none\"/><g class=\"pele-ishikawa-category\" data-id=\"Category one\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,-6.26L-58.5,-49M-47.75,-27.5H-65.75\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-40.58,-5.65L-34.57,-8.66Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-116.52\" y=\"-83\" width=\"116.05\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-58.5\" y=\"-60.4\" text-anchor=\"middle\">Category one</text><g class=\"pele-ishikawa-causes\" font-size=\"14\"><text x=\"-147.01\" y=\"-22.6\" text-anchor=\"middle\">Cause that is rather long</text></g></g><g class=\"pele-ishikawa-category\" data-id=\"Category two\"><path class=\"pele-ishikawa-bones\" d=\"M-37.13,6.26L-58.5,49M-47.75,27.5H-65.75\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M-34,0L-34.57,8.66L-40.58,5.65Z\" fill=\"var(--_l)\" stroke=\"none\"/><rect x=\"-115.63\" y=\"49\" width=\"114.26\" height=\"34\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"-58.5\" y=\"71.6\" text-anchor=\"middle\">Category two</text><g class=\"pele-ishikawa-causes\" font-size=\"14\"><text x=\"-131.06\" y=\"32.4\" text-anchor=\"middle\">Another long cause</text></g></g><g class=\"pele-ishikawa-head\" data-id=\"E\"><path d=\"M0,-24H34.67A24,24 0 0 1 34.67,24H0Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"17.34\" y=\"5.6\">E</tspan></text></g></g></svg>",
  )
}

///|
test "causes running down break long words between characters" {
  inspect(
    svg(
      "ishikawa-beta\n  Effect\n    Category\n      xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n",
      max_width=200,
    ),
    content="195x229 <path class=\"pele-edge\" d=\"M18,44V74H28\" fill=\"none\" stroke=\"var(--_b)\"/><path class=\"pele-edge\" d=\"M38,92V162.5H48\" fill=\"none\" stroke=\"var(--_b)\"/><g class=\"pele-node pele-ishikawa-head\" data-id=\"Effect\"><rect x=\"8\" y=\"8\" width=\"64.45\" height=\"36\" rx=\"12\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"40.22\" y=\"31.6\">Effect</tspan></text></g><g class=\"pele-node pele-ishikawa-category\" data-id=\"Category\"><rect x=\"28\" y=\"56\" width=\"89.34\" height=\"36\" rx=\"4\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"72.67\" y=\"79.6\">Category</tspan></text></g><g class=\"pele-node pele-ishikawa-cause\" data-id=\"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\"><text class=\"pele-label\" font-size=\"14\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"117.5\" y=\"125.4\">xxxxxxxxxxxxxxxxx</tspan><tspan x=\"117.5\" y=\"146.4\">xxxxxxxxxxxxxxxxx</tspan><tspan x=\"117.5\" y=\"167.4\">xxxxxxxxxxxxxxxxx</tspan><tspan x=\"117.5\" y=\"188.4\">xxxxxxxxxxxxxxxxx</tspan><tspan x=\"117.5\" y=\"209.4\">xxxxxxxxxxxx</tspan></text></g></svg>",
  )
}

///|
test "an empty down diagram" {
  inspect(svg("ishikawa-beta\n", max_width=200), content="16x16 </svg>")
}

///|
test "what Mermaid rejects is rejected with its message" {
  inspect(
    svg("ishikawa-beta\n\n  Effect\n"),
    content="Parse error on line 3:\n  Effect\n^\nExpecting 'SPACELINE', 'NL', 'EOF', got 'SPACELIST'",
  )
  inspect(
    svg("ishikawa-beta\n  Effect\n  ishikawa again\n"),
    content="Parse error on line 3:\n  ishikawa again\n--^\nExpecting 'SPACELINE', 'NL', 'EOF', 'TEXT', got 'ISHIKAWA'",
  )
  inspect(
    svg("ishikawa-beta"),
    content="Parse error on line 1:\nishikawa-beta\n-------------^\nExpecting 'SPACELINE', 'SPACELIST', 'TEXT', got 'EOF'",
  )
}
