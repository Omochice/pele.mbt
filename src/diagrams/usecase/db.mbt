///|
/// What an id was first declared as, and where.
priv struct Origin {
  kind : String
  span : Span
  generated : Bool
  /// The label a generated id was derived from.
  label : String?
}

///|
priv struct ElementState {
  kind : String
  id : String
  label : DraftLabel
  span : Span
  mut parent : DraftBoundary?
  mut shape : String?
  mut stereotype : String?
  mut stereotype_span : Span?
  classes : Array[String]
  mut actor_type : String?
  mut icon : String?
  mut business : Bool?
}

///|
priv struct BoundaryState {
  label : DraftLabel
  span : Span
  classes : Array[String]
  mut boundary_type : String?
  members : Array[String]
  member_set : Set[String]
}

///|
/// The values in order of `key`, with ties in their original order as JavaScript's sort keeps them.
fn[T] stable_sorted(values : Array[T], key : (T) -> Int32) -> Array[T] {
  let indexed = values.mapi((i, value) => (key(value), i, value))
  indexed.sort_by((a, b) => {
    if a.0 != b.0 {
      a.0.compare(b.0)
    } else {
      a.1.compare(b.1)
    }
  })
  indexed.map(entry => entry.2)
}

///|
fn push_unique(target : Array[String], values : Array[String]) -> Unit {
  if values.length() == 0 {
    return
  }
  let seen = Set::from_array(target)
  for value in values {
    if !seen.contains(value) {
      seen.add(value)
      target.push(value)
    }
  }
}

///|
fn is_text(value : PropertyValue, options : Array[String]) -> Bool {
  value is Text(text) && options.contains(text)
}

///|
/// Which kind of element the keys of a metadata block could only belong to, for the error message.
fn infer_kind(properties : Array[DraftProperty]) -> String? {
  let possible = ["actor", "usecase", "boundary", "edge"]
  let keep = (kinds : Array[String]) => {
    let kept = possible.filter(kind => kinds.contains(kind))
    possible.clear()
    possible.append(kept)
  }
  for property in properties {
    match property.key {
      "icon" => keep(["actor"])
      "animate" | "animation" => keep(["edge"])
      "type" =>
        if is_text(property.value, ["rect", "package"]) {
          keep(["boundary"])
        } else if is_text(property.value, ["normal", "hollow", "awesome"]) {
          keep(["actor"])
        } else {
          keep([])
        }
      "business" => keep(["actor", "usecase"])
      _ => return None
    }
  }
  if possible.length() == 1 {
    Some(possible[0])
  } else {
    None
  }
}

///|
/// Resolving a diagram's drafts: which ids are actors, use cases, boundaries, JSON nodes or edges,
/// in what order they appear, and whether the statements about them agree.
priv struct Resolver {
  src : String
  model : UsecaseModel
  symbols : Map[String, Origin]
  elements : Map[String, ElementState]
  boundaries : Map[String, BoundaryState]
  edges : Map[String, Relationship]
  /// The offset at which each id is first mentioned, which decides the order of the model.
  first : Map[String, Int32]
}

///|
fn Resolver::error(
  self : Resolver,
  message : String,
  span : Span,
) -> @errors.PeleError {
  let (line, column) = line_column(self.src, span.0)
  @errors.pele_error(message, code=Semantic, kind="usecase", line~, column~)
}

///|
fn Resolver::at(self : Resolver, span : Span) -> String {
  let (line, column) = line_column(self.src, span.0)
  "line \{line}, column \{column} [\{span.0},\{span.1})"
}

///|
fn[T] Resolver::fail(
  self : Resolver,
  message : String,
  span : Span,
) -> T raise @errors.PeleError {
  raise self.error("\{message} at \{self.at(span)}", span)
}

///|
fn[T] Resolver::conflict(
  self : Resolver,
  message : String,
  current : Span,
  previous : Span,
  current_label? : String,
  previous_label? : String,
) -> T raise @errors.PeleError {
  let suffix = (label : String?) => {
    match label {
      Some(text) => " (label \"\{text}\")"
      None => ""
    }
  }
  raise self.error(
    "\{message} at \{self.at(current)}\{suffix(current_label)}; previous declaration at \{self.at(previous)}\{suffix(previous_label)}",
    current,
  )
}

