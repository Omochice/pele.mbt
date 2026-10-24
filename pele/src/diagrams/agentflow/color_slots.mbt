// Two rules, as in Mermaid: a node takes the color of its kind, from a fixed slot, so editing the diagram around it never recolors it.
// Containers count through the slots above the kinds, in the order they were declared, so a frame does not take the color of a node inside it.

///|
/// The palette slot of a kind of node.
fn kind_slot(kind : String) -> Int32? {
  match kind {
    "tool" => Some(0)
    "task" => Some(1)
    "decision" => Some(2)
    "input" => Some(3)
    "refdoc" => Some(4)
    "connector" => Some(5)
    "action" => Some(6)
    _ => None
  }
}

///|
const KIND_COUNT : Int32 = 7

///|
/// At least one, so that a palette shorter than the kinds still gives containers a slot.
fn container_slot_count(palette_length : Int32) -> Int32 {
  if palette_length - KIND_COUNT > 1 {
    palette_length - KIND_COUNT
  } else {
    1
  }
}

///|
/// The palette slot of the `n`th container.
fn container_slot(n : Int32, palette_length : Int32) -> Int32 {
  let slot = KIND_COUNT + n % container_slot_count(palette_length)
  if palette_length > 0 {
    slot % palette_length
  } else {
    slot
  }
}

///|
/// Gives each container its slot and each node its kind.
/// A collapsed container is drawn as a node but keeps its slot, so collapsing one does not recolor the containers after it.
fn assign_color_slots(
  nodes : Array[GraphNode],
  kind_of : (String) -> String?,
  container_order : Map[String, Int32],
  palette_length : Int32,
) -> Unit {
  let mut fallback = container_order.length()
  for node in nodes {
    if node.is_group || node.shape == "collapsedGroup" {
      let n = match container_order.get(node.id) {
        Some(n) => n
        None => {
          fallback += 1
          fallback - 1
        }
      }
      node.color_index = Some(container_slot(n, palette_length))
      continue
    }
    if kind_of(node.id) is Some(kind) && kind_slot(kind) is Some(_) {
      node.kind = Some(kind)
    }
  }
}
