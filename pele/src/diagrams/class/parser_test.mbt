// Ported from pele v1.8.0, tests/class/parser.test.ts.
// The expected models and messages were taken from pele's parser; a model is written as db_test.mbt's db_dump writes it.

///|
fn parsed_dump(source : String) -> String {
  let db = @class.ClassDb::new()
  try {
    @class.parse_class(source, db)
    db_dump(db)
  } catch {
    @errors.PeleError(failure) => "error: " + failure.message
  }
}

///|
test "parses class diagrams into the model Mermaid's grammar builds, or fails as it does" {
  let cases = [
    (
      "classDiagram\n          direction TB\n          class Student {\n            -idCard : IdCard\n          }\n          class IdCard{\n            -id : int\n            -name : string\n          }\n          class Bike{\n            -id : int\n            -name : string\n          }\n          Student \"1\" --o \"1\" IdCard : carries\n          Student \"1\" --o \"1\" Bike : rides",
      "direction=TB title=- accTitle=- accDescr=-\nclass Student type= label=Student css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[-|idCard : IdCard|||] methods=[]\nclass IdCard type= label=IdCard css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[-|id : int|||;-|name : string|||] methods=[]\nclass Bike type= label=Bike css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[-|id : int|||;-|name : string|||] methods=[]\nrel Student IdCard t1=none t2=0 line=0 titles=1/1 title=carries\nrel Student Bike t1=none t2=0 line=0 titles=1/1 title=rides",
    ),
    (
      "classDiagram-v2\n  Animal <|-- Duck", "direction=TB title=- accTitle=- accDescr=-\nclass Animal type= label=Animal css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Duck type= label=Duck css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Animal Duck t1=1 t2=none line=0 titles=none/none title=-",
    ),
    (
      "classDiagram\n<<interface>> Shape\nclass Shape {\n  draw()\n}", "direction=TB title=- accTitle=- accDescr=-\nclass Shape type= label=Shape css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[] methods=[|draw|||]",
    ),
    (
      "classDiagram\nclass Shape {\n  <<interface>>\n  draw()\n}\nColor : <<enumeration>>",
      "direction=TB title=- accTitle=- accDescr=-\nclass Shape type= label=Shape css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[] methods=[|draw|||]\nclass Color type= label=Color css=default parent=- link=- target=- callback=false tooltip=- annotations=[enumeration] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\nclass A:::defined\nclass B\nclassDef def fill:#f00\nclassDef defined fill:#0f0",
      "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default defined parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#0f0] members=[] methods=[]\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\ndef def styles=[fill:#f00] text=[]\ndef defined styles=[fill:#0f0] text=[]",
    ),
    (
      "classDiagram\nclass A\nclassDef default fill:#f00,stroke:#000\nclass B", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#f00;stroke:#000] members=[] methods=[]\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\ndef default styles=[fill:#f00,stroke:#000] text=[]",
    ),
    (
      "classDiagram\nclass 1A\nclass B\ncssClass \"1A,B\" hot\nlink 1A \"https://example.com\"",
      "direction=TB title=- accTitle=- accDescr=-\nclass 1A type= label=1A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default hot parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\nbar ()-- foo\nfoo --() baz\nA ()--() B", "direction=TB title=- accTitle=- accDescr=-\nclass foo type= label=foo css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel interface0 foo t1=4 t2=none line=0 titles=none/none title=-\nrel foo interface1 t1=none t2=4 line=0 titles=none/none title=-\nrel A B t1=4 t2=4 line=0 titles=none/none title=-\niface interface0 bar foo\niface interface1 baz foo",
    ),
    (
      "classDiagram\nclass interface0\nclass note0\nbar ()-- interface0\nnote for note0 \"n\"\nnamespace note0 {\n class X\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass interface0 type= label=interface0 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass note0 type= label=note0 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass X type= label=X css=default parent=note0 link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel interface0 interface0 t1=4 t2=none line=0 titles=none/none title=-\nnote note0 class=note0 text=n index=0 parent=-\nns note0 label=note0 parent=- explicit=true classes=[X] notes=[] children=[]\niface interface0 bar interface0",
    ),
    (
      "classDiagram\nclass A\nclick A call alert(\"x\") \"tip\"\ncallback A \"alert\"",
      "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default clickable clickable parent=- link=- target=- callback=true tooltip=tip annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\nclass A\nclass B\nlink A \"javascript:alert(1)\"\nclick B href \"https://example.com/a b\" \"tip\" _self",
      "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default clickable parent=- link=about:blank target=_blank callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default clickable parent=- link=https://example.com/a%20b target=_self callback=false tooltip=tip annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\nnamespace A.B {\n class X\n}\nnamespace A {\n namespace C[\"See\"] {\n  class Y\n  note \"n\"\n }\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass X type= label=X css=default parent=A.B link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Y type= label=Y css=default parent=A.C link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nnote note0 class=- text=n index=0 parent=A.C\nns A label=A parent=- explicit=true classes=[] notes=[] children=[A.B,A.C]\nns A.B label=B parent=A explicit=true classes=[X] notes=[] children=[]\nns A.C label=See parent=A explicit=true classes=[Y] notes=[note0] children=[]",
    ),
    (
      "B <|-- A~", "direction=TB title=- accTitle=- accDescr=-\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel B A t1=1 t2=none line=0 titles=none/none title=-",
    ),
    (
      "class A", "error: Parse error on line 1:\nclass A\n-------^\nExpecting '$end', got 'EOF'",
    ),
    (
      "classDiagram\nnote link", "error: Parse error on line 2:\nnote link\n-----^\nExpecting 'STR', got 'LINK'",
    ),
    (
      "classDiagram\nclass A { x", "error: Parse error on line 2:\nclass A { x\n-----------^\nExpecting 'STRUCT_STOP', got 'EOF_IN_STRUCT'",
    ),
    (
      "classDiagram\nclass A\n@", "error: Lexical error on line 3. Unrecognized text.\n@\n^",
    ),
    (
      "classDiagram\n", "error: Parse error on line 1:\nclassDiagram\n------------^\nExpecting 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'NAMESPACE', 'ANNOTATION_START', 'CLASS', 'MEMBER', 'NOTE_FOR', 'NOTE', 'CLASSDEF', 'direction_tb', 'CALLBACK', 'LINK', 'CLICK', 'STYLE', 'CSSCLASS', 'ALPHA', 'MINUS', 'BQUOTE_STR', got 'EOF'",
    ),
    (
      "classDiagram\nnamespace N {\n}", "error: Parse error on line 3:\n}\n^\nExpecting 'NAMESPACE', 'CLASS', 'NOTE_FOR', 'NOTE', got 'STRUCT_STOP'",
    ),
    (
      "classDiagram\nclass Duck~T~[\"A duck\"]:::hot {\n  +swim()\n  +String name\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Duck type=T label=A duck css=default hot parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|String name|||] methods=[+|swim|||]",
    ),
    (
      "classDiagram\nclass A <<Service>> {\n}\nclass B <<x>> {\n +y\n}", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[Service] styles=[] members=[] methods=[]\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[x] styles=[] members=[+|y|||] methods=[]",
    ),
    (
      "classDiagram\nclass A {\n}\nclass B:::c", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default c parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\nA \"1\" *-- \"many\" B : has\nC o.. D\nE <|--|> F\nG ..> H : uses\nI -- J",
      "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C type= label=C css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass D type= label=D css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass E type= label=E css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass F type= label=F css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass G type= label=G css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass H type= label=H css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass I type= label=I css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass J type= label=J css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel A B t1=2 t2=none line=0 titles=1/many title=has\nrel C D t1=0 t2=none line=1 titles=none/none title=-\nrel E F t1=1 t2=1 line=0 titles=none/none title=-\nrel G H t1=none t2=3 line=1 titles=none/none title=uses\nrel I J t1=none t2=none line=0 titles=none/none title=-",
    ),
    (
      "classDiagram\nA.B --> C.D\n`x y` --> `z`", "direction=TB title=- accTitle=- accDescr=-\nclass A.B type= label=A.B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C.D type= label=C.D css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass x y type= label=x y css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass z type= label=z css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel A.B C.D t1=none t2=3 line=0 titles=none/none title=-\nrel x y z t1=none t2=3 line=0 titles=none/none title=-",
    ),
    (
      "classDiagram\nA : +run() int\nA : -count$\nA :: x", "error: Parse error on line 4:\nA :: x\n--^\nExpecting 'EOF', got 'COLON'",
    ),
    (
      "classDiagram\nstyle A fill:#f9f,stroke:#333,stroke-width:4px\nclass A", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\nclass A\nstyle A fill:#f9f,stroke:#333,stroke-width:4px", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#f9f;stroke:#333;stroke-width:4px] members=[] methods=[]",
    ),
    (
      "classDiagram\nclassDef a,b fill:#f00,color:red\nclass X:::a", "direction=TB title=- accTitle=- accDescr=-\nclass X type= label=X css=default a parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\ndef a styles=[fill:#f00,color:red] text=[bgFill:#f00,color:red]\ndef b styles=[fill:#f00,color:red] text=[bgFill:#f00,color:red]",
    ),
    (
      "classDiagram\nclass A\ncssClass \"A\" hot", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default hot parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\nclass A\nclick A href \"https://x\" \"tip\"\nclick A call fn(1, 2)\nlink A \"https://y\" _top",
      "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default clickable clickable clickable parent=- link=https://y/ target=_top callback=true tooltip=tip annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\naccTitle: The title\naccDescr: The description\nclass A", "direction=TB title=- accTitle=The title accDescr=The description\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\naccDescr {\n  multi\n    line\n}\nclass A", "direction=TB title=- accTitle=- accDescr=multi\nline\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\ndirection LR\nclass A", "direction=LR title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\ndirection RL\ndirection BT", "direction=BT title=- accTitle=- accDescr=-",
    ),
    (
      "classDiagram\nnote for A \"about A\"\nclass A", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nnote note0 class=A text=about A index=0 parent=-",
    ),
    (
      "classDiagram\nnamespace Outer {\n  class A\n  namespace Inner[\"In here\"] {\n    class B\n  }\n}\nclass C\nA --> B\nB --> C",
      "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=Outer link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default parent=Outer.Inner link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C type= label=C css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel A B t1=none t2=3 line=0 titles=none/none title=-\nrel B C t1=none t2=3 line=0 titles=none/none title=-\nns Outer label=Outer parent=- explicit=true classes=[A] notes=[] children=[Outer.Inner]\nns Outer.Inner label=In here parent=Outer explicit=true classes=[B] notes=[] children=[]",
    ),
    (
      "classDiagram\nnamespace N {\n  class A\n  note for A \"x\"\n}\nnamespace N {\n class B\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=N link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default parent=N link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nnote note0 class=A text=x index=0 parent=N\nns N label=N parent=- explicit=true classes=[A,B] notes=[note0] children=[]",
    ),
    (
      "classDiagram\nnamespace N {\nclass A {\n +x\n}\n}", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=N link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|x|||] methods=[]\nns N label=N parent=- explicit=true classes=[A] notes=[] children=[]",
    ),
    (
      "classDiagram\nclass A\nclass B\nA", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    ("classDiagram\nA B", "direction=TB title=- accTitle=- accDescr=-"),
    (
      "classDiagram\nA --", "error: Parse error on line 2:\nA --\n----^\nExpecting 'UNICODE_TEXT', 'NUM', 'ALPHA', 'MINUS', 'BQUOTE_STR', got 'EOF'",
    ),
    (
      "classDiagram\nA -- B C", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass BC type= label=BC css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel A BC t1=none t2=none line=0 titles=none/none title=-",
    ),
    (
      "classDiagram\nclass A[x]", "error: Parse error on line 2:\nclass A[x]\n--------^\nExpecting 'STR', got 'ALPHA'",
    ),
    (
      "classDiagram\nclass A[\"x\"", "error: Parse error on line 2:\nclass A[\"x\"\n-----------^\nExpecting 'SQE', got 'EOF'",
    ),
    (
      "classDiagram\nclass A:::", "error: Parse error on line 2:\nclass A:::\n----------^\nExpecting 'UNICODE_TEXT', 'NUM', 'ALPHA', 'MINUS', got 'EOF'",
    ),
    (
      "classDiagram\nclass A <<x", "error: Parse error on line 2:\nclass A <<x\n-----------^\nExpecting 'ANNOTATION_END', got 'EOF'",
    ),
    (
      "classDiagram\nstyle A", "error: Parse error on line 2:\nstyle A\n-------^\nExpecting 'ALPHA', 'NUM', 'COLON', 'UNIT', 'SPACE', 'BRKT', 'STYLE', 'PCT', 'LABEL', got 'EOF'",
    ),
    (
      "classDiagram\nstyle A fill:#f00,", "direction=TB title=- accTitle=- accDescr=-",
    ),
    (
      "classDiagram\nclassDef", "error: Parse error on line 2:\nclassDef\n--------^\nExpecting 'ALPHA', got 'EOF'",
    ),
    (
      "classDiagram\ncssClass \"A\"", "error: Parse error on line 2:\ncssClass \"A\"\n------------^\nExpecting 'ALPHA', got 'EOF'",
    ),
    (
      "classDiagram\nlink A", "error: Parse error on line 2:\nlink A\n------^\nExpecting 'STR', got 'EOF'",
    ),
    (
      "classDiagram\nclick A", "error: Parse error on line 2:\nclick A\n-------^\nExpecting 'CALLBACK_NAME', got 'EOF'",
    ),
    (
      "classDiagram\ncallback A", "error: Parse error on line 2:\ncallback A\n----------^\nExpecting 'STR', got 'EOF'",
    ),
    (
      "classDiagram\naccTitle:", "error: Parse error on line 2:\naccTitle:\n---------^\nExpecting 'EOF', got '$end'",
    ),
    (
      "classDiagram\n[*]", "error: Parse error on line 2:\n[*]\n^\nExpecting 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'NAMESPACE', 'ANNOTATION_START', 'CLASS', 'MEMBER', 'NOTE_FOR', 'NOTE', 'CLASSDEF', 'direction_tb', 'CALLBACK', 'LINK', 'CLICK', 'STYLE', 'CSSCLASS', 'ALPHA', 'MINUS', 'BQUOTE_STR', got 'EDGE_STATE'",
    ),
    (
      "classDiagram\nclass A\n\n\nclass B\n", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\nclass A\n%% comment\nclass B", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\n{", "error: Lexical error on line 2. Unrecognized text.\n{\n^",
    ),
    (
      "classDiagram\nclass A {\n+x\n}\n}", "error: Lexical error on line 5. Unrecognized text.\n}\n^",
    ),
    (
      "classDiagram\nnamespace N {\nclass A\n} extra", "error: Parse error on line 4:\n} extra\n--^\nExpecting 'EOF', got 'ALPHA'",
    ),
    (
      "classDiagram\nnamespace N {\nclass A\nclass B\n}\nnamespace M {\nnamespace O {\nclass C\n}\nclass D\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=N link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default parent=N link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C type= label=C css=default parent=M.O link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass D type= label=D css=default parent=M link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nns N label=N parent=- explicit=true classes=[A,B] notes=[] children=[]\nns M label=M parent=- explicit=true classes=[D] notes=[] children=[M.O]\nns M.O label=O parent=M explicit=true classes=[C] notes=[] children=[]",
    ),
    (
      "classDiagram\nnamespace N {\nclass A\n\n\n}", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=N link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nns N label=N parent=- explicit=true classes=[A] notes=[] children=[]",
    ),
    (
      "classDiagram\nnamespace N {\nnamespace M {\nclass A\n}}", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=N.M link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nns N label=N parent=- explicit=true classes=[] notes=[] children=[N.M]\nns N.M label=M parent=N explicit=true classes=[A] notes=[] children=[]",
    ),
    (
      "classDiagram\nnamespace N {\nnote \"x\"\n}", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=x index=0 parent=N\nns N label=N parent=- explicit=true classes=[] notes=[note0] children=[]",
    ),
    (
      "classDiagram\nnamespace N {\nclass A\n}\n}", "error: Lexical error on line 5. Unrecognized text.\n}\n^",
    ),
    (
      "classDiagram\nA -- B : x : y", "error: Parse error on line 2:\nA -- B : x : y\n-----------^\nExpecting 'EOF', got 'LABEL'",
    ),
    (
      "classDiagram\nA \"x\" B", "error: Parse error on line 2:\nA \"x\" B\n------^\nExpecting 'AGGREGATION', 'EXTENSION', 'COMPOSITION', 'DEPENDENCY', 'LOLLIPOP', 'LINE', 'DOTTED_LINE', got 'ALPHA'",
    ),
    (
      "classDiagram\nnote", "error: Parse error on line 2:\nnote\n----^\nExpecting 'STR', got 'EOF'",
    ),
    (
      "classDiagram\nclass é\nclass 中文\né --> 中文", "direction=TB title=- accTitle=- accDescr=-\nclass é type= label=é css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass 中文 type= label=中文 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel é 中文 t1=none t2=3 line=0 titles=none/none title=-",
    ),
    (
      "classDiagram\n-A --> B-", "direction=TB title=- accTitle=- accDescr=-\nclass -A type= label=-A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B- type= label=B- css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel -A B- t1=none t2=3 line=0 titles=none/none title=-",
    ),
    (
      "classDiagram\nclass A\nclass A~T~", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\nclass A~T~\nclass A", "direction=TB title=- accTitle=- accDescr=-\nclass A type=T label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram\nA~T~ --> B~U~\nA~T~ : +x", "direction=TB title=- accTitle=- accDescr=-\nclass A type=T label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|x|||] methods=[]\nclass B type=U label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel A B t1=none t2=3 line=0 titles=none/none title=-",
    ),
    (
      "classDiagram\nlink A \"u\" \"tip\" _blank", "direction=TB title=- accTitle=- accDescr=-",
    ),
    (
      "classDiagram\nclass A\nclick A call fn() \"tip\"", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default clickable parent=- link=- target=- callback=true tooltip=tip annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "classDiagram class A", "error: Parse error on line 1:\nclassDiagram class A\n-------------^\nExpecting 'NEWLINE', got 'CLASS'",
    ),
    (
      "classDiagram\nclass A;", "error: Lexical error on line 2. Unrecognized text.\nclass A;\n-------^",
    ),
    (
      "classDiagram\nclass A\nnote for A \"x\" \"y\"", "error: Parse error on line 3:\nnote for A \"x\" \"y\"\n----------------^\nExpecting 'EOF', got 'STR'",
    ),
    (
      "classDiagram\nA --> B : label\nclass C", "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C type= label=C css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel A B t1=none t2=3 line=0 titles=none/none title=label",
    ),
  ]
  for case in cases {
    let (source, expected) = case
    assert_eq(parsed_dump(source), expected, msg=source)
  }
}
