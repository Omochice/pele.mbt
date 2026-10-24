///|
fn show(node : @railroad.RailroadNode) -> String {
  match node {
    Terminal(value) => value.escape()
    NonTerminal(name) => "<\{name}>"
    Special(text) => "?\{text}?"
    Sequence(elements) => "(" + elements.map(show).join(" ") + ")"
    Choice(alternatives) => "(" + alternatives.map(show).join(" | ") + ")"
    Optional(element) => "[\{show(element)}]"
    Repetition(element~, min~, max~) => "{\{show(element)}}\{min}..\{max}"
  }
}

///|
fn parse(
  source : String,
  title? : String,
) -> @railroad.RailroadModel raise @errors.PeleError {
  @railroad.parse_railroad(source + "\n", title)
}

///|
fn failure(source : String) -> String {
  let _ = parse(source) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "accepted"
}

///|
fn rules(source : String) -> String {
  let model = parse(source) catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  model.rules.map(rule => "\{rule.name} = \{show(rule.definition)}").join("; ")
}

///|
fn definition(keyword : String, body : String) -> String {
  let model = parse("\{keyword}\n\{body}") catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  guard model.rules.get(0) is Some(rule) else { return "no rules" }
  show(rule.definition)
}

///|
fn ir(expression : String) -> String {
  definition("railroad-beta", "r = \{expression} ;")
}

///|
fn ebnf(expression : String) -> String {
  definition("railroad-ebnf-beta", "r = \{expression} ;")
}

///|
fn abnf(expression : String) -> String {
  definition("railroad-abnf-beta", "r = \{expression} ;")
}

///|
fn peg(expression : String) -> String {
  definition("railroad-peg-beta", "R <- \{expression} ;")
}
