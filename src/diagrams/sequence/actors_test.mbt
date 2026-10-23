// The expected sizes and drawings were taken from pele's actors module.

///|
test "sizes and draws each participant kind" {
  let lines = []
  let texts = ["Alice", "A much longer name<br/>on two lines", ""]
  for
    kind_name in [
      "participant", "actor", "boundary", "control", "entity", "database", "collections",
      "queue", "nonsense",
    ] {
    let kind = @sequence.actor_kind(kind_name)
    for text in texts {
      let label = @text.layout_label(
        Some(text),
        false,
        @text.metrics_measurer,
        16,
        1.0 / 0.0,
      )
      let size = @sequence.actor_size(kind, label, 64, 44)
      let tight = @sequence.actor_size(kind, label, 48, 44, padding_x=8)
      let shown = "\"" + text + "\""
      lines.push(
        "\{kind_name} \{kind} \{@sequence.is_figure(kind)} \{shown} \{size.w}x\{size.h} \{tight.w}x\{tight.h}",
      )
      lines.push(@sequence.draw_actor(kind, 100.5, 10, size, label))
    }
  }
  inspect(
    lines.join("\n"),
    content=(
      #|participant participant false "Alice" 66.672x44 50.672x44
      #|<rect x="67.16" y="10" width="66.67" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="100.5" y="37.6" text-anchor="middle">Alice</text>
      #|participant participant false "A much longer name<br/>on two lines" 179.616x68 163.616x68
      #|<rect x="10.69" y="10" width="179.62" height="68" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="100.5" y="37.6">A much longer name</tspan><tspan x="100.5" y="61.6">on two lines</tspan></text>
      #|participant participant false "" 64x44 48x44
      #|<rect x="68.5" y="10" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|actor actor true "Alice" 42.672x62 42.672x62
      #|<circle cx="100.5" cy="17" r="6" fill="var(--_s)" stroke="var(--_b)"/><path d="M100.5,23V34M90.5,27H110.5M92.5,44L100.5,34L108.5,44" fill="none" stroke="var(--_b)"/><text class="pele-label" x="100.5" y="65.6" text-anchor="middle">Alice</text>
      #|actor actor true "A much longer name<br/>on two lines" 155.616x86 155.616x86
      #|<circle cx="100.5" cy="17" r="6" fill="var(--_s)" stroke="var(--_b)"/><path d="M100.5,23V34M90.5,27H110.5M92.5,44L100.5,34L108.5,44" fill="none" stroke="var(--_b)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="100.5" y="65.6">A much longer name</tspan><tspan x="100.5" y="89.6">on two lines</tspan></text>
      #|actor actor true "" 40x34 40x34
      #|<circle cx="100.5" cy="17" r="6" fill="var(--_s)" stroke="var(--_b)"/><path d="M100.5,23V34M90.5,27H110.5M92.5,44L100.5,34L108.5,44" fill="none" stroke="var(--_b)"/>
      #|boundary boundary true "Alice" 42.672x62 42.672x62
      #|<path d="M81.5,16V38M81.5,27H92.5" fill="none" stroke="var(--_b)"/><circle cx="103.5" cy="27" r="11" fill="var(--_s)" stroke="var(--_b)"/><text class="pele-label" x="100.5" y="65.6" text-anchor="middle">Alice</text>
      #|boundary boundary true "A much longer name<br/>on two lines" 155.616x86 155.616x86
      #|<path d="M81.5,16V38M81.5,27H92.5" fill="none" stroke="var(--_b)"/><circle cx="103.5" cy="27" r="11" fill="var(--_s)" stroke="var(--_b)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="100.5" y="65.6">A much longer name</tspan><tspan x="100.5" y="89.6">on two lines</tspan></text>
      #|boundary boundary true "" 40x34 40x34
      #|<path d="M81.5,16V38M81.5,27H92.5" fill="none" stroke="var(--_b)"/><circle cx="103.5" cy="27" r="11" fill="var(--_s)" stroke="var(--_b)"/>
      #|control control true "Alice" 42.672x62 42.672x62
      #|<circle cx="100.5" cy="31" r="11" fill="var(--_s)" stroke="var(--_b)"/><path d="M105.5,15L99.5,20L105.5,25" fill="none" stroke="var(--_b)"/><text class="pele-label" x="100.5" y="65.6" text-anchor="middle">Alice</text>
      #|control control true "A much longer name<br/>on two lines" 155.616x86 155.616x86
      #|<circle cx="100.5" cy="31" r="11" fill="var(--_s)" stroke="var(--_b)"/><path d="M105.5,15L99.5,20L105.5,25" fill="none" stroke="var(--_b)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="100.5" y="65.6">A much longer name</tspan><tspan x="100.5" y="89.6">on two lines</tspan></text>
      #|control control true "" 40x34 40x34
      #|<circle cx="100.5" cy="31" r="11" fill="var(--_s)" stroke="var(--_b)"/><path d="M105.5,15L99.5,20L105.5,25" fill="none" stroke="var(--_b)"/>
      #|entity entity true "Alice" 42.672x62 42.672x62
      #|<circle cx="100.5" cy="25" r="11" fill="var(--_s)" stroke="var(--_b)"/><path d="M89.5,40H111.5" fill="none" stroke="var(--_b)"/><text class="pele-label" x="100.5" y="65.6" text-anchor="middle">Alice</text>
      #|entity entity true "A much longer name<br/>on two lines" 155.616x86 155.616x86
      #|<circle cx="100.5" cy="25" r="11" fill="var(--_s)" stroke="var(--_b)"/><path d="M89.5,40H111.5" fill="none" stroke="var(--_b)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="100.5" y="65.6">A much longer name</tspan><tspan x="100.5" y="89.6">on two lines</tspan></text>
      #|entity entity true "" 40x34 40x34
      #|<circle cx="100.5" cy="25" r="11" fill="var(--_s)" stroke="var(--_b)"/><path d="M89.5,40H111.5" fill="none" stroke="var(--_b)"/>
      #|database database true "Alice" 42.672x62 42.672x62
      #|<path d="M86.5,17V37A14,5 0 0 0 114.5,37V17A14,5 0 0 0 86.5,17Z" fill="var(--_s)" stroke="var(--_b)"/><path d="M86.5,17A14,5 0 0 0 114.5,17" fill="none" stroke="var(--_b)"/><text class="pele-label" x="100.5" y="65.6" text-anchor="middle">Alice</text>
      #|database database true "A much longer name<br/>on two lines" 155.616x86 155.616x86
      #|<path d="M86.5,17V37A14,5 0 0 0 114.5,37V17A14,5 0 0 0 86.5,17Z" fill="var(--_s)" stroke="var(--_b)"/><path d="M86.5,17A14,5 0 0 0 114.5,17" fill="none" stroke="var(--_b)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="100.5" y="65.6">A much longer name</tspan><tspan x="100.5" y="89.6">on two lines</tspan></text>
      #|database database true "" 40x34 40x34
      #|<path d="M86.5,17V37A14,5 0 0 0 114.5,37V17A14,5 0 0 0 86.5,17Z" fill="var(--_s)" stroke="var(--_b)"/><path d="M86.5,17A14,5 0 0 0 114.5,17" fill="none" stroke="var(--_b)"/>
      #|collections collections false "Alice" 71.672x49 55.672x49
      #|<rect x="69.66" y="10" width="66.67" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><rect x="64.66" y="15" width="66.67" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="98" y="42.6" text-anchor="middle">Alice</text>
      #|collections collections false "A much longer name<br/>on two lines" 184.616x73 168.616x73
      #|<rect x="13.19" y="10" width="179.62" height="68" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><rect x="8.19" y="15" width="179.62" height="68" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="98" y="42.6">A much longer name</tspan><tspan x="98" y="66.6">on two lines</tspan></text>
      #|collections collections false "" 69x49 53x49
      #|<rect x="71" y="10" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><rect x="66" y="15" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|queue queue false "Alice" 78.672x44 62.672x44
      #|<path d="M67.16,10H133.84A6,22 0 0 1 133.84,54H67.16A6,22 0 0 1 67.16,10Z" fill="var(--_s)" stroke="var(--_b)"/><path d="M133.84,10A6,22 0 0 0 133.84,54" fill="none" stroke="var(--_b)"/><text class="pele-label" x="97.5" y="37.6" text-anchor="middle">Alice</text>
      #|queue queue false "A much longer name<br/>on two lines" 191.616x68 175.616x68
      #|<path d="M10.69,10H190.31A6,34 0 0 1 190.31,78H10.69A6,34 0 0 1 10.69,10Z" fill="var(--_s)" stroke="var(--_b)"/><path d="M190.31,10A6,34 0 0 0 190.31,78" fill="none" stroke="var(--_b)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="97.5" y="37.6">A much longer name</tspan><tspan x="97.5" y="61.6">on two lines</tspan></text>
      #|queue queue false "" 76x44 60x44
      #|<path d="M68.5,10H132.5A6,22 0 0 1 132.5,54H68.5A6,22 0 0 1 68.5,10Z" fill="var(--_s)" stroke="var(--_b)"/><path d="M132.5,10A6,22 0 0 0 132.5,54" fill="none" stroke="var(--_b)"/>
      #|nonsense participant false "Alice" 66.672x44 50.672x44
      #|<rect x="67.16" y="10" width="66.67" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="100.5" y="37.6" text-anchor="middle">Alice</text>
      #|nonsense participant false "A much longer name<br/>on two lines" 179.616x68 163.616x68
      #|<rect x="10.69" y="10" width="179.62" height="68" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="100.5" y="37.6">A much longer name</tspan><tspan x="100.5" y="61.6">on two lines</tspan></text>
      #|nonsense participant false "" 64x44 48x44
      #|<rect x="68.5" y="10" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
    ),
  )
}
