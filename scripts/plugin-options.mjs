// The JSON forms the plugin accepts for pele's callback options, turned back into the callbacks.
// typst cannot pass a function to a plugin, so each callback is fixed by data instead.
// This module is the reference for what that data means; golden/README.md states the same rules.

const isObject = (value) => typeof value === 'object' && value !== null && !Array.isArray(value);

// Own keys only, because a key such as "constructor" or "__proto__" names an icon or a TeX string like any other.
const own = (object, key) => (Object.hasOwn(object, key) ? object[key] : undefined);

/**
 * An IconResolver that looks the name up in `map`.
 * @param {Record<string, unknown>} map icon name, after entity decoding, to the SVG fragment drawn for it
 * @returns {(name: string) => string | null} null for a name without a string fragment
 */
export function iconResolver(map) {
  return (name) => {
    const fragment = own(map, name);
    return typeof fragment === 'string' ? fragment : null;
  };
}

/**
 * A MathResolver that looks the TeX, then the font size, up in `map`.
 * The markup is handed to pele unchanged, so pele's own check of it applies.
 * @param {Record<string, unknown>} map TeX, after entity decoding, to font size as a JavaScript number string, to MathMarkup
 * @returns {(tex: string, size: number) => object | null} null where either level has no object
 */
export function mathResolver(map) {
  return (tex, size) => {
    const sizes = own(map, tex);
    if (!isObject(sizes)) return null;
    const markup = own(sizes, String(size));
    return isObject(markup) ? markup : null;
  };
}

// The ranges pele's built-in metrics measurer treats as double width and as no width (src/text/measurer.ts).
function isWide(c) {
  return (
    (c >= 0x1100 && c <= 0x115f) ||
    (c >= 0x2e80 && c <= 0xa4cf) ||
    (c >= 0xac00 && c <= 0xd7a3) ||
    (c >= 0xf900 && c <= 0xfaff) ||
    (c >= 0xfe30 && c <= 0xfe4f) ||
    (c >= 0xff00 && c <= 0xff60) ||
    (c >= 0xffe0 && c <= 0xffe6) ||
    (c >= 0xd800 && c <= 0xdbff)
  );
}

function isZeroWidth(c) {
  return c === 0xad || (c >= 0x300 && c <= 0x36f) || (c >= 0x200b && c <= 0x200f) || (c >= 0xdc00 && c <= 0xdfff) || (c >= 0xfe00 && c <= 0xfe0f) || c === 0xfeff;
}

const numberOr = (value, fallback) => (typeof value === 'number' ? value : fallback);

/**
 * A TextMeasurer that sums per-character advances from a table for each style.
 * @param {Record<string, unknown>} spec `unitsPerEm` and `styles`, as golden/README.md describes
 * @returns {{ width(text: string, size: number, style: number): number }}
 */
export function textMeasurer(spec) {
  const unitsPerEm = typeof spec.unitsPerEm === 'number' && spec.unitsPerEm > 0 ? spec.unitsPerEm : 1000;
  const styles = isObject(spec.styles) ? spec.styles : {};
  const faceOf = (style) => {
    const face = own(styles, String(style));
    if (isObject(face)) return face;
    const regular = own(styles, '0');
    return isObject(regular) ? regular : {};
  };
  return {
    width(text, size, style) {
      const face = faceOf(style);
      const advances = isObject(face.advances) ? face.advances : {};
      const narrow = numberOr(face.default, 0);
      const wide = numberOr(face.wide, narrow);
      let units = 0;
      for (let i = 0; i < text.length; i++) {
        const c = text.charCodeAt(i);
        if (c < 32) continue;
        const advance = own(advances, text[i]);
        if (typeof advance === 'number') units += advance;
        else if (isZeroWidth(c)) continue;
        else if (isWide(c)) units += wide;
        else units += narrow;
      }
      return (units * size) / unitsPerEm;
    },
  };
}

/**
 * pele's RenderOptions for a profile written as JSON.
 * `icons`, `math` and `measurer` become callbacks when they are objects and are dropped otherwise.
 * @param {Record<string, unknown>} json the profile as it is stored in golden/manifest.json
 * @returns {Record<string, unknown>}
 */
export function peleOptions(json) {
  const { icons, math, measurer, ...rest } = json;
  const options = { ...rest };
  if (isObject(icons)) options.icons = iconResolver(icons);
  if (isObject(math)) options.math = mathResolver(math);
  if (isObject(measurer)) options.measurer = textMeasurer(measurer);
  return options;
}