///|
fn[T] Resolver::invalid(
  self : Resolver,
  id : String,
  kind : String,
  property : DraftProperty,
) -> T raise @errors.PeleError {
  self.fail(
    "Metadata property '\{property.key}' is invalid for \{kind} '\{id}'",
    property.key_span,
  )
}

///|
fn Resolver::mention(self : Resolver, id : String, offset : Int32) -> Unit {
  match self.first.get(id) {
    Some(previous) if previous <= offset => ()
    _ => self.first.set(id, offset)
  }
}

///|
fn Resolver::order(self : Resolver, id : String) -> Int32 {
  self.first.get(id).unwrap_or(0)
}

///|
fn Resolver::register(
  self : Resolver,
  id : String,
  label : DraftLabel,
  span : Span,
  generated : Bool,
  kind : String,
) -> Unit {
  self.symbols.set(id, { kind, span, generated, label: Some(label.text), })
}

///|
/// An id means one thing in the whole diagram, and an id made from a label may be declared once.
fn Resolver::claim(
  self : Resolver,
  id : String,
  label : DraftLabel,
  span : Span,
  generated : Bool,
  kind : String,
) -> Unit raise @errors.PeleError {
  guard self.symbols.get(id) is Some(origin) else { return }
  let current_label = if generated { Some(label.text) } else { None }
  let previous_label = if origin.generated { origin.label } else { None }
  if origin.kind != kind {
    self.conflict(
      "ID '\{id}' is declared as both \{origin.kind} and \{kind}",
      span,
      origin.span,
      current_label?,
      previous_label?,
    )
  }
  if origin.generated || generated {
    self.conflict(
      "Generated ID '\{id}' collides with another declaration",
      span,
      origin.span,
      current_label?,
      previous_label?,
    )
  }
}

///|
fn Resolver::unique(
  self : Resolver,
  id : String,
  kind : String,
  span : Span,
) -> Unit raise @errors.PeleError {
  if self.symbols.get(id) is Some(previous) {
    self.conflict(
      "ID '\{id}' is declared more than once (\{previous.kind} and \{kind})",
      span,
      previous.span,
      previous_label?=if previous.generated { previous.label } else { None },
    )
  }
  self.symbols.set(id, { kind, span, generated: false, label: None, })
}

///|
/// A metadata statement replaces what a declaration said; two declarations have to agree.
fn Resolver::actor_property(
  self : Resolver,
  state : ElementState,
  property : DraftProperty,
  replace : Bool,
) -> Unit raise @errors.PeleError {
  let clash = (differs : Bool) => {
    if !replace && differs {
      self.conflict(
        "Actor '\{state.id}' has conflicting \{property.key} metadata",
        property.key_span,
        state.span,
      )
    }
  }
  match (property.key, property.value) {
    ("type", Text(value)) if ["normal", "hollow", "awesome"].contains(value) => {
      clash(state.actor_type is Some(previous) && previous != value)
      state.actor_type = Some(value)
    }
    ("icon", Text(value)) => {
      clash(state.icon is Some(previous) && previous != value)
      state.icon = Some(value)
    }
    ("business", Flag(value)) => {
      clash(state.business is Some(previous) && previous != value)
      state.business = Some(value)
    }
    _ => self.invalid(state.id, "actor", property)
  }
}

///|
fn Resolver::element_metadata(
  self : Resolver,
  state : ElementState,
  properties : Array[DraftProperty]?,
  replace : Bool,
) -> Unit raise @errors.PeleError {
  for property in properties.unwrap_or([]) {
    if state.kind == "actor" {
      self.actor_property(state, property, replace)
    } else if property.key == "business" && property.value is Flag(value) {
      if !replace && state.business is Some(previous) && previous != value {
        self.conflict(
          "Use case '\{state.id}' has conflicting business metadata",
          property.key_span,
          state.span,
        )
      }
      state.business = Some(value)
    } else {
      self.invalid(state.id, "usecase", property)
    }
  }
}

///|
fn non_empty(text : String?) -> String? {
  match text {
    Some("") => None
    _ => text
  }
}

