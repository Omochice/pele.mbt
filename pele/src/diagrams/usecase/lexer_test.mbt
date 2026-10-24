// The expected streams were taken from pele's lexer.

///|
/// The token stream as `NAME[start,end)`, or the message of the error the lexer raises.
fn lex(source : String) -> String {
  let tokens = @usecase.tokenize(source) catch {
    @errors.PeleError(failure) => return "error: " + failure.message
  }
  let parts = []
  for i, kind in tokens.types {
    parts.push(
      "\{@usecase.token_name(kind)}[\{tokens.starts[i]},\{tokens.ends[i]})",
    )
  }
  parts.join(" ")
}

///|
test "tokenize: the header, words and keywords" {
  inspect(
    lex("usecase-beta\nactor A --> B"),
    content="USECASE[0,12) NEWLINE[12,13) ACTOR[13,18) IDENTIFIER[19,20) FORWARD_SOLID[21,24) IDENTIFIER[25,26) EOF[26,26) EOF[26,26) EOF[26,26)",
  )
  inspect(
    lex(
      "endx end actorx actor INCLUDE Include extend EXTEND eXtEnd systemBoundary styles style",
    ),
    content="IDENTIFIER[0,4) END[5,8) IDENTIFIER[9,15) ACTOR[16,21) INCLUDE[22,29) INCLUDE[30,37) EXTEND[38,44) EXTEND[45,51) EXTEND[52,58) SYSTEM_BOUNDARY[59,73) IDENTIFIER[74,80) STYLE[81,86) EOF[86,86) EOF[86,86) EOF[86,86)",
  )
  inspect(
    lex(
      "classDef class classDefs json TD TB TBx usecase-betax usecase-beta note notes for false true direction BT LR RL",
    ),
    content="CLASS_DEF[0,8) CLASS[9,14) IDENTIFIER[15,24) JSON[25,29) TD[30,32) TB[33,35) IDENTIFIER[36,39) USECASE[40,52) IDENTIFIER[52,53) USECASE[54,66) NOTE[67,71) IDENTIFIER[72,77) FOR[78,81) FALSE[82,87) TRUE[88,92) DIRECTION[93,102) BT[103,105) LR[106,108) RL[109,111) EOF[111,111) EOF[111,111) EOF[111,111)",
  )
  inspect(
    lex("oops o--B x--C o-x ox-- o-- x- a-b-c a- -b"),
    content="IDENTIFIER[0,4) BACKWARD_CIRCLE[5,8) IDENTIFIER[8,9) BACKWARD_CROSS[10,13) IDENTIFIER[13,14) CSS_IDENTIFIER[15,18) IDENTIFIER[19,21) MARKERLESS_SOLID[21,23) BACKWARD_CIRCLE[24,27) IDENTIFIER[28,29) DASH[29,30) CSS_IDENTIFIER[31,36) IDENTIFIER[37,38) DASH[38,39) DASH[40,41) IDENTIFIER[41,42) EOF[42,42) EOF[42,42) EOF[42,42)",
  )
}

