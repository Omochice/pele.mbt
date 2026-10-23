///|
/// Whether a member of a class is a method or an attribute.
pub(all) enum MemberType {
  Method
  Attribute
}

///|
/// An attribute or method of a class, split into the parts Mermaid reads from its text.
pub struct ClassMember {
  id : String
  member_type : MemberType
  visibility : String
  classifier : String
  parameters : String
  return_type : String
}

///|
/// The text a member is shown with, and the style its classifier gives it.
pub(all) struct DisplayDetails {
  display_text : String
  css_style : String
}

///|
fn is_visibility(c : Int32) -> Bool {
  c == '#' || c == '+' || c == '~' || c == '-'
}

///|
fn is_classifier(c : Int32) -> Bool {
  c == '$' || c == '*'
}

///|
/// Reads a member from its text.
/// Mermaid throws a TypeError for a method with no opening parenthesis, such as `run)`.
/// It is kept here as an attribute, so it is shown as written.
pub fn ClassMember::new(
  input : String,
  member_type : MemberType,
) -> ClassMember {
  let parsed = match member_type {
    Method => parse_method(input)
    Attribute => None
  }
  let split = match parsed {
    Some(found) => found
    None => parse_attribute(input)
  }
  let id = split.id
  let trimmed = @util.trim(id)
  { ..split, id: if id.has_prefix(" ") { " " + trimmed } else { trimmed }, }
}

///|
/// The same split as Mermaid's /([#+~-])?(.+)\((.*)\)([\s$*])?(.*)([$*])?/, found in one pass:
/// the first line with an opening parenthesis after its first character and a closing one later.
fn parse_method(input : String) -> ClassMember? {
  let n = input.length()
  let code = (i : Int32) => @util.code_at(input, i)
  let mut start = 0
  while start < n {
    let mut end = start
    while end < n && !@util.is_line_end(code(end)) {
      end += 1
    }
    let mut close = end - 1
    while close > start && code(close) != ')' {
      close -= 1
    }
    let mut open = close - 1
    while open > start && code(open) != '(' {
      open -= 1
    }
    if open > start {
      let first = code(start)
      let visible = is_visibility(first) && open > start + 1
      let id = @util.slice(
        input,
        if visible {
          start + 1
        } else {
          start
        },
        end=open,
      )
      let parameters = @util.trim(@util.slice(input, open + 1, end=close))
      let mut rest = close + 1
      let mut classifier = ""
      if rest < n {
        let next = code(rest)
        if is_classifier(next) || @util.is_space(next) {
          if is_classifier(next) {
            classifier = @util.slice(input, rest, end=rest + 1)
          }
          rest += 1
        }
      }
      let mut stop = rest
      while stop < n && !@util.is_line_end(code(stop)) {
        stop += 1
      }
      let mut return_type = @util.trim(@util.slice(input, rest, end=stop))
      if classifier == "" {
        let last = return_type.length() - 1
        if is_classifier(@util.code_at(return_type, last)) {
          classifier = @util.slice(return_type, last)
          return_type = @util.slice(return_type, 0, end=last)
        }
      }
      return Some({
        id,
        member_type: Method,
        visibility: if visible {
          @util.slice(input, start, end=start + 1)
        } else {
          ""
        },
        classifier,
        parameters,
        return_type,
      })
    }
    start = end + 1
  }
  None
}

///|
fn parse_attribute(input : String) -> ClassMember {
  let n = input.length()
  let visibility = if is_visibility(@util.code_at(input, 0)) {
    @util.slice(input, 0, end=1)
  } else {
    ""
  }
  let classifier = if is_classifier(@util.code_at(input, n - 1)) {
    @util.slice(input, n - 1)
  } else {
    ""
  }
  let from = if visibility == "" { 0 } else { 1 }
  let to = if classifier == "" { n } else { n - 1 }
  // As `substring`, which swaps bounds given in the wrong order.
  {
    id: if from <= to {
      @util.slice(input, from, end=to)
    } else {
      @util.slice(input, to, end=from)
    },
    member_type: Attribute,
    visibility,
    classifier,
    parameters: "",
    return_type: "",
  }
}

///|
/// The text the member is shown with, and the style of its classifier.
pub fn ClassMember::display_details(self : ClassMember) -> DisplayDetails {
  let text = StringBuilder()
  text.write_string(self.visibility)
  text.write_string(@common.parse_generic_types(self.id))
  if self.member_type is Method {
    text.write_string(
      "(\{@common.parse_generic_types(@util.trim(self.parameters))})",
    )
    if self.return_type != "" {
      text.write_string(" : " + @common.parse_generic_types(self.return_type))
    }
  }
  { display_text: @util.trim(text.to_string()), css_style: self.css_style(), }
}

///|
/// The style a classifier gives a member: italic when abstract, underlined when static.
pub fn ClassMember::css_style(self : ClassMember) -> String {
  match self.classifier {
    "*" => "font-style:italic;"
    "$" => "text-decoration:underline;"
    _ => ""
  }
}
