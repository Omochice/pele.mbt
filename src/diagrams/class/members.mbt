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
/// Reads a member from its text.
pub fn ClassMember::new(
  input : String,
  member_type : MemberType,
) -> ClassMember {
  ignore(input)
  {
    id: "",
    member_type,
    visibility: "",
    classifier: "",
    parameters: "",
    return_type: "",
  }
}

///|
/// The text the member is shown with, and the style of its classifier.
pub fn ClassMember::display_details(self : ClassMember) -> DisplayDetails {
  ignore(self)
  { display_text: "", css_style: "", }
}
