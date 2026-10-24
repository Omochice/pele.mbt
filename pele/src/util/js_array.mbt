///|
/// The most elements V8 holds in an array grown by pushing: 2^27, measured under node 24.21.
/// A push past it throws a RangeError, which pele reports as a diagram nested too deeply, so a
/// lexer that keeps several numbers per token in one array stops at a fraction of that many tokens.
pub const JS_ARRAY_MAX_LENGTH : Int32 = 134217728