///|
fn Resolver::publish(self : Resolver, state : ElementState) -> Unit {
  let model = self.model
  let stereotype = non_empty(state.stereotype)
  let parent_id = match state.parent {
    Some(parent) if parent.id != "" => Some(parent.id)
    _ => None
  }
  if state.kind == "actor" {
    model.use_cases.remove(state.id)
    let icon = non_empty(state.icon)
    model.actors.set(state.id, {
      id: state.id,
      label: state.label.text,
      label_type: state.label.label_type,
      actor_type: if icon is Some(_) {
        "icon"
      } else {
        state.actor_type.unwrap_or("normal")
      },
      icon,
      business: state.business.unwrap_or(false),
      stereotype,
      parent_id,
      classes: state.classes.copy(),
      styles: match model.actors.get(state.id) {
        Some(actor) => actor.styles
        None => []
      },
    })
  } else {
    model.actors.remove(state.id)
    model.use_cases.set(state.id, {
      id: state.id,
      label: state.label.text,
      label_type: state.label.label_type,
      shape: state.shape.unwrap_or("ellipse"),
      business: state.business.unwrap_or(false),
      stereotype,
      parent_id,
      classes: state.classes.copy(),
      styles: match model.use_cases.get(state.id) {
        Some(use_case) => use_case.styles
        None => []
      },
    })
  }
}

///|
fn Resolver::declare_element(
  self : Resolver,
  draft : DraftElement,
) -> Unit raise @errors.PeleError {
  self.claim(draft.id, draft.label, draft.span, draft.generated, draft.kind)
  let parent = match draft.parent {
    Some(boundary) if boundary.id != "" => Some(boundary)
    _ => None
  }
  guard self.elements.get(draft.id) is Some(existing) else {
    let state = {
      kind: draft.kind,
      id: draft.id,
      label: draft.label,
      span: draft.span,
      parent,
      shape: draft.shape,
      stereotype: draft.stereotype,
      stereotype_span: if draft.stereotype is Some(_) {
        Some(draft.span)
      } else {
        None
      },
      classes: draft.classes.copy(),
      actor_type: None,
      icon: None,
      business: None,
    }
    self.element_metadata(state, draft.metadata, false)
    self.elements.set(draft.id, state)
    self.register(
      draft.id,
      draft.label,
      draft.span,
      draft.generated,
      draft.kind,
    )
    return
  }
  if existing.label.text != draft.label.text ||
    existing.label.label_type != draft.label.label_type {
    self.conflict(
      "ID '\{draft.id}' has conflicting labels",
      draft.span,
      existing.span,
    )
  }
  if draft.shape is Some(shape) &&
    existing.shape is Some(previous) &&
    shape != previous {
    self.conflict(
      "Use case '\{draft.id}' has conflicting shapes",
      draft.span,
      existing.span,
    )
  }
  // A boundary whose title makes an empty id is no parent, but it still takes the place of one.
  if parent is Some(boundary) &&
    existing.parent is Some(previous) &&
    previous.id != "" &&
    boundary.id != previous.id {
    self.conflict(
      "Element '\{draft.id}' belongs to more than one system boundary",
      boundary.span,
      previous.span,
    )
  }
  if draft.stereotype is Some(stereotype) &&
    existing.stereotype is Some(previous) &&
    stereotype != previous {
    self.conflict(
      "Element '\{draft.id}' has conflicting stereotypes",
      draft.span,
      existing.stereotype_span.unwrap_or(existing.span),
    )
  }
  if existing.shape is None {
    existing.shape = draft.shape
  }
  if existing.parent is None {
    existing.parent = draft.parent
  }
  if existing.stereotype is None {
    existing.stereotype = draft.stereotype
  }
  if existing.stereotype_span is None && draft.stereotype is Some(_) {
    existing.stereotype_span = Some(draft.span)
  }
  push_unique(existing.classes, draft.classes)
  self.element_metadata(existing, draft.metadata, false)
}