///|
test "tokenize: the relationship operators" {
  inspect(
    lex(
      "A --> B\nA <-- B\nA -- B\nA --o B\nA o-- B\nA --x B\nA x-- B\nA --|> B",
    ),
    content="IDENTIFIER[0,1) FORWARD_SOLID[2,5) IDENTIFIER[6,7) NEWLINE[7,8) IDENTIFIER[8,9) BACKWARD_SOLID[10,13) IDENTIFIER[14,15) NEWLINE[15,16) IDENTIFIER[16,17) MARKERLESS_SOLID[18,20) IDENTIFIER[21,22) NEWLINE[22,23) IDENTIFIER[23,24) FORWARD_CIRCLE[25,28) IDENTIFIER[29,30) NEWLINE[30,31) IDENTIFIER[31,32) BACKWARD_CIRCLE[33,36) IDENTIFIER[37,38) NEWLINE[38,39) IDENTIFIER[39,40) FORWARD_CROSS[41,44) IDENTIFIER[45,46) NEWLINE[46,47) IDENTIFIER[47,48) BACKWARD_CROSS[49,52) IDENTIFIER[53,54) NEWLINE[54,55) IDENTIFIER[55,56) GENERALIZATION[57,61) IDENTIFIER[62,63) EOF[63,63) EOF[63,63) EOF[63,63)",
  )
  inspect(
    lex(
      "A ..> : include B\nA ---> B\nA <--- B\nA ---o B\nA ---|> B\nA -- label --> B",
    ),
    content="IDENTIFIER[0,1) DEPENDENCY_ARROW[2,5) COLON[6,7) INCLUDE[8,15) IDENTIFIER[16,17) NEWLINE[17,18) IDENTIFIER[18,19) FORWARD_SOLID[20,24) IDENTIFIER[25,26) NEWLINE[26,27) IDENTIFIER[27,28) BACKWARD_SOLID[29,33) IDENTIFIER[34,35) NEWLINE[35,36) IDENTIFIER[36,37) MARKERLESS_SOLID[38,41) IDENTIFIER[41,42) IDENTIFIER[43,44) NEWLINE[44,45) IDENTIFIER[45,46) MARKERLESS_SOLID[47,50) CSS_PUNCTUATION[50,51) LABEL_PUNCTUATION[51,52) IDENTIFIER[53,54) NEWLINE[54,55) IDENTIFIER[55,56) MARKERLESS_SOLID[57,59) IDENTIFIER[60,65) FORWARD_SOLID[66,69) IDENTIFIER[70,71) EOF[71,71) EOF[71,71) EOF[71,71)",
  )
  inspect(
    lex("A ..>B A.. > B ..x .. .5 . 1.5.5 1.a"),
    content="IDENTIFIER[0,1) DEPENDENCY_ARROW[2,5) IDENTIFIER[5,6) IDENTIFIER[7,8) DOT[8,9) DOT[9,10) LABEL_PUNCTUATION[11,12) IDENTIFIER[13,14) DOT[15,16) DOT[16,17) IDENTIFIER[17,18) DOT[19,20) DOT[20,21) NUMBER[22,24) DOT[25,26) NUMBER[27,30) NUMBER[30,32) IDENTIFIER[33,34) DOT[34,35) IDENTIFIER[35,36) EOF[36,36) EOF[36,36) EOF[36,36)",
  )
}

///|
test "tokenize: style values" {
  inspect(
    lex(
      "style A stroke-width:1.5px,fill:#fff,color:red\\,blue 1mg .5em 10% 12 3.25 # #g",
    ),
    content="STYLE[0,5) IDENTIFIER[6,7) CSS_IDENTIFIER[8,20) COLON[20,21) NUMBER[21,26) COMMA[26,27) IDENTIFIER[27,31) COLON[31,32) HASH_COLOR[32,36) COMMA[36,37) IDENTIFIER[37,42) COLON[42,43) IDENTIFIER[43,46) CSS_ESCAPED_COMMA[46,48) IDENTIFIER[48,52) IDENTIFIER[53,56) NUMBER[57,61) IDENTIFIER[62,64) PERCENT[64,65) IDENTIFIER[66,68) NUMBER[69,73) CSS_PUNCTUATION[74,75) CSS_PUNCTUATION[76,77) IDENTIFIER[77,78) EOF[78,78) EOF[78,78) EOF[78,78)",
  )
  inspect(
    lex("a::b ::: : :: @ @{ { } [ ] ( ) ,"),
    content="IDENTIFIER[0,1) COLON[1,2) COLON[2,3) IDENTIFIER[3,4) CLASS_SEPARATOR[5,8) COLON[9,10) COLON[11,12) COLON[12,13) AT[14,15) METADATA_START[16,18) LBRACE[19,20) RBRACE[21,22) LBRACKET[23,24) RBRACKET[25,26) LPAREN[27,28) RPAREN[29,30) COMMA[31,32) EOF[32,32) EOF[32,32) EOF[32,32)",
  )
  inspect(
    lex("A(é日 label) [x] , ! ? \\, \\x ; ` ~ = $ & * + / ^ | < >"),
    content="IDENTIFIER[0,1) LPAREN[1,2) LABEL_SYMBOL[2,4) IDENTIFIER[5,10) RPAREN[10,11) LBRACKET[12,13) IDENTIFIER[13,14) RBRACKET[14,15) COMMA[16,17) CSS_PUNCTUATION[18,19) CSS_PUNCTUATION[20,21) CSS_ESCAPED_COMMA[22,24) LABEL_PUNCTUATION[25,26) IDENTIFIER[26,27) LABEL_PUNCTUATION[28,29) LABEL_PUNCTUATION[30,31) CSS_PUNCTUATION[32,33) CSS_PUNCTUATION[34,35) CSS_PUNCTUATION[36,37) CSS_PUNCTUATION[38,39) CSS_PUNCTUATION[40,41) CSS_PUNCTUATION[42,43) CSS_PUNCTUATION[44,45) CSS_PUNCTUATION[46,47) CSS_PUNCTUATION[48,49) LABEL_PUNCTUATION[50,51) LABEL_PUNCTUATION[52,53) EOF[53,53) EOF[53,53) EOF[53,53)",
  )
}

