// What pele v1.8.0's block parser makes of hand-written inputs, the block sources of its specs and Mermaid's documentation, and mutations of them.

///|
let parser_cases : Array[(String, String)] = [
  (
    "block", "error syntax 1:6\nParse error on line 1:\nblock\n-----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'EOF'",
  ),
  (
    "block\n", "error syntax 1:6\nParse error on line 1:\nblock\n-----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'EOF'",
  ),
  (
    "block\n  a - b", "error syntax 2:5\nLexical error on line 2. Unrecognized text.\n  a - b\n----^",
  ),
  (
    "block\n  a[label]", "error syntax 2:5\nLexical error on line 2. Unrecognized text.\n  a[label]\n----^",
  ),
  (
    "block\n  block\n  a", "error syntax 3:4\nParse error on line 3:\n  a\n---^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'EOF'",
  ),
  (
    "block\n  a\n  end", "error syntax 3:3\nParse error on line 3:\n  end\n--^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "block\n  default", "error syntax 2:3\nParse error on line 2:\n  default\n--^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'DEFAULT'",
  ),
  (
    "block\n  accTitle: t\n  a", "error syntax 2:3\nParse error on line 2:\n  accTitle: t\n--^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'acc_title'",
  ),
  (
    "block\n  a --> b --> c -- \"x\" --> d", "ok\nroot columns=-1\n  a na \"a\"\n  b na \"b\"\n  c na \"c\"\n  d na \"d\"\nedge 1-a-b a->b \"\" arrow_open arrow_point normal solid\nedge 1-b-c b->c \"\" arrow_open arrow_point normal solid\nedge 1-c-d c->d \"x\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  a b\n  a[\"Named\"]\n  b((\"x\")) --> a", "ok\nroot columns=-1\n  a square \"Named\" span=1\n  b circle \"x\" span=1\nedge 1-b-a b->a \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  root leaf\n  root --> leaf", "ok\nroot columns=-1\n  root na \"root\" span=1\n  leaf na \"leaf\" span=1\nedge 1-root-leaf root->leaf \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  a space:2\n  block\n    b\n  end", "ok\nroot columns=-1\n  a na \"a\" span=1\n  id-1-0 space \"id-1\" width=2\n  id-1-1 space \"id-1\" width=2\n  id-2 composite \"\" color=0\n    b na \"b\" span=1",
  ),
  (
    "block\n  a:2 --> b", "ok\nroot columns=-1\n  a na \"a\"\n  b na \"b\"\nedge 1-a-b a->b \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  block:A --> B --> C\n  D\n  end\n  E --> F --> G", "ok\nroot columns=-1\n  id-2 composite \"\" color=0\n    D na \"D\" span=1\n  E na \"E\"\n  F na \"F\"\n  G na \"G\"\nedge 1-E-F E->F \"\" arrow_open arrow_point normal solid\nedge 1-F-G F->G \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  block\n  A --> B --> C\n  end", "ok\nroot columns=-1\n  id-1 composite \"\" color=0\n    A na \"A\"\n    B na \"B\"\n    C na \"C\"\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid\nedge 1-B-C B->C \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  block\n  A --> B --> C\n  D\n  end", "ok\nroot columns=-1\n  id-1 composite \"\" color=0\n    A na \"A\"\n    B na \"B\"\n    C na \"C\"\n    D na \"D\" span=1\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid\nedge 1-B-C B->C \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  block:g[\"Title\"]:3\n  a\n  end", "ok\nroot columns=-1\n  g composite \"Title\" span=3 color=0\n    a na \"a\" span=1",
  ),
  (
    "block\n  block:g(\"Round\")\n  a\n  end", "ok\nroot columns=-1\n  g composite \"Round\" span=1 color=0\n    a na \"a\" span=1",
  ),
  (
    "block\n  block:\n  a\n  end", "error syntax 4:3\nParse error on line 4:\n  end\n--^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "block\n  block:g\n  end", "error syntax 3:3\nParse error on line 3:\n  end\n--^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "block\n  block:g", "error syntax 2:10\nParse error on line 2:\n  block:g\n---------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'EOF'",
  ),
  (
    "block\n  block\n  block\n  a\n  end", "error syntax 5:6\nParse error on line 5:\n  end\n-----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'EOF'",
  ),
  (
    "block\n  columns 3\n  a b:3 c\n  columns 2", "ok\nroot columns=2\n  a na \"a\" span=1\n  b na \"b\" span=3\n  c na \"c\" span=1",
  ),
  (
    "block\n  a<[\"x\"]>(right) b<[\"y\"]>(up, down) c<[\"z\"]>( x , y )", "ok\nroot columns=-1\n  a block_arrow \"x\" span=1 dirs=right\n  b block_arrow \"y\" span=1 dirs=up|down\n  c block_arrow \"z\" span=1 dirs= x |y ",
  ),
  (
    "block\n  a<[\"x\"]>()", "error syntax 2:12\nParse error on line 2:\n  a<[\"x\"]>()\n-----------^\nExpecting 'DIR', got 'BLOCK_ARROW_END'",
  ),
  (
    "block\n  a -- \"x\" --> b\n  a == \"y\" ==> b\n  a -. \"z\" .-> b", "ok\nroot columns=-1\n  a na \"a\"\n  b na \"b\"\nedge 1-a-b a->b \"x\" arrow_open arrow_point normal solid\nedge 2-a-b a->b \"y\" arrow_open arrow_point thick solid\nedge 3-a-b a->b \"z\" arrow_open arrow_point normal dotted",
  ),
  (
    "block\n  a -- \"x\" b", "error syntax 2:11\nLexical error on line 2. Unrecognized text.\n  a -- \"x\" b\n----------^",
  ),
  (
    "block\n  a --", "error syntax 2:7\nParse error on line 2:\n  a --\n------^\nExpecting 'LINK_LABEL', got '$end'",
  ),
  (
    "block\n  a -->", "error syntax 2:8\nParse error on line 2:\n  a -->\n-------^\nExpecting 'NODE_ID', got 'EOF'",
  ),
  (
    "block\n  a --> b[\"x\"]:2", "error syntax 2:15\nParse error on line 2:\n  a --> b[\"x\"]:2\n--------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'SIZE'",
  ),
  (
    "block\n  classDef hot fill:#f96\n  class a,b hot\n  style a fill:red\n  a b",
    "ok\nroot columns=-1\n  a na \"a\" span=1 classes=hot styles=fill:red\n  b na \"b\" span=1 classes=hot\nclass hot styles=[fill:#f96] text=[]",
  ),
  (
    "block\n  classDef\n  a", "error syntax 3:3\nLexical error on line 3. Unrecognized text.\n  a\n--^",
  ),
  ("block\n  class a\n  b", "ok\nroot columns=-1\n  b na \"b\" span=1"),
  ("block\n  style a\n  b", "ok\nroot columns=-1\n  b na \"b\" span=1"),
  (
    "block\n  classDef DEFAULT fill:red\n  a", "error syntax 2:12\nParse error on line 2:\n  classDef DEFAULT fill:red\n-----------^\nExpecting 'CLASSDEF_ID', got 'DEFAULT_CLASSDEF_ID'",
  ),
  (
    "block\n  \"x\"", "error syntax 2:4\nParse error on line 2:\n  \"x\"\n---^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'STR'",
  ),
  ("block\n  a[\"x\"]", "ok\nroot columns=-1\n  a square \"x\" span=1"),
  (
    "block\n  a[\"`x`\"]", "error syntax 2:7\nParse error on line 2:\n  a[\"`x`\"]\n------^\nExpecting 'STR', got 'MD_STR'",
  ),
  (
    "block\n  a([\"x\"]) b[[\"x\"]] c[(\"x\")] d((\"x\")) e(((\"x\"))) f>\"x\"] g{\"x\"} h{{\"x\"}} i[/\"x\"/] j[\\\"x\"\\] k[/\"x\"\\] l[\\\"x\"/] m(\"x\"]",
    "ok\nroot columns=-1\n  a stadium \"x\" span=1\n  b subroutine \"x\" span=1\n  c cylinder \"x\" span=1\n  d circle \"x\" span=1\n  e doublecircle \"x\" span=1\n  f rect_left_inv_arrow \"x\" span=1\n  g diamond \"x\" span=1\n  h hexagon \"x\" span=1\n  i lean_right \"x\" span=1\n  j lean_left \"x\" span=1\n  k trapezoid \"x\" span=1\n  l inv_trapezoid \"x\" span=1\n  m na \"x\" span=1",
  ),
  (
    "block\n  a(-\"x\"-) b[|\"x\"]", "ok\nroot columns=-1\n  a na \"x\" span=1\n  b na \"x\" span=1",
  ),
  (
    "block\n  space:0 space:3 space", "ok\nroot columns=-1\n  id-2-0 space \"id-2\" width=3\n  id-2-1 space \"id-2\" width=3\n  id-2-2 space \"id-2\" width=3\n  id-3-0 space \"id-3\" width=1",
  ),
  (
    "block\n  a space:100001 b", "error limit 0:0\nA block diagram can hold at most 100000 space blocks.",
  ),
  (
    "block\n  a:0 b:00 c", "ok\nroot columns=-1\n  a na \"a\" span=0\n  b na \"b\" span=0\n  c na \"c\" span=1",
  ),
  ("block\n  columns 0\n  a", "ok\nroot columns=0\n  a na \"a\" span=1"),
  (
    "block\n  columns 99999999999999999999\n  a b", "ok\nroot columns=100000000000000000000\n  a na \"a\" span=1\n  b na \"b\" span=1",
  ),
  (
    "block\n  block:g:99999999\n  a\n  end\n  b", "ok\nroot columns=-1\n  g composite \"\" span=99999999 color=0\n    a na \"a\" span=1\n  b na \"b\" span=1",
  ),
  ("block-beta\n  a", "ok\nroot columns=-1\n  a na \"a\" span=1"),
  (
    "block-beta", "error syntax 1:11\nParse error on line 1:\nblock-beta\n----------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'EOF'",
  ),
  (
    "block block\n a end end", "error syntax 2:8\nParse error on line 2:\n a end end\n-------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "block\n a end", "error syntax 2:4\nParse error on line 2:\n a end\n---^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "block\n  a\n  block:a\n  b\n  end", "ok\nroot columns=-1\n  a composite \"\" span=1",
  ),
  (
    "block\n  id-1 space", "error syntax 2:5\nLexical error on line 2. Unrecognized text.\n  id-1 space\n----^",
  ),
  (
    "when parsing a block diagram graph it should handle > ", "error syntax 1:1\nParse error on line 1:\nwhen parsing a block diagram graph it should handle > \n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n          id\n      ", "ok\nroot columns=-1\n  id na \"id\" span=1",
  ),
  (
    "block\n          id[\"A label\"]\n          ", "ok\nroot columns=-1\n  id square \"A label\" span=1",
  ),
  (
    "block\n          id[\"<b>Bold</b>\"]\n          ", "ok\nroot columns=-1\n  id square \"<b>Bold</b>\" span=1",
  ),
  (
    "block\n          id1\n          id2\n      ", "ok\nroot columns=-1\n  id1 na \"id1\" span=1\n  id2 na \"id2\" span=1",
  ),
  (
    "block\n          id1\n          id2\n          id3\n      ", "ok\nroot columns=-1\n  id1 na \"id1\" span=1\n  id2 na \"id2\" span=1\n  id3 na \"id3\" span=1",
  ),
  (
    "block\n          id[\"A label\"]\n          id2", "ok\nroot columns=-1\n  id square \"A label\" span=1\n  id2 na \"id2\" span=1",
  ),
  (
    "block\n          id1[\"first\"]  -->   id2[\"second\"]\n      ", "ok\nroot columns=-1\n  id1 square \"first\"\n  id2 square \"second\"\nedge 1-id1-id2 id1->id2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n          id1[\"first\"]  -- \"a label\" -->   id2[\"second\"]\n      ",
    "ok\nroot columns=-1\n  id1 square \"first\"\n  id2 square \"second\"\nedge 1-id1-id2 id1->id2 \"a label\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n          columns 2\n          block1[\"Block 1\"]\n      ", "ok\nroot columns=2\n  block1 square \"Block 1\" span=1",
  ),
  (
    "block\n          block1[\"Block 1\"]\n      ", "ok\nroot columns=-1\n  block1 square \"Block 1\" span=1",
  ),
  (
    "block\n          columns auto\n          block1[\"Block 1\"]\n      ", "ok\nroot columns=-1\n  block1 square \"Block 1\" span=1",
  ),
  (
    "blocks next to each other", "error syntax 1:1\nParse error on line 1:\nblocks next to each other\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          columns 2\n          block1[\"Block 1\"]\n          block2[\"Block 2\"]\n        ",
    "ok\nroot columns=2\n  block1 square \"Block 1\" span=1\n  block2 square \"Block 2\" span=1",
  ),
  (
    "blocks on top of each other", "error syntax 1:1\nParse error on line 1:\nblocks on top of each other\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          columns 1\n          block1[\"Block 1\"]\n          block2[\"Block 2\"]\n        ",
    "ok\nroot columns=1\n  block1 square \"Block 1\" span=1\n  block2 square \"Block 2\" span=1",
  ),
  (
    "compound blocks 2", "error syntax 1:1\nParse error on line 1:\ncompound blocks 2\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          block\n            aBlock[\"ABlock\"]\n            bBlock[\"BBlock\"]\n          end\n        ",
    "ok\nroot columns=-1\n  id-1 composite \"\" color=0\n    aBlock square \"ABlock\" span=1\n    bBlock square \"BBlock\" span=1",
  ),
  (
    "compound blocks of compound blocks", "error syntax 1:1\nParse error on line 1:\ncompound blocks of compound blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          block\n            aBlock[\"ABlock\"]\n            block\n              bBlock[\"BBlock\"]\n            end\n          end\n        ",
    "ok\nroot columns=-1\n  id-2 composite \"\" color=0\n    aBlock square \"ABlock\" span=1\n    id-1 composite \"\" color=1\n      bBlock square \"BBlock\" span=1",
  ),
  (
    "compound blocks with title", "error syntax 1:1\nParse error on line 1:\ncompound blocks with title\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          block:compoundBlock[\"Compound block\"]\n            columns 1\n            block2[\"Block 2\"]\n          end\n        ",
    "ok\nroot columns=-1\n  compoundBlock composite \"Compound block\" span=1 columns=1 color=0\n    block2 square \"Block 2\" span=1",
  ),
  (
    "Compound block", "error syntax 1:1\nParse error on line 1:\nCompound block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block2", "error syntax 1:1\nParse error on line 1:\nblock2\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blocks mixed with compound blocks", "error syntax 1:1\nParse error on line 1:\nblocks mixed with compound blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          columns 1\n          block1[\"Block 1\"]\n\n          block\n            columns 2\n            block2[\"Block 2\"]\n            block3[\"Block 3\"]\n          end\n        ",
    "ok\nroot columns=1\n  block1 square \"Block 1\" span=1\n  id-1 composite \"\" columns=2 color=0\n    block2 square \"Block 2\" span=1\n    block3 square \"Block 3\" span=1",
  ),
  (
    "Arrow blocks", "error syntax 1:1\nParse error on line 1:\nArrow blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        columns 3\n        block1[\"Block 1\"]\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(right)\n        block2[\"Block 2\"]",
    "ok\nroot columns=3\n  block1 square \"Block 1\" span=1\n  blockArrow block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=right\n  block2 square \"Block 2\" span=1",
  ),
  (
    "block1", "error syntax 1:1\nParse error on line 1:\nblock1\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blockArrow", "error syntax 1:1\nParse error on line 1:\nblockArrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block_arrow", "error syntax 1:1\nParse error on line 1:\nblock_arrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "Arrow blocks with multiple points", "error syntax 1:1\nParse error on line 1:\nArrow blocks with multiple points\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        columns 1\n        A\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n          columns 3\n            B\n            C\n            D\n        end",
    "ok\nroot columns=1\n  A na \"A\" span=1\n  blockArrow block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=up|down\n  id-1 composite \"\" columns=3 color=0\n    B na \"B\" span=1\n    C na \"C\" span=1\n    D na \"D\" span=1",
  ),
  (
    "blocks with different widths", "error syntax 1:1\nParse error on line 1:\nblocks with different widths\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        columns 3\n        one[\"One Slot\"]\n        two[\"Two slots\"]:2\n        ",
    "ok\nroot columns=3\n  one square \"One Slot\" span=1\n  two square \"Two slots\" span=2",
  ),
  (
    "empty blocks", "error syntax 1:1\nParse error on line 1:\nempty blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        columns 3\n        space\n        middle[\"In the middle\"]\n        space\n        ",
    "ok\nroot columns=3\n  id-1-0 space \"id-1\" width=1\n  middle square \"In the middle\" span=1\n  id-2-0 space \"id-2\" width=1",
  ),
  (
    "classDef statements applied to a block", "error syntax 1:1\nParse error on line 1:\nclassDef statements applied to a block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'classDef'",
  ),
  (
    "block\n        classDef black color:#ffffff, fill:#000000;\n\n        mc[\"Memcache\"]\n        class mc black\n        ",
    "ok\nroot columns=-1\n  mc square \"Memcache\" span=1 classes=black\nclass black styles=[color:#ffffff|fill:#000000] text=[fill:#ffffff]",
  ),
  (
    "style statements applied to a block", "error syntax 1:1\nParse error on line 1:\nstyle statements applied to a block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'style'",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B fill:#f9F,stroke:#333,stroke-width:4px\n        ",
    "ok\nroot columns=1\n  B square \"A wide one in the middle\" span=1 styles=fill:#f9F|stroke:#333|stroke-width:4px",
  ),
  (
    "should log a warning when block width exceeds column width", "error syntax 1:1\nParse error on line 1:\nshould log a warning when block width exceeds column width\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n  columns 1\n  A:1\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2\n  G:1", "ok\nroot columns=1\n  A na \"A\" span=1\n  B na \"B\" span=2\n  C na \"C\" span=3\n  D na \"D\" span=4\n  E na \"E\" span=3\n  F na \"F\" span=2\n  G na \"G\" span=1",
  ),
  (
    "block\n${prop}", "error syntax 2:3\nLexical error on line 2. Unrecognized text.\n${prop}\n--^",
  ),
  (
    "block\nA; classDef ${prop} color:#ffffff,fill:#000000; class A ${prop}", "error syntax 2:13\nLexical error on line 2. Unrecognized text.\nA; classDef ${prop} color:#ffffff,fill:#000000; class A ${prop}\n------------^",
  ),
  (
    "block colour slots", "ok\nroot columns=-1\n  colour na \"colour\" span=1\n  slots na \"slots\" span=1",
  ),
  (
    "block-beta\n      block:first\n        a\n      end\n      block:second\n        b\n      end\n      block:third\n        c\n      end\n    ",
    "ok\nroot columns=-1\n  first composite \"\" span=1 color=0\n    a na \"a\" span=1\n  second composite \"\" span=1 color=1\n    b na \"b\" span=1\n  third composite \"\" span=1 color=2\n    c na \"c\" span=1",
  ),
  (
    "gives no slot to a simple block", "error syntax 1:1\nParse error on line 1:\ngives no slot to a simple block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      a\n      b\n      block:group\n        c\n      end\n    ",
    "ok\nroot columns=-1\n  a na \"a\" span=1\n  b na \"b\" span=1\n  group composite \"\" span=1 color=0\n    c na \"c\" span=1",
  ),
  (
    "block-beta\n      block:outer\n        block:inner\n          a\n        end\n      end\n      block:sibling\n        b\n      end\n    ",
    "ok\nroot columns=-1\n  outer composite \"\" span=1 color=0\n    inner composite \"\" span=1 color=1\n      a na \"a\" span=1\n  sibling composite \"\" span=1 color=2\n    b na \"b\" span=1",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n      end\n      block:b1\n        block:b2\n          y\n        end\n      end\n    ",
    "ok\nroot columns=-1\n  a1 composite \"\" span=1 color=0\n    a2 composite \"\" span=1 color=1\n      x na \"x\" span=1\n  b1 composite \"\" span=1 color=2\n    b2 composite \"\" span=1 color=3\n      y na \"y\" span=1",
  ),
  (
    "block db edge styles", "ok\nroot columns=-1\n  db na \"db\" span=1\n  edge na \"edge\" span=1\n  styles na \"styles\" span=1",
  ),
  (
    "block db runtime config", "ok\nroot columns=-1\n  db na \"db\" span=1\n  runtime na \"runtime\" span=1\n  config na \"config\" span=1",
  ),
  (
    "should read block.padding from config at call time, not at import time", "error syntax 1:1\nParse error on line 1:\nshould read block.padding from config at call time, not at import time\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#969,stroke:#333,stroke-width:4px\n",
    "ok\nroot columns=1\n  db circle \"DB\" span=1\n  blockArrowId6 block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=down\n  ID composite \"\" span=1 color=0\n    A na \"A\" span=1\n    B square \"A wide one in the middle\" span=1 styles=fill:#969|stroke:#333|stroke-width:4px\n    C na \"C\" span=1\n  id-2-0 space \"id-2\" width=1\n  D na \"D\" span=1\nedge 1-ID-D ID->D \"\" arrow_open arrow_point normal solid\nedge 1-C-D C->D \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  a b c\n", "ok\nroot columns=-1\n  a na \"a\" span=1\n  b na \"b\" span=1\n  c na \"c\" span=1",
  ),
  (
    "block\n  columns 3\n  a b c d\n", "ok\nroot columns=3\n  a na \"a\" span=1\n  b na \"b\" span=1\n  c na \"c\" span=1\n  d na \"d\" span=1",
  ),
  (
    "block\n  columns 3\n  a[\"A label\"] b:2 c:2 d\n", "ok\nroot columns=3\n  a square \"A label\" span=1\n  b na \"b\" span=2\n  c na \"c\" span=2\n  d na \"d\" span=1",
  ),
  (
    "block\n    block\n      D\n    end\n    A[\"A: I am a wide one\"]\n", "ok\nroot columns=-1\n  id-1 composite \"\" color=0\n    D na \"D\" span=1\n  A square \"A: I am a wide one\" span=1",
  ),
  (
    "block\n  columns 3\n  a:3\n  block:group1:2\n    columns 2\n    h i j k\n  end\n  g\n  block:group2:3\n    %% columns auto (default)\n    l m n o p q r\n  end\n",
    "error syntax 10:21\nParse error on line 10:\n    %% columns auto (default)\n--------------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'NODE_DSTART'",
  ),
  (
    "block\n  block\n    columns 1\n    a[\"A label\"] b c d\n  end\n", "ok\nroot columns=-1\n  id-1 composite \"\" columns=1 color=0\n    a square \"A label\" span=1\n    b na \"b\" span=1\n    c na \"c\" span=1\n    d na \"d\" span=1",
  ),
  (
    "block\n    id1(\"This is the text in the box\")\n", "ok\nroot columns=-1\n  id1 round \"This is the text in the box\" span=1",
  ),
  (
    "block\n    id1([\"This is the text in the box\"])\n", "ok\nroot columns=-1\n  id1 stadium \"This is the text in the box\" span=1",
  ),
  (
    "block\n    id1[[\"This is the text in the box\"]]\n", "ok\nroot columns=-1\n  id1 subroutine \"This is the text in the box\" span=1",
  ),
  (
    "block\n    id1[(\"Database\")]\n", "ok\nroot columns=-1\n  id1 cylinder \"Database\" span=1",
  ),
  (
    "block\n    id1((\"This is the text in the circle\"))\n", "ok\nroot columns=-1\n  id1 circle \"This is the text in the circle\" span=1",
  ),
  (
    "block\n  id1>\"This is the text in the box\"]\n", "ok\nroot columns=-1\n  id1 rect_left_inv_arrow \"This is the text in the box\" span=1",
  ),
  (
    "block\n    id1{\"This is the text in the box\"}\n", "ok\nroot columns=-1\n  id1 diamond \"This is the text in the box\" span=1",
  ),
  (
    "block\n    id1{{\"This is the text in the box\"}}\n", "ok\nroot columns=-1\n  id1 hexagon \"This is the text in the box\" span=1",
  ),
  (
    "block\n  id1[/\"This is the text in the box\"/]\n  id2[\\\"This is the text in the box\"\\]\n  A[/\"Christmas\"\\]\n  B[\\\"Go shopping\"/]\n",
    "ok\nroot columns=-1\n  id1 lean_right \"This is the text in the box\" span=1\n  id2 lean_left \"This is the text in the box\" span=1\n  A trapezoid \"Christmas\" span=1\n  B inv_trapezoid \"Go shopping\" span=1",
  ),
  (
    "block\n    id1(((\"This is the text in the circle\")))\n", "ok\nroot columns=-1\n  id1 doublecircle \"This is the text in the circle\" span=1",
  ),
  (
    "block\n  blockArrowId<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"Label\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "ok\nroot columns=-1\n  blockArrowId block_arrow \"Label\" span=1 dirs=right\n  blockArrowId2 block_arrow \"Label\" span=1 dirs=left\n  blockArrowId3 block_arrow \"Label\" span=1 dirs=up\n  blockArrowId4 block_arrow \"Label\" span=1 dirs=down\n  blockArrowId5 block_arrow \"Label\" span=1 dirs=x\n  blockArrowId6 block_arrow \"Label\" span=1 dirs=y\n  blockArrowId7 block_arrow \"Label\" span=1 dirs=x|down",
  ),
  (
    "block\n  columns 3\n  a space b\n  c   d   e\n", "ok\nroot columns=3\n  a na \"a\" span=1\n  id-1-0 space \"id-1\" width=1\n  b na \"b\" span=1\n  c na \"c\" span=1\n  d na \"d\" span=1\n  e na \"e\" span=1",
  ),
  (
    "block\n  ida space:3 idb idc\n", "ok\nroot columns=-1\n  ida na \"ida\" span=1\n  id-1-0 space \"id-1\" width=3\n  id-1-1 space \"id-1\" width=3\n  id-1-2 space \"id-1\" width=3\n  idb na \"idb\" span=1\n  idc na \"idc\" span=1",
  ),
  (
    "block\n  A space B\n  A-->B\n", "ok\nroot columns=-1\n  A na \"A\" span=1\n  id-1-0 space \"id-1\" width=1\n  B na \"B\" span=1\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  A space:2 B\n  A-- \"X\" -->B\n", "ok\nroot columns=-1\n  A na \"A\" span=1\n  id-1-0 space \"id-1\" width=2\n  id-1-1 space \"id-1\" width=2\n  B na \"B\" span=1\nedge 1-A-B A->B \"X\" arrow_open arrow_point normal solid",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:#333,stroke-width:4px\n",
    "ok\nroot columns=1\n  db circle \"DB\" span=1\n  blockArrowId6 block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=down\n  ID composite \"\" span=1 color=0\n    A na \"A\" span=1\n    B square \"A wide one in the middle\" span=1 styles=fill:#939|stroke:#333|stroke-width:4px\n    C na \"C\" span=1\n  id-2-0 space \"id-2\" width=1\n  D na \"D\" span=1\nedge 1-ID-D ID->D \"\" arrow_open arrow_point normal solid\nedge 1-C-D C->D \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"Stop\")\n  style id1 fill:#636,stroke:#333,stroke-width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  id1 round \"Start\" span=1 styles=fill:#636|stroke:#333|stroke-width:4px\n  id-1-0 space \"id-1\" width=1\n  id2 round \"Stop\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:#fff|stroke-dasharray: 5 5\nedge 1-id1-id2 id1->id2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:4px;\n  class A blue\n  style B fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  A na \"A\" span=1 classes=blue\n  id-1-0 space \"id-1\" width=1\n  B na \"B\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:#fff|stroke-dasharray: 5 5\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid\nclass blue styles=[fill:#6e6ce6|stroke:#333|stroke-width:4px] text=[]",
  ),
  (
    "block\n  columns 3\n  Frontend blockArrowId6<[\" \"]>(right) Backend\n  space:2 down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,stroke:#333;\n  classDef back fill:#969,stroke:#333;\n  class Frontend front\n  class Backend,Database back\n",
    "ok\nroot columns=3\n  Frontend na \"Frontend\" span=1 classes=front\n  blockArrowId6 block_arrow \" \" span=1 dirs=right\n  Backend na \"Backend\" span=1 classes=back\n  id-1-0 space \"id-1\" width=2\n  id-1-1 space \"id-1\" width=2\n  down block_arrow \" \" span=1 dirs=down\n  Disk na \"Disk\" span=1\n  left block_arrow \" \" span=1 dirs=left\n  Database cylinder \"Database\" span=1 classes=back\nclass front styles=[fill:#696|stroke:#333] text=[]\nclass back styles=[fill:#969|stroke:#333] text=[]",
  ),
  (
    "block\n  columns 3\n  Start((\"Start\")) space:2\n  down<[\" \"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(right) Process1[\"Process A\"]\n  downAgain<[\"No\"]>(down) space r3<[\"Done\"]>(down)\n  Process2[\"Process B\"] r2<[\"Done\"]>(right) End((\"End\"))\n\n  style Start fill:#969;\n  style End fill:#696;\n",
    "ok\nroot columns=3\n  Start circle \"Start\" span=1 styles=fill:#969;\n  id-1-0 space \"id-1\" width=2\n  id-1-1 space \"id-1\" width=2\n  down block_arrow \" \" span=1 dirs=down\n  id-2-0 space \"id-2\" width=2\n  id-2-1 space \"id-2\" width=2\n  Decision hexagon \"Make Decision\" span=1\n  right block_arrow \"Yes\" span=1 dirs=right\n  Process1 square \"Process A\" span=1\n  downAgain block_arrow \"No\" span=1 dirs=down\n  id-3-0 space \"id-3\" width=1\n  r3 block_arrow \"Done\" span=1 dirs=down\n  Process2 square \"Process B\" span=1\n  r2 block_arrow \"Done\" span=1 dirs=right\n  End circle \"End\" span=1 styles=fill:#696;",
  ),
  (
    "block\n  A space B\n  A --> B\n", "ok\nroot columns=-1\n  A na \"A\" span=1\n  id-1-0 space \"id-1\" width=1\n  B na \"B\" span=1\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid",
  ),
  (
    "  block\n    A\n    style A fill#969;\n", "ok\nroot columns=-1\n  A na \"A\" span=1 styles=fill#969;",
  ),
  (
    "block\n  A\n  style A fill:#969,stroke:#333;\n\n", "ok\nroot columns=-1\n  A na \"A\" span=1 styles=fill:#969|stroke:#333;",
  ),
  (
    "compound <blocks with title", "error syntax 1:1\nParse error on line 1:\ncompound <blocks with title\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  blockArrowId<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"Label\"]>(x)\n <-- blockArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "error syntax 7:6\nLexical error on line 7. Unrecognized text.\n <-- blockArrowId6<[\"Label\"]>(y)\n-----^",
  ),
  (
    "block\n  id1>\"Th is the text in the box\"]\n", "ok\nroot columns=-1\n  id1 rect_left_inv_arrow \"Th is the text in the box\" span=1",
  ),
  (
    "should read block.padding from concks with diffefig at call time,-> not at import time",
    "error syntax 1:1\nParse error on line 1:\nshould read block.padding from concks with diffefig at call time,-> not at import time\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bl\n          block1[\"Block 1\"]lock\n  \n      ", "error syntax 1:1\nParse error on line 1:\nbl\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    iid1((\"This is the text in the circle\"))\n", "ok\nroot columns=-1\n  iid1 circle \"This is the text in the circle\" span=1",
  ),
  (
    "bc,", "error syntax 1:1\nParse error on line 1:\nbc,\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "erentblock db edge styles", "error syntax 1:1\nParse error on line 1:\nerentblock db edge styles\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n <[\"x\"]>(x,y) A\n  style A fill:#969,stroke:#333;\n\n", "error syntax 2:2\nParse error on line 2:\n <[\"x\"]>(x,y) A\n-^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'BLOCK_ARROW_START'",
  ),
  (
    "block colou slots", "ok\nroot columns=-1\n  colou na \"colou\" span=1\n  slots na \"slots\" span=1",
  ),
  (
    "block\n          id1)            id2\n          id3\n     -.- ", "error syntax 2:15\nLexical error on line 2. Unrecognized text.\n          id1)            id2\n--------------^",
  ),
  (
    "block    A\n \n  columns 3\n  a:3\n  block:group1:2\n    columns 2\n    h i j k\n  end\n  g\n  block:gr==>up2:3\n    %% columns auto (default)\n    l m  p q r\n  end\n",
    "error syntax 10:17\nParse error on line 10:\n  block:gr==>up2:3\n----------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'SIZE'",
  ),
  (
    "block-beta\n        block1[ block:a1\n        block:a2\n          x\n        end\n      end\n      block:b1\n      block:b2\n          y\n        end\n      end\n    ",
    "error syntax 2:16\nLexical error on line 2. Unrecognized text.\n        block1[ block:a1\n---------------^",
  ),
  (
    "block\n  A space:2 By\n  A--ck1[\"Bl \"X\" -->B\n", "error syntax 3:6\nLexical error on line 3. Unrecognized text.\n  A--ck1[\"Bl \"X\" -->B\n-----^",
  ),
  (
    "blo)))ck\n          id1\n          id2\n          id3\n      ", "error syntax 1:1\nParse error on line 1:\nblo)))ck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"Stop\")\n  style id1 fill:#636{\"x\"}stroke:#333,stroke-width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,strokeke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  id1 round \"Start\" span=1 styles=fill:#636{\"x\"}stroke:#333|stroke-width:4px\n  id-1-0 space \"id-1\" width=1\n  id2 round \"Stop\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:#fff|strokeke-dasharray: 5 5\nedge 1-id1-id2 id1->id2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "blocks nt o each other", "error syntax 1:1\nParse error on line 1:\nblocks nt o each other\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        columns 3\n        one[\"One Slot\"]\n a b c d\n  <[\"x\"]>(right)      two[\"Two slots\"]:2\n        ",
    "ok\nroot columns=3\n  one square \"One Slot\" span=1\n  a na \"a\" span=1\n  b na \"b\" span=1\n  c na \"c\" span=1\n  d block_arrow \"x\" span=1 dirs=right\n  two square \"Two slots\" span=2",
  ),
  (
    "bloctime ck\n    id1[[\"This is the text in the box\"]]\n", "error syntax 1:1\nParse error on line 1:\nbloctime ck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    block\n      D\n    end\n    A[\"A: I am a wi,de one\"]\n", "ok\nroot columns=-1\n  id-1 composite \"\" color=0\n    D na \"D\" span=1\n  A square \"A: I am a wi,de one\" span=1",
  ),
  (
    "block\n  columns 3\n  Start((\"SclassDef a fill:#f96art\")) space:2\n  down<[\"\"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(right) Process1[\"Process A\"]\n  downAgain<[\"No\"]>(down) space r3<[\"Done\"]>(down)\n  Process2[\"Process B\"] r2<[\"Done\"]>(right) End((\"End\"))\n\n  style Start fill:#969;\n  style End fill:#696<[\"x\"]>(up, down);\n",
    "error syntax 4:14\nParse error on line 4:\n  down<[\"\"]>(down) space:2\n-------------^\nExpecting 'STR', got 'DIR'",
  ),
  (
    "blocks next to each\n othr", "error syntax 1:1\nParse error on line 1:\nblocks next to each\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\nA\n  style A fill:#969,stroke:#333;\n\n", "ok\nroot columns=-1\n  A na \"A\" span=1 styles=fill:#969|stroke:#333;",
  ),
  (
    "block\n          block\n            /]aBlock[\"ABlock\"]\n            bBlock[\"BBlock\"]\n          end\n        ",
    "ok\nroot columns=-1\n  id-1 composite \"\" color=0\n    /]aBlock square \"ABlock\" span=1\n    bBlock square \"BBlock\" span=1",
  ),
  (
    "should read (-block.padding from config at call time, not at import timock[\"BBlock\"]\n  e",
    "error syntax 1:1\nParse error on line 1:\nshould read (-block.padding from config at call time, not at import timock[\"BBlock\"]\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "ock:group\n  compound blocks 2", "error syntax 1:1\nParse error on line 1:\nock:group\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bl(-ock\n    id1[(\"Daask1[\"Block 1\"]\n    e\")]\n", "error syntax 1:1\nParse error on line 1:\nbl(-ock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  A sp/]ace:2 B.\n  A-- \"X\" -->B\naccDescr: d", "error syntax 4:1\nParse error on line 4:\naccDescr: d\n^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'acc_descr'",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the ddle\"]\n  style B fill:#f9F,stroke:#333stroke-width:4px\n        ",
    "ok\nroot columns=1\n  B square \"A wide one in the ddle\" span=1 styles=fill:#f9F|stroke:#333stroke-width:4px",
  ),
  (
    "block  b runtiime config", "ok\nroot columns=-1\n  b na \"b\" span=1\n  runtiime na \"runtiime\" span=1\n  config na \"config\" span=1",
  ),
  (
    "block\n    id1{\"This is the text in the box\"3\n  F}\n", "error syntax 2:38\nLexical error on line 2. Unrecognized text.\n    id1{\"This is the text in the box\"3\n-------------------------------------^",
  ),
  (
    "block\n     classDef black lor:#ffffff, fill:#000000;\n\n        mc[mcache\"]\n        class mc black\n        ",
    "error syntax 4:12\nLexical error on line 4. Unrecognized text.\n        mc[mcache\"]\n-----------^",
  ),
  (
    "block\n  columns 3\n  Start((\"Start\")) space:2\n  down<[\" \"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(right) Process1[\"Process A\"]\n  downAgain<[\"No\"]>(down) space r3<[\"Done\"]>(down)\n  Process2[\"Process B\"] r2<[\"Done\"]>(right) End((\"End\"))\n\n  style Start fill:#969;\n  le End fill:#696;\n",
    "error syntax 10:14\nLexical error on line 10. Unrecognized text.\n  le End fill:#696;\n-------------^",
  ),
  (
    "block\n  id1>\"This is the tee text in th box\"]\n", "ok\nroot columns=-1\n  id1 rect_left_inv_arrow \"This is the tee text in th box\" span=1",
  ),
  (
    "style statements applied to ainterpolate block", "error syntax 1:1\nParse error on line 1:\nstyle statements applied to ainterpolate block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'style'",
  ),
  (
    "block\n    id1{\"This is the texclass A, B at in the box\"}\n[\\\"x\"/]", "error syntax 3:1\nParse error on line 3:\n[\\\"x\"/]\n^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'NODE_DSTART'",
  ),
  (
    "block\ncolumns\n2  columns 3\n  a[\"A label\"] b:2 c:)))2 d\n", "error syntax 4:21\nLexical error on line 4. Unrecognized text.\n  a[\"A label\"] b:2 c:)))2 d\n--------------------^",
  ),
  (
    "Arrow blocks wit multiple pointsoints", "error syntax 1:1\nParse error on line 1:\nArrow blocks wit multiple pointsoints\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n--x    id1[(\"Database\")]\n", "error syntax 2:1\nParse error on line 2:\n--x    id1[(\"Database\")]\n^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'LINK'",
  ),
  (
    "block\n        columns 3\n  --o      block1[\"Block 1\"]\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>([\"Label\"]>(x)\n  bloright)\n        block2[\"Block 2\"]",
    "error syntax 3:3\nParse error on line 3:\n  --o      block1[\"Block 1\"]\n--^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'LINK'",
  ),
  (
    "ock\n    block\n      D\n    end\n    A[\"A: I am a wide one\"]\n", "error syntax 1:1\nParse error on line 1:\nock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          id1[\"first\"-->   id2[\"sesecond\"]\n      ", "error syntax 2:22\nLexical error on line 2. Unrecognized text.\n          id1[\"first\"-->   id2[\"sesecond\"]\n---------------------^",
  ),
  (
    "style sta<[\"x\"]>     block\n   (up, down)tements applied to a block", "error syntax 1:1\nParse error on line 1:\nstyle sta<[\"x\"]>     block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'style'",
  ),
  (
    "classDef statements applied toclass A,B aa bbaccTitle: tlock\nlock", "error syntax 1:1\nParse error on line 1:\nclassDef statements applied toclass A,B aa bbaccTitle: tlock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'classDef'",
  ),
  (
    "block\n  columns 3\n  a:3\n  block:group1:2\n    columns 2\n    h i j k\n  end\n  g\n  block:group2:3\n    %% columns aut\r\n (default)\n    l m n o p q r\n  end\n",
    "error syntax 11:3\nLexical error on line 11. Unrecognized text.\n (default)\n--^",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n      end    bl}ock:b1\n        block:b2\n ]         y\n        end\n      end\n    ",
    "error syntax 6:16\nLexical error on line 6. Unrecognized text.\n      end    bl}ock:b1\n---------------^",
  ),
  (
    "block\n    id1{{\"This--- is the t text in the box\"}}\n", "ok\nroot columns=-1\n  id1 hexagon \"This--- is the t text in the box\" span=1",
  ),
  (
    "block\n          id[\"A labeB\nl\"]\n   -.-       ", "error syntax 4:7\nParse error on line 4:\n   -.-       \n------^\nExpecting 'NODE_ID', got 'EOF'",
  ),
  (
    "block\n        columns 1\n        A\n        blockArrow<[\"&nbsp;& == \"x\" ==> bsclassDef DEFAULT x;&nbsp;\"]>(up, down)\n        block\n          columns 3\n            B\n            C\n           \n        end",
    "error syntax 4:34\nLexical error on line 4. Unrecognized text.\n        blockArrow<[\"&nbsp;& == \"x\" ==> bsclassDef DEFAULT x;&nbsp;\"]>(up, down)\n---------------------------------^",
  ),
  (
    " dia=block_arrow", "error syntax 1:2\nParse error on line 1:\n dia=block_arrow\n-^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  columns 3(\"x\")  a space b\n  c   d   e\n", "error syntax 2:12\nParse error on line 2:\n  columns 3(\"x\")  a space b\n-----------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'NODE_DSTART'",
  ),
  (
    "(((blocks on top of ch other", "error syntax 1:1\nParse error on line 1:\n(((blocks on top of ch other\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_DSTART'",
  ),
  (
    "blo -- \"x\" --> ks with different widths", "error syntax 1:1\nParse error on line 1:\nblo -- \"x\" --> ks with different widths\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          id1\n   c[\"Memcache\"]\n          id2\n      ", "ok\nroot columns=-1\n  id1 na \"id1\" span=1\n  c square \"Memcache\" span=1\n  id2 na \"id2\" span=1",
  ),
  (
    "block\n    id1[(\"Database\")]accTitle\n", "ok\nroot columns=-1\n  id1 cylinder \"Database\" span=1\n  accTitle na \"accTitle\" span=1",
  ),
  (
    "block\n    block\n      D\n    end\n    A[\"A: I am a wide onne\"]\n", "ok\nroot columns=-1\n  id-1 composite \"\" color=0\n    D na \"D\" span=1\n  A square \"A: I am a wide onne\" span=1",
  ),
  (
    "compoBlock 1\"]\n    und bloc2", "error syntax 1:1\nParse error on line 1:\ncompoBlock 1\"]\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "classDef steme applied to a block", "error syntax 1:1\nParse error on line 1:\nclassDef steme applied to a block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'classDef'",
  ),
  (
    "block\n          columns 1\n          block1[\"Block 1\"]\n\n          block\n            columns 2\n         block2[\"Block\n   lock 2\"]\n            block3lock 3\"]\n          end\n        ",
    "ok\nroot columns=1\n  block1 square \"Block 1\" span=1\n  id-1 composite \"\" columns=2 color=0\n    block2 square \"Block\n   lock 2\" span=1\n    block3lock na \"block3lock\" span=1\n    3\"] na \"3\"]\" span=1",
  ),
  (
    "blockbeta\n      block:outer]>\n        block:inner\n          a\n        end\n      end\n      block:sibling\n        b\n      end\n    ",
    "error syntax 1:1\nParse error on line 1:\nblockbeta\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:4px;\n  class A blue\n  style B fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5accDescr {}5\n",
    "ok\nroot columns=-1\n  A na \"A\" span=1 classes=blue\n  id-1-0 space \"id-1\" width=1\n  B na \"B\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:#fff|stroke-dasharray: 5accDescr {}5\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid\nclass blue styles=[fill:#6e6ce6|stroke:#333|stroke-width:4px] text=[]",
  ),
  (
    "block\n)))          id1\n          id2\n          i[\\\"x\"\\]3\n      ", "error syntax 2:1\nParse error on line 2:\n)))          id1\n^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'NODE_DSTART'",
  ),
  (
    "block end   A space B<-.->  A-->B\n", "error syntax 1:7\nParse error on line 1:\nblock end   A space B<-.->  A-->B\n------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "block<-.->\n  ida space:3 idb idc\n", "error syntax 1:6\nParse error on line 1:\nblock<-.->\n-----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'LINK'",
  ),
  (
    "gives no slot to t to a ple block", "error syntax 1:1\nParse error on line 1:\ngives no slot to t to a ple block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n   [|      [\\id\n      ", "error syntax 2:4\nParse error on line 2:\n   [|      [\\id\n---^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'NODE_DSTART'",
  ),
  (
    "block\n  blockArrowId<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n    blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"Label\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "ok\nroot columns=-1\n  blockArrowId block_arrow \"Label\" span=1 dirs=right\n  blockArrowId2 block_arrow \"Label\" span=1 dirs=left\n  blockArrowId3 block_arrow \"Label\" span=1 dirs=up\n  blockArrowId4 block_arrow \"Label\" span=1 dirs=down\n  blockArrowId5 block_arrow \"Label\" span=1 dirs=x\n  blockArrowId6 block_arrow \"Label\" span=1 dirs=y\n  blockArrowId7 block_arrow \"Label\" span=1 dirs=x|down",
  ),
  (
    "blockaccDescr: d\n          id1\n        B      id2\n          id3\n      ",
    "error syntax 1:1\nParse error on line 1:\nblockaccDescr: d\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    i  id1[(\"Database\")]\n", "ok\nroot columns=-1\n  i na \"i\" span=1\n  id1 cylinder \"Database\" span=1",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one i the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:#333,stroke-width:4px\n",
    "ok\nroot columns=1\n  db circle \"DB\" span=1\n  blockArrowId6 block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=down\n  ID composite \"\" span=1 color=0\n    A na \"A\" span=1\n    B square \"A wide one i the middle\" span=1 styles=fill:#939|stroke:#333|stroke-width:4px\n    C na \"C\" span=1\n  id-2-0 space \"id-2\" width=1\n  D na \"D\" span=1\nedge 1-ID-D ID->D \"\" arrow_open arrow_point normal solid\nedge 1-C-D C->D \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block-beta\n      block:outer\n        block:ier\n          a\n        end\n      end\n  olumns 3\n  a sp    block:sibling\n        b\n      enstyle A fill:#f96,stroke:#333\n    ",
    "error syntax 10:21\nLexical error on line 10. Unrecognized text.\n      enstyle A fill:#f96,stroke:#333\n--------------------^",
  ),
  (
    "block\n  id1[/\"This is the text in the box\"/]\n  id2[\\\"This is the text in the box\"\\]\n  A[/\"Christmas\"\\]\n  B[\\\"GaccDescr {}o shopping\"/]\n",
    "ok\nroot columns=-1\n  id1 lean_right \"This is the text in the box\" span=1\n  id2 lean_left \"This is the text in the box\" span=1\n  A trapezoid \"Christmas\" span=1\n  B inv_trapezoid \"GaccDescr {}o shopping\" span=1",
  ),
  (
    "blockc[[\"x\"<[]]k\n${prop}", "error syntax 1:1\nParse error on line 1:\nblockc[[\"x\"<[]]k\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        columns 3\n      -.->  one[\"One Slot\"]\n         tw o[\"Two slots\"]:2\n        ",
    "error syntax 3:7\nParse error on line 3:\n      -.->  one[\"One Slot\"]\n------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'LINK'",
  ),
  (
    "block\n    id1his is the text ine box\"}\n", "error syntax 2:32\nLexical error on line 2. Unrecognized text.\n    id1his is the text ine box\"}\n-------------------------------^",
  ),
  (
    "compound blocks\r\n 2", "error syntax 1:1\nParse error on line 1:\ncompound blocks\r\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    1(((\"This is the text in the B\ncircle\")))\n", "ok\nroot columns=-1\n  1 doublecircle \"This is the text in the B\ncircle\" span=1",
  ),
  (
    "block\nk\n    id1[(\"Data]]b(-se\")]\n", "ok\nroot columns=-1\n  k na \"k\" span=1\n  id1 cylinder \"Data]]b(-se\" span=1",
  ),
  (
    "block\n  i(-\"x\"-)da sp space:3 idb idc\n", "ok\nroot columns=-1\n  i na \"x\" span=1\n  da na \"da\" span=1\n  sp na \"sp\" span=1\n  id-1-0 space \"id-1\" width=3\n  id-1-1 space \"id-1\" width=3\n  id-1-2 space \"id-1\" width=3\n  idb na \"idb\" span=1\n  idc na \"idc\" span=1",
  ),
  (
    "block\n          id1\n          id2\n              id3\n      ", "ok\nroot columns=-1\n  id1 na \"id1\" span=1\n  id2 na \"id2\" span=1\n  id3 na \"id3\" span=1",
  ),
  (
    "block\n          columns 1\n       down   block1[\"Block 1\"]\n\n          block\n            columns 2\n            block2[\"Block 2\"]\n            block3[\"Block 3\"]\n          end\n        ",
    "ok\nroot columns=1\n  down na \"down\" span=1\n  block1 square \"Block 1\" span=1\n  id-1 composite \"\" columns=2 color=0\n    block2 square \"Block 2\" span=1\n    block3 square \"Block 3\" span=1",
  ),
  (
    "block\n    id1((\"This is the text istyle A,B x the circl`e\"))\n", "ok\nroot columns=-1\n  id1 circle \"This is the text istyle A,B x the circl`e\" span=1",
  ),
  (
    "blockpx\n        --rrow", "error syntax 1:1\nParse error on line 1:\nblockpx\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "b2:3\n  = %%A columlock db edge styles", "error syntax 1:1\nParse error on line 1:\nb2:3\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blo<[\"x\"]>(x,y)k db runtime config", "error syntax 1:1\nParse error on line 1:\nblo<[\"x\"]>(x,y)k db runtime config\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blcolumns 3\n  aock\nA; classDef ${prop} color:#ffffff,fill:#000000; class A ${prop}",
    "error syntax 1:1\nParse error on line 1:\nblcolumns 3\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "Arrow blocks w 3\n  a ith multiple pts", "error syntax 1:1\nParse error on line 1:\nArrow blocks w 3\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "em<[\"x\"]>(x,y)pty bllocks", "error syntax 1:1\nParse error on line 1:\nem<[\"x\"]>(x,y)pty bllocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          columns auto\n   [\\\"x\"/]     b\n        block1[\"Block 1\"]\n      ",
    "error syntax 3:4\nParse error on line 3:\n   [\\\"x\"/]     b\n---^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'NODE_DSTART'",
  ),
  (
    "should log a warng when[ block width exceeds colum width", "error syntax 1:1\nParse error on line 1:\nshould log a warng when[ block width exceeds colum width\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blockAckArrow", "error syntax 1:1\nParse error on line 1:\nblockAckArrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n  columns 1\n  A:1\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2right\n  G:1",
    "ok\nroot columns=1\n  A na \"A\" span=1\n  B na \"B\" span=2\n  C na \"C\" span=3\n  D na \"D\" span=4\n  E na \"E\" span=3\n  F na \"F\" span=2\n  right na \"right\" span=1\n  G na \"G\" span=1",
  ),
  (
    "blo\"\"ck\n  ida space:3 i idc\n", "error syntax 1:1\nParse error on line 1:\nblo\"\"ck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  c  columns 3\n  a:3\n  block:group1:2\n    columns 2\n    h i j k\n  end\n  g\n  block:group2:3\n    %% columns auto (default)\n    l mn o p q r\n  end\n",
    "error syntax 10:21\nParse error on line 10:\n    %% columns auto (default)\n--------------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'NODE_DSTART'",
  ),
  (
    "block\n          columns 2\n      dths    block1[\"Block 1\"]\n      ", "ok\nroot columns=2\n  dths na \"dths\" span=1\n  block1 square \"Block 1\" span=1",
  ),
  (
    "block\n  blockArrowId<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Lainterpolatebel\"]>(down)\n  blockArrowId5<[\"Label\n  a[\"A l\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "error syntax 7:6\nLexical error on line 7. Unrecognized text.\n  a[\"A l\"]>(x)\n-----^",
  ),
  (
    "block\n          id1[block\"first\"]  -->   id2[\"second\"]\n      ", "error syntax 2:15\nLexical error on line 2. Unrecognized text.\n          id1[block\"first\"]  -->   id2[\"second\"]\n--------------^",
  ),
  (
    "block\n          block\n            aBlok[\"ABlock\"]\n            block\n              bBlock[\"BBlock\"]\n            end\n          end\n        ",
    "ok\nroot columns=-1\n  id-2 composite \"\" color=0\n    aBlok square \"ABlock\" span=1\n    id-1 composite \"\" color=1\n      bBlock square \"BBlock\" span=1",
  ),
  (
    "sid1tyle statements applied to a blocA l", "error syntax 1:1\nParse error on line 1:\nsid1tyle statements applied to a blocA l\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  columns 3\n  Start((\"Start\")) space:2\n  down<[\" \"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(right) Process1[\"Process A\"]\n  downAgain<[\"No\"]>(down) space r3<[\"Done\"]>(down)\n  Process2[\"Process B\"] r2<[\"Done\"]>(right) En\"\"d((\"End\"))\n\n  style Start fill:#969;\n  style End fill:#696;\n",
    "ok\nroot columns=3\n  Start circle \"Start\" span=1 styles=fill:#969;\n  id-1-0 space \"id-1\" width=2\n  id-1-1 space \"id-1\" width=2\n  down block_arrow \" \" span=1 dirs=down\n  id-2-0 space \"id-2\" width=2\n  id-2-1 space \"id-2\" width=2\n  Decision hexagon \"Make Decision\" span=1\n  right block_arrow \"Yes\" span=1 dirs=right\n  Process1 square \"Process A\" span=1\n  downAgain block_arrow \"No\" span=1 dirs=down\n  id-3-0 space \"id-3\" width=1\n  r3 block_arrow \"Done\" span=1 dirs=down\n  Process2 square \"Process B\" span=1\n  r2 block_arrow \"Done\" span=1 dirs=right\n  En\"\"d circle \"End\" span=1",
  ),
  (
    "block-beta\n      block:first\n      a\n      end\n      block:second\n        b\n      end\n      block:third\n      &nbsp; \n      end\n    ",
    "ok\nroot columns=-1\n  first composite \"\" span=1 color=0\n    a na \"a\" span=1\n  second composite \"\" span=1 color=1\n    b na \"b\" span=1\n  third composite \"\" span=1 color=2\n    &nbsp; na \"&nbsp;\" span=1",
  ),
  (
    "bl:0k widt3ockkArrow", "error syntax 1:1\nParse error on line 1:\nbl:0k widt3ockkArrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "ives no slot to a simple blocklock", "error syntax 1:1\nParse error on line 1:\nives no slot to a simple blocklock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        columnblocks 3\n        one[\"One Slot\"]\n        two[\"Two slots\"]:2\n             ",
    "ok\nroot columns=-1\n  columnblocks na \"columnblocks\" span=1\n  3 na \"3\" span=1\n  one square \"One Slot\" span=1\n  two square \"Two slots\" span=2",
  ),
  (
    "block\n          id   id1\n  \"`        id2\n          id3\n      ", "error syntax 3:5\nParse error on line 3:\n  \"`        id2\n----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'MD_STR'",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  blo:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:#333,stroke-width:4px\n",
    "error syntax 5:6\nLexical error on line 5. Unrecognized text.\n  blo:ID\n-----^",
  ),
  (
    "block db edge stytatements appliles", "ok\nroot columns=-1\n  db na \"db\" span=1\n  edge na \"edge\" span=1\n  stytatements na \"stytatements\" span=1\n  appliles na \"appliles\" span=1",
  ),
  (
    "should log a warning when block width exceeds colum      bn width", "error syntax 1:1\nParse error on line 1:\nshould log a warning when block width exceeds colum      bn width\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bloc)]\n          id[\"<b>Bold</b>\"]\n          ", "error syntax 1:1\nParse error on line 1:\nbloc)]\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bloc{\"x\"}k\n  A space B\n  A-->B{", "error syntax 1:1\nParse error on line 1:\nbloc{\"x\"}k\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blocstyle A fill:#f96,stroke:#333k\n          id[\"A label\"]\n          id2",
    "error syntax 1:1\nParse error on line 1:\nblocstyle A fill:#f96,stroke:#333k\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n  comns 1\n  A:1\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2\n :1", "error syntax 9:2\nParse error on line 9:\n :1\n-^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'SIZE'",
  ),
  (
    "bloclinkStylekArow", "error syntax 1:1\nParse error on line 1:\nbloclinkStylekArow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    " block:b2\n        block\n    id1(defaultThis is the text in th box\")\n", "error syntax 1:2\nParse error on line 1:\n block:b2\n-^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'id-block'",
  ),
  (
    "n)\nompound blo  blblo=ck2", "error syntax 1:1\nParse error on line 1:\nn)\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n     [\\   block1[\"Block 1\"]\n      ", "error syntax 2:6\nParse error on line 2:\n     [\\   block1[\"Block 1\"]\n-----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'NODE_DSTART'",
  ),
  (
    "block-beta\n  columns   1\n  A:1\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2\n  G\"1",
    "ok\nroot columns=1\n  A na \"A\" span=1\n  B na \"B\" span=2\n  C na \"C\" span=3\n  D na \"D\" span=4\n  E na \"E\" span=3\n  F na \"F\" span=2\n  G\"1 na \"G\"1\" span=1",
  ),
  (
    "block\n          columns 1\n       block1[\"Block 1\"]\n          block2[\"Blockconstructor 2\"]\n        ",
    "ok\nroot columns=1\n  block1 square \"Block 1\" span=1\n  block2 square \"Blockconstructor 2\" span=1",
  ),
  (
    "blo{{ck\n          block1[\"Block 1\"]\n      ", "error syntax 1:1\nParse error on line 1:\nblo{{ck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n  columns 1\n  A:1\n\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2\n  G:1",
    "ok\nroot columns=1\n  A na \"A\" span=1\n  B na \"B\" span=2\n  C na \"C\" span=3\n  D na \"D\" span=4\n  E na \"E\" span=3\n  F na \"F\" span=2\n  G na \"G\" span=1",
  ),
  (
    "A[rro-->w cks", "error syntax 1:1\nParse error on line 1:\nA[rro-->w cks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        cendlumnkss 3\n        space\n       --> middle[\"In the middle\"]\n        space\n        ",
    "error syntax 4:8\nParse error on line 4:\n       --> middle[\"In the middle\"]\n-------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'LINK'",
  ),
  (
    "block\n          cols 1\n         #6e6c blblock1[\"Block 1\"]\n          block2[\"Block 2\"]\n        ",
    "ok\nroot columns=-1\n  cols na \"cols\" span=1\n  1 na \"1\" span=1\n  #6e6c na \"#6e6c\" span=1\n  blblock1 square \"Block 1\" span=1\n  block2 square \"Block 2\" span=1",
  ),
  (
    "block\n          id  A\n    style A[\"A label\"]\n          id__proto__", "ok\nroot columns=-1\n  id na \"id\" span=1\n  A na \"A\" span=1 styles=[\"A label\"]\n  id__proto__ na \"id__proto__\" span=1",
  ),
  (
    "block -db edge styles", "error syntax 1:7\nLexical error on line 1. Unrecognized text.\nblock -db edge styles\n------^",
  ),
  (
    "block\n    id1(((\"This ])is the text  the circle\")))\n", "ok\nroot columns=-1\n  id1 doublecircle \"This ])is the text  the circle\" span=1",
  ),
  (
    "block\n          id[\"A label\"]        i", "ok\nroot columns=-1\n  id square \"A label\" span=1\n  i na \"i\" span=1",
  ),
  (
    "bloo--ck-beta\n  columns 1\n  ==A:1\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2\n  G:1",
    "error syntax 1:1\nParse error on line 1:\nbloo--ck-beta\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"Stop\")\n  style id1 fill:#636,stroke:#333,stroke-width:4px\n  style id id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  id1 round \"Start\" span=1 styles=fill:#636|stroke:#333|stroke-width:4px\n  id-1-0 space \"id-1\" width=1\n  id2 round \"Stop\" span=1\nedge 1-id1-id2 id1->id2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "blocBlk\n          id[\"<b>Bold</b>\"]\n          ", "error syntax 1:1\nParse error on line 1:\nblocBlk\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "compound bwilocks with title", "error syntax 1:1\nParse error on line 1:\ncompound bwilocks with title\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bla bock\n >\"x\"]         id1[\"first\"]  --> id2[\"second\"]\n      ", "error syntax 1:1\nParse error on line 1:\nbla bock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "Arrowblock--os", "error syntax 1:1\nParse error on line 1:\nArrowblock--os\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blockAr", "error syntax 1:1\nParse error on line 1:\nblockAr\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\nA; classDef ${prop} color:#ffffff,fill:#000000; class A ${pr[|\"x\"]p}",
    "error syntax 2:13\nLexical error on line 2. Unrecognized text.\nA; classDef ${prop} color:#ffffff,fill:#000000; class A ${pr[|\"x\"]p}\n------------^",
  ),
  (
    "block\n  --oblockArrowIaccDescr {}<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"Label\"]>(x)\n  blockArrowId6<[\"Lbel\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "error syntax 2:3\nParse error on line 2:\n  --oblockArrowIaccDescr {}<[\"Label\"]>(right)\n--^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'LINK'",
  ),
  (
    "block db e styles", "ok\nroot columns=-1\n  db na \"db\" span=1\n  e na \"e\" span=1\n  styles na \"styles\" span=1",
  ),
  (
    "block\n accDescr: d       columns 3\n    ockArrow    classDef one[\"One Slot\"]\n        two[\"Two slots\"]:2\n        ",
    "error syntax 2:2\nParse error on line 2:\n accDescr: d       columns 3\n-^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'acc_descr'",
  ),
  (
    "block         classDef black color:#ffffff, fill:#000000;\n\n        mc[\"Memcache\"]\n        class mc bla(-ck\n     ",
    "ok\nroot columns=-1\n  mc square \"Memcache\" span=1 classes=bla(-ck\nclass black styles=[color:#ffffff|fill:#000000] text=[fill:#ffffff]",
  ),
  (
    "block\n  columns 3\n  Start((\"Start\")) space:2\n  down<[\" \"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(rht) Process1[\"Process A\"]\n  downAgain<[\"No\"]>(down) space r3<[\"Done\"]>(down)\n  [\\\"x\"/]Pros2[\"Process B\"] r2<[\"Done\"]>(right) End((\"End\"))\n\n  style Start fill:#969;\n  style End fill:#696;\n",
    "error syntax 5:46\nLexical error on line 5. Unrecognized text.\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(rht) Process1[\"Process A\"]\n---------------------------------------------^",
  ),
  (
    "block\n          id1         constructorid2\n          id3\n      ", "ok\nroot columns=-1\n  id1 na \"id1\" span=1\n  constructorid2 na \"constructorid2\" span=1\n  id3 na \"id3\" span=1",
  ),
  (
    "block\n    id1{\"This is thclass A ae text in the box\"}\n", "ok\nroot columns=-1\n  id1 diamond \"This is thclass A ae text in the box\" span=1",
  ),
  (
    "block-beta\n  columns 1\n  A:1:1\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2\n  G:1",
    "error syntax 3:6\nParse error on line 3:\n  A:1:1\n-----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'SIZE'",
  ),
  (
    "block\n  A\n  sty       le A fill:#969,stroke:#333;\n\n", "error syntax 3:22\nLexical error on line 3. Unrecognized text.\n  sty       le A fill:#969,stroke:#333;\n---------------------^",
  ),
  (
    "Arrow bl=right=ocks -- \"x\" --> ", "error syntax 1:1\nParse error on line 1:\nArrow bl=right=ocks -- \"x\" --> \n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "  block\n    A\n    s    style A fill#969;\n", "ok\nroot columns=-1\n  A na \"A\" span=1 styles=fill#969;\n  s na \"s\" span=1",
  ),
  (
    "c      columns 2lassDef statements applied to a block", "error syntax 1:1\nParse error on line 1:\nc      columns 2lassDef statements applied to a block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B f/]ill:#f9F,stroke:#333,stroke-width:4px\n      (-  ",
    "error syntax 5:7\nParse error on line 5:\n      (-  \n------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'NODE_DSTART'",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"Stop\")\n  style id1 fill:)]#636,stroke:#333,stroke-width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  id1 round \"Start\" span=1 styles=fill:)]#636|stroke:#333|stroke-width:4px\n  id-1-0 space \"id-1\" width=1\n  id2 round \"Stop\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:#fff|stroke-dasharray: 5 5\nedge 1-id1-id2 id1->id2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "empty bloc      B\n   ks", "error syntax 1:1\nParse error on line 1:\nempty bloc      B\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  id1[/\"Tis is the text in the box\"/]\n  id2[\\\"This is the text in-) the box\"\\]\n  A[/\"Christmas\"\\]\n  B[\\\"Go shopping\"/]\n",
    "ok\nroot columns=-1\n  id1 lean_right \"Tis is the text in the box\" span=1\n  id2 lean_left \"This is the text in-) the box\" span=1\n  A trapezoid \"Christmas\" span=1\n  B inv_trapezoid \"Go shopping\" span=1",
  ),
  (
    "[\"A label\"] b:2 c:2block\n          id==1\n          id2\n          id3\n      ",
    "error syntax 1:1\nParse error on line 1:\n[\"A label\"] b:2 c:2block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_DSTART'",
  ),
  (
    "block-beta\n      a\n    b\n      blockroup\n        c\n      end\n    ", "error syntax 6:7\nParse error on line 6:\n      end\n------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B< fill:#f9F,s--xroke:#333,stroke-width:4px\n        ",
    "ok\nroot columns=1\n  B square \"A wide one in the middle\" span=1 styles=< fill:#f9F|s--xroke:#333|stroke-width:4px",
  ),
  (
    "block colour slots\n    ", "ok\nroot columns=-1\n  colour na \"colour\" span=1\n  slots na \"slots\" span=1",
  ),
  (
    "block\n          id[\"A label\"]   \n       id2", "ok\nroot columns=-1\n  id square \"A label\" span=1\n  id2 na \"id2\" span=1",
  ),
  (
    "bck\n  blockArrowId<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"L1abel\"]>(x)\n  blArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "error syntax 1:1\nParse error on line 1:\nbck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "should log a warning when block width exceeds column width  A[\"A: ", "error syntax 1:1\nParse error on line 1:\nshould log a warning when block width exceeds column width  A[\"A: \n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(dow===)\n  block:ID\n    A\n    B[\"A wide one ace:2 in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:#333,stroke-width:4px\n",
    "error syntax 4:41\nLexical error on line 4. Unrecognized text.\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(dow===)\n----------------------------------------^",
  ),
  (
    "block       classDef black color:#ffffff, fill:ce:2\n  down<[\" #000000;\n\n        mc[\"Memcache\"]\n        class mc black\n        ",
    "error syntax 4:13\nLexical error on line 4. Unrecognized text.\n        mc[\"Memcache\"]\n------------^",
  ),
  (
    "block\n    id1{{\"This is the text in tA-->B\nhe box\"\n", "error syntax 3:8\nLexical error on line 3. Unrecognized text.\nhe box\"\n-------^",
  ),
  (
    "blockArr-ow", "error syntax 1:1\nParse error on line 1:\nblockArr-ow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "cmpouenblock\n        cold blocks 2", "error syntax 1:1\nParse error on line 1:\ncmpouenblock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  blockArwId<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(dowwn)\n  blockArro-.wId5<[\"Label\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "error syntax 5:28\nLexical error on line 5. Unrecognized text.\n  blockArrowId4<[\"Label\"]>(dowwn)\n---------------------------^",
  ),
  (
    "bloaBlock[\"ABck\n  ida space:3 idb idc\n", "error syntax 1:1\nParse error on line 1:\nbloaBlock[\"ABck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n           d\n      ", "ok\nroot columns=-1\n  d na \"d\" span=1",
  ),
  (
    "style st<-->atements applied t{{o a blocid1k", "error syntax 1:1\nParse error on line 1:\nstyle st<-->atements applied t{{o a blocid1k\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'style'",
  ),
  (
    "block\ncolumns 1\n    B[\"B[\"A wi(-de one in the middle\"]\n  style B fill:#f9F,stroke:#333,stroke-width:4px\n       ",
    "error syntax 3:11\nLexical error on line 3. Unrecognized text.\n    B[\"B[\"A wi(-de one in the middle\"]\n----------^",
  ),
  (
    "Compopound block", "error syntax 1:1\nParse error on line 1:\nCompopound block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          id1[\"first\"]  -->   id2[\"second\"]\n  ===    ", "error syntax 3:6\nParse error on line 3:\n  ===    \n-----^\nExpecting 'NODE_ID', got 'EOF'",
  ),
  (
    "block-beta)]\n      a\n      b\n      block:group\n       columns 3\n       c\n      end\nclass A, B a    ",
    "error syntax 1:11\nParse error on line 1:\nblock-beta)]\n----------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'NODE_DSTART'",
  ),
  (
    "b)loblock\n    id1(((\"This is the text in the circle\")))\n", "error syntax 1:1\nParse error on line 1:\nb)loblock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "cound blocks with titlet--oitle", "error syntax 1:1\nParse error on line 1:\ncound blocks with titlet--oitle\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        columns 3\n        block1[\"Block 1\"]\n        blockArr%%w<[\"&nbsp;&nbsp;&nbsp==>;\"]>(right)\n        block2[\"Block 2\"]",
    "ok\nroot columns=3\n  block1 square \"Block 1\" span=1\n  blockArr%%w block_arrow \"&nbsp;&nbsp;&nbsp==>;\" span=1 dirs=right\n  block2 square \"Block 2\" span=1",
  ),
  (
    "block\nA; classDef ${prop} coloolor:#ffffff,fill:([#000000; class A ${prop} ",
    "error syntax 2:13\nLexical error on line 2. Unrecognized text.\nA; classDef ${prop} coloolor:#ffffff,fill:([#000000; class A ${prop} \n------------^",
  ),
  (
    "compoxund b#locks with[/\"x\"/] title", "error syntax 1:1\nParse error on line 1:\ncompoxund b#locks with[/\"x\"/] title\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  columns 3\n  Start((\"Start\")) space:2\n  down<[\" \"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(right) Process1[\"Process A\"]\n  downAgain<[\"No\"]>(down) space r3<[\"Done\"]>(down)\n  Process2[\"Process B\"] r2<[\"Done\"](right) End((\"End\"))\n\n  style Start fill:#969;\n  style End fill:#696;\n",
    "error syntax 7:35\nLexical error on line 7. Unrecognized text.\n  Process2[\"Process B\"] r2<[\"Done\"](right) End((\"End\"))\n----------------------------------^",
  ),
  (
    "pound blocks with ith ti(-tle", "error syntax 1:1\nParse error on line 1:\npound blocks with ith ti(-tle\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          i[\"A: I am a wd[\"A label\"]\n          id2", "error syntax 2:28\nLexical error on line 2. Unrecognized text.\n          i[\"A: I am a wd[\"A label\"]\n---------------------------^",
  ),
  (
    "block\n        columns 1\n        A\n        bl blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(, down)\n        block\n          columns 3\nconstructor           B\n            C\n            D\n        end",
    "ok\nroot columns=1\n  A na \"A\" span=1\n  bl na \"bl\" span=1\n  blockArrow block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=down\n  id-1 composite \"\" columns=3 color=0\n    constructor na \"constructor\" span=1\n    B na \"B\" span=1\n    C na \"C\" span=1\n    D na \"D\" span=1",
  ),
  (
    "block\n        columns 1\n        A\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n          columns 3\n            B\n  B\n         C\n            D\n        end",
    "ok\nroot columns=1\n  A na \"A\" span=1\n  blockArrow block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=up|down\n  id-1 composite \"\" columns=3 color=0\n    B na \"B\" span=1\n    C na \"C\" span=1\n    D na \"D\" span=1",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\naccTitle  block:ID\n    A\n    B[\"A wide one -->in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#969,stroke:#333,stroke-width:4px\n",
    "ok\nroot columns=1\n  db circle \"DB\" span=1\n  blockArrowId6 block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=down\n  accTitle na \"accTitle\" span=1\n  ID composite \"\" span=1 color=0\n    A na \"A\" span=1\n    B square \"A wide one -->in the middle\" span=1 styles=fill:#969|stroke:#333|stroke-width:4px\n    C na \"C\" span=1\n  id-2-0 space \"id-2\" width=1\n  D na \"D\" span=1\nedge 1-ID-D ID->D \"\" arrow_open arrow_point normal solid\nedge 1-C-D C->D \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  A s-beta\n        id\npace B\n\t A-->B\n", "error syntax 2:6\nLexical error on line 2. Unrecognized text.\n  A s-beta\n-----^",
  ),
  (
    "block\n          columns 1        block1[\"Block 1\"]\n\n          block\n            columns 2\n            block2[\"Block 2\"]\n            bl((ck3[\"Bloock 3\"]\n          end\n        ",
    "error syntax 7:17\nLexical error on line 7. Unrecognized text.\n            bl((ck3[\"Bloock 3\"]\n----------------^",
  ),
  (
    "block\n       \r\n  id[\"A label\"]\n          id2", "ok\nroot columns=-1\n  id square \"A label\" span=1\n  id2 na \"id2\" span=1",
  ),
  (
    "blocclassDeef a fil#f96\n          id[\"<b>Bold</b>\"]\n          ", "error syntax 1:1\nParse error on line 1:\nblocclassDeef a fil#f96\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "c[[\"x\"]]lassDef statements applied))) to a block", "error syntax 1:1\nParse error on line 1:\nc[[\"x\"]]lassDef statements applied))) to a block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    " A space Bblock db edge styles", "error syntax 1:2\nParse error on line 1:\n A space Bblock db edge styles\n-^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n         columns 1\n          block1[\"Block 1\"]\n          block2[\"Block 2\"]\n        ",
    "ok\nroot columns=1\n  block1 square \"Block 1\" span=1\n  block2 square \"Block 2\" span=1",
  ),
  (
    "Arrow blocks with mntsuple points", "error syntax 1:1\nParse error on line 1:\nArrow blocks with mntsuple points\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  A\n  stylblock.padding fre A fill:#969,stroke:#333;\n\n", "error syntax 3:31\nLexical error on line 3. Unrecognized text.\n  stylblock.padding fre A fill:#969,stroke:#333;\n------------------------------^",
  ),
  (
    "when p[(arsing a block diagram grap(\"x\") )it should handle > ", "error syntax 1:1\nParse error on line 1:\nwhen p[(arsing a block diagram grap(\"x\") )it should handle > \n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          id1\n              id2\n          id3\n      ", "ok\nroot columns=-1\n  id1 na \"id1\" span=1\n  id2 na \"id2\" span=1\n  id3 na \"id3\" span=1",
  ),
  (
    "blgroupock-beta\n          id\n      ", "error syntax 1:1\nParse error on line 1:\nblgroupock-beta\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "b    lock\n    id1(\"This is the text in  in thhe box\")\n", "error syntax 1:1\nParse error on line 1:\nb    lock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "classDef staents applied to <==> block", "error syntax 1:1\nParse error on line 1:\nclassDef staents applied to <==> block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'classDef'",
  ),
  (
    "block\n--x   id1[[\"This is thtext in the box}]]\n", "error syntax 2:1\nParse error on line 2:\n--x   id1[[\"This is thtext in the box}]]\n^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'LINK'",
  ),
  (
    "block\n          block\n            aBlock[\"ABlock\"]\n            bl<-->o.ck\n              bBlock[\"BBlock\"]\n            end\n          end\n        ",
    "error syntax 7:11\nParse error on line 7:\n          end\n----------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "block-beta\n      block:first\n        a\n      end\n      block:second\n     b\n      end\n  ((    bfffff,filllock:third\n        c\n      end\n    ",
    "error syntax 8:3\nParse error on line 8:\n  ((    bfffff,filllock:third\n--^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'NODE_DSTART'",
  ),
  (
    "block\n          id1[\"first\"]  -- \"a label\" -->   id2[\"second\"]\n  >\"x\"]",
    "error syntax 3:3\nParse error on line 3:\n  >\"x\"]\n--^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'NODE_DSTART'",
  ),
  (
    "blocck\n==={pro-..-p}", "error syntax 1:1\nParse error on line 1:\nblocck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bck\n          columns 2\n          block1[\"Block 1\"]\n      ", "error syntax 1:1\nParse error on line 1:\nbck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bloc-.kAr.->row", "error syntax 1:1\nParse error on line 1:\nbloc-.kAr.->row\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n     b    1[\"first\"]  -- \"a label\" -->   id2[\"second\"]\n      ",
    "ok\nroot columns=-1\n  b na \"b\" span=1\n  1 square \"first\"\n  id2 square \"second\"\nedge 1-1-id2 1->id2 \"a label\" arrow_open arrow_point normal solid",
  ),
  (
    "blockht) Backend-beta\n      a\n      b\n      block:group\n        c\n      end\n    ",
    "error syntax 1:1\nParse error on line 1:\nblockht) Backend-beta\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blocck\n    id1((\"This is the text in the circle\"))\n", "error syntax 1:1\nParse error on line 1:\nblocck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "<[\"x\"]>(right)bl2", "error syntax 1:1\nParse error on line 1:\n<[\"x\"]>(right)bl2\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'BLOCK_ARROW_START'",
  ),
  (
    "block colour <[\"x\"]>(x,y)sls", "ok\nroot columns=-1\n  colour block_arrow \"x\" span=1 dirs=x|y\n  sls na \"sls\" span=1",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#969,stroke:#333,stroke-widt b c\nh:4px\n",
    "ok\nroot columns=1\n  db circle \"DB\" span=1\n  blockArrowId6 block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=down\n  ID composite \"\" span=1 color=0\n    A na \"A\" span=1\n    B square \"A wide one in the middle\" span=1 styles=fill:#969|stroke:#333|stroke-widt b c\n    C na \"C\" span=1\n  id-2-0 space \"id-2\" width=1\n  D na \"D\" span=1\n  h na \"h\" span=4\n  px na \"px\" span=1\nedge 1-ID-D ID->D \"\" arrow_open arrow_point normal solid\nedge 1-C-D C->D \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  id1>\"This is the text inhe box\"]\n", "ok\nroot columns=-1\n  id1 rect_left_inv_arrow \"This is the text inhe box\" span=1",
  ),
  (
    "block\n          block\n            aBlock[\"ABlock\"]\n            bBlock[\"BBlock\"] end     ([\"x\"])      end\n        ",
    "error syntax 4:38\nParse error on line 4:\n            bBlock[\"BBlock\"] end     ([\"x\"])      end\n-------------------------------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'NODE_DSTART'",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\")#)\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the mid[\\\"x\"\\]<==>le\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#969,stroke:#333,stroke-width:4px\n",
    "error syntax 3:14\nLexical error on line 3. Unrecognized text.\n  db((\"DB\")#)\n-------------^",
  ),
  (
    "block\n        classDef black color:#ffffff, fill:#000000;\n\n        mc[\"Memcache\"]\n        label\"] b c d\nclass mc black\n        ",
    "ok\nroot columns=-1\n  mc square \"Memcache\" span=1 classes=black\n  label\"] na \"label\"]\" span=1\n  b na \"b\" span=1\n  c na \"c\" span=1\n  d na \"d\" span=1\nclass black styles=[color:#ffffff|fill:#000000] text=[fill:#ffffff]",
  ),
  (
    "block\n    iblock:d1(\"This is<[\"x\"]>( x ) the text in the box\")\n", "error syntax 2:11\nLexical error on line 2. Unrecognized text.\n    iblock:d1(\"This is<[\"x\"]>( x ) the text in the box\")\n----------^",
  ),
  (
    "block\n  A\n  style A fill:#969,stroendke:#333;\n\n", "ok\nroot columns=-1\n  A na \"A\" span=1 styles=fill:#969|stroendke:#333;",
  ),
  (
    "b((lock\n    id1((\"This is the text in the cir{{cle\"))\n{\"x\"}", "error syntax 1:1\nParse error on line 1:\nb((lock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "empty blockstyle s", "error syntax 1:1\nParse error on line 1:\nempty blockstyle s\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        classDef black color:#ffffff, fill fill:#000000;\n\n        mc[\"Memcache\"]\n        class mc black\n        ",
    "ok\nroot columns=-1\n  mc square \"Memcache\" span=1 classes=black\nclass black styles=[color:#ffffff|fill fill:#000000] text=[fill:#ffffff]",
  ),
  (
    "block\n          id23[\"<b> end old</lock1b>\"]\n          ", "ok\nroot columns=-1\n  id23 square \"<b> end old</lock1b>\" span=1",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  spound bltyle B fill:#f9F,stroke:#333,stroke-width:4px\n        ",
    "error syntax 4:23\nLexical error on line 4. Unrecognized text.\n  spound bltyle B fill:#f9F,stroke:#333,stroke-width:4px\n----------------------^",
  ),
  (
    "row blocks with multiple poin)))s", "error syntax 1:1\nParse error on line 1:\nrow blocks with multiple poin)))s\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bl\"\"ock\n  columns 3\n  a:3\n  block:group1:2\n    c)lumns 2\n    h  k\n  end\n  g\n  block:group2:3\n    %% columns auto (default)\n    l m n o p q r\n  end\n",
    "error syntax 1:1\nParse error on line 1:\nbl\"\"ock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  columns 3\n  a b }}ccolumns 3d\n", "error syntax 3:7\nLexical error on line 3. Unrecognized text.\n  a b }}ccolumns 3d\n------^",
  ),
  (
    "bloc\n\\]__proto__prop}", "error syntax 1:1\nParse error on line 1:\nbloc\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "gives no slot to a simplb -- \"x\" --> ock", "error syntax 1:1\nParse error on line 1:\ngives no slot to a simplb -- \"x\" --> ock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n k\n    id1(\"Thisblock\n${ is the text in t23he box\")\n", "ok\nroot columns=-1\n  k na \"k\" span=1\n  id1 round \"Thisblock\n${ is the text in t23he box\" span=1",
  ),
  (
    "shd read block.padding from config at call time, not at import time", "error syntax 1:1\nParse error on line 1:\nshd read block.padding from config at call time, not at import time\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "when parsingspace:2 a blocstyle A fill:#f96,stroke:#333k diagram graph it should hedge stylesandle > ",
    "error syntax 1:1\nParse error on line 1:\nwhen parsingspace:2 a blocstyle A fill:#f96,stroke:#333k diagram graph it should hedge stylesandle > \n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blocdk c((\"x\"))lour slots", "error syntax 1:1\nParse error on line 1:\nblocdk c((\"x\"))lour slots\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B ffill:#f9F,st))roke:#333,stroke-width:4px\n      ",
    "ok\nroot columns=1\n  B square \"A wide one in the middle\" span=1 styles=ffill:#f9F|st))roke:#333|stroke-width:4px",
  ),
  (
    "class A arrow blocks", "error syntax 1:1\nParse error on line 1:\nclass A arrow blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'class'",
  ),
  (
    "block\n  columns 3\n\n  a b c d\n", "ok\nroot columns=3\n  a na \"a\" span=1\n  b na \"b\" span=1\n  c na \"c\" span=1\n  d na \"d\" span=1",
  ),
  (
    "classDef a fill:#f96block\n          id1[\"first\"]  -->   id2[\"second\"]\n      ",
    "error syntax 1:1\nParse error on line 1:\nclassDef a fill:#f96block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'classDef'",
  ),
  (
    "block\n            id[\"A label\"]\n           ", "ok\nroot columns=-1\n  id square \"A label\" span=1",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fc -- \"x\" --> lassaccTitle: tDef a\nll:#6e6ce6,stroke:#333,stroke-width:4px;\n  class A blue\n  style B fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "error syntax 5:3\nLexical error on line 5. Unrecognized text.\nll:#6e6ce6,stroke:#333,stroke-width:4px;\n--^",
  ),
  (
    "bylock2", "error syntax 1:1\nParse error on line 1:\nbylock2\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blodefaultck\"]>(riArrow", "error syntax 1:1\nParse error on line 1:\nblodefaultck\"]>(riArrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "should read block.pang from confi[[ at call time, not at import ===time", "error syntax 1:1\nParse error on line 1:\nshould read block.pang from confi[[ at call time, not at import ===time\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          id1\n          id2\n          id3\n   \\]\n  A[/\"   ", "error syntax 6:7\nParse error on line 6:\n  A[/\"   \n------^\nExpecting 'NODE_DEND', got 'STR'",
  ),
  (
    "Com[]\\po\"Christmasund block", "error syntax 1:1\nParse error on line 1:\nCom[]\\po\"Christmasund block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n${op}}", "error syntax 2:3\nLexical error on line 2. Unrecognized text.\n${op}}\n--^",
  ),
  (
    "block\n    d1(\"This is ths the text in the box\")\n", "ok\nroot columns=-1\n  d1 round \"This is ths the text in the box\" span=1",
  ),
  (
    "block\n  A\n st{{\"x\"}}yle A fill:#969,stroke:#333;\n\n", "error syntax 3:21\nLexical error on line 3. Unrecognized text.\n st{{\"x\"}}yle A fill:#969,stroke:#333;\n--------------------^",
  ),
  (
    "block\n          columns auto\n          block1[\"Block 1      ", "error syntax 3:26\nParse error on line 3:\n          block1[\"Block 1      \n-------------------------^\nExpecting 'NODE_DEND', got 'STR'",
  ),
  (
    "block\n         1[\"firs]  -- \"a label\" -->   id2[|\"x\"][\"second\"]\n      ",
    "error syntax 2:24\nLexical error on line 2. Unrecognized text.\n         1[\"firs]  -- \"a label\" -->   id2[|\"x\"][\"second\"]\n-----------------------^",
  ),
  (
    "bloc`k\n          block1[\"Blo k 1\"]\n      ", "error syntax 1:1\nParse error on line 1:\nbloc`k\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n     -. \"x\" .->   block:a1\n        block:a2\n          x\n        end\n      end\n      block:b1\n        block:b2\n          y\n     ]]  end\n      end\n    ",
    "error syntax 2:6\nParse error on line 2:\n     -. \"x\" .->   block:a1\n-----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'START_LINK'",
  ),
  (
    "block\n  block\n    columns 1\n    a[\"A >\"x\"]abel\"] b c d\n\r\n  end\n",
    "error syntax 4:12\nLexical error on line 4. Unrecognized text.\n    a[\"A >\"x\"]abel\"] b c d\n-----------^",
  ),
  (
    "block\n          id[\"A l]]abel\"]\n         linkStyle", "error syntax 3:10\nParse error on line 3:\n         linkStyle\n---------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'LINKSTYLE'",
  ),
  (
    "block\n  column\n  a[\"A labyle A fillnext to each #el\"] b:2 c:2 d\n", "ok\nroot columns=-1\n  column na \"column\" span=1\n  a square \"A labyle A fillnext to each #el\" span=1\n  b na \"b\" span=2\n  c na \"c\" span=2\n  d na \"d\" span=1",
  ),
  (
    "ee:#333;\n\nmpty blocks", "error syntax 1:1\nParse error on line 1:\nee:#333;\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  block\n    columns 1\n  left  a[\"A label\"] b c d\n           block1end<[\"x\"]>( x )\n",
    "error syntax 5:33\nParse error on line 5:\n           block1end<[\"x\"]>( x )\n--------------------------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'EOF'",
  ),
  (
    "block\n  A space B\n ->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:4px;\n  class A blue\n  style B fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "error syntax 3:2\nLexical error on line 3. Unrecognized text.\n ->B\n-^",
  ),
  (
    "  block\n    A\n    style A fi<[ll#969;9;\n;9;\n", "ok\nroot columns=-1\n  A na \"A\" span=1 styles=fi<[ll#969;9;\n  ;9; na \";9;\" span=1",
  ),
  (
    "bloc(\"x\")k\n    id1((\"This; is the text in the circle\"))\n\u{e9}", "error syntax 1:1\nParse error on line 1:\nbloc(\"x\")k\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blocks next to each o%%ther", "error syntax 1:1\nParse error on line 1:\nblocks next to each o%%ther\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          block:compoundBlock[/[\"Compound block\"]\n            columns 1\n            block2[\"Block 2\"]\n          e        ",
    "error syntax 2:32\nLexical error on line 2. Unrecognized text.\n          block:compoundBlock[/[\"Compound block\"]\n-------------------------------^",
  ),
  (
    "((blockend\nAd\nArrow", "error syntax 1:1\nParse error on line 1:\n((blockend\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_DSTART'",
  ),
  (
    "block\nc]>olumns 1\n    B[\"A wide one in the  -- \"x\" --> iddle\"]\n  style B fill:#f9F,stroke#333,stroke-width:4px\n        ",
    "error syntax 2:4\nLexical error on line 2. Unrecognized text.\nc]>olumns 1\n---^",
  ),
  (
    "blockdstyle A,B xefault\n  a b c\n", "error syntax 1:1\nParse error on line 1:\nblockdstyle A,B xefault\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "accDescr {}ck\n          block1[\"Block 1style A fill:#f96,stroke:#333]\n      ",
    "error syntax 1:12\nParse error on line 1:\naccDescr {}ck\n-----------^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "when parsing a block-.- diagram graph it should handle > ", "error syntax 1:1\nParse error on line 1:\nwhen parsing a block-.- diagram graph it should handle > \n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\nA; assDef ${prop} color:#ffffff,fill:#000000; class A ${prop}", "error syntax 2:13\nLexical error on line 2. Unrecognized text.\nA; assDef ${prop} color:#ffffff,fill:#000000; class A ${prop}\n------------^",
  ),
  (
    "block_arrowrrow", "error syntax 1:1\nParse error on line 1:\nblock_arrowrrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block db eddge styles", "ok\nroot columns=-1\n  db na \"db\" span=1\n  eddge na \"eddge\" span=1\n  styles na \"styles\" span=1",
  ),
  (
    "block-beta\n  columnss 1([\n  A:1\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2\n  G:1",
    "error syntax 2:15\nLexical error on line 2. Unrecognized text.\n  columnss 1([\n--------------^",
  ),
  (
    "block\n  \t       columns auto\n        block1[\"Block 1\"]\n      ", "ok\nroot columns=-1\n  block1 square \"Block 1\" span=1",
  ),
  (
    "blockaccDescr { d }\n             id[\"A label\"]\n           id2", "error syntax 1:1\nParse error on line 1:\nblockaccDescr { d }\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  A space:-.->2-.->2 B\n  A-- \"X\" -->B\n", "error syntax 2:10\nLexical error on line 2. Unrecognized text.\n  A space:-.->2-.->2 B\n---------^",
  ),
  (
    "Compa bound blol tim(-, not atck", "error syntax 1:1\nParse error on line 1:\nCompa bound blol tim(-, not atck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blaccDescr { d }cks mixed with comp.->ound blocks", "error syntax 1:1\nParse error on line 1:\nblaccDescr { d }cks mixed with comp.->ound blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blockta\n  columns 1\n  A:1\n  B:2\n  C:3\n  D:4\n <[\"x\"]>(x,y) E:3\n  F:2\n  G:1",
    "error syntax 1:1\nParse error on line 1:\nblockta\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    interpolate  columns auto\n   ===       block1[\"Block 1\"]\n      ",
    "error syntax 2:5\nParse error on line 2:\n    interpolate  columns auto\n----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'INTERPOLATE'",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:4px;\nls A blue\n  style B fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  A na \"A\" span=1\n  id-1-0 space \"id-1\" width=1\n  B na \"B\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:#fff|stroke-dasharray: 5 5\n  ls na \"ls\" span=1\n  blue na \"blue\" span=1\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid\nclass blue styles=[fill:#6e6ce6|stroke:#333|stroke-width:4px] text=[]",
  ),
  (
    "block\n      id1(\"This is the text in the<-- -. \"x\" .-> > box\")\n", "error syntax 2:43\nLexical error on line 2. Unrecognized text.\n      id1(\"This is the text in the<-- -. \"x\" .-> > box\")\n------------------------------------------^",
  ),
  (
    "blockconstructor\n    id1{{\"{\"This is the text in ck:second\n        the box\"}}\n",
    "error syntax 1:1\nParse error on line 1:\nblockconstructor\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        columns 3\n        one[\"One Slot\"]\n        two[\"Two slots\"]:2-.\n        ",
    "error syntax 4:29\nParse error on line 4:\n        two[\"Two slots\"]:2-.\n----------------------------^\nExpecting 'LINK_LABEL', got '$end'",
  ),
  (
    "compound blocksocks with title", "error syntax 1:1\nParse error on line 1:\ncompound blocksocks with title\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\nace:        columns 1\n        A\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        blspaceock\n          columns 3\n            B\n            C\n            D\n        end",
    "error syntax 2:4\nLexical error on line 2. Unrecognized text.\nace:        columns 1\n---^",
  ),
  (
    "bloc        columns 3\n    \"This is the tex    one[[\"One Slot\"]\n        two[\"Two slots\"]:2\n        ",
    "error syntax 1:1\nParse error on line 1:\nbloc        columns 3\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block{{  a b  a b c\n", "error syntax 1:6\nParse error on line 1:\nblock{{  a b  a b c\n-----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'NODE_DSTART'",
  ),
  (
    "A a simpaccDescr: dle rrow blocks", "error syntax 1:1\nParse error on line 1:\nA a simpaccDescr: dle rrow blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      block:outer\n        block:inner\n      accDescr { d }    a\n      end\n      end\n      block:sibling\n        b\n      end\n  ",
    "error syntax 4:18\nParse error on line 4:\n      accDescr { d }    a\n-----------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'acc_descr_multiline_value'",
  ),
  (
    "when parsing a block diagram graph it should handleclass A,B a > ", "error syntax 1:1\nParse error on line 1:\nwhen parsing a block diagram graph it should handleclass A,B a > \n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blo    id1[(\"taba]]se\")]\n", "error syntax 1:1\nParse error on line 1:\nblo    id1[(\"taba]]se\")]\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bloc[/k\n    id1(((\"This is the text in the circle\")))\n", "error syntax 1:1\nParse error on line 1:\nbloc[/k\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  A space B\n>\"This is   A-->B\n", "error syntax 3:18\nParse error on line 3:\n>\"This is   A-->B\n-----------------^\nExpecting 'NODE_DEND', got 'STR'",
  ),
  (
    "Arrow bocks", "error syntax 1:1\nParse error on line 1:\nArrow bocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "when parsing a block diagram graph iaph it should handle > ", "error syntax 1:1\nParse error on line 1:\nwhen parsing a block diagram graph iaph it should handle > \n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "Astyle rrow oc", "error syntax 1:1\nParse error on line 1:\nAstyle rrow oc\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          id[\"A label\"]oke-dasharr\n          ", "error syntax 2:27\nLexical error on line 2. Unrecognized text.\n          id[\"A label\"]oke-dasharr\n--------------------------^",
  ),
  (
    "  blocks on top of e  c   d  ach other", "error syntax 1:3\nParse error on line 1:\n  blocks on top of e  c   d  ach other\n--^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    1(\"This is t text in the box\")\")\n", "error syntax 2:36\nParse error on line 2:\n    1(\"This is t text in the box\")\")\n-----------------------------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'STR'",
  ),
  (
    "compaccDe the boscr: dound b---locks with title", "error syntax 1:1\nParse error on line 1:\ncompaccDe the boscr: dound b---locks with title\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blocks  == \"x\" ==> with different widths", "error syntax 1:1\nParse error on line 1:\nblocks  == \"x\" ==> with different widths\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  ("block\n   c\n", "ok\nroot columns=-1\n  c na \"c\" span=1"),
  (
    "block\n          columns 1\n       end   block1[\"Block 1\"]\n          block2[\"Block 2\"]\n       ([ ",
    "error syntax 3:8\nParse error on line 3:\n       end   block1[\"Block 1\"]\n-------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "blockock\n    id1((e te(\"T((\"This is the text in the circle\")))\n", "error syntax 1:1\nParse error on line 1:\nblockock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      a\n      b\n      block:group\n     columns auto   c\n      e)]nd\n    ",
    "error syntax 6:9\nParse error on line 6:\n      e)]nd\n--------^\nExpecting 'STR', got 'NODE_DEND'",
  ),
  (
    "blocks mixed with compoclassDef a\nund blockold</b>\"]\n      s", "error syntax 1:1\nParse error on line 1:\nblocks mixed with compoclassDef a\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          =id1[\"first\"]  -->   id2[\"second\"]\n      ", "error syntax 2:11\nLexical error on line 2. Unrecognized text.\n          =id1[\"first\"]  -->   id2[\"second\"]\n----------^",
  ),
  (
    "cssDef statements applied to a bloclock", "error syntax 1:1\nParse error on line 1:\ncssDef statements applied to a bloclock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        colaccTitle: tumns 3\n        one[\"One Slot\"]\n        twowo slots\"]:2\n        ((\"x\"))",
    "error syntax 2:20\nLexical error on line 2. Unrecognized text.\n        colaccTitle: tumns 3\n-------------------^",
  ),
  (
    "b lock\n${id1[(\"Databprop}", "error syntax 1:1\nParse error on line 1:\nb lock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bloc<[k\n  ida space:3 idb i;c\n", "error syntax 1:1\nParse error on line 1:\nbloc<[k\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n   w 1{{\"This is the text in the box\"}==}\n", "error syntax 2:41\nLexical error on line 2. Unrecognized text.\n   w 1{{\"This is the text in the box\"}==}\n----------------------------------------^",
  ),
  (
    "block\n    id1([\"Th[\\\"x\"\\]is is the text in the box\"])Aconstructor", "error syntax 2:16\nLexical error on line 2. Unrecognized text.\n    id1([\"Th[\\\"x\"\\]is is the text in the box\"])Aconstructor\n---------------^",
  ),
  (
    "when lock\n          iparsing a block diagram graph it should handle > ", "error syntax 1:1\nParse error on line 1:\nwhen lock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "empty class A ablocks", "error syntax 1:1\nParse error on line 1:\nempty class A ablocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n         id[\"<b>Bold</b>\"]\n          ", "ok\nroot columns=-1\n  id square \"<b>Bold</b>\" span=1",
  ),
  (
    "when parsing a block diaram graph it should handle >%% ", "error syntax 1:1\nParse error on line 1:\nwhen parsing a block diaram graph it should handle >%% \n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      block:first\n        a\n      end\n      block:second\n        b\n      end\n  }    block:thir)\nd\n        c\n      end\n    ",
    "error syntax 8:3\nLexical error on line 8. Unrecognized text.\n  }    block:thir)\n--^",
  ),
  (
    "block\n         d1[\"first\"]  -- \"a label\" -->   id2[\"second\"]\n      ",
    "ok\nroot columns=-1\n  d1 square \"first\"\n  id2 square \"second\"\nedge 1-d1-id2 d1->id2 \"a label\" arrow_open arrow_point normal solid",
  ),
  (
    "block-betta\n        iid\n      ", "error syntax 1:6\nLexical error on line 1. Unrecognized text.\nblock-betta\n-----^",
  ),
  (
    "block\n          id1\n     .->     id2\n          id3   \n      ", "error syntax 3:7\nLexical error on line 3. Unrecognized text.\n     .->     id2\n------^",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n      e]>(nd\n      block:b1\n        block:b2\n          y\n        end\n      end\n    ",
    "error syntax 6:10\nParse error on line 6:\n      e]>(nd\n---------^\nExpecting 'STR', got 'NODE_DEND'",
  ),
  (
    "emptyblock: blocks", "error syntax 1:1\nParse error on line 1:\nemptyblock: blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n      ennd\n      block:b1\n        block:b2\n          y\n        end\n    end\n[/\"x\"/]    ",
    "error syntax 12:1\nParse error on line 12:\n[/\"x\"/]    \n^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'NODE_DSTART'",
  ),
  (
    "block\n  columns 3\n  Frontend blockArrowId6<[\" \"]>(ight) Backend\n  space:2 down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,stroke:#333;\n  classDef back fill:#969,stroke:#333;\n  class Frontend froernt\n  class Backend,Database back\n",
    "error syntax 3:33\nLexical error on line 3. Unrecognized text.\n  Frontend blockArrowId6<[\" \"]>(ight) Backend\n--------------------------------^",
  ),
  (
    "bl   block1ocks nexto each otherarrow", "error syntax 1:1\nParse error on line 1:\nbl   block1ocks nexto each otherarrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bl`\"ck\n          id[\"<b>Bold</b>\"]\n          ", "error syntax 1:1\nParse error on line 1:\nbl`\"ck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  id1>\"This is the text in the box", "error syntax 2:35\nParse error on line 2:\n  id1>\"This is the text in the box\n----------------------------------^\nExpecting 'NODE_DEND', got 'STR'",
  ),
  (
    "gives no sl slot to a simple block", "error syntax 1:1\nParse error on line 1:\ngives no sl slot to a simple block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bcolumns auto))loclocksk1", "error syntax 1:1\nParse error on line 1:\nbcolumns auto))loclocksk1\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          id1[\"first\"]  -- \"a label\" -->classDef a fill:#f96     idsecond\"]\n      ",
    "error syntax 2:41\nParse error on line 2:\n          id1[\"first\"]  -- \"a label\" -->classDef a fill:#f96     idsecond\"]\n----------------------------------------^\nExpecting 'NODE_ID', got 'classDef'",
  ),
  (
    "bl]ock1", "error syntax 1:1\nParse error on line 1:\nbl]ock1\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n   :03 block\n          D\n    end\n    A[\"A: I am a wide one\"]\n",
    "error syntax 2:4\nParse error on line 2:\n   :03 block\n---^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'SIZE'",
  ),
  (
    "should <==>read block.padding from config at leftall time, not at import time",
    "error syntax 1:1\nParse error on line 1:\nshould <==>read block.padding from config at leftall time, not at import time\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        column< 1\n        A\n        blockArrow<[\"/]&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n          columns 3\n            B\n            C\n            D\n        end",
    "error syntax 2:15\nLexical error on line 2. Unrecognized text.\n        column< 1\n--------------^",
  ),
  (
    "block\n  A spae B\n  --oA --> B\n", "ok\nroot columns=-1\n  A na \"A\" span=1\n  spae na \"spae\" span=1\n  B na \"B\"\nedge 1-B-A B->A \"\" arrow_open arrow_circle normal solid\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block-beta\n  columns 1\n  A:1\n  \n  C:3\n  interpolate:4\n  E:3\n  F:2\n  G:1",
    "error syntax 6:3\nParse error on line 6:\n  interpolate:4\n--^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'INTERPOLATE'",
  ),
  (
    "block\n(((  A spac B\n  A--e:2 B\n  A-- \"X\" -->B\n", "error syntax 2:1\nParse error on line 2:\n(((  A spac B\n^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'NODE_DSTART'",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the mid~~~dle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B filB fill:#969,stroke:#333,stroke-width:4px\n",
    "ok\nroot columns=1\n  db circle \"DB\" span=1\n  blockArrowId6 block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=down\n  ID composite \"\" span=1 color=0\n    A na \"A\" span=1\n    B square \"A wide one in the mid~~~dle\" span=1 styles=filB fill:#969|stroke:#333|stroke-width:4px\n    C na \"C\" span=1\n  id-2-0 space \"id-2\" width=1\n  D na \"D\" span=1\nedge 1-ID-D ID->D \"\" arrow_open arrow_point normal solid\nedge 1-C-D C->D \"\" arrow_open arrow_point normal solid",
  ),
  (
    "compoundocks with title", "error syntax 1:1\nParse error on line 1:\ncompoundocks with title\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      block:first\n             end\n      block:second\n        b\n      end\n  [/\"x\"\\]    block:third\n        c\n      end\n    ",
    "error syntax 3:14\nParse error on line 3:\n             end\n-------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,[|\"x\"]troke-width:4px;\n  class A blue\n  style B fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  A na \"A\" span=1 classes=blue\n  id-1-0 space \"id-1\" width=1\n  B na \"B\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:#fff|stroke-dasharray: 5 5\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid\nclass blue styles=[fill:#6e6ce6|stroke:#333|[|\"x\"]troke-width:4px] text=[]",
  ),
  (
    "blo    id1{\"x\"}[\"This is the text in the box\"])\n", "error syntax 1:1\nParse error on line 1:\nblo    id1{\"x\"}[\"This is the text in the box\"])\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      a\n      b\n      block:group\n        c\n      id1(\"Tblockhis is   end\n     ",
    "error syntax 6:30\nParse error on line 6:\n      id1(\"Tblockhis is   end\n-----------------------------^\nExpecting 'NODE_DEND', got 'STR'",
  ),
  (
    "block2ck2", "error syntax 1:1\nParse error on line 1:\nblock2ck2\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "label\"]\n      blocks mixed withompd blocks", "error syntax 1:1\nParse error on line 1:\nlabel\"]\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  columns 3\n  Frontend blockArrowId6<[\" \"]>(right) Backend\n  space:2 down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,strok\ne:#333;\n  classDef back fill:#969,stroke:#333;\n  spaceclass Frontend front\n  class Backend,Database back\n",
    "error syntax 8:2\nLexical error on line 8. Unrecognized text.\ne:#333;\n-^",
  ),
  (
    "blo&nbsp;ck\n    id1\n  block[(\"Database\")]\n", "error syntax 1:1\nParse error on line 1:\nblo&nbsp;ck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    id1([\"This is the aBlock[\"ABloc[[text in the box\"])\n", "error syntax 2:31\nLexical error on line 2. Unrecognized text.\n    id1([\"This is the aBlock[\"ABloc[[text in the box\"])\n------------------------------^",
  ),
  (
    "block\n  A space B\n  A --> B {\n  end\n{\"x\"}}\n", "error syntax 3:12\nLexical error on line 3. Unrecognized text.\n  A --> B {\n-----------^",
  ),
  (
    "block\n -.->   id1{\"This is is the blockext in the box\"}\n", "error syntax 2:2\nParse error on line 2:\n -.->   id1{\"This is is the blockext in the box\"}\n-^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'LINK'",
  ),
  (
    "classDef == \"x\" ==> statements applied to a block", "error syntax 1:1\nParse error on line 1:\nclassDef == \"x\" ==> statements applied to a block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'classDef'",
  ),
  (
    "block-beta\n  columns 1\n \n A:1\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2\n  G:1",
    "ok\nroot columns=1\n  A na \"A\" span=1\n  B na \"B\" span=2\n  C na \"C\" span=3\n  D na \"D\" span=4\n  E na \"E\" span=3\n  F na \"F\" span=2\n  G na \"G\" span=1",
  ),
  (
    "blocwith different widtths", "error syntax 1:1\nParse error on line 1:\nblocwith different widtths\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    x--    classDef black color:#ffffff, [/ill:#000000;\n\n        mc[\"Memcache\"]\n        class mc black\n        ",
    "error syntax 2:12\nLexical error on line 2. Unrecognized text.\n    x--    classDef black color:#ffffff, [/ill:#000000;\n-----------^",
  ),
  (
    "block\n  A sp{{ce B\n:  A --> B\n", "error syntax 2:9\nLexical error on line 2. Unrecognized text.\n  A sp{{ce B\n--------^",
  ),
  (
    "compound blocks with titlxe", "error syntax 1:1\nParse error on line 1:\ncompound blocks with titlxe\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blocks mixed with compound [/\"x\"\\]blocks", "error syntax 1:1\nParse error on line 1:\nblocks mixed with compound [/\"x\"\\]blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bcolumns autolock1", "error syntax 1:1\nParse error on line 1:\nbcolumns autolock1\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    ".-<--bl_arrow", "error syntax 1:1\nParse error on line 1:\n.-<--bl_arrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      blocko--:oute:outer\n        block:inner\n          a\n        end\n      end\n      block:siblispace:2ng\n        b\n      end\n    ",
    "error syntax 2:15\nLexical error on line 2. Unrecognized text.\n      blocko--:oute:outer\n--------------^",
  ),
  (
    "block-beta~~~          }}d\n      ", "error syntax 1:24\nLexical error on line 1. Unrecognized text.\nblock-beta~~~          }}d\n-----------------------^",
  ),
  (
    "columns\n2blocks on top of each other", "error syntax 1:1\nParse error on line 1:\ncolumns\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'COLUMNS'",
  ),
  (
    "b--xlock\n  column- 3\n  a space b\n  c<--   d   e\n", "error syntax 1:1\nParse error on line 1:\nb--xlock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blocks on ton top of each h other", "error syntax 1:1\nParse error on line 1:\nblocks on ton top of each h other\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      blck:a1\n        block:a2\n          x\n        end\n      end\n      block:b1\n      block:b2\n          y\n         end\n      end\n    ",
    "error syntax 2:11\nLexical error on line 2. Unrecognized text.\n      blck:a1\n----------^",
  ),
  (
    "block\n        columns 3\n\n        space\n      middle[\"In the middle\"]\n        space\n        ",
    "ok\nroot columns=3\n  id-1-0 space \"id-1\" width=1\n  middle square \"In the middle\" span=1\n  id-2-0 space \"id-2\" width=1",
  ),
  (
    "block\n        columns 1\n        A\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n          columns 3\n--           B\n            C\n            D\n        end",
    "error syntax 7:1\nParse error on line 7:\n--           B\n^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'START_LINK'",
  ),
  (
    "block exceeds\n          id1\n          id2\n          id3\n      ", "ok\nroot columns=-1\n  exceeds na \"exceeds\" span=1\n  id1 na \"id1\" span=1\n  id2 na \"id2\" span=1\n  id3 na \"id3\" span=1",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"Stop\")\n  style id1 fill:#636,stroclass A,B ae:#333,stroke-width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:a b#fff,stroke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  id1 round \"Start\" span=1 styles=fill:#636|stroclass A|B ae:#333|stroke-width:4px\n  id-1-0 space \"id-1\" width=1\n  id2 round \"Stop\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:a b#fff|stroke-dasharray: 5 5\nedge 1-id1-id2 id1->id2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "empty block`s", "error syntax 1:1\nParse error on line 1:\nempty block`s\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  columns 3\n  Frontend blockArrowId6<[\" \"]>(right) Backend\n  space:2 down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,stroke:#333;\n  classDef back fill:fill:#969,stroke:#333;\n  class Frontend front\n  class Backend,Database back\n",
    "ok\nroot columns=3\n  Frontend na \"Frontend\" span=1 classes=front\n  blockArrowId6 block_arrow \" \" span=1 dirs=right\n  Backend na \"Backend\" span=1 classes=back\n  id-1-0 space \"id-1\" width=2\n  id-1-1 space \"id-1\" width=2\n  down block_arrow \" \" span=1 dirs=down\n  Disk na \"Disk\" span=1\n  left block_arrow \" \" span=1 dirs=left\n  Database cylinder \"Database\" span=1 classes=back\nclass front styles=[fill:#696|stroke:#333] text=[]\nclass back styles=[fill:fill:#969|stroke:#333] text=[]",
  ),
  (
    "when parsing a b([\"x\"])ock diagram gog a warning((raph it should handle > ",
    "error syntax 1:1\nParse error on line 1:\nwhen parsing a b([\"x\"])ock diagram gog a warning((raph it should handle > \n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          id[\"A space\n    label\"]\n            id1[[\"This is ", "error syntax 4:26\nParse error on line 4:\n            id1[[\"This is \n-------------------------^\nExpecting 'NODE_DEND', got 'STR'",
  ),
  (
    "block\n  columns 3\n  3\n  a[\"A label\"] b:2 c:2 d\n", "ok\nroot columns=3\n  3 na \"3\" span=1\n  a square \"A label\" span=1\n  b na \"b\" span=2\n  c na \"c\" span=2\n  d na \"d\" span=1",
  ),
  (
    "block\n          bl[\\ock:compoundBlock[\"Compoupou&nbsp;d block\"]\n            columns 1\n            block2[\"Block 2\"]\n          end\n        ",
    "error syntax 2:15\nLexical error on line 2. Unrecognized text.\n          bl[\\ock:compoundBlock[\"Compoupou&nbsp;d block\"]\n--------------^",
  ),
  (
    "b\nck2", "error syntax 1:1\nParse error on line 1:\nb\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n [[ a classDef a fill:#f96b c\n", "error syntax 2:2\nParse error on line 2:\n [[ a classDef a fill:#f96b c\n-^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'NODE_DSTART'",
  ),
  (
    "block-beta\n         accDescr: did\n      ", "error syntax 2:10\nParse error on line 2:\n         accDescr: did\n---------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'acc_descr'",
  ),
  (
    "[lock_arrow", "error syntax 1:1\nParse error on line 1:\n[lock_arrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_DSTART'",
  ),
  (
    "block\n        olumns 3\n        one[\"One Slot\"]\n  n  abel\"    two[\"Two slots\"]:2\n        ",
    "ok\nroot columns=-1\n  olumns na \"olumns\" span=1\n  3 na \"3\" span=1\n  one square \"One Slot\" span=1\n  n na \"n\" span=1\n  abel\" na \"abel\"\" span=1\n  two square \"Two slots\" span=2",
  ),
  (
    "block\n          block1[\"Boclock 1\"]\n      ", "ok\nroot columns=-1\n  block1 square \"Boclock 1\" span=1",
  ),
  (
    "Cmpound block", "error syntax 1:1\nParse error on line 1:\nCmpound block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    id1([is is the text in the box\"])\n", "error syntax 2:10\nLexical error on line 2. Unrecognized text.\n    id1([is is the text in the box\"])\n---------^",
  ),
  (
    "blcolumns autoock\n    id1((\"This is the text in the circle\"))\n\n", "error syntax 1:1\nParse error on line 1:\nblcolumns autoock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    id1o--[~~~(\"Database\")]\nclass A,B a", "error syntax 2:11\nLexical error on line 2. Unrecognized text.\n    id1o--[~~~(\"Database\")]\n----------^",
  ),
  (
    "block\n  A space B\n  A-A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:4px;\n  clas,s A blue\n  style B fill:#b,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "error syntax 3:4\nLexical error on line 3. Unrecognized text.\n  A-A-->B\n---^",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in {{\"x\"}}the middle\"]\n ->style B fill:#f9F,stroke:#333,stroke-width:4px\n        ",
    "error syntax 3:25\nLexical error on line 3. Unrecognized text.\n    B[\"A wide one in {{\"x\"}}the middle\"]\n------------------------^",
  ),
  (
    "borlock\n  second\"]\naccDescr { d }           columns 3\n        one[\"One Slot\"]\n        two[\"Two slots\"]:2\n        ",
    "error syntax 1:1\nParse error on line 1:\nborlock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    id1([\"Thspaceis is the text in the box\"])\n", "ok\nroot columns=-1\n  id1 stadium \"Thspaceis is the text in the box\" span=1",
  ),
  (
    "block\n    id1([[\"This is the text in the box\"]]\n", "error syntax 2:10\nLexical error on line 2. Unrecognized text.\n    id1([[\"This is the text in the box\"]]\n---------^",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Star-t\")-->id2(\"Stop\")\n  style id1 fill:#636,stroke:#333,st-.roke-width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  id1 round \"Star-t\" span=1 styles=fill:#636|stroke:#333|st-.roke-width:4px\n  id-1-0 space \"id-1\" width=1\n  id2 round \"Stop\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:#fff|stroke-dasharray: 5 5\nedge 1-id1-id2 id1->id2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n    id1[[\"This is the textks with title in the box\"]]\n", "ok\nroot columns=-1\n  id1 subroutine \"This is the textks with title in the box\" span=1",
  ),
  (
    "blo[/\"x\"\\]ck colou\"x\"r slots{{", "error syntax 1:1\nParse error on line 1:\nblo[/\"x\"\\]ck colou\"x\"r slots{{\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "should log a warning ning when interpolateblock width exceeds column width",
    "error syntax 1:1\nParse error on line 1:\nshould log a warning ning when interpolateblock width exceeds column width\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        columns 1\n        A        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n          columns 3\n            B\n            C\n            D\n        end",
    "ok\nroot columns=1\n  A na \"A\" span=1\n  blockArrow block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=up|down\n  id-1 composite \"\" columns=3 color=0\n    B na \"B\" span=1\n    C na \"C\" span=1\n    D na \"D\" span=1",
  ),
  (
    "<[lock\n    id1(\"This is the text in thcolumns e box\")\n", "error syntax 1:1\nParse error on line 1:\n<[lock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'BLOCK_ARROW_START'",
  ),
  (
    "block\n  A space:2 B\n-- \"X\" --\"x\"B\n", "error syntax 3:7\nLexical error on line 3. Unrecognized text.\n-- \"X\" --\"x\"B\n------^",
  ),
  (
    "style statements applied to a blockclassDef a\n", "error syntax 1:1\nParse error on line 1:\nstyle statements applied to a blockclassDef a\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'style'",
  ),
  (
    "blocks next to each o(-thens 1\n  A:1\n  B:2\n r", "error syntax 1:1\nParse error on line 1:\nblocks next to each o(-thens 1\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "cpound blocks with title", "error syntax 1:1\nParse error on line 1:\ncpound blocks with title\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blo((cks on top of :each other", "error syntax 1:1\nParse error on line 1:\nblo((cks on top of :each other\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "Compound blo([\"x\"])ck", "error syntax 1:1\nParse error on line 1:\nCompound blo([\"x\"])ck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\nid1        columns 3\n        one[\"One ([Slot\"]\n        two[\"Two slots\"]:2\n             ",
    "ok\nroot columns=3\n  id1 na \"id1\" span=1\n  one square \"One ([Slot\" span=1\n  two square \"Two slots\" span=2",
  ),
  (
    "block\n          block\n            aBlock[\"ABloc\n        classDef     bBlock[\"BBlock\"]\n          end\n        ",
    "error syntax 4:30\nLexical error on line 4. Unrecognized text.\n        classDef     bBlock[\"BBlock\"]\n-----------------------------^",
  ),
  (
    "bloc          comns 3kArro", "error syntax 1:1\nParse error on line 1:\nbloc          comns 3kArro\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "  block\n    A\n    style A fill--969;\n", "ok\nroot columns=-1\n  A na \"A\" span=1 styles=fill--969;",
  ),
  (
    "block\n  blockArrowId<[\"bel\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"Label\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  blockArrowId\"`7<[\"Label\"]>(x, down)\n",
    "ok\nroot columns=-1\n  blockArrowId block_arrow \"bel\" span=1 dirs=right\n  blockArrowId2 block_arrow \"Label\" span=1 dirs=left\n  blockArrowId3 block_arrow \"Label\" span=1 dirs=up\n  blockArrowId4 block_arrow \"Label\" span=1 dirs=down\n  blockArrowId5 block_arrow \"Label\" span=1 dirs=x\n  blockArrowId6 block_arrow \"Label\" span=1 dirs=y\n  blockArrowId\"`7 block_arrow \"Label\" span=1 dirs=x|down",
  ),
  (
    "compound ((blcks 2", "error syntax 1:1\nParse error on line 1:\ncompound ((blcks 2\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "Arrow <locks", "error syntax 1:1\nParse error on line 1:\nArrow <locks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "shoulspaced read block.]padding from config at call time, not atmport time",
    "error syntax 1:1\nParse error on line 1:\nshoulspaced read block.]padding from config at call time, not atmport time\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    id1(((\"This(((is the text in tthe circle\")))\n", "ok\nroot columns=-1\n  id1 doublecircle \"This(((is the text in tthe circle\" span=1",
  ),
  (
    "bl<==>ock\n    id1(\"Thbox\"]]\nis is the text in the box\")\n", "error syntax 1:1\nParse error on line 1:\nbl<==>ock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bock\n    id-->1[(\"Database\")]\n", "error syntax 1:1\nParse error on line 1:\nbock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          block:compoundBlock[\"Compound block\"]\n            columns 1\n            block2[\"Block 2\"])))          end\n        ",
    "error syntax 4:31\nParse error on line 4:\n            block2[\"Block 2\"])))          end\n------------------------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'NODE_DSTART'",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"This is \"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:#333,stroke-width:4px\n",
    "error syntax 3:11\nLexical error on line 3. Unrecognized text.\n  db((\"DB\"This is \"))\n----------^",
  ),
  (
    "b\r\nlock-betab \n      a\n      b\n      block:group\n        c\n      <==>end\n    ",
    "error syntax 1:1\nParse error on line 1:\nb\r\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      block:first\n       b a\n      end\n      block:second\n        b\n      end\n      block:third\n        c]\n      end\n    ",
    "ok\nroot columns=-1\n  first composite \"\" span=1 color=0\n    b na \"b\" span=1\n    a na \"a\" span=1\n  second composite \"\" span=1 color=1\n  third composite \"\" span=1 color=2\n    c] na \"c]\" span=1",
  ),
  (
    "compound blockAs with title", "error syntax 1:1\nParse error on line 1:\ncompound blockAs with title\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n                    D\nx\n        end\n}      end\n      block:b1\n        block:b2\n          y\n        end\n      end\n    ",
    "error syntax 7:1\nLexical error on line 7. Unrecognized text.\n}      end\n^",
  ),
  (
    "block-beta\n      block:first\n        a\n      end\n      block:second\n        b\n      end\n      block:therird\n        c\n      end\numns 2])\n         ",
    "error syntax 11:9\nLexical error on line 11. Unrecognized text.\numns 2])\n--------^",
  ),
  (
    "block-beta\n  columns 1\n  A:1\n  B:2\n  C:3\n  D:4\n  E:3\n :2\n  G:1", "error syntax 8:2\nParse error on line 8:\n :2\n-^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'SIZE'",
  ),
  (
    "block\n          id1[\"first\"]  -->   id2[\"second\"]\n ock\n          colum     ",
    "ok\nroot columns=-1\n  id1 square \"first\"\n  id2 square \"second\"\n  ock na \"ock\" span=1\n  colum na \"colum\" span=1\nedge 1-id1-id2 id1->id2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->-..-id2(\"Stop\"),   style id1 fill:#636,stroke:#33,stroke-width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "error syntax 3:18\nParse error on line 3:\n  id1(\"Start\")-->-..-id2(\"Stop\"),   style id1 fill:#636,stroke:#33,stroke-width:4px\n-----------------^\nExpecting 'NODE_ID', got 'LINK'",
  ),
  (
    "block-beta\n      block:outer\n        block:inner\n          a\n        end\n    columns   end\n      block:sibling\n        b\n      end\n    ",
    "ok\nroot columns=-1\n  outer composite \"\" span=1 color=0\n    inner composite \"\" span=1 color=1\n      a na \"a\" span=1\n    columns na \"columns\" span=1\n  sibling composite \"\" span=1 color=2\n    b na \"b\" span=1",
  ),
  (
    "bBlock\n          id[\"<b>Bold</b>\"]\n               ", "error syntax 1:1\nParse error on line 1:\nbBlock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  columns 3\n  Frontend blockArra bowId6<[\" \"]>(right) Backend\n  space:2 down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,sclassDef DEFAULT xtroke:#333;\n  classDef back fill:#969,stroke:#333;\n  class Frontend front\n  class Backend,Database bclass A aack\n",
    "ok\nroot columns=3\n  Frontend na \"Frontend\" span=1 classes=front\n  blockArra na \"blockArra\" span=1\n  bowId6 block_arrow \" \" span=1 dirs=right\n  Backend na \"Backend\" span=1 classes=bclass A aack\n  id-1-0 space \"id-1\" width=2\n  id-1-1 space \"id-1\" width=2\n  down block_arrow \" \" span=1 dirs=down\n  Disk na \"Disk\" span=1\n  left block_arrow \" \" span=1 dirs=left\n  Database cylinder \"Database\" span=1 classes=bclass A aack\nclass front styles=[fill:#696|sclassDef DEFAULT xtroke:#333] text=[]\nclass back styles=[fill:#969|stroke:#333] text=[]",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-==>->id2(\"Stop\")\n  style id1 fill:#636,stroke:#333,stroke-width:4px\n  style id2 fill:#bbf,stroke:#f66, space B\n  A stroke-width:2px,color:#fff,stroke-dasharray: 5 ",
    "error syntax 3:15\nLexical error on line 3. Unrecognized text.\n  id1(\"Start\")-==>->id2(\"Stop\")\n--------------^",
  ),
  (
    "block\n        columns 1\n        A\n        bAlockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n          columns 3\n            B\n            C\n            D\n        end",
    "ok\nroot columns=1\n  A na \"A\" span=1\n  bAlockArrow block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=up|down\n  id-1 composite \"\" columns=3 color=0\n    B na \"B\" span=1\n    C na \"C\" span=1\n    D na \"D\" span=1",
  ),
  (
    "block\n    id1(((\"This is the otext  B fill:#f9F,stroin the circle\")<))\n",
    "error syntax 2:62\nLexical error on line 2. Unrecognized text.\n    id1(((\"This is the otext  B fill:#f9F,stroin the circle\")<))\n-------------------------------------------------------------^",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n     end\n     block:b1\n        block:b2\n          y\n        end\n      end\n    ",
    "ok\nroot columns=-1\n  a1 composite \"\" span=1 color=0\n    a2 composite \"\" span=1 color=1\n      x na \"x\" span=1\n  b1 composite \"\" span=1 color=2\n    b2 composite \"\" span=1 color=3\n      y na \"y\" span=1",
  ),
  (
    "block\n       id<b>Bold</b>\"]\n          ", "error syntax 2:10\nLexical error on line 2. Unrecognized text.\n       id<b>Bold</b>\"]\n---------^",
  ),
  (
    "lock d[[\"x\"]]b edge styles", "error syntax 1:1\nParse error on line 1:\nlock d[[\"x\"]]b edge styles\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n   :03id1([\"This is the text in the box\"])ck\n${p\n", "error syntax 2:4\nParse error on line 2:\n   :03id1([\"This is the text in the box\"])ck\n---^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'SIZE'",
  ),
  (
    "block\n  columns 3\n  Frontend blockArrowId6<[\" \"]>(right) Backend\n  space:2 down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,stroke:#333;\n  classDef back fill:#969,stroke:#333;((\"x\"))\n  class Frontend front\n  class Backend,Database back\n",
    "ok\nroot columns=3\n  Frontend na \"Frontend\" span=1 classes=front\n  blockArrowId6 block_arrow \" \" span=1 dirs=right\n  Backend na \"Backend\" span=1 classes=back\n  id-1-0 space \"id-1\" width=2\n  id-1-1 space \"id-1\" width=2\n  down block_arrow \" \" span=1 dirs=down\n  Disk na \"Disk\" span=1\n  left block_arrow \" \" span=1 dirs=left\n  Database cylinder \"Database\" span=1 classes=back\nclass front styles=[fill:#696|stroke:#333] text=[]\nclass back styles=[fill:#969|stroke:#333((\"x\"))] text=[]",
  ),
  (
    "blococks mixed wispace:h com\"`pound blocks", "error syntax 1:1\nParse error on line 1:\nblococks mixed wispace:h com\"`pound blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    b  block\n      <==>D\n    end\n    A[\" A[\"A: I am a wide one\"]\n",
    "error syntax 3:7\nParse error on line 3:\n      <==>D\n------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'LINK'",
  ),
  (
    "blo\r\ncks mixed with compound block", "error syntax 1:1\nParse error on line 1:\nblo\r\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowblockId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one~~~ in the middle\"]\n    C\n  end\n  space\n  D<[\n  ID --> D\n  C --> D\n  style B fill:#969,stroke:#333,stroke-width:4px\n",
    "error syntax 11:6\nLexical error on line 11. Unrecognized text.\n  D<[\n-----^",
  ),
  (
    "block\n   b c\n", "ok\nroot columns=-1\n  b na \"b\" span=1\n  c na \"c\" span=1",
  ),
  (
    "classDef stateme{{\"x\"}}n(-\"x\"-)ts applied to a)\n block", "error syntax 1:1\nParse error on line 1:\nclassDef stateme{{\"x\"}}n(-\"x\"-)ts applied to a)\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'classDef'",
  ),
  (
    "[ock2", "error syntax 1:1\nParse error on line 1:\n[ock2\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_DSTART'",
  ),
  (
    "block_arrclass A aow", "error syntax 1:1\nParse error on line 1:\nblock_arrclass A aow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    id1{{\"This is the text in t\nhe box\"}}\n", "ok\nroot columns=-1\n  id1 hexagon \"This is the text in t\nhe box\" span=1",
  ),
  (
    "block\n    i`d1[[\"This is the text in the box\"]]\n", "ok\nroot columns=-1\n  i`d1 subroutine \"This is the text in the box\" span=1",
  ),
  (
    "blo          columns auto\n          block1[\"Block 1\"]\n    ==  ", "error syntax 1:1\nParse error on line 1:\nblo          columns auto\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n   --       x\n      n the box\"]]\n  end\n      end\n      block:b1\n        block:b2\n          y\n        end\n      end\n    ",
    "error syntax 4:13\nLexical error on line 4. Unrecognized text.\n   --       x\n------------^",
  ),
  (
    "block\n   d1\"This is the text in the box\"}\n", "error syntax 2:35\nLexical error on line 2. Unrecognized text.\n   d1\"This is the text in the box\"}\n----------------------------------^",
  ),
  (
    "block\n          columns 2\n  6ce6,stroke:#333,        block1[\"Block 1\"]\n      ",
    "error syntax 3:14\nLexical error on line 3. Unrecognized text.\n  6ce6,stroke:#333,        block1[\"Block 1\"]\n-------------^",
  ),
  (
    "block\n  id1[/\"This is the text in the box\"/]\n  id2[\\\"This is the teto a bloxt in the box\"\\]\n  A[/\"Christmas\"\\ B[\\\"Go shoppiding\"/]\n",
    "error syntax 4:17\nLexical error on line 4. Unrecognized text.\n  A[/\"Christmas\"\\ B[\\\"Go shoppiding\"/]\n----------------^",
  ),
  (
    "block\n ock\n  A spacespace B\n  A --> B", "ok\nroot columns=-1\n  ock na \"ock\" span=1\n  A na \"A\" span=1\n  spacespace na \"spacespace\" span=1\n  B na \"B\" span=1\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\ncolum~~~ns 1\n  db((\"DB\"))\n  blockArrowId]6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:<[#333,stroke-width:4px\n",
    "ok\nroot columns=-1\n  colum~~~ns na \"colum~~~ns\" span=1\n  1 na \"1\" span=1\n  db circle \"DB\" span=1\n  blockArrowId]6 block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=down\n  ID composite \"\" span=1 color=0\n    A na \"A\" span=1\n    B square \"A wide one in the middle\" span=1 styles=fill:#939|stroke:<[#333|stroke-width:4px\n    C na \"C\" span=1\n  id-2-0 space \"id-2\" width=1\n  D na \"D\" span=1\nedge 1-ID-D ID->D \"\" arrow_open arrow_point normal solid\nedge 1-C-D C->D \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n    id1((\"This]>( is the text in the circle\"))\nclass A, B a", "ok\nroot columns=-1\n  id1 circle \"This]>( is the text in the circle\" span=1",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n      end\n   block:b1\n        block:b2\n     abel\"]>(left)\n       y\n        end\n      end\n    ",
    "error syntax 9:13\nParse error on line 9:\n     abel\"]>(left)\n------------^\nExpecting 'STR', got 'NODE_DEND'",
  ),
  (
    "block\n  columns 3\n  Frontend blockArrowId6<[\" \"]>(right) Backend\n  space:2 dow down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,stroke:#333;\n  classDef back fill:#969,stroke:#333;\n  class Frontend front\n  class Backend,Database back\n",
    "ok\nroot columns=3\n  Frontend na \"Frontend\" span=1 classes=front\n  blockArrowId6 block_arrow \" \" span=1 dirs=right\n  Backend na \"Backend\" span=1 classes=back\n  id-1-0 space \"id-1\" width=2\n  id-1-1 space \"id-1\" width=2\n  dow na \"dow\" span=1\n  down block_arrow \" \" span=1 dirs=down\n  Disk na \"Disk\" span=1\n  left block_arrow \" \" span=1 dirs=left\n  Database cylinder \"Database\" span=1 classes=back\nclass front styles=[fill:#696|stroke:#333] text=[]\nclass back styles=[fill:#969|stroke:#333] text=[]",
  ),
  (
    "  block\n   the box\"}\n  A\n    stylcolumns atoe A fill#969;\n", "error syntax 2:12\nLexical error on line 2. Unrecognized text.\n   the box\"}\n-----------^",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:#333,stroke-width:4:4px\n",
    "ok\nroot columns=1\n  db circle \"DB\" span=1\n  blockArrowId6 block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=down\n  ID composite \"\" span=1 color=0\n    A na \"A\" span=1\n    B square \"A wide one in the middle\" span=1 styles=fill:#939|stroke:#333|stroke-width:4:4px\n    C na \"C\" span=1\n  id-2-0 space \"id-2\" width=1\n  D na \"D\" span=1\nedge 1-ID-D ID->D \"\" arrow_open arrow_point normal solid\nedge 1-C-D C->D \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block_a[/rrow", "error syntax 1:1\nParse error on line 1:\nblock_a[/rrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          block\n            aBlock[\"ABlock\"]\n   columns 0         block\n              bBlo bBlock[\"BBlock\"]\n            end\n          end\n        ",
    "ok\nroot columns=-1\n  id-2 composite \"\" columns=0 color=0\n    aBlock square \"ABlock\" span=1\n    id-1 composite \"\" color=1\n      bBlo na \"bBlo\" span=1\n      bBlock square \"BBlock\" span=1",
  ),
  (
    "block\n         d[\"A label\"]\n          ", "ok\nroot columns=-1\n  d square \"A label\" span=1",
  ),
  (
    "block\n          c[|olumns auto\n          block1[\"ck 1\"]\n      ", "error syntax 2:14\nLexical error on line 2. Unrecognized text.\n          c[|olumns auto\n-------------^",
  ),
  (
    "classDef statements applied to a blok", "error syntax 1:1\nParse error on line 1:\nclassDef statements applied to a blok\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'classDef'",
  ),
  (
    "block\n      olumns 1\n        A\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n          column;s 3\n            B\n            C\n            D\n        end",
    "ok\nroot columns=-1\n  olumns na \"olumns\" span=1\n  1 na \"1\" span=1\n  A na \"A\" span=1\n  blockArrow block_arrow \"&nbsp;&nbsp;&nbsp;\" span=1 dirs=up|down\n  id-1 composite \"\" color=0\n    column;s na \"column;s\" span=1\n    3 na \"3\" span=1\n    B na \"B\" span=1\n    C na \"C\" span=1\n    D na \"D\" span=1",
  ),
  (
    "block_blockrrow", "error syntax 1:1\nParse error on line 1:\nblock_blockrrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n columns 3\n  a:3\n  block:group1:2\n    columns 2\n    h i j k\n  end\n  g\n  block:group2:3\n    %% columns auto (default)\n    l m n o p q r\n  end\n",
    "error syntax 10:21\nParse error on line 10:\n    %% columns auto (default)\n--------------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'NODE_DSTART'",
  ),
  (
    "block-beta\n     : block:first\n        a\n      end\n      block:second\n        b\n      end\n      block:third\n        c\n      end\n    ",
    "error syntax 2:6\nLexical error on line 2. Unrecognized text.\n     : block:first\n-----^",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  ;\"]>(down)\n  bbl===ock:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:#333,stroke-oke-width:4px\n",
    "error syntax 5:7\nParse error on line 5:\n  ;\"]>(down)\n------^\nExpecting 'STR', got 'NODE_DEND'",
  ),
  (
    "block\n          columns 2\n          b<lock1[\"Block 1block-beta]\n          block2[\"B[\\\"x\"\\]ock 2\"]\n        ",
    "error syntax 3:12\nLexical error on line 3. Unrecognized text.\n          b<lock1[\"Block 1block-beta]\n-----------^",
  ),
  (
    "blo[/\"x\"/]/]k1", "error syntax 1:1\nParse error on line 1:\nblo[/\"x\"/]/]k1\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bloin the circle\")))ck\n        columns 1\n        A\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n          columns 3\n            B\n            C\n            D\n        end",
    "error syntax 1:1\nParse error on line 1:\nbloin the circle\")))ck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "gi[(ves no slot to a icolumns\n2nterpolateimple block", "error syntax 1:1\nParse error on line 1:\ngi[(ves no slot to a icolumns\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blocks on top ofblblock\n          id1ock: each other", "error syntax 1:1\nParse error on line 1:\nblocks on top ofblblock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n  columns 1\n  A:1\n  B:2\n  C:3\n  D:4\n  E:3\n  block-betaF:2\n  G:1",
    "error syntax 8:8\nLexical error on line 8. Unrecognized text.\n  block-betaF:2\n-------^",
  ),
  (
    "block-beta\n      block:first\n        a\n      end\n  o--    block:second\n        b\n      end\n     block:third\n        c\n      end\n    ",
    "error syntax 5:10\nLexical error on line 5. Unrecognized text.\n  o--    block:second\n---------^",
  ),
  (
    "blocks with differen-- widthshs", "error syntax 1:1\nParse error on line 1:\nblocks with differen-- widthshs\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  A sp}}ace Bce B\n  Aocks-->B\n", "error syntax 2:7\nLexical error on line 2. Unrecognized text.\n  A sp}}ace Bce B\n------^",
  ),
  (
    "block\n  223A space B\n  A --> B", "ok\nroot columns=-1\n  223A na \"223A\" span=1\n  id-1-0 space \"id-1\" width=1\n  B na \"B\" span=1\n  A na \"A\"\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\nx-- a b c\n", "error syntax 2:5\nLexical error on line 2. Unrecognized text.\nx-- a b c\n----^",
  ),
  (
    "block\n        classDef black color:ffffff, fill:#000000;\n\n        mc[\"Memcache\"]\n        class mc black\n    == \"x\" ==>      ",
    "error syntax 6:5\nParse error on line 6:\n    == \"x\" ==>      \n----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'START_LINK'",
  ),
  (
    "styl-e statemblents applied to a block", "error syntax 1:1\nParse error on line 1:\nstyl-e statemblents applied to a block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  a bc\n", "ok\nroot columns=-1\n  a na \"a\" span=1\n  bc na \"bc\" span=1",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  bloblockck:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,strok:#333,stroke-width:4px\n",
    "error syntax 5:13\nLexical error on line 5. Unrecognized text.\n  bloblockck:ID\n------------^",
  ),
  (
    "block\n          b<lock1[\"Block 1\"]\n      ", "error syntax 2:12\nLexical error on line 2. Unrecognized text.\n          b<lock1[\"Block 1\"]\n-----------^",
  ),
  (
    "block\n          columns2\n          block1[\"Block 1\"]\n          block2[\"Block 2\"]\n        ",
    "ok\nroot columns=-1\n  columns2 na \"columns2\" span=1\n  block1 square \"Block 1\" span=1\n  block2 square \"Block 2\" span=1",
  ),
  (
    "block\n   `     classDef black xcolor:#ffffff, fill:#000000;\n\n        mc[\"Memcache\"]\n        class mc black\n        ",
    "ok\nroot columns=-1\n  ` na \"`\" span=1\n  mc square \"Memcache\" span=1 classes=black\nclass black styles=[xcolor:#ffffff|fill:#000000] text=[xfill:#ffffff]",
  ),
  (
    "bloc:#969,strokek-beta\n      aconstructor\n      b\n      block:group\n        c\n    --x  end\n    ",
    "error syntax 1:1\nParse error on line 1:\nbloc:#969,strokek-beta\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n        columns 3\n        space\n         middle[\"In the middle\"]\n        space\n        ",
    "ok\nroot columns=3\n  id-1-0 space \"id-1\" width=1\n  middle square \"In the middle\" span=1\n  id-2-0 space \"id-2\" width=1",
  ),
  (
    "block\n        classDef black color:#ffff fill:#000000;\n\n        mc[\"Memcache\"]\n        class mc black\n        ",
    "ok\nroot columns=-1\n  mc square \"Memcache\" span=1 classes=black\nclass black styles=[color:#ffff fill:#000000] text=[fill:#ffff bgFill:#000000]",
  ),
  (
    "block\n    id1{{\"This is the text in the box\"}}\n[\\", "error syntax 3:1\nParse error on line 3:\n[\\\n^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'NODE_DSTART'",
  ),
  (
    "onfibl\n          id-)1\n          id2\n          id3\n      ", "error syntax 1:1\nParse error on line 1:\nonfibl\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "should read block.paing frg fro[/m config at call time, not at import time",
    "error syntax 1:1\nParse error on line 1:\nshould read block.paing frg fro[/m config at call time, not at import time\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "Arrow blocks with multle points", "error syntax 1:1\nParse error on line 1:\nArrow blocks with multle points\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "should loxt in g a warn[\\\"x\"/]ng when block width exceeaccDescr { d }s column width",
    "error syntax 1:1\nParse error on line 1:\nshould loxt in g a warn[\\\"x\"/]ng when block width exceeaccDescr { d }s column width\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block_arrblock:ow", "error syntax 1:1\nParse error on line 1:\nblock_arrblock:ow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"S#bbf,stroke:#f6top\")\n  style id1 (((fill:#636,stroke:#333,stroke-width:4px\n  style idx--2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  id1 round \"Start\" span=1 styles=(((fill:#636|stroke:#333|stroke-width:4px\n  id-1-0 space \"id-1\" width=1\n  id2 round \"S#bbf,stroke:#f6top\" span=1\nedge 1-id1-id2 id1->id2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "blck\n    i bd1((\"This is the text in the circle\"))\n", "error syntax 1:1\nParse error on line 1:\nblck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    id1(\"This is the text in the bo{{x\")end\n", "error syntax 2:41\nParse error on line 2:\n    id1(\"This is the text in the bo{{x\")end\n----------------------------------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "block\n   --x       block1[\"Block 1\"]\n      ", "error syntax 2:4\nParse error on line 2:\n   --x       block1[\"Block 1\"]\n---^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'LINK'",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbssp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#969,stroke:#333,stroke-width:4px\n",
    "ok\nroot columns=1\n  db circle \"DB\" span=1\n  blockArrowId6 block_arrow \"&nbssp;&nbsp;&nbsp;\" span=1 dirs=down\n  ID composite \"\" span=1 color=0\n    A na \"A\" span=1\n    B square \"A wide one in the middle\" span=1 styles=fill:#969|stroke:#333|stroke-width:4px\n    C na \"C\" span=1\n  id-2-0 space \"id-2\" width=1\n  D na \"D\" span=1\nedge 1-ID-D ID->D \"\" arrow_open arrow_point normal solid\nedge 1-C-D C->D \"\" arrow_open arrow_point normal solid",
  ),
  (
    "when prrow blocksarsing a block diagram graph it should handle > ", "error syntax 1:1\nParse error on line 1:\nwhen prrow blocksarsing a block diagram graph it should handle > \n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blblocks with different widths", "error syntax 1:1\nParse error on line 1:\nblblocks with different widths\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          id[\"A labebel\"]\n     :     id2", "error syntax 3:6\nLexical error on line 3. Unrecognized text.\n     :     id2\n-----^",
  ),
  (
    "blo[|[|ck\n  a b(- c\n", "error syntax 1:1\nParse error on line 1:\nblo[|[|ck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    id1((\"This is the text in the circt[/he text in tin the le\"))\n",
    "ok\nroot columns=-1\n  id1 circle \"This is the text in the circt[/he text in tin the le\" span=1",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n      end\n      block:b1\n        block:b2\n          y\n  y\n        end\n      end\n    ",
    "ok\nroot columns=-1\n  a1 composite \"\" span=1 color=0\n    a2 composite \"\" span=1 color=1\n      x na \"x\" span=1\n  b1 composite \"\" span=1 color=2\n    b2 composite \"\" span=1 color=3\n      y na \"y\" span=1",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n      end\n      block:b\n        block:b2\n          y\n        end\n      end\n    ",
    "ok\nroot columns=-1\n  a1 composite \"\" span=1 color=0\n    a2 composite \"\" span=1 color=1\n      x na \"x\" span=1\n  b composite \"\" span=1 color=2\n    b2 composite \"\" span=1 color=3\n      y na \"y\" span=1",
  ),
  (
    "block\n  columns 3\n  Start((\"Start\")) space:2\n  dowaccDescr: dn<[\" \"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(right) Process1[\"Process A\"]\n  downAgain<[\"No\"]>(down) space r3<[\"Done\"]>(down)\n  Process2[\"Process B\"] r2<[\"Done\"]>(right) End((\"End\"))\n\n  style Start fill:#969;\n  style End fill:#696;\n",
    "error syntax 4:14\nLexical error on line 4. Unrecognized text.\n  dowaccDescr: dn<[\" \"]>(down) space:2\n-------------^",
  ),
  (
    "block\n        columns 3\n        one[\"One Slot\"]\n        two[\"T\"Two slots\"]:2\n        ",
    "error syntax 4:16\nLexical error on line 4. Unrecognized text.\n        two[\"T\"Two slots\"]:2\n---------------^",
  ),
  (
    "block\n    id1([\"This is the text in the she sbox\"])\n", "ok\nroot columns=-1\n  id1 stadium \"This is the text in the she sbox\" span=1",
  ),
  (
    "Arrow blocks with multi]>le pointpoints", "error syntax 1:1\nParse error on line 1:\nArrow blocks with multi]>le pointpoints\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blo  colu:2mns 3\n  a[\"A label\"] b:2 c:2 d\n", "error syntax 1:1\nParse error on line 1:\nblo  colu:2mns 3\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  id1[/\"This is the text in the box\"/]\n  id2[\\\"This is the text in ]>(he box\"\\]\n  A[/\"accTitle: tChristmas\"\\]\n  B[\\\"Go shoppg\"/]\n",
    "ok\nroot columns=-1\n  id1 lean_right \"This is the text in the box\" span=1\n  id2 lean_left \"This is the text in ]>(he box\" span=1\n  A trapezoid \"accTitle: tChristmas\" span=1\n  B inv_trapezoid \"Go shoppg\" span=1",
  ),
  (
    "compounblocks with title", "error syntax 1:1\nParse error on line 1:\ncompounblocks with title\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "classDef         id1 statements applied to a block", "error syntax 1:1\nParse error on line 1:\nclassDef         id1 statements applied to a block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'classDef'",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"Stop\")\n  style id1 fill:#636,stroke:#333,stroke-width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,oke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  id1 round \"Start\" span=1 styles=fill:#636|stroke:#333|stroke-width:4px\n  id-1-0 space \"id-1\" width=1\n  id2 round \"Stop\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:#fff|oke-dasharray: 5 5\nedge 1-id1-id2 id1->id2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "blclassDef a fill:#f96ck db edge styles", "error syntax 1:1\nParse error on line 1:\nblclassDef a fill:#f96ck db edge styles\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n     id1([       block\n            aBlock[\"ABlock\"]\n          block\n              bBllock[\"BBlock\"]\n            end\n          end\n        ",
    "error syntax 2:11\nLexical error on line 2. Unrecognized text.\n     id1([       block\n----------^",
  ),
  (
    "bloc\n        --x  id[\"<b>interpolateBold</b>\"]\n          ", "error syntax 1:1\nParse error on line 1:\nbloc\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    id1(\"This is the text it in the box\")end\n", "error syntax 2:42\nParse error on line 2:\n    id1(\"This is the text it in the box\")end\n-----------------------------------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'",
  ),
  (
    "co-)mpound blocks of  ompound blocks", "error syntax 1:1\nParse error on line 1:\nco-)mpound blocks of  ompound blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          id[\"A label\"]\n          :", "error syntax 3:11\nLexical error on line 3. Unrecognized text.\n          :\n----------^",
  ),
  (
    "block\n          id1\n     o     id2\n         (- id3\n      ", "error syntax 4:12\nLexical error on line 4. Unrecognized text.\n         (- id3\n-----------^",
  ),
  (
    "block\n    {{\"This is the text in the box\"<=columns =>}}\n", "error syntax 2:5\nParse error on line 2:\n    {{\"This is the text in the box\"<=columns =>}}\n----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'NODE_DSTART'",
  ),
  (
    "block\n          id[\"A label\"]\n  <[\"x\"]>(x,y)  teme      id2", "error syntax 3:3\nParse error on line 3:\n  <[\"x\"]>(x,y)  teme      id2\n--^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'BLOCK_ARROW_START'",
  ),
  (
    "block\n        columns 3\n        space\n        middle[\"In the middle\"]\n        space   \n        ",
    "ok\nroot columns=3\n  id-1-0 space \"id-1\" width=1\n  middle square \"In the middle\" span=1\n  id-2-0 space \"id-2\" width=1",
  ),
  (
    "bl])occlass A, B ak\n          columns 1\n          block1[\"Block 1\"]\n          block2[\"Block 2\"]\n        ",
    "error syntax 1:1\nParse error on line 1:\nbl])occlass A, B ak\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "ock1blo", "error syntax 1:1\nParse error on line 1:\nock1blo\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "  \u{e9}bloc   ock A\n    style A fill#969;\n", "error syntax 1:3\nParse error on line 1:\n  \u{e9}bloc   ock A\n--^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n ock 1\"]\n           block:first\n        a\n      end\n      block:second\n        b\n      end\n      block:third\n        c\n      end\n    ",
    "ok\nroot columns=-1\n  ock na \"ock\" span=1\n  1\"] na \"1\"]\" span=1\n  first composite \"\" span=1 color=0\n    a na \"a\" span=1\n  second composite \"\" span=1 color=1\n    b na \"b\" span=1\n  third composite \"\" span=1 color=2\n    c na \"c\" span=1",
  ),
  (
    "block\n          block:cock:compoundBlock[\"Compound block\"]\n            columns 1\n            blok2[\"Block 2\"]\n          end\n        ",
    "error syntax 2:21\nLexical error on line 2. Unrecognized text.\n          block:cock:compoundBlock[\"Compound block\"]\n--------------------^",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:4px;\n  class A blue\nA  style B fl:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  A na \"A\" span=1 classes=blue\n  id-1-0 space \"id-1\" width=1\n  B na \"B\" span=1 styles=fl:#bbf|stroke:#f66|stroke-width:2px|color:#fff|stroke-dasharray: 5 5\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid\nclass blue styles=[fill:#6e6ce6|stroke:#333|stroke-width:4px] text=[]",
  ),
  (
    "compound blocks<[ of accDescr: dc.ompound blocks", "error syntax 1:1\nParse error on line 1:\ncompound blocks<[ of accDescr: dc.ompound blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blocclass A ak_arrow", "error syntax 1:1\nParse error on line 1:\nblocclass A ak_arrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block-beta\n      bloclock:first\n \"\"      e text in a\n      end\n      block:second\n        b\n      end\n      block:third\n        c\n      end\n    ",
    "error syntax 2:15\nLexical error on line 2. Unrecognized text.\n      bloclock:first\n--------------^",
  ),
  (
    "ck\nstyle    id1([\"This is the text in the box\"])\n", "error syntax 1:1\nParse error on line 1:\nck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  A ace:2 B\n  A-- \"X\" -->B\n", "ok\nroot columns=-1\n  A na \"A\" span=1\n  ace na \"ace\" span=2\n  B na \"B\" span=1\nedge 1-A-B A->B \"X\" arrow_open arrow_point normal solid",
  ),
  (
    "should read block.paddiding from con]\n      fig at call time, not at import time",
    "error syntax 1:1\nParse error on line 1:\nshould read block.paddiding from con]\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "should read block.padding from config at caallall time, not at import time",
    "error syntax 1:1\nParse error on line 1:\nshould read block.padding from config at caallall time, not at import time\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n            coumns auto        block1[\"Block 1\"]\n      ", "ok\nroot columns=-1\n  coumns na \"coumns\" span=1\n  auto na \"auto\" span=1\n  block1 square \"Block 1\" span=1",
  ),
  (
    "should read block.padding from config at cal{{ time, not at import time", "error syntax 1:1\nParse error on line 1:\nshould read block.padding from config at cal{{ time, not at import time\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  A space B\n  A-->B\n  classD/]\n  id2[\\\"Thief blue fill:#6e6ce6,stroke:#333l,stroke-width:4px;\n  class A blue\n  style B fill:#bbf,roke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "error syntax 7:80\nParse error on line 7:\n  style B fill:#bbf,roke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n-------------------------------------------------------------------------------^\nExpecting 'NODE_DEND', got 'STR'",
  ),
  (
    "block-beta\n      block:first\n        a\n      end\n      block:secod\n        b\n      end\n      block:third\n        c\n      end\n    ",
    "ok\nroot columns=-1\n  first composite \"\" span=1 color=0\n    a na \"a\" span=1\n  secod composite \"\" span=1 color=1\n    b na \"b\" span=1\n  third composite \"\" span=1 color=2\n    c na \"c\" span=1",
  ),
  (
    "block\n  id\"1>\"This is the text in the box\"-.->\n", "error syntax 2:37\nLexical error on line 2. Unrecognized text.\n  id\"1>\"This is the text in the box\"-.->\n------------------------------------^",
  ),
  (
    "block\nA; classDef ${prop} color:#ffffff,fill:#0000(((; class A ${prop}", "error syntax 2:13\nLexical error on line 2. Unrecognized text.\nA; classDef ${prop} color:#ffffff,fill:#0000(((; class A ${prop}\n------------^",
  ),
  (
    "block colc<[olumns 0our sts", "error syntax 1:13\nLexical error on line 1. Unrecognized text.\nblock colc<[olumns 0our sts\n------------^",
  ),
  (
    "block\n          columns 2\n        A\n    style A f  block1[\"Block 1\"]\n          block2[\"Block 2\"]\n        ",
    "ok\nroot columns=2\n  A na \"A\" span=1 styles=f  block1[\"Block 1\"]\n  block2 square \"Block 2\" span=1",
  ),
  (
    "block\n          columns 2\n          block1[\"Block ((1\"]\n       block2[\"Block 2\"]\n        ",
    "ok\nroot columns=2\n  block1 square \"Block ((1\" span=1\n  block2 square \"Block 2\" span=1",
  ),
  (
    "block\n  A space B\n  A --B\n", "error syntax 3:7\nLexical error on line 3. Unrecognized text.\n  A --B\n------^",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:4px;\n  class A blue\n columns 3r style B fill:#bbf,stroke:#f66,stroke-width:2px,color:#ffftroke-dasharray: 5 5\n",
    "ok\nroot columns=3\n  A na \"A\" span=1 classes=blue\n  id-1-0 space \"id-1\" width=1\n  B na \"B\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:#ffftroke-dasharray: 5 5\n  r na \"r\" span=1\nedge 1-A-B A->B \"\" arrow_open arrow_point normal solid\nclass blue styles=[fill:#6e6ce6|stroke:#333|stroke-width:4px] text=[]",
  ),
  (
    "block\n          columns 2(\"x\")      ]>(    block1[\"Block 1\"]\n      ",
    "error syntax 2:20\nParse error on line 2:\n          columns 2(\"x\")      ]>(    block1[\"Block 1\"]\n-------------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'NODE_DSTART'",
  ),
  (
    "block\n  columns 3\n  Frontend blockArrowId6<[\" \"]>(right) Backend\n  space:2 down<[\" \"]>(down)\n upDisk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,stroke:#333;\n  classDef back fill:#969,stroke:#333;\n  class Frontend f<-.->ront\n  class Backend,Database back\n",
    "ok\nroot columns=3\n  Frontend na \"Frontend\" span=1 classes=f<-.->ront\n  blockArrowId6 block_arrow \" \" span=1 dirs=right\n  Backend na \"Backend\" span=1 classes=back\n  id-1-0 space \"id-1\" width=2\n  id-1-1 space \"id-1\" width=2\n  down block_arrow \" \" span=1 dirs=down\n  upDisk na \"upDisk\" span=1\n  left block_arrow \" \" span=1 dirs=left\n  Database cylinder \"Database\" span=1 classes=back\nclass front styles=[fill:#696|stroke:#333] text=[]\nclass back styles=[fill:#969|stroke:#333] text=[]",
  ),
  (
    "block\n  id1[/\"This is the text in the box\"/\n  id2[\\\"This is the text in the box\"\\]\n  A[/\"Christmas\"\\]\n  B[\\\"Go shopping\"/]\n",
    "error syntax 2:37\nLexical error on line 2. Unrecognized text.\n  id1[/\"This is the text in the box\"/\n------------------------------------^",
  ),
  (
    "block\n[/\"x\"/]         columns 1\n          block1[\"Block 1\"]\n\n          block\n                 columns 2\n         [\\\"x\"\\]   block2[\"Block 2\"]\n            block3[\"Block 3\"]\n          end\n        ",
    "error syntax 2:1\nParse error on line 2:\n[/\"x\"/]         columns 1\n^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'NODE_DSTART'",
  ),
  (
    "block\n          colummns auto\n          block1[\"Block 1\"]\n      ", "ok\nroot columns=-1\n  colummns na \"colummns\" span=1\n  auto na \"auto\" span=1\n  block1 square \"Block 1\" span=1",
  ),
  (
    "blblock\n  columns 3\n  a[\"A label\"] b:2 c:2 d\n", "error syntax 1:1\nParse error on line 1:\nblblock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\ncolumns 1\n    B[\"A wiwide one in the middle\"]\n  st\nyle B fill:#f9F->,stroke:#333,stroke-width:4px\n        ",
    "error syntax 5:11\nLexical error on line 5. Unrecognized text.\nyle B fill:#f9F->,stroke:#333,stroke-width:4px\n----------^",
  ),
  (
    "block\n  columns 3\n  a:3\n =block:group1:2\n    columns 2\n    h i j k\n  end\n  g\n  block:group2:3\n    %% columns auto (default)\n    l m n o p q r\n  end\n",
    "error syntax 4:2\nLexical error on line 4. Unrecognized text.\n =block:group1:2\n-^",
  ),
  (
    "block\n  id1[/\"This is the text in the box\"/]\n  id2[\\\"This is the text in the box\"\n  A[/\"Christmas\"\\]\n  B[\\\"Go shopping\"/]\n",
    "error syntax 3:37\nLexical error on line 3. Unrecognized text.\n  id2[\\\"This is the text in the box\"\n------------------------------------^",
  ),
  (
    "block\n${prop}p}", "error syntax 2:3\nLexical error on line 2. Unrecognized text.\n${prop}p}\n--^",
  ),
  (
    "block\n  A spa]]ce:2 B\n  A-- \"X\" -->>B\n", "error syntax 3:14\nParse error on line 3:\n  A-- \"X\" -->>B\n-------------^\nExpecting 'NODE_ID', got 'NODE_DSTART'",
  ),
  (
    "block\n        columns 3\n        space\n  \n        middle[\"In the middle\"]\n        space\n        ",
    "ok\nroot columns=3\n  id-1-0 space \"id-1\" width=1\n  middle square \"In the middle\" span=1\n  id-2-0 space \"id-2\" width=1",
  ),
  (
    "Aempt      block1[\"Bloylocks", "error syntax 1:1\nParse error on line 1:\nAempt      block1[\"Bloylocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "bl(-\"x\"-)ock\n          block\n            aBlock[\"ABlock\"]\n            bBlock[\"BBlock\"]\n          end\n        ",
    "error syntax 1:1\nParse error on line 1:\nbl(-\"x\"-)ock\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "classDef statements aplieblock2d to a block", "error syntax 1:1\nParse error on line 1:\nclassDef statements aplieblock2d to a block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'classDef'",
  ),
  (
    "block\n  columns 3\n  Start((\"Start\")) space:2\n  down<[\" \"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(right) Process1[\"Process A\"]\n  downAgain<[\"No\"]>(down) space -r3<[\"Done\"]>(down)\n  Process2[\"Process B\"] r2<[\"Done\"]>(ri(\"x\")ht) End((\"End\"))\n\n  style Start fill:#969;\n  style End fill:#696;\n",
    "error syntax 6:33\nLexical error on line 6. Unrecognized text.\n  downAgain<[\"No\"]>(down) space -r3<[\"Done\"]>(down)\n--------------------------------^",
  ),
  (
    "b~~~ocks nextclas to each other", "error syntax 1:1\nParse error on line 1:\nb~~~ocks nextclas to each other\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n    \"This       id1\n        id2\n       1   id3\n      ", "error syntax 2:6\nParse error on line 2:\n    \"This       id1\n-----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'STR'",
  ),
  (
    "block-be`ta\n      block:a1\n        block:a2\n          x\n      end\n      end\n      b\r\nlock:b1\n        block:b2\n          y\n        end\n      end\n    ",
    "error syntax 1:6\nLexical error on line 1. Unrecognized text.\nblock-be`ta\n-----^",
  ),
  (
    "blocks with different widthcks on top ofs", "error syntax 1:1\nParse error on line 1:\nblocks with different widthcks on top ofs\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block--accDescr: d-\n id1((\"This is the text in the circle\"))\n", "error syntax 1:6\nParse error on line 1:\nblock--accDescr: d-\n-----^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'START_LINK'",
  ),
  (
    "ock db edge style[/\"x\"\\]", "error syntax 1:1\nParse error on line 1:\nock db edge style[/\"x\"\\]\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "when parsing a blo\r\nck diagram graph it should handle > ", "error syntax 1:1\nParse error on line 1:\nwhen parsing a blo\r\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "  defaultblock\n    A\n    style A fill#969;\n", "error syntax 1:3\nParse error on line 1:\n  defaultblock\n--^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n       id1\n          id2\n         id3\n      ", "ok\nroot columns=-1\n  id1 na \"id1\" span=1\n  id2 na \"id2\" span=1\n  id3 na \"id3\" span=1",
  ),
  (
    "block coourblock: slots", "error syntax 1:17\nLexical error on line 1. Unrecognized text.\nblock coourblock: slots\n----------------^",
  ),
  (
    "block\n        columns 3\n        one[\"One Slot\"].->        two[\"Two slots\"]:2\n        ",
    "error syntax 3:25\nLexical error on line 3. Unrecognized text.\n        one[\"One Slot\"].->        two[\"Two slots\"]:2\n------------------------^",
  ),
  (
    "  block\n  label\"]    A\n    style A fistyle A,B xll#969;\n", "ok\nroot columns=-1\n  label\"] na \"label\"]\" span=1\n  A na \"A\" span=1 styles=fistyle A|B xll#969;",
  ),
  (
    "block\n    id1(((\"This is the text <[\"x\" == \"x\" ==> ]>(x,y)n the circle\")))\n",
    "error syntax 2:32\nLexical error on line 2. Unrecognized text.\n    id1(((\"This is the text <[\"x\" == \"x\" ==> ]>(x,y)n the circle\")))\n-------------------------------^",
  ),
  (
    "blck\n          id1\n          id2\n      ", "error syntax 1:1\nParse error on line 1:\nblck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"Stop\")\n  style id1 fill:#636,stroke:#333,stroendke-width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "ok\nroot columns=-1\n  id1 round \"Start\" span=1 styles=fill:#636|stroke:#333|stroendke-width:4px\n  id-1-0 space \"id-1\" width=1\n  id2 round \"Stop\" span=1 styles=fill:#bbf|stroke:#f66|stroke-width:2px|color:#fff|stroke-dasharray: 5 5\nedge 1-id1-id2 id1->id2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "block\n  columns 3\n  a label\"] b:2 c:2 d\n", "ok\nroot columns=3\n  a na \"a\" span=1\n  label\"] na \"label\"]\" span=1\n  b na \"b\" span=2\n  c na \"c\" span=2\n  d na \"d\" span=1",
  ),
  (
    "block\n  columns 3\n  a:3\n ( block:group1:2\n    columns 2\n    h i j k\n  end\n  g\n  block:group2:3\n    %% columns auto (default)\n    l m n o p q r\n  end\n",
    "error syntax 4:2\nParse error on line 4:\n ( block:group1:2\n-^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'NODE_DSTART'",
  ),
  (
    "compound b{lo 2", "error syntax 1:1\nParse error on line 1:\ncompound b{lo 2\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "compou blocks 2 {\"x\"}the", "error syntax 1:1\nParse error on line 1:\ncompou blocks 2 {\"x\"}the\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "blo ck\n  columt to a sins 3\n  a b c((\"x\")) d\n", "error syntax 1:1\nParse error on line 1:\nblo ck\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n 2   id1[(\"downDatabase)]\n", "error syntax 2:26\nParse error on line 2:\n 2   id1[(\"downDatabase)]\n-------------------------^\nExpecting 'NODE_DEND', got 'STR'",
  ),
  (
    "block\n    id1{\"This is th3e text in the box\"}\n", "ok\nroot columns=-1\n  id1 diamond \"This is th3e text in the box\" span=1",
  ),
  (
    "blockmpound block_arrow", "error syntax 1:1\nParse error on line 1:\nblockmpound block_arrow\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    ",em=pty blocks", "error syntax 1:1\nParse error on line 1:\n,em=pty blocks\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          columns 1\n          bloc/]k1[\"Block 1\"]\n\n          block\n            columns 2\n            block2[\"Block 2\"]\n[[\"x\"]]            block3[\"Block 3\"]\n          end\n        ",
    "error syntax 8:1\nParse error on line 8:\n[[\"x\"]]            block3[\"Block 3\"]\n^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'NODE_DSTART'",
  ),
  (
    "block\n  space:2 Bclass A a\n  }}A-- \"X\" -->B\n", "error syntax 3:3\nLexical error on line 3. Unrecognized text.\n  }}A-- \"X\" -->B\n--^",
  ),
  (
    "clDef statements appliked to a block", "error syntax 1:1\nParse error on line 1:\nclDef statements appliked to a block\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n      (-    id1[\"first\"]  -->   id2[\"second\"]\n      ", "error syntax 2:7\nParse error on line 2:\n      (-    id1[\"first\"]  -->   id2[\"second\"]\n------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'NODE_DSTART'",
  ),
  (
    "block\n          columns 1\n          block1[\"Block 1\"]\n [[      block2[\"Block 2\"]\n        ",
    "error syntax 4:2\nParse error on line 4:\n [[      block2[\"Block 2\"]\n-^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'EOF', got 'NODE_DSTART'",
  ),
  (
    "sho -. x\" .-> uld log a warning when blockaccDescr { d }width exceeds column width",
    "error syntax 1:1\nParse error on line 1:\nsho -. x\" .-> uld log a warning when blockaccDescr { d }width exceeds column width\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\n          id1[\"first\"]  -->  d2[\"second\"]\n      ", "ok\nroot columns=-1\n  id1 square \"first\"\n  d2 square \"second\"\nedge 1-id1-d2 id1->d2 \"\" arrow_open arrow_point normal solid",
  ),
  (
    "bl\n  A sp[(\"x\")]ace:2 B\n  A-- \"X\" -->B\n", "error syntax 1:1\nParse error on line 1:\nbl\n^\nExpecting 'BLOCK_DIAGRAM_KEY', got 'NODE_ID'",
  ),
  (
    "block\ndown  columns 3\n  a:3\n  block:group1:2\n    columns 2\n accTitle   h i j k\n  end\n  g\n  block:group2:3\n    %% columns auto (default)\n    l m n o p q r\n  end\n",
    "error syntax 10:21\nParse error on line 10:\n    %% columns auto (default)\n--------------------^\nExpecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', 'end', got 'NODE_DSTART'",
  ),
]