///|
fn Resolver::declare_boundary(
  self : Resolver,
  draft : DraftBoundary,
) -> Unit raise @errors.PeleError {
  self.claim(draft.id, draft.label, draft.span, draft.generated, "boundary")
  if self.boundaries.get(draft.id) is Some(existing) {
    if existing.label.text != draft.label.text ||
      existing.label.label_type != draft.label.label_type {
      self.conflict(
        "Boundary '\{draft.id}' has conflicting titles",
        draft.span,
        existing.span,
      )
    }
    push_unique(existing.classes, draft.classes)
    return
  }
  self.boundaries.set(draft.id, {
    label: draft.label,
    span: draft.span,
    classes: draft.classes.copy(),
    boundary_type: None,
    members: [],
    member_set: Set([]),
  })
  self.register(draft.id, draft.label, draft.span, draft.generated, "boundary")
}

///|
/// The kind of an end of a relationship; an end that nothing declares becomes a use case.
fn Resolver::endpoint(
  self : Resolver,
  end : DraftEndpoint,
) -> String raise @errors.PeleError {
  if end.classed && !end.declares {
    self.fail(
      "Relationship endpoint '\{end.id}' uses ::: without declaring the node",
      end.span,
    )
  }
  if self.symbols.get(end.id) is Some(origin) {
    return origin.kind
  }
  self.elements.set(end.id, {
    kind: "usecase",
    id: end.id,
    label: end.label,
    span: end.span,
    parent: None,
    shape: Some("ellipse"),
    stereotype: None,
    stereotype_span: None,
    classes: [],
    actor_type: None,
    icon: None,
    business: None,
  })
  self.register(end.id, end.label, end.span, end.generated, "usecase")
  self.mention(end.id, end.span.0)
  "usecase"
}

///|
/// The classes and styles of what a `class` or `style` statement names.
fn Resolver::stylable(
  self : Resolver,
  id : String,
  span : Span,
) -> (Array[String], Array[String]) raise @errors.PeleError {
  let model = self.model
  let found = match self.symbols.get(id).map(origin => origin.kind) {
    Some("actor") => model.actors.get(id).map(t => (t.classes, t.styles))
    Some("usecase") => model.use_cases.get(id).map(t => (t.classes, t.styles))
    Some("boundary") =>
      model.system_boundaries.get(id).map(t => (t.classes, t.styles))
    Some("json") => model.json_nodes.get(id).map(t => (t.classes, t.styles))
    _ => self.edges.get(id).map(t => (t.classes, t.styles))
  }
  match found {
    Some(target) => target
    None =>
      self.fail("Class/style target '\{id}' is unresolved or anonymous", span)
  }
}

///|
fn is_related(kind : String) -> Bool {
  kind == "actor" || kind == "usecase" || kind == "json"
}

///|
fn Resolver::relationships(
  self : Resolver,
  drafts : Drafts,
) -> Unit raise @errors.PeleError {
  let mut anonymous = 0
  for draft in drafts.relationships {
    let source = draft.source
    let target = draft.target
    let source_kind = self.endpoint(source)
    let target_kind = self.endpoint(target)
    if !is_related(source_kind) {
      self.conflict(
        "Relationship source '\{source.id}' cannot be \{source_kind}",
        source.span,
        self.symbols.get(source.id).unwrap().span,
      )
    }
    if !is_related(target_kind) {
      self.conflict(
        "Relationship target '\{target.id}' cannot be \{target_kind}",
        target.span,
        self.symbols.get(target.id).unwrap().span,
      )
    }
    let rel_type = draft.rel_type
    if (rel_type == "include" || rel_type == "extend") &&
      (source_kind != "usecase" || target_kind != "usecase") {
      self.fail(
        "\{rel_type} relationship requires use-case endpoints",
        draft.span,
      )
    }
    if rel_type == "generalization" &&
      (source_kind == "json" || source_kind != target_kind) {
      self.fail(
        "Generalization requires actor-to-actor or use-case-to-use-case endpoints",
        draft.span,
      )
    }
    if rel_type == "association" &&
      (source_kind == "json" || target_kind == "json") &&
      draft.arrow_type > 2 {
      self.fail(
        "JSON relationship '\{source.id}' to '\{target.id}' permits only point, reversed-point, or markerless solid association",
        draft.span,
      )
    }
    let id = match draft.id {
      Some(id) => id
      None => {
        anonymous += 1
        "edge-\{anonymous - 1}"
      }
    }
    let relationship = {
      id,
      explicit_id: draft.id is Some(_),
      source: source.id,
      target: target.id,
      rel_type,
      arrow_type: draft.arrow_type,
      label: draft.label.map(label => label.text),
      label_type: draft.label.map(label => label.label_type),
      minlen: draft.minlen,
      classes: [],
      styles: [],
      animate: false,
      animation: None,
    }
    self.model.relationships.push(relationship)
    self.edges.set(id, relationship)
  }
}