///|
test "tokenize: strings" {
  inspect(
    lex("\"a b\" \"`md`\" 'single' \"`unclosed"),
    content="PLAIN_STRING[0,5) MARKDOWN_STRING[6,12) PLAIN_STRING[13,21) UNCLOSED_MARKDOWN_STRING[22,32) EOF[32,32) EOF[32,32) EOF[32,32)",
  )
  inspect(
    lex("\"`two\nlines`\" \"x\""),
    content="MARKDOWN_STRING[0,13) PLAIN_STRING[14,17) EOF[17,17) EOF[17,17) EOF[17,17)",
  )
}

///|
test "tokenize: comments and accessibility lines at the start of a line" {
  inspect(
    lex("%% comment\n  %% indented\nA %% not\n%x"),
    content="COMMENT[0,10) NEWLINE[10,11) COMMENT[13,24) NEWLINE[24,25) IDENTIFIER[25,26) PERCENT[27,28) PERCENT[28,29) IDENTIFIER[30,33) NEWLINE[33,34) PERCENT[34,35) IDENTIFIER[35,36) EOF[36,36) EOF[36,36) EOF[36,36)",
  )
  inspect(
    lex(
      "accTitle: T\naccDescr : D\naccDescr {\n x\n}\naccTitlex\n accTitle: indented\nA accTitle: x",
    ),
    content="ACC_TITLE_LINE[0,11) NEWLINE[11,12) ACC_DESCR_LINE[12,24) NEWLINE[24,25) ACC_DESCR_BLOCK[25,40) NEWLINE[40,41) IDENTIFIER[41,50) NEWLINE[50,51) ACC_TITLE_LINE[52,70) NEWLINE[70,71) IDENTIFIER[71,72) IDENTIFIER[73,81) COLON[81,82) IDENTIFIER[83,84) EOF[84,84) EOF[84,84) EOF[84,84)",
  )
  inspect(
    lex("accDescr { never\naccDescr no colon\naccDescr {x}"),
    content="ACC_DESCR_BLOCK[0,47) EOF[47,47) EOF[47,47) EOF[47,47)",
  )
  inspect(
    lex("accDescr {x}\naccDescr {\n"),
    content="ACC_DESCR_BLOCK[0,12) NEWLINE[12,13) IDENTIFIER[13,21) LBRACE[22,23) NEWLINE[23,24) EOF[24,24) EOF[24,24) EOF[24,24)",
  )
}

