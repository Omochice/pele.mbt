///|
/// A set (one id) or an overlap of sets (two or more ids, sorted), with its relative area.
pub(all) struct VennSubset {
  sets : Array[String]
  size : Double
  label : String?
}

///|
/// A line of text shown inside the region of the given sets.
pub(all) struct VennText {
  sets : Array[String]
  id : String
  label : String?
}

///|
/// Declarations for the sorted ids of a set or overlap, or for the id of a text.
pub(all) struct VennStyle {
  targets : Array[String]
  styles : Map[String, String]
}

///|
/// What a venn diagram says, collected statement by statement as the parser reads it.
pub(all) struct VennDb {
  mut title : String?
  subsets : Array[VennSubset]
  text_nodes : Array[VennText]
  styles : Array[VennStyle]
  known : Set[String]
  mut current : Array[String]?
  /// Whether an indented `text` line belongs to the set or union before it. The lexer reads this.
  mut indent : Bool
}

///|
pub fn VennDb::new() -> VennDb {
  {
    title: None,
    subsets: [],
    text_nodes: [],
    styles: [],
    known: Set([]),
    current: None,
    indent: false,
  }
}

///|
/// Mermaid takes one pair of quotes off an id, label or style value.
pub fn normalize_text(text : String) -> String {
  let trimmed = @util.trim(text)
  if trimmed.length() >= 2 &&
    trimmed.has_prefix("\"") &&
    trimmed.has_suffix("\"") {
    @util.slice(trimmed, 1, end=trimmed.length() - 1)
  } else {
    trimmed
  }
}

///|
fn normalize_ids(ids : Array[String]) -> Array[String] {
  let normalized = ids.map(normalize_text)
  sort_ids(normalized)
  normalized
}

///|
fn normalized_label(label : String?) -> String? {
  match label {
    Some(text) if text != "" => Some(normalize_text(text))
    _ => None
  }
}

///|
/// A set without a size gets 10, and an overlap of n sets 10 / n².
pub fn VennDb::add_subset_data(
  self : VennDb,
  ids : Array[String],
  label : String?,
  size : Double?,
) -> Unit {
  let sets = normalize_ids(ids)
  self.current = Some(sets)
  if sets.length() == 1 {
    self.known.add(sets[0])
  }
  let count = ids.length().to_double()
  self.subsets.push({
    sets,
    size: size.unwrap_or(10.0 / (count * count)),
    label: normalized_label(label),
  })
}

///|
pub fn VennDb::add_text_data(
  self : VennDb,
  ids : Array[String],
  id : String,
  label : String?,
) -> Unit {
  self.text_nodes.push({
    sets: normalize_ids(ids),
    id: normalize_text(id),
    label: normalized_label(label),
  })
}

///|
pub fn VennDb::add_style_data(
  self : VennDb,
  ids : Array[String],
  data : Array[(String, String)],
) -> Unit {
  let styles : Map[String, String] = Map([])
  for pair in data {
    let (key, value) = pair
    styles[key] = if value == "" { value } else { normalize_text(value) }
  }
  self.styles.push({ targets: normalize_ids(ids), styles, })
}

///|
/// Raises a semantic `PeleError` naming the ids that no `set` statement has introduced.
pub fn VennDb::validate_union_identifiers(
  self : VennDb,
  ids : Array[String],
) -> Unit raise @errors.PeleError {
  let unknown = ids.map(normalize_text).filter(id => !self.known.contains(id))
  if !unknown.is_empty() {
    raise @errors.pele_error(
      "unknown set identifier: \{unknown.map(@text.decode_entities).join(", ")}",
      code=Semantic,
      kind="venn",
    )
  }
}
