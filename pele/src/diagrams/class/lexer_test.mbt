// The expected token streams were taken from pele v1.8.0's class lexer.

///|
fn dump(tokens : @class.Tokens) -> String {
  let parts = []
  for i, kind in tokens.types {
    parts.push("\{kind.name()}:\{tokens.texts[i]}@\{tokens.starts[i]}")
  }
  parts.join(" | ")
}

///|
test "splits class diagrams into the tokens of Mermaid's lexer" {
  let cases = [
    (
      "classDiagram\n  Animal <|-- Duck", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | ALPHA:Animal@15 | EXTENSION:<|@22 | LINE:--@24 | ALPHA:Duck@27 | EOF:@31 | $end:@31",
    ),
    (
      "classDiagram-v2\nclass A", "CLASS_DIAGRAM:classDiagram-v2@0 | NEWLINE:\n@15 | CLASS:class@16 | ALPHA:A@22 | EOF:@23 | $end:@23",
    ),
    (
      "classDiagram\nclass Duck {\n  +String beakColor\n  +swim()\n}", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:Duck@19 | STRUCT_START:{@24 | MEMBER:  +String beakColor@26 | MEMBER:  +swim()@46 | STRUCT_STOP:}@56 | EOF:@57 | $end:@57",
    ),
    (
      "classDiagram\nclass A~T~ {\n\"x\"\n[*]\n{\n}", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | GENERICTYPE:T@21 | STRUCT_START:{@24 | STR:x@27 | EDGE_STATE:[*]@30 | OPEN_IN_STRUCT:{@34 | STRUCT_STOP:}@36 | EOF:@37 | $end:@37",
    ),
    (
      "classDiagram\nclass `Animal Class!`\n`A` --> `B~T~`", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | BQUOTE_STR:Animal Class!@20 | NEWLINE:\n@34 | BQUOTE_STR:A@36 | LINE:--@39 | DEPENDENCY:>@41 | BQUOTE_STR:B~T~@44 | EOF:@49 | $end:@49",
    ),
    (
      "classDiagram\nA \"1\" --o \"many\" B : label here", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | ALPHA:A@13 | STR:1@16 | LINE:--@19 | AGGREGATION:o@21 | STR:many@24 | ALPHA:B@30 | LABEL:: label here@32 | EOF:@44 | $end:@44",
    ),
    (
      "classDiagram\nA ()-- B\nC --() D\nE <|..|> F\nG *--o H\nI <-- J", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | ALPHA:A@13 | LOLLIPOP:()@15 | LINE:--@17 | ALPHA:B@20 | NEWLINE:\n@21 | ALPHA:C@22 | LINE:--@24 | LOLLIPOP:()@26 | ALPHA:D@29 | NEWLINE:\n@30 | ALPHA:E@31 | EXTENSION:<|@33 | DOTTED_LINE:..@35 | EXTENSION:|>@37 | ALPHA:F@40 | NEWLINE:\n@41 | ALPHA:G@42 | COMPOSITION:*@44 | LINE:--@45 | AGGREGATION:o@47 | ALPHA:H@49 | NEWLINE:\n@50 | ALPHA:I@51 | DEPENDENCY:<@53 | LINE:--@54 | ALPHA:J@57 | EOF:@58 | $end:@58",
    ),
    (
      "classDiagram\nA : +run() int\nA :: x\nA :::hot\nclass B:::cold", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | ALPHA:A@13 | LABEL:: +run() int@15 | NEWLINE:\n@27 | ALPHA:A@28 | COLON::@30 | LABEL:: x@31 | NEWLINE:\n@34 | ALPHA:A@35 | STYLE_SEPARATOR::::@37 | ALPHA:hot@40 | NEWLINE:\n@43 | CLASS:class@44 | ALPHA:B@50 | STYLE_SEPARATOR::::@51 | ALPHA:cold@54 | EOF:@58 | $end:@58",
    ),
    (
      "classDiagram\nnamespace N {\n  class A\n  namespace M {\n    class B\n  }\n}\nnamespace X[\"lab\"] {\nclass Y\n}",
      "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | NAMESPACE:namespace@13 | ALPHA:N@23 | STRUCT_START:{@25 | NEWLINE:\n@26 | CLASS:class@29 | ALPHA:A@35 | NEWLINE:\n@36 | NAMESPACE:namespace@39 | ALPHA:M@49 | STRUCT_START:{@51 | NEWLINE:\n@52 | CLASS:class@57 | ALPHA:B@63 | NEWLINE:\n@64 | STRUCT_STOP:}@67 | NEWLINE:\n@68 | STRUCT_STOP:}@69 | NEWLINE:\n@70 | NAMESPACE:namespace@71 | ALPHA:X@81 | SQS:[@82 | STR:lab@84 | SQE:]@88 | STRUCT_START:{@90 | NEWLINE:\n@91 | CLASS:class@92 | ALPHA:Y@98 | NEWLINE:\n@99 | STRUCT_STOP:}@100 | EOF:@101 | $end:@101",
    ),
    (
      "classDiagram\nnote \"hello\"\nnote for A \"x\"", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | NOTE:note@13 | STR:hello@19 | NEWLINE:\n@25 | NOTE_FOR:note for@26 | ALPHA:A@35 | STR:x@38 | EOF:@40 | $end:@40",
    ),
    (
      "classDiagram\nclick A call alert(\"x\") \"tip\"\nclick B call f()\nclick C call  g(  )\ncallback A \"fn\" \"tip\"",
      "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLICK:click@13 | ALPHA:A@19 | CALLBACK_NAME:alert@26 | CALLBACK_ARGS:\"x\"@32 | STR:tip@38 | NEWLINE:\n@42 | CLICK:click@43 | ALPHA:B@49 | CALLBACK_NAME:f@56 | NEWLINE:\n@59 | CLICK:click@60 | ALPHA:C@66 | CALLBACK_NAME:g@74 | NEWLINE:\n@79 | CALLBACK:callback@80 | ALPHA:A@89 | STR:fn@92 | STR:tip@97 | EOF:@101 | $end:@101",
    ),
    (
      "classDiagram\nlink A \"https://x\" \"tip\" _self\nclick B href \"u\" _blank\nlink C \"v\" _parent\nlink D \"w\" _top",
      "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | LINK:link@13 | ALPHA:A@18 | STR:https://x@21 | STR:tip@33 | LINK_TARGET:_self@38 | NEWLINE:\n@43 | CLICK:click@44 | ALPHA:B@50 | HREF:href@52 | STR:u@58 | LINK_TARGET:_blank@61 | NEWLINE:\n@67 | LINK:link@68 | ALPHA:C@73 | STR:v@76 | LINK_TARGET:_parent@79 | NEWLINE:\n@86 | LINK:link@87 | ALPHA:D@92 | STR:w@95 | LINK_TARGET:_top@98 | EOF:@102 | $end:@102",
    ),
    (
      "classDiagram\nstyle A fill:#f9f,stroke:#333,stroke-width:4px\nclassDef hot fill:#f00,color:#fff\nclassDef a,b fill:1%\ncssClass \"A,B\" hot",
      "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | STYLE:style@13 | ALPHA:A@19 | ALPHA:fill@21 | LABEL::#f9f,stroke@25 | LABEL::#333,stroke-width@37 | LABEL::4px@55 | NEWLINE:\n@59 | CLASSDEF:classDef@60 | ALPHA:hot@69 | ALPHA:fill@73 | LABEL::#f00,color@77 | LABEL::#fff@88 | NEWLINE:\n@93 | CLASSDEF:classDef@94 | ALPHA:a@103 | COMMA:,@104 | ALPHA:b@105 | ALPHA:fill@107 | LABEL::1%@111 | NEWLINE:\n@114 | CSSCLASS:cssClass@115 | STR:A,B@125 | ALPHA:hot@130 | EOF:@133 | $end:@133",
    ),
    (
      "classDiagram\naccTitle: The title\naccDescr: The desc\naccDescr {\n multi\n line\n}\naccTitle no colon",
      "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | acc_title:accTitle: @13 | acc_title_value:The title@23 | NEWLINE:\n@32 | acc_descr:accDescr: @33 | acc_descr_value:The desc@43 | NEWLINE:\n@51 | acc_descr_multiline_value:multi\n line\n@64 | NEWLINE:\n@77 | ALPHA:accTitle@78 | ALPHA:no@87 | ALPHA:colon@90 | EOF:@95 | $end:@95",
    ),
    (
      "classDiagram\ndirection LR\n  direction RL\nA direction TB x\ndirection BT\ndirection XX",
      "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | direction_lr:direction LR@13 | NEWLINE:\n@25 | direction_rl:  direction RL@26 | NEWLINE:\n@40 | direction_tb:A direction TB x@41 | NEWLINE:\n@57 | direction_bt:direction BT@58 | NEWLINE:\n@70 | ALPHA:direction@71 | ALPHA:XX@81 | EOF:@83 | $end:@83",
    ),
    (
      "classDiagram\n%% comment\r\n\r\nclass A %% not a comment", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@27 | ALPHA:A@33 | PCT:%@35 | PCT:%@36 | ALPHA:not@38 | ALPHA:a@42 | ALPHA:comment@44 | EOF:@51 | $end:@51",
    ),
    (
      "classDiagram\nclass A\n@", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | NEWLINE:\n@20 | INVALID:@21",
    ),
    (
      "classDiagram\n<<interface>> Shape\nclass S <<Service>>\nclass T {\n<<enum>>\n}",
      "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | ANNOTATION_START:<<@13 | ALPHA:interface@15 | ANNOTATION_END:>>@24 | ALPHA:Shape@27 | NEWLINE:\n@32 | CLASS:class@33 | ALPHA:S@39 | ANNOTATION_START:<<@41 | ALPHA:Service@43 | ANNOTATION_END:>>@50 | NEWLINE:\n@52 | CLASS:class@53 | ALPHA:T@59 | STRUCT_START:{@61 | MEMBER:<<enum>>@63 | STRUCT_STOP:}@72 | EOF:@73 | $end:@73",
    ),
    (
      "classDiagram\nA \"x\" .. B\nC -- D\nE..F", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | ALPHA:A@13 | STR:x@16 | DOTTED_LINE:..@19 | ALPHA:B@22 | NEWLINE:\n@23 | ALPHA:C@24 | LINE:--@26 | ALPHA:D@29 | NEWLINE:\n@30 | ALPHA:E@31 | DOTTED_LINE:..@32 | ALPHA:F@34 | EOF:@35 | $end:@35",
    ),
    (
      "classDiagram\nclass A { x", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | STRUCT_START:{@21 | MEMBER: x@22 | EOF_IN_STRUCT:@24 | $end:@24",
    ),
    (
      "classDiagram\nclass A~T", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | GENERICTYPE:T@21 | GENERICTYPE:@22 | $end:@22",
    ),
    (
      "classDiagram\nclass `abc", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | BQUOTE_STR:abc@20 | EOF:@23 | $end:@23",
    ),
    (
      "classDiagram\nnote \"abc", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | NOTE:note@13 | STR:abc@19 | STR:@22 | $end:@22",
    ),
    (
      "classDiagram\nclick A call f(a,b", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLICK:click@13 | ALPHA:A@19 | CALLBACK_NAME:f@26 | CALLBACK_ARGS:a,b@28 | CALLBACK_ARGS:@31 | $end:@31",
    ),
    (
      "classDiagram\naccDescr {\nabc", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | acc_descr_multiline_value:abc@24 | acc_descr_multiline_value:@27 | $end:@27",
    ),
    (
      "B <|-- A~", "ALPHA:B@0 | EXTENSION:<|@2 | LINE:--@4 | ALPHA:A@7 | GENERICTYPE:@9 | $end:@9",
    ),
    (
      "classDiagram\nclass é\nclass 中文 \nA : ::: ;x", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | UNICODE_TEXT:é@19 | NEWLINE:\n@20 | CLASS:class@21 | UNICODE_TEXT:中@27 | UNICODE_TEXT:文@28 | NEWLINE: \n@29 | ALPHA:A@31 | LABEL:: @33 | STYLE_SEPARATOR::::@35 | INVALID:@39",
    ),
    (
      "classDiagram\nclass A {\n  +x\n}\n}\n{", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | STRUCT_START:{@21 | MEMBER:  +x@23 | STRUCT_STOP:}@28 | NEWLINE:\n@29 | INVALID:@30",
    ),
    (
      "classDiagram\nclass A~List~int~~\nA~T~ <|-- B~link~", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | GENERICTYPE:List@21 | ALPHA:int@26 | NEWLINE:\n@31 | ALPHA:A@32 | GENERICTYPE:T@34 | EXTENSION:<|@37 | LINE:--@39 | ALPHA:B@42 | LINK:link@44 | EOF:@49 | $end:@49",
    ),
    (
      "classDiagram\nclass A\n  \t\n \n   class B", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | NEWLINE:\n  \t\n \n@20 | CLASS:class@30 | ALPHA:B@36 | EOF:@37 | $end:@37",
    ),
    (
      "classDiagram\nclass A[\"Label\"]\nclass B[\"x\"]", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | SQS:[@20 | STR:Label@22 | SQE:]@28 | NEWLINE:\n@29 | CLASS:class@30 | ALPHA:B@36 | SQS:[@37 | STR:x@39 | SQE:]@41 | EOF:@42 | $end:@42",
    ),
    (
      "classDiagram\nA:x;y\nA ! # $ & ' , ? \\ / + % =", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | ALPHA:A@13 | LABEL::x@14 | INVALID:@16",
    ),
    (
      "classDiagram\nclass A {\n note\n link x\n}\nclass B~cssClass~\nclass `x callback y`",
      "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | STRUCT_START:{@21 | MEMBER: note@23 | MEMBER: link x@29 | STRUCT_STOP:}@37 | NEWLINE:\n@38 | CLASS:class@39 | ALPHA:B@45 | CSSCLASS:cssClass@47 | NEWLINE:\n@56 | CLASS:class@57 | BQUOTE_STR:x callback y@64 | EOF:@77 | $end:@77",
    ),
    (
      "classDiagram\noA o-- oB\no o-- o", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | ALPHA:oA@13 | AGGREGATION:o@16 | LINE:--@17 | ALPHA:oB@20 | NEWLINE:\n@22 | AGGREGATION:o@23 | AGGREGATION:o@25 | LINE:--@26 | AGGREGATION:o@29 | EOF:@30 | $end:@30",
    ),
    (
      "classDiagram\nnamespace A.B {\nclass C\n}\nnamespace D }", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | NAMESPACE:namespace@13 | ALPHA:A@23 | DOT:.@24 | ALPHA:B@25 | STRUCT_START:{@27 | NEWLINE:\n@28 | CLASS:class@29 | ALPHA:C@35 | NEWLINE:\n@36 | STRUCT_STOP:}@37 | NEWLINE:\n@38 | NAMESPACE:namespace@39 | ALPHA:D@49 | INVALID:@51",
    ),
    (
      "classDiagram\nclassDefx\nclassx\nnamespaced\nstylex\nnotex\nlinkx", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | ALPHA:classDefx@13 | NEWLINE:\n@22 | ALPHA:classx@23 | NEWLINE:\n@29 | ALPHA:namespaced@30 | NEWLINE:\n@40 | ALPHA:stylex@41 | NEWLINE:\n@47 | ALPHA:notex@48 | NEWLINE:\n@53 | ALPHA:linkx@54 | EOF:@59 | $end:@59",
    ),
    (
      "classDiagram\nA \"1\" --> \"2\" B\nA ..> B : x\nA --> \"2\" B", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | ALPHA:A@13 | STR:1@16 | LINE:--@19 | DEPENDENCY:>@21 | STR:2@24 | ALPHA:B@27 | NEWLINE:\n@28 | ALPHA:A@29 | DOTTED_LINE:..@31 | DEPENDENCY:>@33 | ALPHA:B@35 | LABEL:: x@37 | NEWLINE:\n@40 | ALPHA:A@41 | LINE:--@43 | DEPENDENCY:>@45 | STR:2@48 | ALPHA:B@51 | EOF:@52 | $end:@52",
    ),
    (
      "classDiagram\n[*] --> A\nclass A\nnamespace N {\n[*]\n}", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | EDGE_STATE:[*]@13 | LINE:--@17 | DEPENDENCY:>@19 | ALPHA:A@21 | NEWLINE:\n@22 | CLASS:class@23 | ALPHA:A@29 | NEWLINE:\n@30 | NAMESPACE:namespace@31 | ALPHA:N@41 | STRUCT_START:{@43 | NEWLINE:\n@44 | EDGE_STATE:[*]@45 | NEWLINE:\n@48 | STRUCT_STOP:}@49 | EOF:@50 | $end:@50",
    ),
    (
      "classDiagram\nclass A\ncall x(y)", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | NEWLINE:\n@20 | CALLBACK_NAME:x@26 | CALLBACK_ARGS:y@28 | EOF:@30 | $end:@30",
    ),
    (
      "classDiagram\naccTitle   :   spaced  \naccDescr:\n", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | acc_title:accTitle   :   @13 | acc_title_value:spaced  @28 | NEWLINE:\n@36 | acc_descr:accDescr:\n@37 | acc_descr_value:@47 | $end:@47",
    ),
    (
      "classDiagram\ndirection\n\n TB", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | direction_tb:direction\n\n TB@13 | EOF:@27 | $end:@27",
    ),
    (
      "classDiagram\nA direction LR B\nclass C", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | direction_lr:A direction LR B@13 | NEWLINE:\n@29 | CLASS:class@30 | ALPHA:C@36 | EOF:@37 | $end:@37",
    ),
    (
      "classDiagram\nclass A {\n+x\n}\nclass B {\r\n+y\r\n}", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | STRUCT_START:{@21 | MEMBER:+x@23 | STRUCT_STOP:}@26 | NEWLINE:\n@27 | CLASS:class@28 | ALPHA:B@34 | STRUCT_START:{@36 | MEMBER:\r@37 | MEMBER:+y\r@39 | STRUCT_STOP:}@43 | EOF:@44 | $end:@44",
    ),
    (
      "classDiagram\nclass A:::x {\n+y\n}", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | STYLE_SEPARATOR::::@20 | ALPHA:x@23 | STRUCT_START:{@25 | MEMBER:+y@27 | STRUCT_STOP:}@30 | EOF:@31 | $end:@31",
    ),
    (
      "classDiagram\nnamespace N {\nnamespace M {\nclass A\n}\n}\nclass B", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | NAMESPACE:namespace@13 | ALPHA:N@23 | STRUCT_START:{@25 | NEWLINE:\n@26 | NAMESPACE:namespace@27 | ALPHA:M@37 | STRUCT_START:{@39 | NEWLINE:\n@40 | CLASS:class@41 | ALPHA:A@47 | NEWLINE:\n@48 | STRUCT_STOP:}@49 | NEWLINE:\n@50 | STRUCT_STOP:}@51 | NEWLINE:\n@52 | CLASS:class@53 | ALPHA:B@59 | EOF:@60 | $end:@60",
    ),
    (
      "classDiagram\nnamespace N { class A }", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | NAMESPACE:namespace@13 | ALPHA:N@23 | STRUCT_START:{@25 | CLASS:class@27 | ALPHA:A@33 | STRUCT_STOP:}@35 | EOF:@36 | $end:@36",
    ),
    (
      "classDiagram\n`a\"b\"c` --> X", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | BQUOTE_STR:a\"b\"c@14 | LINE:--@21 | DEPENDENCY:>@23 | ALPHA:X@25 | EOF:@26 | $end:@26",
    ),
    (
      "classDiagram\nclass A~\"x\"~", "CLASS_DIAGRAM:classDiagram@0 | NEWLINE:\n@12 | CLASS:class@13 | ALPHA:A@19 | STR:x@22 | EOF:@25 | $end:@25",
    ),
  ]
  for case in cases {
    let (source, expected) = case
    assert_eq(dump(@class.tokenize(source)), expected, msg=source)
  }
}