///|
fn Resolver::metadata(
  self : Resolver,
  drafts : Drafts,
) -> Unit raise @errors.PeleError {
  for statement in drafts.metadata {
    let target = statement.target
    guard self.symbols.get(target) is Some(origin) else {
      let implied = match infer_kind(statement.properties) {
        Some(kind) => " (metadata implies \{kind})"
        None => ""
      }
      self.fail(
        "Metadata target '\{target}' is unresolved\{implied}",
        statement.span,
      )
    }
    let kind = origin.kind
    if kind == "actor" || kind == "usecase" {
      self.element_metadata(
        self.elements.get(target).unwrap(),
        Some(statement.properties),
        true,
      )
      continue
    }
    let boundary = self.boundaries.get(target)
    let edge = self.edges.get(target)
    for property in statement.properties {
      match (kind, property.key, property.value) {
        ("boundary", "type", Text("rect" | "package" as value)) if boundary
          is Some(state) => state.boundary_type = Some(value)
        ("edge", "animate", Flag(value)) if edge is Some(relationship) =>
          relationship.animate = value
        ("edge", "animation", Text("fast" | "slow" as value)) if edge
          is Some(relationship) => {
          relationship.animation = Some(value)
          relationship.animate = true
        }
        _ => self.invalid(target, kind, property)
      }
    }
  }
  for relationship in self.model.relationships {
    if relationship.animation is Some(_) {
      relationship.animate = true
    }
  }
}

///|
fn Resolver::validate(
  self : Resolver,
  state : ElementState,
) -> Unit raise @errors.PeleError {
  let icon = non_empty(state.icon)
  if state.kind == "actor" {
    if icon is Some(_) &&
      state.actor_type is Some(actor_type) &&
      actor_type != "normal" {
      self.fail(
        "Actor '\{state.id}' cannot combine icon with type '\{actor_type}'",
        state.span,
      )
    }
    if state.business is Some(true) &&
      (icon is Some(_) || state.actor_type is Some("awesome")) {
      self.fail(
        "Business actor '\{state.id}' must use normal or hollow geometry",
        state.span,
      )
    }
  } else if state.shape is Some("rect") && state.business is Some(true) {
    self.fail(
      "Rectangular use case '\{state.id}' cannot be a business use case",
      state.span,
    )
  }
}

///|
/// Collapses the indentation of every line after the first, as `/\n\s+/g` replaced by a line break.
fn drop_indentation(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    let c = @util.code_at(text, i)
    i += 1
    out.write_char(c.unsafe_to_char())
    if c == 10 && i < text.length() && @util.is_space(@util.code_at(text, i)) {
      while i < text.length() && @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    }
  }
  out.to_string()
}

