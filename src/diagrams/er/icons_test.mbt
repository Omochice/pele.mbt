///|
/// A host that has exactly the icons in `pairs`, by name.
fn host(pairs : Array[(String, String)]) -> @types.IconResolver {
  let icons = Map::from_array(pairs)
  name => icons.get(name)
}

///|
/// The size and drawing of `source` for a host with `icons`, or the message of its error.
fn with_icons(source : String, icons~ : @types.IconResolver) -> String {
  let options = { ..@types.RenderOptions::default(), icons: Some(icons), }
  let result = @core.render([@er.er], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "entities, attributes and relationship labels draw the host's icons" {
  inspect(
    with_icons(
      "erDiagram\n  CUSTOMER[\"fa:fa-car Customer\"] {\n    string name PK \"fa:fa-car comment\"\n  }\n  CUSTOMER ||--o{ ORDER : \"fa:fa-car places\"\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="253x225 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-er\" viewBox=\"0 0 253 225\" width=\"253\" height=\"225\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"er\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-er-identifying\" data-id=\"id_entity-CUSTOMER-0_entity-ORDER-1_0\"><path d=\"M126.11,80L126.11,169\"/><path class=\"pele-marker\" d=\"M121.11,86L131.11,86M121.11,90L131.11,90\"/><path class=\"pele-marker\" d=\"M132.11,169L126.11,159L120.11,169\"/><circle class=\"pele-marker\" cx=\"126.11\" cy=\"155\" r=\"3.5\" fill=\"var(--_bg)\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"id_entity-CUSTOMER-0_entity-ORDER-1_0\"><rect x=\"91.18\" y=\"114\" width=\"69.85\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"112.68\" y=\"129.4\" text-anchor=\"start\"> places</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"95.18\" y=\"116.8\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-entity\" data-id=\"CUSTOMER\" transform=\"translate(126.11,44)\"><rect x=\"-118.11\" y=\"-36\" width=\"236.21\" height=\"72\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><g class=\"pele-er-stripes\" fill=\"var(--_bg)\"><rect x=\"-118.11\" width=\"236.21\" y=\"6\" height=\"30\" style=\"rx:var(--_r)\"/><rect x=\"-118.11\" width=\"236.21\" y=\"6\" height=\"15\"/></g><path class=\"pele-er-divider\" d=\"M-118.11,6H118.11\" stroke=\"var(--_b)\"/><rect x=\"-118.11\" y=\"-36\" width=\"236.21\" height=\"72\" fill=\"none\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"-26.9\" y=\"-9.4\" text-anchor=\"start\"> Customer</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-46.9\" y=\"-23.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg><g class=\"pele-er-attributes\" font-size=\"14\"><text class=\"pele-er-type\" fill=\"var(--_m)\" x=\"-106.11\" y=\"25.9\">string</text><text class=\"pele-er-name\" x=\"-55.88\" y=\"25.9\">name</text><text class=\"pele-er-keys\" font-size=\"12\" fill=\"var(--_m)\" x=\"-4.86\" y=\"25.9\">PK</text><text class=\"pele-er-comment\" fill=\"var(--_m)\" xml:space=\"preserve\"><tspan x=\"44.65\" y=\"25.9\"> comment</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"27.15\" y=\"13.3\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g><g class=\"pele-node pele-entity\" data-id=\"ORDER\" transform=\"translate(126.11,193)\"><rect x=\"-48\" y=\"-24\" width=\"96\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">ORDER</text></g></g></svg>",
  )
}