///|
test "tokenize: JSON declarations" {
  inspect(
    lex("json P@{\"a\": {\"b\": \"}\"}} :::c\njson Q @ {\"x\": \"\\\"}\""),
    content="JSON_DECLARATION_START[0,7) JSON_OBJECT_LITERAL[7,24) CLASS_SEPARATOR[25,28) IDENTIFIER[28,29) NEWLINE[29,30) JSON_DECLARATION_START[30,39) UNCLOSED_JSON_OBJECT_LITERAL[39,50) EOF[50,50) EOF[50,50) EOF[50,50)",
  )
  inspect(
    lex("jsonx P@{} json P {} json P@ x"),
    content="IDENTIFIER[0,5) IDENTIFIER[6,7) METADATA_START[7,9) RBRACE[9,10) JSON[11,15) IDENTIFIER[16,17) LBRACE[18,19) RBRACE[19,20) JSON[21,25) IDENTIFIER[26,27) AT[27,28) IDENTIFIER[29,30) EOF[30,30) EOF[30,30) EOF[30,30)",
  )
  inspect(
    lex("json P@{\"a\":"),
    content="JSON_DECLARATION_START[0,7) UNCLOSED_JSON_OBJECT_LITERAL[7,12) EOF[12,12) EOF[12,12) EOF[12,12)",
  )
  inspect(
    lex("json\tP\t@\t{}"),
    content="JSON_DECLARATION_START[0,9) JSON_OBJECT_LITERAL[9,11) EOF[11,11) EOF[11,11) EOF[11,11)",
  )
}

///|
test "tokenize: stereotypes" {
  inspect(
    lex("A <<Human>>\nB <<>>\nC << x\nD <<   >>\nE <<a>b>>"),
    content="IDENTIFIER[0,1) STEREOTYPE_START[2,4) STEREOTYPE_TEXT[4,9) STEREOTYPE_END[9,11) NEWLINE[11,12) IDENTIFIER[12,13) STEREOTYPE_START[14,16) STEREOTYPE_END[16,18) NEWLINE[18,19) IDENTIFIER[19,20) STEREOTYPE_START[21,23) UNCLOSED_STEREOTYPE_TEXT[23,25) NEWLINE[25,26) IDENTIFIER[26,27) STEREOTYPE_START[28,30) UNCLOSED_STEREOTYPE_TEXT[30,35) NEWLINE[35,36) IDENTIFIER[36,37) STEREOTYPE_START[38,40) STEREOTYPE_TEXT[40,43) STEREOTYPE_END[43,45) EOF[45,45) EOF[45,45) EOF[45,45)",
  )
  inspect(
    lex("A <<"),
    content="IDENTIFIER[0,1) STEREOTYPE_START[2,4) EOF[4,4) EOF[4,4) EOF[4,4)",
  )
  inspect(
    lex("A <<x"),
    content="IDENTIFIER[0,1) STEREOTYPE_START[2,4) UNCLOSED_STEREOTYPE_TEXT[4,5) EOF[5,5) EOF[5,5) EOF[5,5)",
  )
}

///|
test "tokenize: line breaks" {
  inspect(
    lex("usecase-beta\r\nA\rB\n\r\nC"),
    content="USECASE[0,12) NEWLINE[12,14) IDENTIFIER[14,15) NEWLINE[15,16) IDENTIFIER[16,17) NEWLINE[17,18) NEWLINE[18,20) IDENTIFIER[20,21) EOF[21,21) EOF[21,21) EOF[21,21)",
  )
}

///|
test "tokenize: characters no token starts with" {
  inspect(
    lex("A \"b"),
    content="error: Error lexing usecase diagram: unexpected character: ->\"<- at offset: 2, skipped 1 characters. at line 1, column 3 [2,3)",
  )
  inspect(
    lex("A 'b"),
    content="error: Error lexing usecase diagram: unexpected character: ->'<- at offset: 2, skipped 1 characters. at line 1, column 3 [2,3)",
  )
  inspect(
    lex("x 'unclosed\n"),
    content="error: Error lexing usecase diagram: unexpected character: ->'<- at offset: 2, skipped 1 characters. at line 1, column 3 [2,3)",
  )
  inspect(
    lex("A <<\n\nB"),
    content="error: Error lexing usecase diagram: unexpected character: ->\n<- at offset: 4, skipped 2 characters. at line 1, column 5 [4,6)",
  )
  inspect(
    lex("A \"'\"' x"),
    content="error: Error lexing usecase diagram: unexpected character: ->'<- at offset: 5, skipped 1 characters. at line 1, column 6 [5,6)",
  )
}