///|
/// Resolves what the parser read into a model, once the whole diagram is read.
/// Ports Mermaid's UsecaseModelBuilder, with its messages.
fn resolve_usecase(
  src : String,
  drafts : Drafts,
  title : String?,
) -> UsecaseModel raise @errors.PeleError {
  let model = empty_model()
  let self : Resolver = {
    src,
    model,
    symbols: Map([]),
    elements: Map([]),
    boundaries: Map([]),
    edges: Map([]),
    first: Map([]),
  }
  for relationship in drafts.relationships {
    self.mention(relationship.source.id, relationship.source.span.0)
    self.mention(relationship.target.id, relationship.target.span.0)
  }
  let declarations : Array[(Int32, () -> Unit raise @errors.PeleError)] = []
  for draft in drafts.elements {
    self.mention(draft.id, draft.span.0)
    declarations.push((draft.span.0, () => self.declare_element(draft)))
  }
  for draft in drafts.boundaries {
    self.mention(draft.id, draft.span.0)
    declarations.push((draft.span.0, () => self.declare_boundary(draft)))
  }
  for draft in drafts.jsons {
    self.mention(draft.id, draft.span.0)
    declarations.push(
      (draft.span.0, () => self.unique(draft.id, "json", draft.span)),
    )
  }
  for relationship in drafts.relationships {
    if relationship.id is Some(id) && relationship.id_span is Some(span) {
      declarations.push((span.0, () => self.unique(id, "edge", span)))
    }
  }
  for declaration in stable_sorted(declarations, entry => entry.0) {
    (declaration.1)()
  }
  let in_order = (ids : Array[String]) => {
    stable_sorted(ids, id => self.order(id))
  }
  let element_ids = () => self.elements.keys().collect()
  for id in in_order(element_ids()) {
    self.publish(self.elements.get(id).unwrap())
  }
  for id in in_order(self.boundaries.keys().collect()) {
    let state = self.boundaries.get(id).unwrap()
    model.system_boundaries.set(id, {
      id,
      label: state.label.text,
      label_type: state.label.label_type,
      boundary_type: "rect",
      members: [],
      classes: [],
      styles: [],
    })
  }
  for draft in stable_sorted(drafts.jsons, draft => self.order(draft.id)) {
    model.json_nodes.set(draft.id, {
      id: draft.id,
      value: draft.value,
      classes: draft.classes.copy(),
      styles: [],
    })
  }
  self.relationships(drafts)

  // The relationships may have added use cases; put all elements back in the order of first mention.
  let declared_actors = model.actors.copy()
  let declared_use_cases = model.use_cases.copy()
  model.actors.clear()
  model.use_cases.clear()
  for id in in_order(element_ids()) {
    match (declared_actors.get(id), declared_use_cases.get(id)) {
      (Some(actor), _) => model.actors.set(id, actor)
      (None, Some(use_case)) => model.use_cases.set(id, use_case)
      (None, None) => self.publish(self.elements.get(id).unwrap())
    }
  }
  self.metadata(drafts)
  for _, state in self.elements {
    self.validate(state)
    self.publish(state)
  }
  for draft in stable_sorted(drafts.elements, draft => draft.span.0) {
    guard draft.parent is Some(parent) && parent.id != "" else { continue }
    let boundary = self.boundaries.get(parent.id).unwrap()
    if !boundary.member_set.contains(draft.id) {
      boundary.member_set.add(draft.id)
      boundary.members.push(draft.id)
    }
  }
  for id, state in self.boundaries {
    let boundary = model.system_boundaries.get(id).unwrap()
    boundary.boundary_type = state.boundary_type.unwrap_or("rect")
    boundary.members = state.members
    boundary.classes = state.classes.copy()
  }
  let mut notes = 0
  for draft in drafts.notes {
    guard self.symbols.get(draft.target) is Some(origin) else {
      self.fail("Note target '\{draft.target}' is unresolved", draft.span)
    }
    if origin.kind != "actor" && origin.kind != "usecase" {
      self.conflict(
        "Note target '\{draft.target}' must be an actor or use case, not \{origin.kind}",
        draft.span,
        origin.span,
      )
    }
    let id = "note-\{notes}"
    notes += 1
    model.notes.set(id, {
      id,
      target: draft.target,
      label: draft.label.text,
      label_type: draft.label.label_type,
    })
  }
  for definition in drafts.class_defs {
    for id in definition.ids {
      model.class_defs.set(id, { id, styles: definition.styles.copy(), })
    }
  }
  for assignment in drafts.classes {
    for target in assignment.targets {
      let (classes, _) = self.stylable(target.0, target.1)
      push_unique(classes, assignment.classes)
    }
  }
  for assignment in drafts.styles {
    let (_, styles) = self.stylable(assignment.target, assignment.span)
    styles.append(assignment.styles)
  }
  model.direction = drafts.direction.unwrap_or(model.direction)
  model.title = title
  model.acc_title = drafts.acc_title
  model.acc_descr = drop_indentation(drafts.acc_description)
  model
}
