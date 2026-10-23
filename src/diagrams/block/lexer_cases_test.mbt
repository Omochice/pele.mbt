// The token streams pele v1.8.0 makes of hand-written inputs, the block sources of its specs and Mermaid's documentation, and mutations of them.

///|
let lexer_cases : Array[(String, String)] = [
  (
    "block\n a[\"x\"] --> b", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nNODE_DSTART@8 [\nSTR@10 x\nNODE_DEND@12 ]\nLINK@14 --> \nNODE_ID@18 b\nEOF@19 \n$end@19 ",
  ),
  (
    "block-beta\n a b c", "BLOCK_DIAGRAM_KEY@0 block-beta\nNODE_ID@12 a\nNODE_ID@14 b\nNODE_ID@16 c\nEOF@17 \n$end@17 ",
  ),
  ("block-betax", "BLOCK_DIAGRAM_KEY@0 block\nINVALID@5 "),
  ("blockx y", "NODE_ID@0 blockx\nNODE_ID@7 y\nEOF@8 \n$end@8 "),
  (
    "block:g[\"T\"]:2\n a\nend", "id-block@0 block:\nNODE_ID@6 g\nNODE_DSTART@7 [\nSTR@9 T\nNODE_DEND@11 ]\nSIZE@12 2\nNODE_ID@16 a\nend@18 end\nEOF@21 \n$end@21 ",
  ),
  (
    "block\n columns 3\n columns auto\n columnsx\n columns\n x", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@7 3\nCOLUMNS@18 -1\nNODE_ID@32 columnsx\nNODE_ID@42 columns\nNODE_ID@51 x\nEOF@52 \n$end@52 ",
  ),
  (
    "block\n columns    12 a", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@7 12\nNODE_ID@21 a\nEOF@22 \n$end@22 ",
  ),
  (
    "block\n space space:3 space: spacex", "BLOCK_DIAGRAM_KEY@0 block\nSPACE_BLOCK@7 1\nSPACE_BLOCK@13 3\nSPACE_BLOCK@21 1\nINVALID@26 ",
  ),
  (
    "block\n classDef hot fill:#f96,stroke:#333\n class a,b , c hot\n classDefx\n classes",
    "BLOCK_DIAGRAM_KEY@0 block\nclassDef@7 classDef \nCLASSDEF_ID@16 hot \nCLASSDEF_STYLEOPTS@20 fill:#f96,stroke:#333\nclass@43 class \nCLASSENTITY_IDS@49 a,b\nSTYLECLASS@52  , c hot\nNODE_ID@62 classDefx\nNODE_ID@73 classes\nEOF@80 \n$end@80 ",
  ),
  (
    "block\n classDef DEFAULT x\n classDef DEFAULTx y\n classDef DEFAULT", "BLOCK_DIAGRAM_KEY@0 block\nclassDef@7 classDef \nDEFAULT_CLASSDEF_ID@16 DEFAULT \nCLASSDEF_STYLEOPTS@24 x\nclassDef@27 classDef \nCLASSDEF_ID@36 DEFAULTx \nCLASSDEF_STYLEOPTS@45 y\nclassDef@48 classDef \nINVALID@57 ",
  ),
  (
    "block\n classDef a", "BLOCK_DIAGRAM_KEY@0 block\nclassDef@7 classDef \nINVALID@16 ",
  ),
  (
    "block\n class a", "BLOCK_DIAGRAM_KEY@0 block\nclass@7 class \nCLASSENTITY_IDS@13 a\nSTYLECLASS@14 \n$end@14 ",
  ),
  ("block\n class ,", "BLOCK_DIAGRAM_KEY@0 block\nclass@7 class \nINVALID@13 "),
  (
    "block\n style a,b fill:red;stroke:blue\n stylex", "BLOCK_DIAGRAM_KEY@0 block\nstyle@7 style \nSTYLE_ENTITY_IDS@13 a,b\nSTYLE_DEFINITION_DATA@16  fill:red;stroke:blue\nNODE_ID@39 stylex\nEOF@45 \n$end@45 ",
  ),
  ("block\n style ", "BLOCK_DIAGRAM_KEY@0 block\nstyle@7 style \n$end@13 "),
  (
    "block\n default linkStyle interpolate defaultx", "BLOCK_DIAGRAM_KEY@0 block\nDEFAULT@7 default\nLINKSTYLE@15 linkStyle\nINTERPOLATE@25 interpolate\nNODE_ID@37 defaultx\nEOF@45 \n$end@45 ",
  ),
  (
    "block\n accTitle : t\n accDescr: d\n accDescr { multi\n line }\n a", "BLOCK_DIAGRAM_KEY@0 block\nacc_title@7 accTitle : \nacc_title_value@18 t\nacc_descr@21 accDescr: \nacc_descr_value@31 d\nacc_descr_multiline_value@45 multi\n line \nNODE_ID@60 a\nEOF@61 \n$end@61 ",
  ),
  (
    "block\n accDescr {", "BLOCK_DIAGRAM_KEY@0 block\nacc_descr_multiline_value@17 \n$end@17 ",
  ),
  (
    "block\n accTitle", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 accTitle\nEOF@15 \n$end@15 ",
  ),
  (
    "block\n a end endx", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nend@9 end \nNODE_ID@13 endx\nEOF@17 \n$end@17 ",
  ),
  (
    "block\n a(-\"x\"-) b-)", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nNODE_DSTART@8 (-\nSTR@11 x\nNODE_DEND@13 -)\nNODE_ID@16 b\nNODE_DSTART@17 -)\n$end@19 ",
  ),
  (
    "block\n a(\"x\") b((\"x\")) c(((\"x\"))) d([\"x\"]) e[[\"x\"]] f[(\"x\")] g[|\"x\"] h[\\\"x\"\\] i[/\"x\"/] j[/\"x\"\\] k[\\\"x\"/]",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nNODE_DSTART@8 (\nSTR@10 x\nNODE_DEND@12 )\nNODE_ID@14 b\nNODE_DSTART@15 ((\nSTR@18 x\nNODE_DEND@20 ))\nNODE_ID@23 c\nNODE_DSTART@24 (((\nSTR@28 x\nNODE_DEND@30 )))\nNODE_ID@34 d\nNODE_DSTART@35 ([\nSTR@38 x\nNODE_DEND@40 ])\nNODE_ID@43 e\nNODE_DSTART@44 [[\nSTR@47 x\nNODE_DEND@49 ]]\nNODE_ID@52 f\nNODE_DSTART@53 [(\nSTR@56 x\nNODE_DEND@58 )]\nNODE_ID@61 g\nNODE_DSTART@62 [|\nSTR@65 x\nNODE_DEND@67 ]\nNODE_ID@69 h\nNODE_DSTART@70 [\\\nSTR@73 x\nNODE_DEND@75 \\]\nNODE_ID@78 i\nNODE_DSTART@79 [/\nSTR@82 x\nNODE_DEND@84 /]\nNODE_ID@87 j\nNODE_DSTART@88 [/\nSTR@91 x\nNODE_DEND@93 \\]\nNODE_ID@96 k\nNODE_DSTART@97 [\\\nSTR@100 x\nNODE_DEND@102 /]\nEOF@104 \n$end@104 ",
  ),
  (
    "block\n a{\"x\"} b{{\"x\"}} c>\"x\"] d)\"x\"( e))\"x\"((", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nNODE_DSTART@8 {\nSTR@10 x\nNODE_DEND@12 }\nNODE_ID@14 b\nNODE_DSTART@15 {{\nSTR@18 x\nNODE_DEND@20 }}\nNODE_ID@23 c\nNODE_DSTART@24 >\nSTR@26 x\nNODE_DEND@28 ]\nNODE_ID@30 d\nNODE_DSTART@31 )\nSTR@33 x\nNODE_DEND@35 (\nNODE_ID@37 e\nNODE_DSTART@38 ))\nSTR@41 x\nNODE_DEND@43 ((\nEOF@45 \n$end@45 ",
  ),
  (
    "block\n a(\"x\"] b(\"x\"))) c(\"x\")]", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nNODE_DSTART@8 (\nSTR@10 x\nNODE_DEND@12 ]\nNODE_ID@14 b\nNODE_DSTART@15 (\nSTR@17 x\nNODE_DEND@19 )))\nNODE_ID@23 c\nNODE_DSTART@24 (\nSTR@26 x\nNODE_DEND@28 )]\nEOF@30 \n$end@30 ",
  ),
  (
    "block\n a[\"x\"", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nNODE_DSTART@8 [\nSTR@10 x\n$end@12 ",
  ),
  (
    "block\n a[\"`md`\"]", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nNODE_DSTART@8 [\nMD_STR@11 md\nNODE_DEND@15 ]\nEOF@16 \n$end@16 ",
  ),
  (
    "block\n a[\"`md", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nNODE_DSTART@8 [\nMD_STR@11 md\n$end@13 ",
  ),
  (
    "block\n a[\"`m\"d`\"]", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nNODE_DSTART@8 [\nMD_STR@11 m\nINVALID@12 ",
  ),
  (
    "block\n a<[\"x\"]>(right) b<[\"y\"]>( up , down,x,y ) c<[\"z\"]>(rightleft)",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nBLOCK_ARROW_START@8 <[\nSTR@11 x\nDIR@16 right\nBLOCK_ARROW_END@21 ]>\nNODE_ID@23 b\nBLOCK_ARROW_START@24 <[\nSTR@27 y\nDIR@32  up \nDIR@36 down\nDIR@42 x\nDIR@44 y \nBLOCK_ARROW_END@47 ]>\nNODE_ID@49 c\nBLOCK_ARROW_START@50 <[\nSTR@53 z\nDIR@58 right\nDIR@63 left\nBLOCK_ARROW_END@67 ]>\nEOF@68 \n$end@68 ",
  ),
  (
    "block\n a<[\"x\"]>  (left)", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nBLOCK_ARROW_START@8 <[\nSTR@11 x\nDIR@18 left\nBLOCK_ARROW_END@22 ]>\nEOF@23 \n$end@23 ",
  ),
  (
    "block\n a<[\"x\"]>(sideways)", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nBLOCK_ARROW_START@8 <[\nSTR@11 x\nINVALID@16 ",
  ),
  (
    "block\n a<[\"x\"]>(", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nBLOCK_ARROW_START@8 <[\nSTR@11 x\n$end@16 ",
  ),
  (
    "block\n a<[\"x\"]", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nBLOCK_ARROW_START@8 <[\nSTR@11 x\nINVALID@13 ",
  ),
  (
    "block\n a<[x]>", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nBLOCK_ARROW_START@8 <[\nINVALID@10 ",
  ),
  (
    "block\n a --> b\n a --- b\n a --x b\n a --o b\n a <--> b\n a x--x b\n a o--o b\n a ==> b\n a === b\n a -.-> b\n a -.- b\n a <-.-> b",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nLINK@9 --> \nNODE_ID@13 b\nNODE_ID@16 a\nLINK@18 --- \nNODE_ID@22 b\nNODE_ID@25 a\nLINK@27 --x \nNODE_ID@31 b\nNODE_ID@34 a\nLINK@36 --o \nNODE_ID@40 b\nNODE_ID@43 a\nLINK@45 <--> \nNODE_ID@50 b\nNODE_ID@53 a\nNODE_ID@55 x\nLINK@56 --x \nNODE_ID@60 b\nNODE_ID@63 a\nNODE_ID@65 o\nLINK@66 --o \nNODE_ID@70 b\nNODE_ID@73 a\nLINK@75 ==> \nNODE_ID@79 b\nNODE_ID@82 a\nLINK@84 === \nNODE_ID@88 b\nNODE_ID@91 a\nLINK@93 -.-> \nNODE_ID@98 b\nNODE_ID@101 a\nLINK@103 -.- \nNODE_ID@107 b\nNODE_ID@110 a\nLINK@112 <-.-> \nNODE_ID@118 b\nEOF@119 \n$end@119 ",
  ),
  (
    "block\n a -- \"x\" --> b\n a == \"y\" ==> b\n a -. \"z\" .-> b\n a -- \"`m`\" --> b",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nSTART_LINK@9 -- \nLINK_LABEL@12 \"\nSTR@13 x\nLINK@15  --> \nNODE_ID@20 b\nNODE_ID@23 a\nSTART_LINK@25 == \nLINK_LABEL@28 \"\nSTR@29 y\nLINK@31  ==> \nNODE_ID@36 b\nNODE_ID@39 a\nSTART_LINK@41 -. \nLINK_LABEL@44 \"\nSTR@45 z\nLINK@47  .-> \nNODE_ID@52 b\nNODE_ID@55 a\nSTART_LINK@57 -- \nMD_STR@62 m\nLINK@65  --> \nNODE_ID@70 b\nEOF@71 \n$end@71 ",
  ),
  (
    "block\n a -- \"x\" b", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nSTART_LINK@9 -- \nLINK_LABEL@12 \"\nSTR@13 x\nINVALID@15 ",
  ),
  (
    "block\n a -- \"x", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nSTART_LINK@9 -- \nLINK_LABEL@12 \"\nSTR@13 x\nSTR@14 \n$end@14 ",
  ),
  ("block\n a - b", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nINVALID@9 "),
  ("block\n a -> b", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nINVALID@9 "),
  ("block\n a = b", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nINVALID@9 "),
  (
    "block\n a == b", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nSTART_LINK@9 == \nINVALID@12 ",
  ),
  (
    "block\n a ~~~ b", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nNODE_ID@9 ~~~\nNODE_ID@13 b\nEOF@14 \n$end@14 ",
  ),
  (
    "block\n a -..- b", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nLINK@9 -..- \nNODE_ID@14 b\nEOF@15 \n$end@15 ",
  ),
  (
    "block\n a -...-> b", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nLINK@9 -...-> \nNODE_ID@16 b\nEOF@17 \n$end@17 ",
  ),
  (
    "block\n a:2 b:03 c: d", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nSIZE@8 2\nNODE_ID@11 b\nSIZE@12 03\nNODE_ID@16 c\nINVALID@17 ",
  ),
  ("block\n \"x\"", "BLOCK_DIAGRAM_KEY@0 block\nSTR@8 x\nEOF@10 \n$end@10 "),
  (
    "block\n \u{e9} \u{fc} \u{4e2d}", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 \u{e9}\nNODE_ID@9 \u{fc}\nNODE_ID@11 \u{4e2d}\nEOF@12 \n$end@12 ",
  ),
  (
    "block\n a\u{a0}b", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a\nNODE_ID@9 b\nEOF@10 \n$end@10 ",
  ),
  ("block\n a;b", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 a;b\nEOF@10 \n$end@10 "),
  ("", "EOF@0 \n$end@0 "),
  ("block", "BLOCK_DIAGRAM_KEY@0 block\nEOF@5 \n$end@5 "),
  ("block\n", "BLOCK_DIAGRAM_KEY@0 block\nEOF@6 \n$end@6 "),
  (
    "when parsing a block diagram graph it should handle > ", "NODE_ID@0 when\nNODE_ID@5 parsing\nNODE_ID@13 a\nBLOCK_DIAGRAM_KEY@15 block\nNODE_ID@21 diagram\nNODE_ID@29 graph\nNODE_ID@35 it\nNODE_ID@38 should\nNODE_ID@45 handle\nNODE_DSTART@52 >\nINVALID@53 ",
  ),
  (
    "block-beta\n          id\n      ", "BLOCK_DIAGRAM_KEY@0 block-beta\nNODE_ID@21 id\nEOF@30 \n$end@30 ",
  ),
  (
    "block\n          id[\"A label\"]\n          ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id\nNODE_DSTART@18 [\nSTR@20 A label\nNODE_DEND@28 ]\nEOF@40 \n$end@40 ",
  ),
  (
    "block\n          id[\"<b>Bold</b>\"]\n          ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id\nNODE_DSTART@18 [\nSTR@20 <b>Bold</b>\nNODE_DEND@32 ]\nEOF@44 \n$end@44 ",
  ),
  (
    "block\n          id1\n          id2\n      ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1\nNODE_ID@30 id2\nEOF@40 \n$end@40 ",
  ),
  (
    "block\n          id1\n          id2\n          id3\n      ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1\nNODE_ID@30 id2\nNODE_ID@44 id3\nEOF@54 \n$end@54 ",
  ),
  (
    "block\n          id[\"A label\"]\n          id2", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id\nNODE_DSTART@18 [\nSTR@20 A label\nNODE_DEND@28 ]\nNODE_ID@40 id2\nEOF@43 \n$end@43 ",
  ),
  (
    "block\n          id1[\"first\"]  -->   id2[\"second\"]\n      ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1\nNODE_DSTART@19 [\nSTR@21 first\nNODE_DEND@27 ]\nLINK@30 -->   \nNODE_ID@36 id2\nNODE_DSTART@39 [\nSTR@41 second\nNODE_DEND@48 ]\nEOF@56 \n$end@56 ",
  ),
  (
    "block\n          id1[\"first\"]  -- \"a label\" -->   id2[\"second\"]\n      ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1\nNODE_DSTART@19 [\nSTR@21 first\nNODE_DEND@27 ]\nSTART_LINK@30 -- \nLINK_LABEL@33 \"\nSTR@34 a label\nLINK@42  -->   \nNODE_ID@49 id2\nNODE_DSTART@52 [\nSTR@54 second\nNODE_DEND@61 ]\nEOF@69 \n$end@69 ",
  ),
  (
    "block\n          columns 2\n          block1[\"Block 1\"]\n      ", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@16 2\nNODE_ID@36 block1\nNODE_DSTART@42 [\nSTR@44 Block 1\nNODE_DEND@52 ]\nEOF@60 \n$end@60 ",
  ),
  (
    "block\n          block1[\"Block 1\"]\n      ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 block1\nNODE_DSTART@22 [\nSTR@24 Block 1\nNODE_DEND@32 ]\nEOF@40 \n$end@40 ",
  ),
  (
    "block\n          columns auto\n          block1[\"Block 1\"]\n      ", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@16 -1\nNODE_ID@39 block1\nNODE_DSTART@45 [\nSTR@47 Block 1\nNODE_DEND@55 ]\nEOF@63 \n$end@63 ",
  ),
  (
    "blocks next to each other", "NODE_ID@0 blocks\nNODE_ID@7 next\nNODE_ID@12 to\nNODE_ID@15 each\nNODE_ID@20 other\nEOF@25 \n$end@25 ",
  ),
  (
    "block\n          columns 2\n          block1[\"Block 1\"]\n          block2[\"Block 2\"]\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@16 2\nNODE_ID@36 block1\nNODE_DSTART@42 [\nSTR@44 Block 1\nNODE_DEND@52 ]\nNODE_ID@64 block2\nNODE_DSTART@70 [\nSTR@72 Block 2\nNODE_DEND@80 ]\nEOF@90 \n$end@90 ",
  ),
  (
    "blocks on top of each other", "NODE_ID@0 blocks\nNODE_ID@7 on\nNODE_ID@10 top\nNODE_ID@14 of\nNODE_ID@17 each\nNODE_ID@22 other\nEOF@27 \n$end@27 ",
  ),
  (
    "block\n          columns 1\n          block1[\"Block 1\"]\n          block2[\"Block 2\"]\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@16 1\nNODE_ID@36 block1\nNODE_DSTART@42 [\nSTR@44 Block 1\nNODE_DEND@52 ]\nNODE_ID@64 block2\nNODE_DSTART@70 [\nSTR@72 Block 2\nNODE_DEND@80 ]\nEOF@90 \n$end@90 ",
  ),
  (
    "compound blocks 2", "NODE_ID@0 compound\nNODE_ID@9 blocks\nNODE_ID@16 2\nEOF@17 \n$end@17 ",
  ),
  (
    "block\n          block\n            aBlock[\"ABlock\"]\n            bBlock[\"BBlock\"]\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@16 block\nNODE_ID@34 aBlock\nNODE_DSTART@40 [\nSTR@42 ABlock\nNODE_DEND@49 ]\nNODE_ID@63 bBlock\nNODE_DSTART@69 [\nSTR@71 BBlock\nNODE_DEND@78 ]\nend@90 end\n        \nEOF@102 \n$end@102 ",
  ),
  (
    "compound blocks of compound blocks", "NODE_ID@0 compound\nNODE_ID@9 blocks\nNODE_ID@16 of\nNODE_ID@19 compound\nNODE_ID@28 blocks\nEOF@34 \n$end@34 ",
  ),
  (
    "block\n          block\n            aBlock[\"ABlock\"]\n            block\n              bBlock[\"BBlock\"]\n            end\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@16 block\nNODE_ID@34 aBlock\nNODE_DSTART@40 [\nSTR@42 ABlock\nNODE_DEND@49 ]\nBLOCK_DIAGRAM_KEY@63 block\nNODE_ID@83 bBlock\nNODE_DSTART@89 [\nSTR@91 BBlock\nNODE_DEND@98 ]\nend@112 end\n          \nend@126 end\n        \nEOF@138 \n$end@138 ",
  ),
  (
    "compound blocks with title", "NODE_ID@0 compound\nNODE_ID@9 blocks\nNODE_ID@16 with\nNODE_ID@21 title\nEOF@26 \n$end@26 ",
  ),
  (
    "block\n          block:compoundBlock[\"Compound block\"]\n            columns 1\n            block2[\"Block 2\"]\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nid-block@16 block:\nNODE_ID@22 compoundBlock\nNODE_DSTART@35 [\nSTR@37 Compound block\nNODE_DEND@52 ]\nCOLUMNS@66 1\nNODE_ID@88 block2\nNODE_DSTART@94 [\nSTR@96 Block 2\nNODE_DEND@104 ]\nend@116 end\n        \nEOF@128 \n$end@128 ",
  ),
  (
    "Compound block", "NODE_ID@0 Compound\nBLOCK_DIAGRAM_KEY@9 block\nEOF@14 \n$end@14 ",
  ),
  ("block2", "NODE_ID@0 block2\nEOF@6 \n$end@6 "),
  (
    "blocks mixed with compound blocks", "NODE_ID@0 blocks\nNODE_ID@7 mixed\nNODE_ID@13 with\nNODE_ID@18 compound\nNODE_ID@27 blocks\nEOF@33 \n$end@33 ",
  ),
  (
    "block\n          columns 1\n          block1[\"Block 1\"]\n\n          block\n            columns 2\n            block2[\"Block 2\"]\n            block3[\"Block 3\"]\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@16 1\nNODE_ID@36 block1\nNODE_DSTART@42 [\nSTR@44 Block 1\nNODE_DEND@52 ]\nBLOCK_DIAGRAM_KEY@65 block\nCOLUMNS@83 2\nNODE_ID@105 block2\nNODE_DSTART@111 [\nSTR@113 Block 2\nNODE_DEND@121 ]\nNODE_ID@135 block3\nNODE_DSTART@141 [\nSTR@143 Block 3\nNODE_DEND@151 ]\nend@163 end\n        \nEOF@175 \n$end@175 ",
  ),
  ("Arrow blocks", "NODE_ID@0 Arrow\nNODE_ID@6 blocks\nEOF@12 \n$end@12 "),
  (
    "block\n        columns 3\n        block1[\"Block 1\"]\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(right)\n        block2[\"Block 2\"]",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nNODE_ID@32 block1\nNODE_DSTART@38 [\nSTR@40 Block 1\nNODE_DEND@48 ]\nNODE_ID@58 blockArrow\nBLOCK_ARROW_START@68 <[\nSTR@71 &nbsp;&nbsp;&nbsp;\nDIR@93 right\nBLOCK_ARROW_END@98 ]>\nNODE_ID@108 block2\nNODE_DSTART@114 [\nSTR@116 Block 2\nNODE_DEND@124 ]\nEOF@125 \n$end@125 ",
  ),
  ("block1", "NODE_ID@0 block1\nEOF@6 \n$end@6 "),
  ("blockArrow", "NODE_ID@0 blockArrow\nEOF@10 \n$end@10 "),
  ("block_arrow", "NODE_ID@0 block_arrow\nEOF@11 \n$end@11 "),
  (
    "Arrow blocks with multiple points", "NODE_ID@0 Arrow\nNODE_ID@6 blocks\nNODE_ID@13 with\nNODE_ID@18 multiple\nNODE_ID@27 points\nEOF@33 \n$end@33 ",
  ),
  (
    "block\n        columns 1\n        A\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n          columns 3\n            B\n            C\n            D\n        end",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 1\nNODE_ID@32 A\nNODE_ID@42 blockArrow\nBLOCK_ARROW_START@52 <[\nSTR@55 &nbsp;&nbsp;&nbsp;\nDIR@77 up\nDIR@79 down\nBLOCK_ARROW_END@85 ]>\nBLOCK_DIAGRAM_KEY@95 block\nCOLUMNS@111 3\nNODE_ID@133 B\nNODE_ID@147 C\nNODE_ID@161 D\nend@171 end\nEOF@174 \n$end@174 ",
  ),
  (
    "blocks with different widths", "NODE_ID@0 blocks\nNODE_ID@7 with\nNODE_ID@12 different\nNODE_ID@22 widths\nEOF@28 \n$end@28 ",
  ),
  (
    "block\n        columns 3\n        one[\"One Slot\"]\n        two[\"Two slots\"]:2\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nNODE_ID@32 one\nNODE_DSTART@35 [\nSTR@37 One Slot\nNODE_DEND@46 ]\nNODE_ID@56 two\nNODE_DSTART@59 [\nSTR@61 Two slots\nNODE_DEND@71 ]\nSIZE@72 2\nEOF@83 \n$end@83 ",
  ),
  ("empty blocks", "NODE_ID@0 empty\nNODE_ID@6 blocks\nEOF@12 \n$end@12 "),
  (
    "block\n        columns 3\n        space\n        middle[\"In the middle\"]\n        space\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nSPACE_BLOCK@32 1\nNODE_ID@46 middle\nNODE_DSTART@52 [\nSTR@54 In the middle\nNODE_DEND@68 ]\nSPACE_BLOCK@78 1\nEOF@92 \n$end@92 ",
  ),
  (
    "classDef statements applied to a block", "classDef@0 classDef \nCLASSDEF_ID@9 statements \nCLASSDEF_STYLEOPTS@20 applied to a block\nEOF@38 \n$end@38 ",
  ),
  (
    "block\n        classDef black color:#ffffff, fill:#000000;\n\n        mc[\"Memcache\"]\n        class mc black\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nclassDef@14 classDef \nCLASSDEF_ID@23 black \nCLASSDEF_STYLEOPTS@29 color:#ffffff, fill:#000000;\nNODE_ID@67 mc\nNODE_DSTART@69 [\nSTR@71 Memcache\nNODE_DEND@80 ]\nclass@90 class \nCLASSENTITY_IDS@96 mc\nSTYLECLASS@98  black\nEOF@113 \n$end@113 ",
  ),
  (
    "style statements applied to a block", "style@0 style \nSTYLE_ENTITY_IDS@6 statements\nSTYLE_DEFINITION_DATA@16  applied to a block\nEOF@35 \n$end@35 ",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B fill:#f9F,stroke:#333,stroke-width:4px\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@20 B\nNODE_DSTART@21 [\nSTR@23 A wide one in the middle\nNODE_DEND@48 ]\nstyle@52 style \nSTYLE_ENTITY_IDS@58 B\nSTYLE_DEFINITION_DATA@59  fill:#f9F,stroke:#333,stroke-width:4px\nEOF@107 \n$end@107 ",
  ),
  (
    "should log a warning when block width exceeds column width", "NODE_ID@0 should\nNODE_ID@7 log\nNODE_ID@11 a\nNODE_ID@13 warning\nNODE_ID@21 when\nBLOCK_DIAGRAM_KEY@26 block\nNODE_ID@32 width\nNODE_ID@38 exceeds\nNODE_ID@46 column\nNODE_ID@53 width\nEOF@58 \n$end@58 ",
  ),
  (
    "block-beta\n  columns 1\n  A:1\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2\n  G:1", "BLOCK_DIAGRAM_KEY@0 block-beta\nCOLUMNS@13 1\nNODE_ID@25 A\nSIZE@26 1\nNODE_ID@31 B\nSIZE@32 2\nNODE_ID@37 C\nSIZE@38 3\nNODE_ID@43 D\nSIZE@44 4\nNODE_ID@49 E\nSIZE@50 3\nNODE_ID@55 F\nSIZE@56 2\nNODE_ID@61 G\nSIZE@62 1\nEOF@64 \n$end@64 ",
  ),
  (
    "block\n${prop}", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 $\nNODE_DSTART@7 {\nINVALID@8 ",
  ),
  (
    "block\nA; classDef ${prop} color:#ffffff,fill:#000000; class A ${prop}", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 A;\nclassDef@9 classDef \nINVALID@18 ",
  ),
  (
    "block colour slots", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 colour\nNODE_ID@13 slots\nEOF@18 \n$end@18 ",
  ),
  (
    "block-beta\n      block:first\n        a\n      end\n      block:second\n        b\n      end\n      block:third\n        c\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 first\nNODE_ID@37 a\nend@45 end\n      \nid-block@55 block:\nNODE_ID@61 second\nNODE_ID@76 b\nend@84 end\n      \nid-block@94 block:\nNODE_ID@100 third\nNODE_ID@114 c\nend@122 end\n    \nEOF@130 \n$end@130 ",
  ),
  (
    "gives no slot to a simple block", "NODE_ID@0 gives\nNODE_ID@6 no\nNODE_ID@9 slot\nNODE_ID@14 to\nNODE_ID@17 a\nNODE_ID@19 simple\nBLOCK_DIAGRAM_KEY@26 block\nEOF@31 \n$end@31 ",
  ),
  (
    "block-beta\n      a\n      b\n      block:group\n        c\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nNODE_ID@17 a\nNODE_ID@25 b\nid-block@33 block:\nNODE_ID@39 group\nNODE_ID@53 c\nend@61 end\n    \nEOF@69 \n$end@69 ",
  ),
  (
    "block-beta\n      block:outer\n        block:inner\n          a\n        end\n      end\n      block:sibling\n        b\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 outer\nid-block@37 block:\nNODE_ID@43 inner\nNODE_ID@59 a\nend@69 end\n      \nend@79 end\n      \nid-block@89 block:\nNODE_ID@95 sibling\nNODE_ID@111 b\nend@119 end\n    \nEOF@127 \n$end@127 ",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n      end\n      block:b1\n        block:b2\n          y\n        end\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 a1\nid-block@34 block:\nNODE_ID@40 a2\nNODE_ID@53 x\nend@63 end\n      \nend@73 end\n      \nid-block@83 block:\nNODE_ID@89 b1\nid-block@100 block:\nNODE_ID@106 b2\nNODE_ID@119 y\nend@129 end\n      \nend@139 end\n    \nEOF@147 \n$end@147 ",
  ),
  (
    "block db edge styles", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 db\nNODE_ID@9 edge\nNODE_ID@14 styles\nEOF@20 \n$end@20 ",
  ),
  (
    "block db runtime config", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 db\nNODE_ID@9 runtime\nNODE_ID@17 config\nEOF@23 \n$end@23 ",
  ),
  (
    "should read block.padding from config at call time, not at import time", "NODE_ID@0 should\nNODE_ID@7 read\nBLOCK_DIAGRAM_KEY@12 block\nNODE_ID@17 .padding\nNODE_ID@26 from\nNODE_ID@31 config\nNODE_ID@38 at\nNODE_ID@41 call\nNODE_ID@46 time,\nNODE_ID@52 not\nNODE_ID@56 at\nNODE_ID@59 import\nNODE_ID@66 time\nEOF@70 \n$end@70 ",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#969,stroke:#333,stroke-width:4px\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@18 db\nNODE_DSTART@20 ((\nSTR@23 DB\nNODE_DEND@26 ))\nNODE_ID@31 blockArrowId6\nBLOCK_ARROW_START@44 <[\nSTR@47 &nbsp;&nbsp;&nbsp;\nDIR@69 down\nBLOCK_ARROW_END@73 ]>\nid-block@77 block:\nNODE_ID@83 ID\nNODE_ID@90 A\nNODE_ID@96 B\nNODE_DSTART@97 [\nSTR@99 A wide one in the middle\nNODE_DEND@124 ]\nNODE_ID@130 C\nend@134 end\n  \nSPACE_BLOCK@140 1\nNODE_ID@148 D\nNODE_ID@152 ID\nLINK@155 --> \nNODE_ID@159 D\nNODE_ID@163 C\nLINK@165 --> \nNODE_ID@169 D\nstyle@173 style \nSTYLE_ENTITY_IDS@179 B\nSTYLE_DEFINITION_DATA@180  fill:#969,stroke:#333,stroke-width:4px\nEOF@220 \n$end@220 ",
  ),
  (
    "block\n  a b c\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 a\nNODE_ID@10 b\nNODE_ID@12 c\nEOF@14 \n$end@14 ",
  ),
  (
    "block\n  columns 3\n  a b c d\n", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 a\nNODE_ID@22 b\nNODE_ID@24 c\nNODE_ID@26 d\nEOF@28 \n$end@28 ",
  ),
  (
    "block\n  columns 3\n  a[\"A label\"] b:2 c:2 d\n", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 a\nNODE_DSTART@21 [\nSTR@23 A label\nNODE_DEND@31 ]\nNODE_ID@33 b\nSIZE@34 2\nNODE_ID@37 c\nSIZE@38 2\nNODE_ID@41 d\nEOF@43 \n$end@43 ",
  ),
  (
    "block\n    block\n      D\n    end\n    A[\"A: I am a wide one\"]\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@10 block\nNODE_ID@22 D\nend@28 end\n    \nNODE_ID@36 A\nNODE_DSTART@37 [\nSTR@39 A: I am a wide one\nNODE_DEND@58 ]\nEOF@60 \n$end@60 ",
  ),
  (
    "block\n  columns 3\n  a:3\n  block:group1:2\n    columns 2\n    h i j k\n  end\n  g\n  block:group2:3\n    %% columns auto (default)\n    l m n o p q r\n  end\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 a\nSIZE@21 3\nid-block@26 block:\nNODE_ID@32 group1\nSIZE@38 2\nCOLUMNS@45 2\nNODE_ID@59 h\nNODE_ID@61 i\nNODE_ID@63 j\nNODE_ID@65 k\nend@69 end\n  \nNODE_ID@75 g\nid-block@79 block:\nNODE_ID@85 group2\nSIZE@91 3\nNODE_ID@98 %%\nCOLUMNS@101 -1\nNODE_DSTART@114 (\nINVALID@115 ",
  ),
  (
    "block\n  block\n    columns 1\n    a[\"A label\"] b c d\n  end\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@8 block\nCOLUMNS@18 1\nNODE_ID@32 a\nNODE_DSTART@33 [\nSTR@35 A label\nNODE_DEND@43 ]\nNODE_ID@45 b\nNODE_ID@47 c\nNODE_ID@49 d\nend@53 end\n\nEOF@57 \n$end@57 ",
  ),
  (
    "block\n    id1(\"This is the text in the box\")\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 (\nSTR@15 This is the text in the box\nNODE_DEND@43 )\nEOF@45 \n$end@45 ",
  ),
  (
    "block\n    id1([\"This is the text in the box\"])\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 ([\nSTR@16 This is the text in the box\nNODE_DEND@44 ])\nEOF@47 \n$end@47 ",
  ),
  (
    "block\n    id1[[\"This is the text in the box\"]]\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 [[\nSTR@16 This is the text in the box\nNODE_DEND@44 ]]\nEOF@47 \n$end@47 ",
  ),
  (
    "block\n    id1[(\"Database\")]\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 [(\nSTR@16 Database\nNODE_DEND@25 )]\nEOF@28 \n$end@28 ",
  ),
  (
    "block\n    id1((\"This is the text in the circle\"))\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 ((\nSTR@16 This is the text in the circle\nNODE_DEND@47 ))\nEOF@50 \n$end@50 ",
  ),
  (
    "block\n  id1>\"This is the text in the box\"]\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nNODE_DSTART@11 >\nSTR@13 This is the text in the box\nNODE_DEND@41 ]\nEOF@43 \n$end@43 ",
  ),
  (
    "block\n    id1{\"This is the text in the box\"}\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 {\nSTR@15 This is the text in the box\nNODE_DEND@43 }\nEOF@45 \n$end@45 ",
  ),
  (
    "block\n    id1{{\"This is the text in the box\"}}\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 {{\nSTR@16 This is the text in the box\nNODE_DEND@44 }}\nEOF@47 \n$end@47 ",
  ),
  (
    "block\n  id1[/\"This is the text in the box\"/]\n  id2[\\\"This is the text in the box\"\\]\n  A[/\"Christmas\"\\]\n  B[\\\"Go shopping\"/]\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nNODE_DSTART@11 [/\nSTR@14 This is the text in the box\nNODE_DEND@42 /]\nNODE_ID@47 id2\nNODE_DSTART@50 [\\\nSTR@53 This is the text in the box\nNODE_DEND@81 \\]\nNODE_ID@86 A\nNODE_DSTART@87 [/\nSTR@90 Christmas\nNODE_DEND@100 \\]\nNODE_ID@105 B\nNODE_DSTART@106 [\\\nSTR@109 Go shopping\nNODE_DEND@121 /]\nEOF@124 \n$end@124 ",
  ),
  (
    "block\n    id1(((\"This is the text in the circle\")))\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 (((\nSTR@17 This is the text in the circle\nNODE_DEND@48 )))\nEOF@52 \n$end@52 ",
  ),
  (
    "block\n  blockArrowId<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"Label\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 blockArrowId\nBLOCK_ARROW_START@20 <[\nSTR@23 Label\nDIR@32 right\nBLOCK_ARROW_END@37 ]>\nNODE_ID@41 blockArrowId2\nBLOCK_ARROW_START@54 <[\nSTR@57 Label\nDIR@66 left\nBLOCK_ARROW_END@70 ]>\nNODE_ID@74 blockArrowId3\nBLOCK_ARROW_START@87 <[\nSTR@90 Label\nDIR@99 up\nBLOCK_ARROW_END@101 ]>\nNODE_ID@105 blockArrowId4\nBLOCK_ARROW_START@118 <[\nSTR@121 Label\nDIR@130 down\nBLOCK_ARROW_END@134 ]>\nNODE_ID@138 blockArrowId5\nBLOCK_ARROW_START@151 <[\nSTR@154 Label\nDIR@163 x\nBLOCK_ARROW_END@164 ]>\nNODE_ID@168 blockArrowId6\nBLOCK_ARROW_START@181 <[\nSTR@184 Label\nDIR@193 y\nBLOCK_ARROW_END@194 ]>\nNODE_ID@198 blockArrowId7\nBLOCK_ARROW_START@211 <[\nSTR@214 Label\nDIR@223 x\nDIR@224 down\nBLOCK_ARROW_END@230 ]>\nEOF@232 \n$end@232 ",
  ),
  (
    "block\n  columns 3\n  a space b\n  c   d   e\n", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 a\nSPACE_BLOCK@22 1\nNODE_ID@28 b\nNODE_ID@32 c\nNODE_ID@36 d\nNODE_ID@40 e\nEOF@42 \n$end@42 ",
  ),
  (
    "block\n  ida space:3 idb idc\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 ida\nSPACE_BLOCK@12 3\nNODE_ID@20 idb\nNODE_ID@24 idc\nEOF@28 \n$end@28 ",
  ),
  (
    "block\n  A space B\n  A-->B\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 A\nLINK@21 -->\nNODE_ID@24 B\nEOF@26 \n$end@26 ",
  ),
  (
    "block\n  A space:2 B\n  A-- \"X\" -->B\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 2\nNODE_ID@18 B\nNODE_ID@22 A\nSTART_LINK@23 -- \nLINK_LABEL@26 \"\nSTR@27 X\nLINK@29  -->\nNODE_ID@33 B\nEOF@35 \n$end@35 ",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:#333,stroke-width:4px\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@18 db\nNODE_DSTART@20 ((\nSTR@23 DB\nNODE_DEND@26 ))\nNODE_ID@31 blockArrowId6\nBLOCK_ARROW_START@44 <[\nSTR@47 &nbsp;&nbsp;&nbsp;\nDIR@69 down\nBLOCK_ARROW_END@73 ]>\nid-block@77 block:\nNODE_ID@83 ID\nNODE_ID@90 A\nNODE_ID@96 B\nNODE_DSTART@97 [\nSTR@99 A wide one in the middle\nNODE_DEND@124 ]\nNODE_ID@130 C\nend@134 end\n  \nSPACE_BLOCK@140 1\nNODE_ID@148 D\nNODE_ID@152 ID\nLINK@155 --> \nNODE_ID@159 D\nNODE_ID@163 C\nLINK@165 --> \nNODE_ID@169 D\nstyle@173 style \nSTYLE_ENTITY_IDS@179 B\nSTYLE_DEFINITION_DATA@180  fill:#939,stroke:#333,stroke-width:4px\nEOF@220 \n$end@220 ",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"Stop\")\n  style id1 fill:#636,stroke:#333,stroke-width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nSPACE_BLOCK@12 1\nNODE_ID@18 id2\nNODE_ID@24 id1\nNODE_DSTART@27 (\nSTR@29 Start\nNODE_DEND@35 )\nLINK@36 -->\nNODE_ID@39 id2\nNODE_DSTART@42 (\nSTR@44 Stop\nNODE_DEND@49 )\nstyle@53 style \nSTYLE_ENTITY_IDS@59 id1\nSTYLE_DEFINITION_DATA@62  fill:#636,stroke:#333,stroke-width:4px\nstyle@104 style \nSTYLE_ENTITY_IDS@110 id2\nSTYLE_DEFINITION_DATA@113  fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\nEOF@186 \n$end@186 ",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:4px;\n  class A blue\n  style B fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 A\nLINK@21 -->\nNODE_ID@24 B\nclassDef@28 classDef \nCLASSDEF_ID@37 blue \nCLASSDEF_STYLEOPTS@42 fill:#6e6ce6,stroke:#333,stroke-width:4px;\nclass@87 class \nCLASSENTITY_IDS@93 A\nSTYLECLASS@94  blue\nstyle@102 style \nSTYLE_ENTITY_IDS@108 B\nSTYLE_DEFINITION_DATA@109  fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\nEOF@182 \n$end@182 ",
  ),
  (
    "block\n  columns 3\n  Frontend blockArrowId6<[\" \"]>(right) Backend\n  space:2 down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,stroke:#333;\n  classDef back fill:#969,stroke:#333;\n  class Frontend front\n  class Backend,Database back\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 Frontend\nNODE_ID@29 blockArrowId6\nBLOCK_ARROW_START@42 <[\nSTR@45  \nDIR@50 right\nBLOCK_ARROW_END@55 ]>\nNODE_ID@57 Backend\nSPACE_BLOCK@67 2\nNODE_ID@75 down\nBLOCK_ARROW_START@79 <[\nSTR@82  \nDIR@87 down\nBLOCK_ARROW_END@91 ]>\nNODE_ID@95 Disk\nNODE_ID@100 left\nBLOCK_ARROW_START@104 <[\nSTR@107  \nDIR@112 left\nBLOCK_ARROW_END@116 ]>\nNODE_ID@118 Database\nNODE_DSTART@126 [(\nSTR@129 Database\nNODE_DEND@138 )]\nclassDef@144 classDef \nCLASSDEF_ID@153 front \nCLASSDEF_STYLEOPTS@159 fill:#696,stroke:#333;\nclassDef@184 classDef \nCLASSDEF_ID@193 back \nCLASSDEF_STYLEOPTS@198 fill:#969,stroke:#333;\nclass@223 class \nCLASSENTITY_IDS@229 Frontend\nSTYLECLASS@237  front\nclass@246 class \nCLASSENTITY_IDS@252 Backend,Database\nSTYLECLASS@268  back\nEOF@274 \n$end@274 ",
  ),
  (
    "block\n  columns 3\n  Start((\"Start\")) space:2\n  down<[\" \"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(right) Process1[\"Process A\"]\n  downAgain<[\"No\"]>(down) space r3<[\"Done\"]>(down)\n  Process2[\"Process B\"] r2<[\"Done\"]>(right) End((\"End\"))\n\n  style Start fill:#969;\n  style End fill:#696;\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 Start\nNODE_DSTART@25 ((\nSTR@28 Start\nNODE_DEND@34 ))\nSPACE_BLOCK@37 2\nNODE_ID@47 down\nBLOCK_ARROW_START@51 <[\nSTR@54  \nDIR@59 down\nBLOCK_ARROW_END@63 ]>\nSPACE_BLOCK@65 2\nNODE_ID@75 Decision\nNODE_DSTART@83 {{\nSTR@86 Make Decision\nNODE_DEND@100 }}\nNODE_ID@103 right\nBLOCK_ARROW_START@108 <[\nSTR@111 Yes\nDIR@118 right\nBLOCK_ARROW_END@123 ]>\nNODE_ID@125 Process1\nNODE_DSTART@133 [\nSTR@135 Process A\nNODE_DEND@145 ]\nNODE_ID@149 downAgain\nBLOCK_ARROW_START@158 <[\nSTR@161 No\nDIR@167 down\nBLOCK_ARROW_END@171 ]>\nSPACE_BLOCK@173 1\nNODE_ID@179 r3\nBLOCK_ARROW_START@181 <[\nSTR@184 Done\nDIR@192 down\nBLOCK_ARROW_END@196 ]>\nNODE_ID@200 Process2\nNODE_DSTART@208 [\nSTR@210 Process B\nNODE_DEND@220 ]\nNODE_ID@222 r2\nBLOCK_ARROW_START@224 <[\nSTR@227 Done\nDIR@235 right\nBLOCK_ARROW_END@240 ]>\nNODE_ID@242 End\nNODE_DSTART@245 ((\nSTR@248 End\nNODE_DEND@252 ))\nstyle@258 style \nSTYLE_ENTITY_IDS@264 Start\nSTYLE_DEFINITION_DATA@269  fill:#969;\nstyle@283 style \nSTYLE_ENTITY_IDS@289 End\nSTYLE_DEFINITION_DATA@292  fill:#696;\nEOF@304 \n$end@304 ",
  ),
  (
    "block\n  A space B\n  A --> B\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 A\nLINK@22 --> \nNODE_ID@26 B\nEOF@28 \n$end@28 ",
  ),
  (
    "  block\n    A\n    style A fill#969;\n", "BLOCK_DIAGRAM_KEY@2 block\nNODE_ID@12 A\nstyle@18 style \nSTYLE_ENTITY_IDS@24 A\nSTYLE_DEFINITION_DATA@25  fill#969;\nEOF@36 \n$end@36 ",
  ),
  (
    "block\n  A\n  style A fill:#969,stroke:#333;\n\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nstyle@12 style \nSTYLE_ENTITY_IDS@18 A\nSTYLE_DEFINITION_DATA@19  fill:#969,stroke:#333;\nEOF@44 \n$end@44 ",
  ),
  (
    "co%%pound blocks block:ith ttle", "NODE_ID@0 co%%pound\nNODE_ID@10 blocks\nid-block@17 block:\nNODE_ID@23 ith\nNODE_ID@27 ttle\nEOF@31 \n$end@31 ",
  ),
  (
    "block\nA; classDef ${prop} color:#fffffffe circlef,fill:#000000; class A ${prop}",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 A;\nclassDef@9 classDef \nINVALID@18 ",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B fill:#f9F,stroke:#333,3,stroke-width:4px\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@20 B\nNODE_DSTART@21 [\nSTR@23 A wide one in the middle\nNODE_DEND@48 ]\nstyle@52 style \nSTYLE_ENTITY_IDS@58 B\nSTYLE_DEFINITION_DATA@59  fill:#f9F,stroke:#333,3,stroke-width:4px\nEOF@109 \n$end@109 ",
  ),
  (
    "block\n   }     columns 1\n          block1[\"Block 1\"]\n          block2]][\"Block 2\"]\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nINVALID@9 ",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"Stop\")\n  style id1 fill:#636,stroke:#333,stroke-width:4px\n  style d2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nSPACE_BLOCK@12 1\nNODE_ID@18 id2\nNODE_ID@24 id1\nNODE_DSTART@27 (\nSTR@29 Start\nNODE_DEND@35 )\nLINK@36 -->\nNODE_ID@39 id2\nNODE_DSTART@42 (\nSTR@44 Stop\nNODE_DEND@49 )\nstyle@53 style \nSTYLE_ENTITY_IDS@59 id1\nSTYLE_DEFINITION_DATA@62  fill:#636,stroke:#333,stroke-width:4px\nstyle@104 style \nSTYLE_ENTITY_IDS@110 d2\nSTYLE_DEFINITION_DATA@112  fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\nEOF@185 \n$end@185 ",
  ),
  (
    "blocclass-.-> A akprop}", "NODE_ID@0 blocclass\nLINK@9 -.-> \nNODE_ID@14 A\nNODE_ID@16 akprop\nINVALID@22 ",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start(-\")-->id2(\"Stop\")\n  style id1 fill:#636,stroke:#333,stroke-[[\"x\"]]width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nSPACE_BLOCK@12 1\nNODE_ID@18 id2\nNODE_ID@24 id1\nNODE_DSTART@27 (\nSTR@29 Start(-\nNODE_DEND@37 )\nLINK@38 -->\nNODE_ID@41 id2\nNODE_DSTART@44 (\nSTR@46 Stop\nNODE_DEND@51 )\nstyle@55 style \nSTYLE_ENTITY_IDS@61 id1\nSTYLE_DEFINITION_DATA@64  fill:#636,stroke:#333,stroke-[[\"x\"]]width:4px\nstyle@113 style \nSTYLE_ENTITY_IDS@119 id2\nSTYLE_DEFINITION_DATA@122  fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\nEOF@195 \n$end@195 ",
  ),
  (
    "block\n    id1[[\"This is th space Be text in the box\"]]\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 [[\nSTR@16 This is th space Be text in the box\nNODE_DEND@52 ]]\nEOF@55 \n$end@55 ",
  ),
  (
    "should read blocaccDescr { d }k.padding from confat call time, not at import ticlass A,B ame",
    "NODE_ID@0 should\nNODE_ID@7 read\nNODE_ID@12 blocaccDescr\nNODE_DSTART@25 {\nINVALID@26 ",
  ),
  (
    "blo\u{e9}ck\n  block\n    columns 1\n    a[\"A label\"] b c d\n  end\n", "NODE_ID@0 blo\u{e9}ck\nBLOCK_DIAGRAM_KEY@9 block\nCOLUMNS@19 1\nNODE_ID@33 a\nNODE_DSTART@34 [\nSTR@36 A label\nNODE_DEND@44 ]\nNODE_ID@46 b\nNODE_ID@48 c\nNODE_ID@50 d\nend@54 end\n\nEOF@58 \n$end@58 ",
  ),
  (
    "block\n    id1[[\"This is ththe text in the box\"]]\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 [[\nSTR@16 This is ththe text in the box\nNODE_DEND@46 ]]\nEOF@49 \n$end@49 ",
  ),
  (
    "block\n        columns 3\n         block1[\"Block 1\"]\n        blockArrow<[\"&nbsp;&nbsp;&n        spbsp;\"]>(right)\n        block2[\"Block 2\"]",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nNODE_ID@33 block1\nNODE_DSTART@39 [\nSTR@41 Block 1\nNODE_DEND@49 ]\nNODE_ID@59 blockArrow\nBLOCK_ARROW_START@69 <[\nSTR@72 &nbsp;&nbsp;&n        spbsp;\nDIR@104 right\nBLOCK_ARROW_END@109 ]>\nNODE_ID@119 block2\nNODE_DSTART@125 [\nSTR@127 Block 2\nNODE_DEND@135 ]\nEOF@136 \n$end@136 ",
  ),
  ("bl1", "NODE_ID@0 bl1\nEOF@3 \n$end@3 "),
  (
    "blo ck\n  ca\n      block:olumns 3\n  a space b\n   d   e\n", "NODE_ID@0 blo\nNODE_ID@4 ck\nNODE_ID@9 ca\nid-block@18 block:\nNODE_ID@24 olumns\nNODE_ID@31 3\nNODE_ID@35 a\nSPACE_BLOCK@37 1\nNODE_ID@43 b\nNODE_ID@48 d\nNODE_ID@52 e\nEOF@54 \n$end@54 ",
  ),
  (
    "compound blocks 2 2", "NODE_ID@0 compound\nNODE_ID@9 blocks\nNODE_ID@16 2\nNODE_ID@18 2\nEOF@19 \n$end@19 ",
  ),
  (
    "block\n  columns 3\n  Frontend blockArrowId6<[\" \"]>(right) Backend\n  space:2 down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,stroke:#333;\n  classDef back fill:#969,stroke:#333;\n  class Frontend front&nbsp;\n  class Backend,Database back\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 Frontend\nNODE_ID@29 blockArrowId6\nBLOCK_ARROW_START@42 <[\nSTR@45  \nDIR@50 right\nBLOCK_ARROW_END@55 ]>\nNODE_ID@57 Backend\nSPACE_BLOCK@67 2\nNODE_ID@75 down\nBLOCK_ARROW_START@79 <[\nSTR@82  \nDIR@87 down\nBLOCK_ARROW_END@91 ]>\nNODE_ID@95 Disk\nNODE_ID@100 left\nBLOCK_ARROW_START@104 <[\nSTR@107  \nDIR@112 left\nBLOCK_ARROW_END@116 ]>\nNODE_ID@118 Database\nNODE_DSTART@126 [(\nSTR@129 Database\nNODE_DEND@138 )]\nclassDef@144 classDef \nCLASSDEF_ID@153 front \nCLASSDEF_STYLEOPTS@159 fill:#696,stroke:#333;\nclassDef@184 classDef \nCLASSDEF_ID@193 back \nCLASSDEF_STYLEOPTS@198 fill:#969,stroke:#333;\nclass@223 class \nCLASSENTITY_IDS@229 Frontend\nSTYLECLASS@237  front&nbsp;\nclass@252 class \nCLASSENTITY_IDS@258 Backend,Database\nSTYLECLASS@274  back\nEOF@280 \n$end@280 ",
  ),
  (
    "space:2compound blocks with `\"tot itle", "SPACE_BLOCK@0 2\nNODE_ID@7 compound\nNODE_ID@16 blocks\nNODE_ID@23 with\nNODE_ID@28 `\"tot\nNODE_ID@34 itle\nEOF@38 \n$end@38 ",
  ),
  (
    "should log warning whenblock width ex[(\"x\")]ceeds column width", "NODE_ID@0 should\nNODE_ID@7 log\nNODE_ID@11 warning\nNODE_ID@19 whenblock\nNODE_ID@29 width\nNODE_ID@35 ex\nNODE_DSTART@37 [(\nSTR@40 x\nNODE_DEND@42 )]\nNODE_ID@44 ceeds\nNODE_ID@50 column\nNODE_ID@57 width\nEOF@62 \n$end@62 ",
  ),
  (
    "block\n            columns 1\n          block1[\"Block 1\"]\n          bloc2[\"Block 2\"]\n [       ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@18 1\nNODE_ID@38 block1\nNODE_DSTART@44 [\nSTR@46 Block 1\nNODE_DEND@54 ]\nNODE_ID@66 bloc2\nNODE_DSTART@71 [\nSTR@73 Block 2\nNODE_DEND@81 ]\nNODE_DSTART@84 [\nINVALID@85 ",
  ),
  (
    "should read block.p[\\aAdding from config at call time, not at import time",
    "NODE_ID@0 should\nNODE_ID@7 read\nBLOCK_DIAGRAM_KEY@12 block\nNODE_ID@17 .p\nNODE_DSTART@19 [\\\nINVALID@21 ",
  ),
  (
    "gives Bo slot to a simpl block", "NODE_ID@0 gives\nNODE_ID@6 Bo\nNODE_ID@9 slot\nNODE_ID@14 to\nNODE_ID@17 a\nNODE_ID@19 simpl\nBLOCK_DIAGRAM_KEY@25 block\nEOF@30 \n$end@30 ",
  ),
  (
    "block\n          id[\"A<[ label\"]\n          ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id\nNODE_DSTART@18 [\nSTR@20 A<[ label\nNODE_DEND@30 ]\nEOF@42 \n$end@42 ",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nb&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:#333,__proto__stroke-width:4px\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@18 db\nNODE_DSTART@20 ((\nSTR@23 DB\nNODE_DEND@26 ))\nNODE_ID@31 blockArrowId6\nBLOCK_ARROW_START@44 <[\nSTR@47 &nbsp;&nb&nbsp;\nDIR@66 down\nBLOCK_ARROW_END@70 ]>\nid-block@74 block:\nNODE_ID@80 ID\nNODE_ID@87 A\nNODE_ID@93 B\nNODE_DSTART@94 [\nSTR@96 A wide one in the middle\nNODE_DEND@121 ]\nNODE_ID@127 C\nend@131 end\n  \nSPACE_BLOCK@137 1\nNODE_ID@145 D\nNODE_ID@149 ID\nLINK@152 --> \nNODE_ID@156 D\nNODE_ID@160 C\nLINK@162 --> \nNODE_ID@166 D\nstyle@170 style \nSTYLE_ENTITY_IDS@176 B\nSTYLE_DEFINITION_DATA@177  fill:#939,stroke:#333,__proto__stroke-width:4px\nEOF@226 \n$end@226 ",
  ),
  (
    "compound blocks with titl == \"x\" ==> e", "NODE_ID@0 compound\nNODE_ID@9 blocks\nNODE_ID@16 with\nNODE_ID@21 titl\nSTART_LINK@26 == \nLINK_LABEL@29 \"\nSTR@30 x\nLINK@32  ==> \nNODE_ID@37 e\nEOF@38 \n$end@38 ",
  ),
  (
    "block\n 3         id[\"A label\"]\n         ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 3\nNODE_ID@17 id\nNODE_DSTART@19 [\nSTR@21 A label\nNODE_DEND@29 ]\nEOF@40 \n$end@40 ",
  ),
  ("bx--loc${prop{{", "NODE_ID@0 bx\nSTART_LINK@2 --\nINVALID@4 "),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fistyle A,B xll:#6e6ce6,stroke:#333,stroke-width:4px;\n  class A blue\n  style B fill:#bbf,stroke:#f66,stroke-width:2px   id1(\"This ,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 A\nLINK@21 -->\nNODE_ID@24 B\nclassDef@28 classDef \nCLASSDEF_ID@37 blue \nCLASSDEF_STYLEOPTS@42 fistyle A,B xll:#6e6ce6,stroke:#333,stroke-width:4px;\nclass@98 class \nCLASSENTITY_IDS@104 A\nSTYLECLASS@105  blue\nstyle@113 style \nSTYLE_ENTITY_IDS@119 B\nSTYLE_DEFINITION_DATA@120  fill:#bbf,stroke:#f66,stroke-width:2px   id1(\"This ,color:#fff,stroke-dasharray: 5 5\nEOF@206 \n$end@206 ",
  ),
  (
    "ck-beta\n      block:first\n        a\n      end\n      block:second\n        b\n      end\n      block:third\n        c\n c\n      end\n    ",
    "NODE_ID@0 ck\nINVALID@2 ",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbs ;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stre:#333,stroke-width:]>4px\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@18 db\nNODE_DSTART@20 ((\nSTR@23 DB\nNODE_DEND@26 ))\nNODE_ID@31 blockArrowId6\nBLOCK_ARROW_START@44 <[\nSTR@47 &nbsp;&nbsp;&nbs ;\nDIR@69 down\nBLOCK_ARROW_END@73 ]>\nid-block@77 block:\nNODE_ID@83 ID\nNODE_ID@90 A\nNODE_ID@96 B\nNODE_DSTART@97 [\nSTR@99 A wide one in the middle\nNODE_DEND@124 ]\nNODE_ID@130 C\nend@134 end\n  \nSPACE_BLOCK@140 1\nNODE_ID@148 D\nNODE_ID@152 ID\nLINK@155 --> \nNODE_ID@159 D\nNODE_ID@163 C\nLINK@165 --> \nNODE_ID@169 D\nstyle@173 style \nSTYLE_ENTITY_IDS@179 B\nSTYLE_DEFINITION_DATA@180  fill:#939,stre:#333,stroke-width:]>4px\nEOF@220 \n$end@220 ",
  ),
  (
    "block\n    id1(\"This-.- the text in thebox\")\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 (\nSTR@15 This-.- the text in thebox\nNODE_DEND@42 )\nEOF@44 \n$end@44 ",
  ),
  (
    "block\n  block\n    columns 1\n    a[\"A laabel\"] b c d\n    end\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@8 block\nCOLUMNS@18 1\nNODE_ID@32 a\nNODE_DSTART@33 [\nSTR@35 A laabel\nNODE_DEND@44 ]\nNODE_ID@46 b\nNODE_ID@48 c\nNODE_ID@50 d\nend@56 end\n\nEOF@60 \n$end@60 ",
  ),
  (
    "e>\"xd3\n      \"]mpty blocks", "NODE_ID@0 e\nNODE_DSTART@1 >\nSTR@3 xd3\n      \nNODE_DEND@14 ]\nNODE_ID@15 mpty\nNODE_ID@20 blocks\nEOF@26 \n$end@26 ",
  ),
  (
    "block\n  columns 3\n  a:3\n  block:group1:2\n    columns 2\n    h i j k\n  end\n  g\n  block:group22:3\n    %% columns auto (default)\n    l m n o p q r\n  end\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 a\nSIZE@21 3\nid-block@26 block:\nNODE_ID@32 group1\nSIZE@38 2\nCOLUMNS@45 2\nNODE_ID@59 h\nNODE_ID@61 i\nNODE_ID@63 j\nNODE_ID@65 k\nend@69 end\n  \nNODE_ID@75 g\nid-block@79 block:\nNODE_ID@85 group22\nSIZE@92 3\nNODE_ID@99 %%\nCOLUMNS@102 -1\nNODE_DSTART@115 (\nINVALID@116 ",
  ),
  (
    "block\n    id1((\"Ta {\"x\"}bhis is the text in the circle\"))\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 ((\nSTR@16 Ta {\nINVALID@21 ",
  ),
  (
    "blks with different wi>dths", "NODE_ID@0 blks\nNODE_ID@5 with\nNODE_ID@10 different\nNODE_ID@20 wi\nNODE_DSTART@22 >\nINVALID@23 ",
  ),
  (
    "block-beta\n      block:a1\n        ck:a2\n          x\n        end\n      end\n      block:b1\n        block:b2\n          y\n        end\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 a1\nNODE_ID@34 ck\nINVALID@36 ",
  ),
  (
    "block\n  columns 3\n<==>  a space b\n  c   d   e\n", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nLINK@18 <==>  \nNODE_ID@24 a\nSPACE_BLOCK@26 1\nNODE_ID@32 b\nNODE_ID@36 c\nNODE_ID@40 d\nNODE_ID@44 e\nEOF@46 \n$end@46 ",
  ),
  (
    "block\nlumn  columns 3\n  a[\"A label\"] b---2 c:2 dc:2 d\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 lumn\nCOLUMNS@12 3\nNODE_ID@24 a\nNODE_DSTART@25 [\nSTR@27 A label\nNODE_DEND@35 ]\nNODE_ID@37 b\nLINK@38 ---\nNODE_ID@41 2\nNODE_ID@43 c\nSIZE@44 2\nNODE_ID@47 dc\nSIZE@49 2\nNODE_ID@52 d\nEOF@54 \n$end@54 ",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the mi.ddle\"]\n  style B fill:#f9F,stroke:#333,stroke-width:4px\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@20 B\nNODE_DSTART@21 [\nSTR@23 A wide one in the mi.ddle\nNODE_DEND@49 ]\nstyle@53 style \nSTYLE_ENTITY_IDS@59 B\nSTYLE_DEFINITION_DATA@60  fill:#f9F,stroke:#333,stroke-width:4px\nEOF@108 \n$end@108 ",
  ),
  (
    "blyock\n          block:compoundBlock[\"Compound block\"]\n          columns 1\n            block2[\"Block{{ 2\"]\n          end\n        ",
    "NODE_ID@0 blyock\nid-block@17 block:\nNODE_ID@23 compoundBlock\nNODE_DSTART@36 [\nSTR@38 Compound block\nNODE_DEND@53 ]\nCOLUMNS@65 1\nNODE_ID@87 block2\nNODE_DSTART@93 [\nSTR@95 Block{{ 2\nNODE_DEND@105 ]\nend@117 end\n        \nEOF@129 \n$end@129 ",
  ),
  (
    "binterpolatelock\n    id1(\"This is the tex{\"x\"}t in the box\")\n", "NODE_ID@0 binterpolatelock\nNODE_ID@21 id1\nNODE_DSTART@24 (\nSTR@26 This is the tex{\nINVALID@43 ",
  ),
  ("bl--ck-.-2", "NODE_ID@0 bl\nSTART_LINK@2 --\nINVALID@4 "),
  (
    "bloc db (\"x\")dge styles", "NODE_ID@0 bloc\nNODE_ID@5 db\nNODE_DSTART@8 (\nSTR@10 x\nNODE_DEND@12 )\nNODE_ID@13 dge\nNODE_ID@17 styles\nEOF@23 \n$end@23 ",
  ),
  (
    "block\n  columns 3\n  :0ock13a space b\n  c   d   e\n\n", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nSIZE@20 0\nNODE_ID@22 ock13a\nSPACE_BLOCK@29 1\nNODE_ID@35 b\nNODE_ID@39 c\nNODE_ID@43 d\nNODE_ID@47 e\nEOF@50 \n$end@50 ",
  ),
  (
    "blo(-ck\n[\\\"x\"/]${prop/]}", "NODE_ID@0 blo\nNODE_DSTART@3 (-\nINVALID@5 ",
  ),
  (
    "block\n  id1[/\"This is thrighte text in the box\"/]\n  id2[\\\"This is the tex{{t in the box\"\\]\n  A[/\"Christmas\"\\]\n  B[\\\"Go shopping\"/]\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nNODE_DSTART@11 [/\nSTR@14 This is thrighte text in the box\nNODE_DEND@47 /]\nNODE_ID@52 id2\nNODE_DSTART@55 [\\\nSTR@58 This is the tex{{t in the box\nNODE_DEND@88 \\]\nNODE_ID@93 A\nNODE_DSTART@94 [/\nSTR@97 Christmas\nNODE_DEND@107 \\]\nNODE_ID@112 B\nNODE_DSTART@113 [\\\nSTR@116 Go shopping\nNODE_DEND@128 /]\nEOF@131 \n$end@131 ",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"Stop\")\n  style id1 fill:#636,stroke:#333,stroke-width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nSPACE_BLOCK@12 1\nNODE_ID@18 id2\nNODE_ID@24 id1\nNODE_DSTART@27 (\nSTR@29 Start\nNODE_DEND@35 )\nLINK@36 -->\nNODE_ID@39 id2\nNODE_DSTART@42 (\nSTR@44 Stop\nNODE_DEND@49 )\nstyle@53 style \nSTYLE_ENTITY_IDS@59 id1\nSTYLE_DEFINITION_DATA@62  fill:#636,stroke:#333,stroke-width:4px\nstyle@104 style \nSTYLE_ENTITY_IDS@110 id2\nSTYLE_DEFINITION_DATA@113  fill:#bbf,stroke:#f66,stroke-width:2px,color:fff,stroke-dasharray: 5 5\nEOF@185 \n$end@185 ",
  ),
  (
    "block\n        columns 3\n        one[\"One Slo       t\"]\n        taccDescr {}wo[\"Two slots\"]:2\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nNODE_ID@32 one\nNODE_DSTART@35 [\nSTR@37 One Slo       t\nNODE_DEND@53 ]\nNODE_ID@63 taccDescr\nNODE_DSTART@73 {\nNODE_DEND@74 }\nNODE_ID@75 wo\nNODE_DSTART@77 [\nSTR@79 Two slots\nNODE_DEND@89 ]\nSIZE@90 2\nEOF@101 \n$end@101 ",
  ),
  (
    "classDef statementsplied to a block", "classDef@0 classDef \nCLASSDEF_ID@9 statementsplied \nCLASSDEF_STYLEOPTS@25 to a block\nEOF@35 \n$end@35 ",
  ),
  (
    "block\n          block:compoundBlock[\"Compound b[\\lock\"]\n            columns 1\n          id1  block2[\"Block 2\"]\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nid-block@16 block:\nNODE_ID@22 compoundBlock\nNODE_DSTART@35 [\nSTR@37 Compound b[\\lock\nNODE_DEND@54 ]\nCOLUMNS@68 1\nNODE_ID@88 id1\nNODE_ID@93 block2\nNODE_DSTART@99 [\nSTR@101 Block 2\nNODE_DEND@109 ]\nend@121 end\n        \nEOF@133 \n$end@133 ",
  ),
  (
    "block\n          id1[\"firblock:gst\"]  -->   id2[\"second\"]\n      ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1\nNODE_DSTART@19 [\nSTR@21 firblock:gst\nNODE_DEND@34 ]\nLINK@37 -->   \nNODE_ID@43 id2\nNODE_DSTART@46 [\nSTR@48 second\nNODE_DEND@55 ]\nEOF@63 \n$end@63 ",
  ),
  (
    "block\n          block1[\"Block 1\"]\n  1\n            bloc    ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 block1\nNODE_DSTART@22 [\nSTR@24 Block 1\nNODE_DEND@32 ]\nNODE_ID@36 1\nNODE_ID@50 bloc\nEOF@58 \n$end@58 ",
  ),
  (
    "compound blcolumns autoocks 2", "NODE_ID@0 compound\nNODE_ID@9 blcolumns\nNODE_ID@19 autoocks\nNODE_ID@28 2\nEOF@29 \n$end@29 ",
  ),
  (
    "block\"  columns 3\n  Frontend blockArrowId6<[\" \"]>(right) Backend\n  space:2 down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,stroke:#333;\n  classDef back fill:#969,stroke:#333;\n  class Frontend front\n   class Backend,Database back\n",
    "BLOCK_DIAGRAM_KEY@0 block\nSTR@6   columns 3\n  Frontend blockArrowId6<[\nSTR@47 ]>(right) Backend\n  space:2 down<[\nSTR@84 ]>(down)\n  Disk left<[\nSTR@109 ]>(left) Database[(\nNODE_ID@129 Database\"\nNODE_DSTART@138 )\nNODE_DEND@139 ]\nclassDef@144 classDef \nCLASSDEF_ID@153 front \nCLASSDEF_STYLEOPTS@159 fill:#696,stroke:#333;\nclassDef@184 classDef \nCLASSDEF_ID@193 back \nCLASSDEF_STYLEOPTS@198 fill:#969,stroke:#333;\nclass@223 class \nCLASSENTITY_IDS@229 Frontend\nSTYLECLASS@237  front\nclass@247 class \nCLASSENTITY_IDS@253 Backend,Database\nSTYLECLASS@269  back\nEOF@275 \n$end@275 ",
  ),
  (
    "block\n  columns 3\n  a b  a b c d\n", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 a\nNODE_ID@22 b\nNODE_ID@25 a\nNODE_ID@27 b\nNODE_ID@29 c\nNODE_ID@31 d\nEOF@33 \n$end@33 ",
  ),
  (
    "block\n              columns auto\n (((\"x\")))         block1[\"Block 1\"]\n4px\n             ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@20 -1\nNODE_DSTART@34 (((\nSTR@38 x\nNODE_DEND@40 )))\nNODE_ID@52 block1\nNODE_DSTART@58 [\nSTR@60 Block 1\nNODE_DEND@68 ]\nNODE_ID@70 4px\nEOF@87 \n$end@87 ",
  ),
  (
    "block\n  columns 3\n  Frontend blockArrowId6<[\" \"]>(right) Backend\n  space:2 down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front filclass A al:#696,stroke:#333;\n  classDef back fill:#969,stroke:#333;\n  class Frontend front\n  class Backend,Dabase back\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 Frontend\nNODE_ID@29 blockArrowId6\nBLOCK_ARROW_START@42 <[\nSTR@45  \nDIR@50 right\nBLOCK_ARROW_END@55 ]>\nNODE_ID@57 Backend\nSPACE_BLOCK@67 2\nNODE_ID@75 down\nBLOCK_ARROW_START@79 <[\nSTR@82  \nDIR@87 down\nBLOCK_ARROW_END@91 ]>\nNODE_ID@95 Disk\nNODE_ID@100 left\nBLOCK_ARROW_START@104 <[\nSTR@107  \nDIR@112 left\nBLOCK_ARROW_END@116 ]>\nNODE_ID@118 Database\nNODE_DSTART@126 [(\nSTR@129 Database\nNODE_DEND@138 )]\nclassDef@144 classDef \nCLASSDEF_ID@153 front \nCLASSDEF_STYLEOPTS@159 filclass A al:#696,stroke:#333;\nclassDef@193 classDef \nCLASSDEF_ID@202 back \nCLASSDEF_STYLEOPTS@207 fill:#969,stroke:#333;\nclass@232 class \nCLASSENTITY_IDS@238 Frontend\nSTYLECLASS@246  front\nclass@255 class \nCLASSENTITY_IDS@261 Backend,Dabase\nSTYLECLASS@275  back\nEOF@281 \n$end@281 ",
  ),
  (
    "block\n          columns 1\n          block1[\"Block 1\"]\n       < lock2[\"Bloendck 2\"]\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@16 1\nNODE_ID@36 block1\nNODE_DSTART@42 [\nSTR@44 Block 1\nNODE_DEND@52 ]\nINVALID@61 ",
  ),
  (
    "block db space:2edge styles", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 db\nSPACE_BLOCK@9 2\nNODE_ID@16 edge\nNODE_ID@21 styles\nEOF@27 \n$end@27 ",
  ),
  (
    "comp         blocound blocks 2", "NODE_ID@0 comp\nNODE_ID@13 blocound\nNODE_ID@22 blocks\nNODE_ID@29 2\nEOF@30 \n$end@30 ",
  ),
  (
    "block-beta\n (         id\n      ", "BLOCK_DIAGRAM_KEY@0 block-beta\nNODE_DSTART@12 (\nINVALID@13 ",
  ),
  (
    "block\n    id1{{\"This is the text style A fill:#f96,stroke:#333in 1(\"This isthe box\"}}\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 {{\nSTR@16 This is the text style A fill:#f96,stroke:#333in 1(\nINVALID@68 ",
  ),
  (
    "block\n          id1irst\"]  -- \"a lab<--el\" -->   id2[\"second\"]\n      ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1irst\"]\nSTART_LINK@27 -- \nLINK_LABEL@30 \"\nSTR@31 a lab<--el\nLINK@42  -->   \nNODE_ID@49 id2\nNODE_DSTART@52 [\nSTR@54 second\nNODE_DEND@61 ]\nEOF@69 \n$end@69 ",
  ),
  (
    "block\n          id1\n          id2\n     block:g([", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1\nNODE_ID@30 id2\nid-block@39 block:\nNODE_ID@45 g\nNODE_DSTART@46 ([\n$end@48 ",
  ),
  (
    "block\n  columns 3\next in the box  a space b\n  c   d   e\n", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@18 ext\nNODE_ID@22 in\nNODE_ID@25 the\nNODE_ID@29 box\nNODE_ID@34 a\nSPACE_BLOCK@36 1\nNODE_ID@42 b\nNODE_ID@46 c\nNODE_ID@50 d\nNODE_ID@54 e\nEOF@56 \n$end@56 ",
  ),
  (
    "blockclassDef DEFAULT x\n         s 3\n  a b c d\n id[\"A label\"]\n          ",
    "NODE_ID@0 blockclassDef\nNODE_ID@14 DEFAULT\nNODE_ID@22 x\nNODE_ID@33 s\nNODE_ID@35 3\nNODE_ID@39 a\nNODE_ID@41 b\nNODE_ID@43 c\nNODE_ID@45 d\nNODE_ID@48 id\nNODE_DSTART@50 [\nSTR@52 A label\nNODE_DEND@60 ]\nEOF@72 \n$end@72 ",
  ),
  (
    "  block\n    A\n    st]>(yle A fill#969;\n", "BLOCK_DIAGRAM_KEY@2 block\nNODE_ID@12 A\nNODE_ID@18 st]\nNODE_DSTART@21 >\nNODE_DEND@22 (\nNODE_ID@23 yle\nNODE_ID@27 A\nNODE_ID@29 fill#969;\nEOF@39 \n$end@39 ",
  ),
  (
    "block\n         \u{e9} id[\"<b>Bold<b>\"]\n         ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@15 \u{e9}\nNODE_ID@17 id\nNODE_DSTART@19 [\nSTR@21 <b>Bold<b>\nNODE_DEND@32 ]\nEOF@43 \n$end@43 ",
  ),
  (
    "block\n     :#969,stroke:#333;     columns 1\n          block1[\"Block 1\"]\n          block2[\"Bloc2\"]       ",
    "BLOCK_DIAGRAM_KEY@0 block\nINVALID@11 ",
  ),
  (
    "blocks ~~~with different widths", "NODE_ID@0 blocks\nNODE_ID@7 ~~~with\nNODE_ID@15 different\nNODE_ID@25 widths\nEOF@31 \n$end@31 ",
  ),
  (
    "block\n    id1(((\"This is the text(-\"x\"-)in the circle\")))\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 (((\nSTR@17 This is the text(-\nINVALID@36 ",
  ),
  (
    "lock:ID\n    Arow blocks with mul%%tiple points", "NODE_ID@0 lock\nINVALID@4 ",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B fill:#f9F,stroke:#333,stroke-width:4px\nblock:       ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@20 B\nNODE_DSTART@21 [\nSTR@23 A wide one in the middle\nNODE_DEND@48 ]\nstyle@52 style \nSTYLE_ENTITY_IDS@58 B\nSTYLE_DEFINITION_DATA@59  fill:#f9F,stroke:#333,stroke-width:4px\nid-block@99 block:\nEOF@112 \n$end@112 ",
  ),
  (
    "block\n       po   block\n         aBlock[\"ABlock\"]\n            block\n              bBlock[\"BBlock\"]\n            end\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@13 po\nBLOCK_DIAGRAM_KEY@18 block\nNODE_ID@33 aBlock\nNODE_DSTART@39 [\nSTR@41 ABlock\nNODE_DEND@48 ]\nBLOCK_DIAGRAM_KEY@62 block\nNODE_ID@82 bBlock\nNODE_DSTART@88 [\nSTR@90 BBlock\nNODE_DEND@97 ]\nend@111 end\n          \nend@125 end\n        \nEOF@137 \n$end@137 ",
  ),
  (
    "blo==k\n        oc  block\n            aBlock[\"ABlock\"] \n            bBlock[\"BBlock\"]\n          end\n        ",
    "NODE_ID@0 blo\nSTART_LINK@3 ==\nINVALID@5 ",
  ),
  (
    "-.->blockA==>rowIrow", "LINK@0 -.->\nNODE_ID@4 blockA\nLINK@10 ==>\nNODE_ID@13 rowIrow\nEOF@20 \n$end@20 ",
  ),
  ("blblock:gock db edge styles", "NODE_ID@0 blblock\nINVALID@7 "),
  (
    "block\n        columns 3\n        one[\"One Slot\"]\naccDescr { d }        two[\"Two slots\"]:2\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nNODE_ID@32 one\nNODE_DSTART@35 [\nSTR@37 One Slot\nNODE_DEND@46 ]\nacc_descr_multiline_value@59 d \nNODE_ID@70 two\nNODE_DSTART@73 [\nSTR@75 Two slots\nNODE_DEND@85 ]\nSIZE@86 2\nEOF@97 \n$end@97 ",
  ),
  (
    "block\n          columns 1\n          block1[\"Block 1\"]\n\n          block\n            columns 2\n            block2[<\"Block 2\"]\n            block3[\"Block 3\"]\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@16 1\nNODE_ID@36 block1\nNODE_DSTART@42 [\nSTR@44 Block 1\nNODE_DEND@52 ]\nBLOCK_DIAGRAM_KEY@65 block\nCOLUMNS@83 2\nNODE_ID@105 block2\nNODE_DSTART@111 [\nINVALID@112 ",
  ),
  (
    "block\n  A\n  style A fi<[\"x\"]>(right)ll:#969,stroke:#333;\n\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nstyle@12 style \nSTYLE_ENTITY_IDS@18 A\nSTYLE_DEFINITION_DATA@19  fi<[\"x\"]>(right)ll:#969,stroke:#333;\nEOF@58 \n$end@58 ",
  ),
  (
    "Arr bon) spacx\"}\now blocks with tiple points", "NODE_ID@0 Arr\nNODE_ID@4 bon\nNODE_DSTART@7 )\nINVALID@8 ",
  ),
  (
    "block\n      id1(\"This s the tein the box\")\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@12 id1\nNODE_DSTART@15 (\nSTR@17 This s the tein the box\nNODE_DEND@41 )\nEOF@43 \n$end@43 ",
  ),
  (
    "block-beta\n  columns 1\n  A:1\n  B:2\n  C:3  D:4\n  E:3\n  F:2\n  G:1", "BLOCK_DIAGRAM_KEY@0 block-beta\nCOLUMNS@13 1\nNODE_ID@25 A\nSIZE@26 1\nNODE_ID@31 B\nSIZE@32 2\nNODE_ID@37 C\nSIZE@38 3\nNODE_ID@42 D\nSIZE@43 4\nNODE_ID@48 E\nSIZE@49 3\nNODE_ID@54 F\nSIZE@55 2\nNODE_ID@60 G\nSIZE@61 1\nEOF@63 \n$end@63 ",
  ),
  (
    "block{          block1[\"Block 1id1\"]\n      ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_DSTART@5 {\nINVALID@6 ",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:4px`\";\n  class A blue\n  style B fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 A\nLINK@21 -->\nNODE_ID@24 B\nclassDef@28 classDef \nCLASSDEF_ID@37 blue \nCLASSDEF_STYLEOPTS@42 fill:#6e6ce6,stroke:#333,stroke-width:4px`\";\nclass@89 class \nCLASSENTITY_IDS@95 A\nSTYLECLASS@96  blue\nstyle@104 style \nSTYLE_ENTITY_IDS@110 B\nSTYLE_DEFINITION_DATA@111  fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\nEOF@184 \n$end@184 ",
  ),
  (
    "block-beta\n      block:outer\n        block:inner-)\n        = a\n        end\n      end\n      block:sibling\n        b\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 outer\nid-block@37 block:\nNODE_ID@43 inner\nNODE_DSTART@48 -)\nINVALID@50 ",
  ),
  (
    "block_s;tyle A,B xrrow", "NODE_ID@0 block_s;tyle\nNODE_ID@13 A,B\nNODE_ID@17 xrrow\nEOF@22 \n$end@22 ",
  ),
  (
    "Arw blocks\r\n with multiple points", "NODE_ID@0 Arw\nNODE_ID@4 blocks\nNODE_ID@13 with\nNODE_ID@18 multiple\nNODE_ID@27 points\nEOF@33 \n$end@33 ",
  ),
  (
    "block\n    block\n      D\n    end\n    A[23\"A: I am a wide one\"]\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@10 block\nNODE_ID@22 D\nend@28 end\n    \nNODE_ID@36 A\nNODE_DSTART@37 [\nINVALID@38 ",
  ),
  (
    "block\n  d1[(\"Databasblocke\"", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 d1\nNODE_DSTART@10 [(\nSTR@13 Databasblocke\n$end@27 ",
  ),
  (
    "block\n    block\n      D\n    end\n    A[\"A: I B\nam a wstyle A,B xide onspace:\"]\n",
    "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@10 block\nNODE_ID@22 D\nend@28 end\n    \nNODE_ID@36 A\nNODE_DSTART@37 [\nSTR@39 A: I B\nam a wstyle A,B xide onspace:\nNODE_DEND@76 ]\nEOF@78 \n$end@78 ",
  ),
  (
    "block\n  id1A space B\n  A-->B->B", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1A\nSPACE_BLOCK@13 1\nNODE_ID@19 B\nNODE_ID@23 A\nLINK@24 -->\nNODE_ID@27 B\nINVALID@28 ",
  ),
  (
    "block colou slots", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 colou\nNODE_ID@12 slots\nEOF@17 \n$end@17 ",
  ),
  (
    "block\n    id1accDescr {}[\"This is the text in in the box\"]]\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1accDescr\nNODE_DSTART@22 {\nNODE_DEND@23 }\nNODE_DSTART@24 [\nSTR@26 This is the text in in the box\nNODE_DEND@57 ]]\nEOF@60 \n$end@60 ",
  ),
  (
    "block:2\n          columns 1\n          block1[\"Block 1\"]\n       columns    block2[\"Block 2\"]\n        ",
    "id-block@0 block:\nNODE_ID@6 2\nCOLUMNS@18 1\nNODE_ID@38 block1\nNODE_DSTART@44 [\nSTR@46 Block 1\nNODE_DEND@54 ]\nNODE_ID@63 columns\nNODE_ID@74 block2\nNODE_DSTART@80 [\nSTR@82 Block 2\nNODE_DEND@90 ]\nEOF@100 \n$end@100 ",
  ),
  (
    "Arrrrow bloclockA<-.->ks", "NODE_ID@0 Arrrrow\nNODE_ID@8 bloclockA\nLINK@17 <-.->\nNODE_ID@22 ks\nEOF@24 \n$end@24 ",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:#333,stroke-\nwidth:4px\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@18 db\nNODE_DSTART@20 ((\nSTR@23 DB\nNODE_DEND@26 ))\nNODE_ID@31 blockArrowId6\nBLOCK_ARROW_START@44 <[\nSTR@47 &nbsp;&nbsp;&nbsp;\nDIR@69 down\nBLOCK_ARROW_END@73 ]>\nid-block@77 block:\nNODE_ID@83 ID\nNODE_ID@90 A\nNODE_ID@96 B\nNODE_DSTART@97 [\nSTR@99 A wide one in the middle\nNODE_DEND@124 ]\nNODE_ID@130 C\nend@134 end\n  \nSPACE_BLOCK@140 1\nNODE_ID@148 D\nNODE_ID@152 ID\nLINK@155 --> \nNODE_ID@159 D\nNODE_ID@163 C\nLINK@165 --> \nNODE_ID@169 D\nstyle@173 style \nSTYLE_ENTITY_IDS@179 B\nSTYLE_DEFINITION_DATA@180  fill:#939,stroke:#333,stroke-\nNODE_ID@211 width\nSIZE@216 4\nNODE_ID@218 px\nEOF@221 \n$end@221 ",
  ),
  (
    "block\n    id1[[\"This is the text %%in the box\"]]\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 [[\nSTR@16 This is the text %%in the box\nNODE_DEND@46 ]]\nEOF@49 \n$end@49 ",
  ),
  (
    "block\n          id1[\"[[\"x\"]]first\"]  -->   id2[\"olourse\"second\"]\n      ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1\nNODE_DSTART@19 [\nSTR@21 [[\nINVALID@24 ",
  ),
  (
    "bblock1lock\n    id1((\"This is the text the circle\"))\n", "NODE_ID@0 bblock1lock\nNODE_ID@16 id1\nNODE_DSTART@19 ((\nSTR@22 This is the text the circle\nNODE_DEND@50 ))\nEOF@53 \n$end@53 ",
  ),
  (
    "givno slot to a simple block", "NODE_ID@0 givno\nNODE_ID@6 slot\nNODE_ID@11 to\nNODE_ID@14 a\nNODE_ID@16 simple\nBLOCK_DIAGRAM_KEY@23 block\nEOF@28 \n$end@28 ",
  ),
  (
    "block\n${ -. \"x\" .-> prop}", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 $\nNODE_DSTART@7 {\nINVALID@8 ",
  ),
  (
    "Arrow blocks with multiaccDescr: dple pupoints", "NODE_ID@0 Arrow\nNODE_ID@6 blocks\nNODE_ID@13 with\nNODE_ID@18 multiaccDescr\nINVALID@31 ",
  ),
  (
    "block\n    block\n      D\n --o   end\n    A[\"A: I am a wide one\"]\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@10 block\nNODE_ID@22 D\nLINK@25 --o   \nend@31 end\n    \nNODE_ID@39 A\nNODE_DSTART@40 [\nSTR@42 A: I am a wide one\nNODE_DEND@61 ]\nEOF@63 \n$end@63 ",
  ),
  (
    "block\n  block\n    colulumns 1\n    a[\"A label\"] b c d\n  end\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@8 block\nNODE_ID@18 colulumns\nNODE_ID@28 1\nNODE_ID@34 a\nNODE_DSTART@35 [\nSTR@37 A label\nNODE_DEND@45 ]\nNODE_ID@47 b\nNODE_ID@49 c\nNODE_ID@51 d\nend@55 end\n\nEOF@59 \n$end@59 ",
  ),
  (
    "block\n  blockArrowId<[\"Label\"]>(right)\n  blockArrowI[(d2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"Label\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 blockArrowId\nBLOCK_ARROW_START@20 <[\nSTR@23 Label\nDIR@32 right\nBLOCK_ARROW_END@37 ]>\nNODE_ID@41 blockArrowI\nNODE_DSTART@52 [(\nINVALID@54 ",
  ),
  (
    "bl\no[[\"x\"]]ck_arrow", "NODE_ID@0 bl\nNODE_ID@3 o\nNODE_DSTART@4 [[\nSTR@7 x\nNODE_DEND@9 ]]\nNODE_ID@11 ck_arrow\nEOF@19 \n$end@19 ",
  ),
  (
    "Arrbl[/\"x\"\\]ocks", "NODE_ID@0 Arrbl\nNODE_DSTART@5 [/\nSTR@8 x\nNODE_DEND@10 \\]\nNODE_ID@12 ocks\nEOF@16 \n$end@16 ",
  ),
  (
    "block\naccDescr { d }          block:compoundBlock[\"Compound block\"]\n            columns 1\n            block2[\"Block 2\"]\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nacc_descr_multiline_value@17 d \nid-block@30 block:\nNODE_ID@36 compoundBlock\nNODE_DSTART@49 [\nSTR@51 Compound block\nNODE_DEND@66 ]\nCOLUMNS@80 1\nNODE_ID@102 block2\nNODE_DSTART@108 [\nSTR@110 Block 2\nNODE_DEND@118 ]\nend@130 end\n        \nEOF@142 \n$end@142 ",
  ),
  (
    "block\n  id1[/\"This is t text in the box\"/]\n  id2[\\\"This is the text in the box\"\\]\n  A[/\"Christmas\"\\]\n  B[\\\"Go shopping\"/]\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nNODE_DSTART@11 [/\nSTR@14 This is t text in the box\nNODE_DEND@40 /]\nNODE_ID@45 id2\nNODE_DSTART@48 [\\\nSTR@51 This is the text in the box\nNODE_DEND@79 \\]\nNODE_ID@84 A\nNODE_DSTART@85 [/\nSTR@88 Christmas\nNODE_DEND@98 \\]\nNODE_ID@103 B\nNODE_DSTART@104 [\\\nSTR@107 Go shopping\nNODE_DEND@119 /]\nEOF@122 \n$end@122 ",
  ),
  (
    "block\n  A   A space B\n  A --> B\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nNODE_ID@12 A\nSPACE_BLOCK@14 1\nNODE_ID@20 B\nNODE_ID@24 A\nLINK@26 --> \nNODE_ID@30 B\nEOF@32 \n$end@32 ",
  ),
  (
    "bl\tcks mixed with compound--x blocks", "NODE_ID@0 bl\nNODE_ID@3 cks\nNODE_ID@7 mixed\nNODE_ID@13 with\nNODE_ID@18 compound\nLINK@26 --x \nNODE_ID@30 blocks\nEOF@36 \n$end@36 ",
  ),
  (
    "block\n  A space:2 B\n {{ A-- \"X\" -->B\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 2\nNODE_ID@18 B\nNODE_DSTART@21 {{\nINVALID@23 ",
  ),
  (
    "  block\n    A\n    styl\"\"e A fill#969;\n", "BLOCK_DIAGRAM_KEY@2 block\nNODE_ID@12 A\nNODE_ID@18 styl\"\"e\nNODE_ID@26 A\nNODE_ID@28 fill#969;\nEOF@38 \n$end@38 ",
  ),
  (
    "  bl===ock\n    A\n    ste A fillclass A a#969;\n", "NODE_ID@2 bl\nLINK@4 ===o\nNODE_ID@8 ck\nNODE_ID@15 A\nNODE_ID@21 ste\nNODE_ID@25 A\nNODE_ID@27 fillclass\nNODE_ID@37 A\nNODE_ID@39 a#969;\nEOF@46 \n$end@46 ",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n      end\n         blo[|k:b 1\n        block:b2\n          y\n        end\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 a1\nid-block@34 block:\nNODE_ID@40 a2\nNODE_ID@53 x\nend@63 end\n      \nend@73 end\n         \nNODE_ID@86 blo\nNODE_DSTART@89 [|\nINVALID@91 ",
  ),
  (
    "block-beta\n      block:outer\n        -. \"x\" .->  block:inner\n          a\n        end\n      end\n      block:sibling\n        b\n   end   end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 outer\nSTART_LINK@37 -. \nLINK_LABEL@40 \"\nSTR@41 x\nLINK@43  .->  \nid-block@49 block:\nNODE_ID@55 inner\nNODE_ID@71 a\nend@81 end\n      \nend@91 end\n      \nid-block@101 block:\nNODE_ID@107 sibling\nNODE_ID@123 b\nend@128 end   \nend@134 end\n    \nEOF@142 \n$end@142 ",
  ),
  (
    "block\n  blockArrowId<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(l-.downeft)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"Label\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[abel\"]>(x, down)\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 blockArrowId\nBLOCK_ARROW_START@20 <[\nSTR@23 Label\nDIR@32 right\nBLOCK_ARROW_END@37 ]>\nNODE_ID@41 blockArrowId2\nBLOCK_ARROW_START@54 <[\nSTR@57 Label\nINVALID@66 ",
  ),
  (
    "block\nblock  ida space:3 i\"`db idc\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@6 block\nNODE_ID@13 ida\nSPACE_BLOCK@17 3\nNODE_ID@25 i\"`db\nNODE_ID@31 idc\nEOF@35 \n$end@35 ",
  ),
  (
    "blocks mixed with compo bcks", "NODE_ID@0 blocks\nNODE_ID@7 mixed\nNODE_ID@13 with\nNODE_ID@18 compo\nNODE_ID@24 bcks\nEOF@28 \n$end@28 ",
  ),
  (
    "block-beta-->\n  columns 1\n  A:1\n  B:2\n  C:3\n  D\n  D:4\n  E:3\n  F:2\n  G:1",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nLINK@10 -->\n  \nCOLUMNS@16 1\nNODE_ID@28 A\nSIZE@29 1\nNODE_ID@34 B\nSIZE@35 2\nNODE_ID@40 C\nSIZE@41 3\nNODE_ID@46 D\nNODE_ID@50 D\nSIZE@51 4\nNODE_ID@56 E\nSIZE@57 3\nNODE_ID@62 F\nSIZE@63 2\nNODE_ID@68 G\nSIZE@69 1\nEOF@71 \n$end@71 ",
  ),
  (
    "block((\"x\"))\n  A\n  style A fill:#969,stroke:#333;\n\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_DSTART@5 ((\nSTR@8 x\nNODE_DEND@10 ))\nNODE_ID@15 A\nstyle@19 style \nSTYLE_ENTITY_IDS@25 A\nSTYLE_DEFINITION_DATA@26  fill:#969,stroke:#333;\nEOF@51 \n$end@51 ",
  ),
  (
    "block\n        classDef black color:#ffffff, fill:#000000;\n\n       mcMemcache\"]\n        class mc black\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nclassDef@14 classDef \nCLASSDEF_ID@23 black \nCLASSDEF_STYLEOPTS@29 color:#ffffff, fill:#000000;\nNODE_ID@66 mcMemcache\"]\nclass@87 class \nCLASSENTITY_IDS@93 mc\nSTYLECLASS@95  black\nEOF@110 \n$end@110 ",
  ),
  (
    "block\n  A\n  style ill:#969,stroke:#333;\n\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nstyle@12 style \nSTYLE_ENTITY_IDS@18 ill\nSTYLE_DEFINITION_DATA@21 :#969,stroke:#333;\nEOF@41 \n$end@41 ",
  ),
  (
    "blo     --xk colour slots", "NODE_ID@0 blo\nLINK@8 --x\nNODE_ID@11 k\nNODE_ID@13 colour\nNODE_ID@20 slots\nEOF@25 \n$end@25 ",
  ),
  (
    "blBck\n          id[\"A label\"]\n          ", "NODE_ID@0 blBck\nNODE_ID@16 id\nNODE_DSTART@18 [\nSTR@20 A label\nNODE_DEND@28 ]\nEOF@40 \n$end@40 ",
  ),
  (
    "block\n   ==id1[(\"Database\")]\n", "BLOCK_DIAGRAM_KEY@0 block\nSTART_LINK@9 ==\nINVALID@11 ",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n tyle B fill:#969,stroke:#333,stroke-width:4px\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@18 db\nNODE_DSTART@20 ((\nSTR@23 DB\nNODE_DEND@26 ))\nNODE_ID@31 blockArrowId6\nBLOCK_ARROW_START@44 <[\nSTR@47 &nbsp;&nbsp;&nbsp;\nDIR@69 down\nBLOCK_ARROW_END@73 ]>\nid-block@77 block:\nNODE_ID@83 ID\nNODE_ID@90 A\nNODE_ID@96 B\nNODE_DSTART@97 [\nSTR@99 A wide one in the middle\nNODE_DEND@124 ]\nNODE_ID@130 C\nend@134 end\n  \nSPACE_BLOCK@140 1\nNODE_ID@148 D\nNODE_ID@152 ID\nLINK@155 --> \nNODE_ID@159 D\nNODE_ID@163 C\nLINK@165 --> \nNODE_ID@169 D\nNODE_ID@172 tyle\nNODE_ID@177 B\nNODE_ID@179 fill\nINVALID@183 ",
  ),
  (
    "Arrow blo cks with multiple points", "NODE_ID@0 Arrow\nNODE_ID@6 blo\nNODE_ID@10 cks\nNODE_ID@14 with\nNODE_ID@19 multiple\nNODE_ID@28 points\nEOF@34 \n$end@34 ",
  ),
  (
    "blockck\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"<-->&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#939,stroke:#333,stroke-width:4px\n",
    "NODE_ID@0 blockck\nCOLUMNS@8 1\nNODE_ID@20 db\nNODE_DSTART@22 ((\nSTR@25 DB\nNODE_DEND@28 ))\nNODE_ID@33 blockArrowId6\nBLOCK_ARROW_START@46 <[\nSTR@49 <-->&nbsp;&nbsp;&nbsp;\nDIR@75 down\nBLOCK_ARROW_END@79 ]>\nid-block@83 block:\nNODE_ID@89 ID\nNODE_ID@96 A\nNODE_ID@102 B\nNODE_DSTART@103 [\nSTR@105 A wide one in the middle\nNODE_DEND@130 ]\nNODE_ID@136 C\nend@140 end\n  \nSPACE_BLOCK@146 1\nNODE_ID@154 D\nNODE_ID@158 ID\nLINK@161 --> \nNODE_ID@165 D\nNODE_ID@169 C\nLINK@171 --> \nNODE_ID@175 D\nstyle@179 style \nSTYLE_ENTITY_IDS@185 B\nSTYLE_DEFINITION_DATA@186  fill:#939,stroke:#333,stroke-width:4px\nEOF@226 \n$end@226 ",
  ),
  ("blocksmixed <with compound blocks", "NODE_ID@0 blocksmixed\nINVALID@12 "),
  (
    "block\n        olumns 3\n        block1[\"Block 1\"]\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(right)\n        block2[\"         id3\n   right Block 2\"]",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@14 olumns\nNODE_ID@21 3\nNODE_ID@31 block1\nNODE_DSTART@37 [\nSTR@39 Block 1\nNODE_DEND@47 ]\nNODE_ID@57 blockArrow\nBLOCK_ARROW_START@67 <[\nSTR@70 &nbsp;&nbsp;&nbsp;\nDIR@92 right\nBLOCK_ARROW_END@97 ]>\nNODE_ID@107 block2\nNODE_DSTART@113 [\nSTR@115          id3\n   right Block 2\nNODE_DEND@145 ]\nEOF@146 \n$end@146 ",
  ),
  (
    "block\n  A\n  style A fill:#969,(-\",(-\"x\"-)stroke:#333;\n\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nstyle@12 style \nSTYLE_ENTITY_IDS@18 A\nSTYLE_DEFINITION_DATA@19  fill:#969,(-\",(-\"x\"-)stroke:#333;\nEOF@55 \n$end@55 ",
  ),
  (
    "bl   ock\n       id1\n          id2\n          id3\n      ", "NODE_ID@0 bl\nNODE_ID@5 ock\nNODE_ID@16 id1\nNODE_ID@30 id2\nNODE_ID@44 id3\nEOF@54 \n$end@54 ",
  ),
  (
    "block\n          id1\n          i]]d2\n--          id3\n      ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1\nNODE_ID@30 i]]d2\nSTART_LINK@36 --          \nINVALID@48 ",
  ),
  (
    "block\n        id[\"A label\"]\n          id2", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@14 id\nNODE_DSTART@16 [\nSTR@18 A label\nNODE_DEND@26 ]\nNODE_ID@38 id2\nEOF@41 \n$end@41 ",
  ),
  (
    "block\n  columns 3\n  Start((\"Start\")) space:2\n  down<[\" \"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(right) Process1[\"Process A\" downAgain<[\"No\"]>(down) space r3<[\"Done\"]>(down)\n  Process2[\"Process B\"] r2<[\"Done\"]>(right) End((\"End\"))\n\n  style Start fill:#969;\n  style End fill:#696;\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 Start\nNODE_DSTART@25 ((\nSTR@28 Start\nNODE_DEND@34 ))\nSPACE_BLOCK@37 2\nNODE_ID@47 down\nBLOCK_ARROW_START@51 <[\nSTR@54  \nDIR@59 down\nBLOCK_ARROW_END@63 ]>\nSPACE_BLOCK@65 2\nNODE_ID@75 Decision\nNODE_DSTART@83 {{\nSTR@86 Make Decision\nNODE_DEND@100 }}\nNODE_ID@103 right\nBLOCK_ARROW_START@108 <[\nSTR@111 Yes\nDIR@118 right\nBLOCK_ARROW_END@123 ]>\nNODE_ID@125 Process1\nNODE_DSTART@133 [\nSTR@135 Process A\nINVALID@145 ",
  ),
  ("}Arrow blockslinkStyle with m66,stroke-ultiple points", "INVALID@0 "),
  (
    "block\n          columns 1\n          block1[\"Block 1\"]\n\n          block\n    >       columns 2\n            block2[\"Block 2\"]\n            block3[\"Block 3\"]\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@16 1\nNODE_ID@36 block1\nNODE_DSTART@42 [\nSTR@44 Block 1\nNODE_DEND@52 ]\nBLOCK_DIAGRAM_KEY@65 block\nNODE_DSTART@75 >\nINVALID@76 ",
  ),
  (
    "block\n    id1(\"Ttlehis ihe text in the box\")\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 (\nSTR@15 Ttlehis ihe text in the box\nNODE_DEND@43 )\nEOF@45 \n$end@45 ",
  ),
  (
    "blocks txt in the box\"(\"x\")])\nh different widths", "NODE_ID@0 blocks\nNODE_ID@7 txt\nNODE_ID@11 in\nNODE_ID@14 the\nNODE_ID@18 box\"\nNODE_DSTART@22 (\nSTR@24 x\nNODE_DEND@26 )]\nNODE_DSTART@28 )\nINVALID@29 ",
  ),
  (
    "block-beta\n      block:outer\n        block:inner\n          a((\"This is the tex\n        end\n      end\n      block:sibling\n    class  b\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 outer\nid-block@37 block:\nNODE_ID@43 inner\nNODE_ID@59 a\nNODE_DSTART@60 ((\nSTR@63 This is the tex\n        end\n      end\n      block:sibling\n    class  b\n      end\n    \nSTR@148 \n$end@148 ",
  ),
  (
    "Arrdownowcolumns(\"x\") blocks", "NODE_ID@0 Arrdownowcolumns\nNODE_DSTART@16 (\nSTR@18 x\nNODE_DEND@20 )\nNODE_ID@22 blocks\nEOF@28 \n$end@28 ",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n   3\n  a sp        x\n        end\n      end\n      block == \"x\" ==> :b1\n        block:b2\n          y\n        end\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 a1\nid-block@34 block:\nNODE_ID@40 a2\nNODE_ID@46 3\nNODE_ID@50 a\nNODE_ID@52 sp\nNODE_ID@62 x\nend@72 end\n      \nend@82 end\n      \nBLOCK_DIAGRAM_KEY@92 block\nSTART_LINK@98 == \nLINK_LABEL@101 \"\nSTR@102 x\nLINK@104  ==> \nINVALID@109 ",
  ),
  (
    "should ld log a warng when block width exceeds column width", "NODE_ID@0 should\nNODE_ID@7 ld\nNODE_ID@10 log\nNODE_ID@14 a\nNODE_ID@16 warng\nNODE_ID@22 when\nBLOCK_DIAGRAM_KEY@27 block\nNODE_ID@33 width\nNODE_ID@39 exceeds\nNODE_ID@47 column\nNODE_ID@54 width\nEOF@59 \n$end@59 ",
  ),
  (
    "ock cour slots", "NODE_ID@0 ock\nNODE_ID@4 cour\nNODE_ID@9 slots\nEOF@14 \n$end@14 ",
  ),
  (
    "block-beta\n      block:.outer\n        block:inner          a\n        end\n      k\nend\n      block:sibling\n        b\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 .outer\nid-block@38 block:\nNODE_ID@44 inner\nNODE_ID@59 a\nend@69 end\n      \nNODE_ID@79 k\nend@81 end\n      \nid-block@91 block:\nNODE_ID@97 sibling\nNODE_ID@113 b\nend@121 end\n    \nEOF@129 \n$end@129 ",
  ),
  (
    "  oblo)))k\n    A\n    style A fill#969;\n", "NODE_ID@2 oblo\nNODE_DSTART@6 ))\nNODE_DEND@8 )\nNODE_ID@9 k\nNODE_ID@15 A\nstyle@21 style \nSTYLE_ENTITY_IDS@27 A\nSTYLE_DEFINITION_DATA@28  fill#969;\nEOF@39 \n$end@39 ",
  ),
  (
    "block\n  blockock\n    columns 1\n   \r\n a[\"A label\"] b c d\n  end\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 blockock\nCOLUMNS@21 1\nNODE_ID@37 a\nNODE_DSTART@38 [\nSTR@40 A label\nNODE_DEND@48 ]\nNODE_ID@50 b\nNODE_ID@52 c\nNODE_ID@54 d\nend@58 end\n\nEOF@62 \n$end@62 ",
  ),
  (
    "b[[\"x\"]]lock\n         y id1\n       [  id2\n      ", "NODE_ID@0 b\nNODE_DSTART@1 [[\nSTR@4 x\nNODE_DEND@6 ]]\nNODE_ID@8 lock\nNODE_ID@22 y\nNODE_ID@24 id1\nNODE_DSTART@35 [\nINVALID@36 ",
  ),
  (
    "compound blocks:032", "NODE_ID@0 compound\nNODE_ID@9 blocks\nSIZE@15 032\nEOF@19 \n$end@19 ",
  ),
  (
    "block\n  id1[/\"This is the text in the box\"/]\n  id2[\\\"Th\\\"This is the text in the box\"\\]\n  A[/\"Christmas\"\\]\n  B[\\\"Go shopping\"/]\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nNODE_DSTART@11 [/\nSTR@14 This is the text in the box\nNODE_DEND@42 /]\nNODE_ID@47 id2\nNODE_DSTART@50 [\\\nSTR@53 Th\\\nINVALID@57 ",
  ),
  (
    "blts appock db runtime config", "NODE_ID@0 blts\nNODE_ID@5 appock\nNODE_ID@12 db\nNODE_ID@15 runtime\nNODE_ID@23 config\nEOF@29 \n$end@29 ",
  ),
  (
    "block\n  columns 3\n  a[\"A label\"] b:2 c:2<[\"x\"]>(right) d\n", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 a\nNODE_DSTART@21 [\nSTR@23 A label\nNODE_DEND@31 ]\nNODE_ID@33 b\nSIZE@34 2\nNODE_ID@37 c\nSIZE@38 2\nBLOCK_ARROW_START@40 <[\nSTR@43 x\nDIR@48 right\nBLOCK_ARROW_END@53 ]>\nNODE_ID@55 d\nEOF@57 \n$end@57 ",
  ),
  (
    "bcolumns 0lock\n  colus 3\n  a space  c   d   e\n", "NODE_ID@0 bcolumns\nNODE_ID@9 0lock\nNODE_ID@17 colus\nNODE_ID@23 3\nNODE_ID@27 a\nSPACE_BLOCK@29 1\nNODE_ID@36 c\nNODE_ID@40 d\nNODE_ID@44 e\nEOF@46 \n$end@46 ",
  ),
  (
    "blocks on top of e of each othr", "NODE_ID@0 blocks\nNODE_ID@7 on\nNODE_ID@10 top\nNODE_ID@14 of\nNODE_ID@17 e\nNODE_ID@19 of\nNODE_ID@22 each\nNODE_ID@27 othr\nEOF@31 \n$end@31 ",
  ),
  (
    "compound bund blocks defa", "NODE_ID@0 compound\nNODE_ID@9 bund\nNODE_ID@14 blocks\nNODE_ID@21 defa\nEOF@25 \n$end@25 ",
  ),
  (
    "ck\n  id1[/\"This is the text in the box\"/]\n  id2[\\\"This is the text iB the box\"\\]\n  A[/\"Christmas\"\\]\n  B[\\\"Go shopping\"/]\n",
    "NODE_ID@0 ck\nNODE_ID@5 id1\nNODE_DSTART@8 [/\nSTR@11 This is the text in the box\nNODE_DEND@39 /]\nNODE_ID@44 id2\nNODE_DSTART@47 [\\\nSTR@50 This is the text iB the box\nNODE_DEND@78 \\]\nNODE_ID@83 A\nNODE_DSTART@84 [/\nSTR@87 Christmas\nNODE_DEND@97 \\]\nNODE_ID@102 B\nNODE_DSTART@103 [\\\nSTR@106 Go shopping\nNODE_DEND@118 /]\nEOF@121 \n$end@121 ",
  ),
  (
    "blocks next to each oter", "NODE_ID@0 blocks\nNODE_ID@7 next\nNODE_ID@12 to\nNODE_ID@15 each\nNODE_ID@20 oter\nEOF@24 \n$end@24 ",
  ),
  (
    "blocks mixompound bloed with compound blocks", "NODE_ID@0 blocks\nNODE_ID@7 mixompound\nNODE_ID@18 bloed\nNODE_ID@24 with\nNODE_ID@29 compound\nNODE_ID@38 blocks\nEOF@44 \n$end@44 ",
  ),
  (
    "compound b A-->B\nlocks with title", "NODE_ID@0 compound\nNODE_ID@9 b\nNODE_ID@11 A\nLINK@12 -->\nNODE_ID@15 B\nNODE_ID@17 locks\nNODE_ID@23 with\nNODE_ID@28 title\nEOF@33 \n$end@33 ",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B fill:#f9F,stroke:#333,stroke-width:4px\n-        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@20 B\nNODE_DSTART@21 [\nSTR@23 A wide one in the middle\nNODE_DEND@48 ]\nstyle@52 style \nSTYLE_ENTITY_IDS@58 B\nSTYLE_DEFINITION_DATA@59  fill:#f9F,stroke:#333,stroke-width:4px\nINVALID@99 ",
  ),
  (
    "block\n  blockArrowId<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"Label\"b el\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 blockArrowId\nBLOCK_ARROW_START@20 <[\nSTR@23 Label\nDIR@32 right\nBLOCK_ARROW_END@37 ]>\nNODE_ID@41 blockArrowId2\nBLOCK_ARROW_START@54 <[\nSTR@57 Label\nDIR@66 left\nBLOCK_ARROW_END@70 ]>\nNODE_ID@74 blockArrowId3\nBLOCK_ARROW_START@87 <[\nSTR@90 Label\nDIR@99 up\nBLOCK_ARROW_END@101 ]>\nNODE_ID@105 blockArrowId4\nBLOCK_ARROW_START@118 <[\nSTR@121 Label\nDIR@130 down\nBLOCK_ARROW_END@134 ]>\nNODE_ID@138 blockArrowId5\nBLOCK_ARROW_START@151 <[\nSTR@154 Label\nINVALID@160 ",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n ]  C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#969,stroke:#333,stroke-width:4px\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@18 db\nNODE_DSTART@20 ((\nSTR@23 DB\nNODE_DEND@26 ))\nNODE_ID@31 blockArrowId6\nBLOCK_ARROW_START@44 <[\nSTR@47 &nbsp;&nbsp;&nbsp;\nDIR@69 down\nBLOCK_ARROW_END@73 ]>\nid-block@77 block:\nNODE_ID@83 ID\nNODE_ID@90 A\nNODE_ID@96 B\nNODE_DSTART@97 [\nSTR@99 A wide one in the middle\nNODE_DEND@124 ]\nNODE_ID@127 ]\nNODE_ID@130 C\nend@134 end\n  \nSPACE_BLOCK@140 1\nNODE_ID@148 D\nNODE_ID@152 ID\nLINK@155 --> \nNODE_ID@159 D\nNODE_ID@163 C\nLINK@165 --> \nNODE_ID@169 D\nstyle@173 style \nSTYLE_ENTITY_IDS@179 B\nSTYLE_DEFINITION_DATA@180  fill:#969,stroke:#333,stroke-width:4px\nEOF@220 \n$end@220 ",
  ),
  (
    "compound blocks w[[ith title", "NODE_ID@0 compound\nNODE_ID@9 blocks\nNODE_ID@16 w\nNODE_DSTART@17 [[\nINVALID@19 ",
  ),
  (
    "block\n          c(-\"x\"-)olumns auto[\"x\"]\n          block1[\"Block 1\"]\n      ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 c\nNODE_DSTART@17 (-\nSTR@20 x\nNODE_DEND@22 -)\nNODE_ID@24 olumns\nNODE_ID@31 auto\nNODE_DSTART@35 [\nSTR@37 x\nNODE_DEND@39 ]\nNODE_ID@51 block1\nNODE_DSTART@57 [\nSTR@59 Block 1\nNODE_DEND@67 ]\nEOF@75 \n$end@75 ",
  ),
  (
    "block\n    block\n      D\n    end\n    Acolumns 0[\"A: I am a  wide one\"]\n",
    "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@10 block\nNODE_ID@22 D\nend@28 end\n    \nNODE_ID@36 Acolumns\nNODE_ID@45 0\nNODE_DSTART@46 [\nSTR@48 A: I am a  wide one\nNODE_DEND@68 ]\nEOF@70 \n$end@70 ",
  ),
  (
    "blupck\n  ida[\\\"x\"/] sptiple pointsace:3 idb idc\n", "NODE_ID@0 blupck\nNODE_ID@9 ida\nNODE_DSTART@12 [\\\nSTR@15 x\nNODE_DEND@17 /]\nNODE_ID@20 sptiple\nNODE_ID@28 pointsace\nSIZE@37 3\nNODE_ID@40 idb\nNODE_ID@44 idc\nEOF@48 \n$end@48 ",
  ),
  (
    "blcolumns autoock\n    id1[[\"This is the text in the box\"]]\n", "NODE_ID@0 blcolumns\nNODE_ID@10 autoock\nNODE_ID@22 id1\nNODE_DSTART@25 [[\nSTR@28 This is the text in the box\nNODE_DEND@56 ]]\nEOF@59 \n$end@59 ",
  ),
  (
    "blocks onext tach o->her", "NODE_ID@0 blocks\nNODE_ID@7 onext\nNODE_ID@13 tach\nNODE_ID@18 o\nINVALID@19 ",
  ),
  (
    "block\n  columns 3\n  a:3\n  block:group1:2\n    columns 2\n    h i j k\n  end\n  g\n  block:group2:3\n    %% columns auto (defaul<[\"x\"]>(x,y)t)\n    l m n o p q r\n  end\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 a\nSIZE@21 3\nid-block@26 block:\nNODE_ID@32 group1\nSIZE@38 2\nCOLUMNS@45 2\nNODE_ID@59 h\nNODE_ID@61 i\nNODE_ID@63 j\nNODE_ID@65 k\nend@69 end\n  \nNODE_ID@75 g\nid-block@79 block:\nNODE_ID@85 group2\nSIZE@91 3\nNODE_ID@98 %%\nCOLUMNS@101 -1\nNODE_DSTART@114 (\nINVALID@115 ",
  ),
  (
    "compound blockwith title", "NODE_ID@0 compound\nNODE_ID@9 blockwith\nNODE_ID@19 title\nEOF@24 \n$end@24 ",
  ),
  (
    "compound blcks 2", "NODE_ID@0 compound\nNODE_ID@9 blcks\nNODE_ID@15 2\nEOF@16 \n$end@16 ",
  ),
  (
    "block\n block\n      D\n    end\n    A[\"A: Im a wide one\"]\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@7 block\nNODE_ID@19 D\nend@25 end\n    \nNODE_ID@33 A\nNODE_DSTART@34 [\nSTR@36 A: Im a wide one\nNODE_DEND@53 ]\nEOF@55 \n$end@55 ",
  ),
  (
    "bloc   a\n ,k\n  a b c\n", "NODE_ID@0 bloc\nNODE_ID@7 a\nNODE_ID@10 ,k\nNODE_ID@15 a\nNODE_ID@17 b\nNODE_ID@19 c\nEOF@21 \n$end@21 ",
  ),
  (
    "bloid1ck\n  A space:2 B\n - \"X\" -->B\n", "NODE_ID@0 bloid1ck\nNODE_ID@11 A\nSPACE_BLOCK@13 2\nNODE_ID@21 B\nINVALID@24 ",
  ),
  (
    "compound bl((ocks of c-> D\n  C -->ompound blocks", "NODE_ID@0 compound\nNODE_ID@9 bl\nNODE_DSTART@11 ((\nINVALID@13 ",
  ),
  (
    "blocks on -..-top of each other", "NODE_ID@0 blocks\nNODE_ID@7 on\nLINK@10 -..-\nNODE_ID@14 top\nNODE_ID@18 of\nNODE_ID@21 each\nNODE_ID@26 other\nEOF@31 \n$end@31 ",
  ),
  (
    "blocks ocks mixed with compound bloc", "NODE_ID@0 blocks\nNODE_ID@7 ocks\nNODE_ID@12 mixed\nNODE_ID@18 with\nNODE_ID@23 compound\nNODE_ID@32 bloc\nEOF@36 \n$end@36 ",
  ),
  (
    "block-beta\n  co   lmns 1\n  A:1\n  B:2\n  C:3\n  \n  E:3\n  F:2\n  G:1", "BLOCK_DIAGRAM_KEY@0 block-beta\nNODE_ID@13 co\nNODE_ID@18 lmns\nNODE_ID@23 1\nNODE_ID@27 A\nSIZE@28 1\nNODE_ID@33 B\nSIZE@34 2\nNODE_ID@39 C\nSIZE@40 3\nNODE_ID@48 E\nSIZE@49 3\nNODE_ID@54 F\nSIZE@55 2\nNODE_ID@60 G\nSIZE@61 1\nEOF@63 \n$end@63 ",
  ),
  (
    "bk\n          dblock1[\"Block 1\"]\n      ", "NODE_ID@0 bk\nNODE_ID@13 dblock1\nNODE_DSTART@20 [\nSTR@22 Block 1\nNODE_DEND@30 ]\nEOF@38 \n$end@38 ",
  ),
  (
    "block\n  block\n    columns 1\n    a[\"a[\"A label\"] b c d\n  end\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@8 block\nCOLUMNS@18 1\nNODE_ID@32 a\nNODE_DSTART@33 [\nSTR@35 a[\nINVALID@38 ",
  ),
  (
    "block\n    id1[[\"T[[\"This is the text in the box\"]]\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 [[\nSTR@16 T[[\nINVALID@20 ",
  ),
  (
    "bloclassDef k\n  ida space:3 idb idc\n", "NODE_ID@0 bloclassDef\nNODE_ID@12 k\nNODE_ID@16 ida\nSPACE_BLOCK@20 3\nNODE_ID@28 idb\nNODE_ID@32 idc\nEOF@36 \n$end@36 ",
  ),
  (
    "b>\"x\"]locks on  of each oach other", "NODE_ID@0 b\nNODE_DSTART@1 >\nSTR@3 x\nNODE_DEND@5 ]\nNODE_ID@6 locks\nNODE_ID@12 on\nNODE_ID@16 of\nNODE_ID@19 each\nNODE_ID@24 oach\nNODE_ID@29 other\nEOF@34 \n$end@34 ",
  ),
  ("ey endblocks", "NODE_ID@0 ey\nNODE_ID@3 endblocks\nEOF@12 \n$end@12 "),
  (
    "block\n          lock\n            aBlock[\"ABlock\"]\n            block\n              bBlock[\"BBlock\"]\n            e      block1[\"Blocnd\n         d\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 lock\nNODE_ID@33 aBlock\nNODE_DSTART@39 [\nSTR@41 ABlock\nNODE_DEND@48 ]\nBLOCK_DIAGRAM_KEY@62 block\nNODE_ID@82 bBlock\nNODE_DSTART@88 [\nSTR@90 BBlock\nNODE_DEND@97 ]\nNODE_ID@111 e\nNODE_ID@118 block1\nNODE_DSTART@124 [\nSTR@126 Blocnd\n         d\n        \nSTR@152 \n$end@152 ",
  ),
  (
    "block\n olumns s 3\n  ==a b c d\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@7 olumns\nNODE_ID@14 s\nNODE_ID@16 3\nSTART_LINK@20 ==\nINVALID@22 ",
  ),
  (
    "block\n    id1{\"This i}}s the text in the box\":2}\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 {\nSTR@15 This i}}s the text in the box\nINVALID@45 ",
  ),
  ("A[({{\"x\"}}rrow blocks", "NODE_ID@0 A\nNODE_DSTART@1 [(\nINVALID@3 "),
  (
    "style sl -. \"x\" .-> e saccTitle: tatements applied to a block", "style@0 style \nSTYLE_ENTITY_IDS@6 sl\nSTYLE_DEFINITION_DATA@8  -. \"x\" .-> e saccTitle: tatements applied to a block\nEOF@61 \n$end@61 ",
  ),
  (
    "block\n          block\n            aBlock[\"ABlock\"]\n            bBlock[\"\"BBlock\"-.]\n        end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@16 block\nNODE_ID@34 aBlock\nNODE_DSTART@40 [\nSTR@42 ABlock\nNODE_DEND@49 ]\nNODE_ID@63 bBlock\nNODE_DSTART@69 [\nINVALID@72 ",
  ),
  (
    "block\n     == \"x\" ==> d1(((\"This is the tex`\"t in the circle\")){{)\n",
    "BLOCK_DIAGRAM_KEY@0 block\nSTART_LINK@11 == \nLINK_LABEL@14 \"\nSTR@15 x\nLINK@17  ==> \nNODE_ID@22 d1\nNODE_DSTART@24 (((\nSTR@28 This is the tex`\nINVALID@45 ",
  ),
  ("blockAr rowrow", "NODE_ID@0 blockAr\nNODE_ID@8 rowrow\nEOF@14 \n$end@14 "),
  (
    "block\n        colum     ns s 3\n        space\n        middle[\"In the middle\"]\n        space\n)        ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@14 colum\nNODE_ID@24 ns\nNODE_ID@27 s\nNODE_ID@29 3\nSPACE_BLOCK@39 1\nNODE_ID@53 middle\nNODE_DSTART@59 [\nSTR@61 In the middle\nNODE_DEND@75 ]\nSPACE_BLOCK@85 1\nNODE_DSTART@91 )\nINVALID@92 ",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B fill:#f9F,stroke:#333,stroke-wth:4px\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@20 B\nNODE_DSTART@21 [\nSTR@23 A wide one in the middle\nNODE_DEND@48 ]\nstyle@52 style \nSTYLE_ENTITY_IDS@58 B\nSTYLE_DEFINITION_DATA@59  fill:#f9F,stroke:#333,stroke-wth:4px\nEOF@105 \n$end@105 ",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n      end\n      block:  id[\"A         block:b2\n          y\n    style    end\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 a1\nid-block@34 block:\nNODE_ID@40 a2\nNODE_ID@53 x\nend@63 end\n      \nend@73 end\n      \nid-block@83 block:\nNODE_ID@91 id\nNODE_DSTART@93 [\nSTR@95 A         block:b2\n          y\n    style    end\n      end\n    \nSTR@157 \n$end@157 ",
  ),
  (
    "cla  Def statements aplied to a block", "NODE_ID@0 cla\nNODE_ID@5 Def\nNODE_ID@9 statements\nNODE_ID@20 aplied\nNODE_ID@27 to\nNODE_ID@30 a\nBLOCK_DIAGRAM_KEY@32 block\nEOF@37 \n$end@37 ",
  ),
  (
    "bloc---s next--o to each other", "NODE_ID@0 bloc\nLINK@4 ---\nNODE_ID@7 s\nNODE_ID@9 next\nLINK@13 --o \nNODE_ID@17 to\nNODE_ID@20 each\nNODE_ID@25 other\nEOF@30 \n$end@30 ",
  ),
  ("bo[2", "NODE_ID@0 bo\nNODE_DSTART@2 [\nINVALID@3 "),
  (
    "block\n  columns 3\n  Start((\"Start\")) spacelinkStyle:2\n  down<[\" \"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(right) Process1[\"Process A\"]\n  downAgain<[\"No\"]>(down) space r3<[\"Done\"]>(down)\n  Process2[\"Process B\"] r2<[\"Done\"]>(right) End((\"End\"))\n\n  style Start fill:#969;\n  style End fill:#696;\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 Start\nNODE_DSTART@25 ((\nSTR@28 Start\nNODE_DEND@34 ))\nNODE_ID@37 spacelinkStyle\nSIZE@51 2\nNODE_ID@56 down\nBLOCK_ARROW_START@60 <[\nSTR@63  \nDIR@68 down\nBLOCK_ARROW_END@72 ]>\nSPACE_BLOCK@74 2\nNODE_ID@84 Decision\nNODE_DSTART@92 {{\nSTR@95 Make Decision\nNODE_DEND@109 }}\nNODE_ID@112 right\nBLOCK_ARROW_START@117 <[\nSTR@120 Yes\nDIR@127 right\nBLOCK_ARROW_END@132 ]>\nNODE_ID@134 Process1\nNODE_DSTART@142 [\nSTR@144 Process A\nNODE_DEND@154 ]\nNODE_ID@158 downAgain\nBLOCK_ARROW_START@167 <[\nSTR@170 No\nDIR@176 down\nBLOCK_ARROW_END@180 ]>\nSPACE_BLOCK@182 1\nNODE_ID@188 r3\nBLOCK_ARROW_START@190 <[\nSTR@193 Done\nDIR@201 down\nBLOCK_ARROW_END@205 ]>\nNODE_ID@209 Process2\nNODE_DSTART@217 [\nSTR@219 Process B\nNODE_DEND@229 ]\nNODE_ID@231 r2\nBLOCK_ARROW_START@233 <[\nSTR@236 Done\nDIR@244 right\nBLOCK_ARROW_END@249 ]>\nNODE_ID@251 End\nNODE_DSTART@254 ((\nSTR@257 End\nNODE_DEND@261 ))\nstyle@267 style \nSTYLE_ENTITY_IDS@273 Start\nSTYLE_DEFINITION_DATA@278  fill:#969;\nstyle@292 style \nSTYLE_ENTITY_IDS@298 End\nSTYLE_DEFINITION_DATA@301  fill:#696;\nEOF@313 \n$end@313 ",
  ),
  (
    "block\n  A space B\n  A-->B \n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 A\nLINK@21 -->\nNODE_ID@24 B\nEOF@27 \n$end@27 ",
  ),
  (
    "block\n        columns 3\n        blk1[\"Block 1\"]\n        blockArro->w<<-->\"&nbsp;&nbsp;&nbsp;\"]>(right)\n        block2[\"Block 2\"]",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nNODE_ID@32 blk1\nNODE_DSTART@36 [\nSTR@38 Block 1\nNODE_DEND@46 ]\nNODE_ID@56 blockArro\nINVALID@65 ",
  ),
  (
    "\"\"blok\n    id1{{\"Thik1sck\n    id1{\"This is the text in the box\"}\n",
    "NODE_ID@2 blok\nNODE_ID@11 id1\nNODE_DSTART@14 {{\nSTR@17 Thik1sck\n    id1{\nINVALID@35 ",
  ),
  (
    "block\n        columns 3\n      on top of ea  one[\"One Slot\"]\n        two[\"Two slots\"]:2\n columns\n2       ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nNODE_ID@30 on\nNODE_ID@33 top\nNODE_ID@37 of\nNODE_ID@40 ea\nNODE_ID@44 one\nNODE_DSTART@47 [\nSTR@49 One Slot\nNODE_DEND@58 ]\nNODE_ID@68 two\nNODE_DSTART@71 [\nSTR@73 Two slots\nNODE_DEND@83 ]\nSIZE@84 2\nCOLUMNS@88 2\nEOF@104 \n$end@104 ",
  ),
  (
    "block\n         id[\"A label\"]\n         \n id2", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@15 id\nNODE_DSTART@17 [\nSTR@19 A label\nNODE_DEND@27 ]\nNODE_ID@40 id2\nEOF@43 \n$end@43 ",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B fill:#f9F,stroke:#3,strok:03e-wide-width:4px\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@20 B\nNODE_DSTART@21 [\nSTR@23 A wide one in the middle\nNODE_DEND@48 ]\nstyle@52 style \nSTYLE_ENTITY_IDS@58 B\nSTYLE_DEFINITION_DATA@59  fill:#f9F,stroke:#3,strok:03e-wide-width:4px\nEOF@113 \n$end@113 ",
  ),
  (
    "block duntimonfig", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 duntimonfig\nEOF@17 \n$end@17 ",
  ),
  (
    "bloco--ks nck\n    ext to each other", "NODE_ID@0 bloco\nSTART_LINK@5 --\nINVALID@7 ",
  ),
  (
    "blocklocks\n  A space B\n  A->B\n", "NODE_ID@0 blocklocks\nNODE_ID@13 A\nSPACE_BLOCK@15 1\nNODE_ID@21 B\nNODE_ID@25 A\nINVALID@26 ",
  ),
  (
    "gives  block2[\"Block  no sclassDef lot to a si a simple block", "NODE_ID@0 gives\nNODE_ID@7 block2\nNODE_DSTART@13 [\nSTR@15 Block  no sclassDef lot to a si a simple block\nSTR@61 \n$end@61 ",
  ),
  (
    "block\n        columns 1\n        A\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n block\n  A fill#969;\n   co         columns 3\n            B\n            C\n            D\n        end",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 1\nNODE_ID@32 A\nNODE_ID@42 blockArrow\nBLOCK_ARROW_START@52 <[\nSTR@55 &nbsp;&nbsp;&nbsp;\nDIR@77 up\nDIR@79 down\nBLOCK_ARROW_END@85 ]>\nBLOCK_DIAGRAM_KEY@95 block\nBLOCK_DIAGRAM_KEY@102 block\nNODE_ID@110 A\nNODE_ID@112 fill#969;\nNODE_ID@125 co\nCOLUMNS@136 3\nNODE_ID@158 B\nNODE_ID@172 C\nNODE_ID@186 D\nend@196 end\nEOF@199 \n$end@199 ",
  ),
  (
    "block\n    id1([\"This. is the text in([\"x\"])the box\"])", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 ([\nSTR@16 This. is the text in([\nINVALID@39 ",
  ),
  (
    "block\n          block\n            aBlock[\"ABlock>\"x\"]\"]\n          -.->  block\n              bBlock[\"BBlock\"]\n            end\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@16 block\nNODE_ID@34 aBlock\nNODE_DSTART@40 [\nSTR@42 ABlock>\nINVALID@50 ",
  ),
  (
    "block\n          id[\"A la\"A label\"        ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id\nNODE_DSTART@18 [\nSTR@20 A la\nINVALID@25 ",
  ),
  (
    "block\n          columns auto\n            block1[\"Block 1\"]\n      ", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@16 -1\nNODE_ID@41 block1\nNODE_DSTART@47 [\nSTR@49 Block 1\nNODE_DEND@57 ]\nEOF@65 \n$end@65 ",
  ),
  (
    "cmpound blocks of compond blocks[(", "NODE_ID@0 cmpound\nNODE_ID@8 blocks\nNODE_ID@15 of\nNODE_ID@18 compond\nNODE_ID@26 blocks\nNODE_DSTART@32 [(\n$end@34 ",
  ),
  (
    "bloc]]k-beta\n          id\n     block:g    ", "NODE_ID@0 bloc]]k\nINVALID@7 ",
  ),
  (
    "should lclass og arning when block [[\"x\"]]width exceeds column width", "NODE_ID@0 should\nNODE_ID@7 lclass\nNODE_ID@14 og\nNODE_ID@17 arning\nNODE_ID@24 when\nBLOCK_DIAGRAM_KEY@29 block\nNODE_DSTART@35 [[\nSTR@38 x\nNODE_DEND@40 ]]\nNODE_ID@42 width\nNODE_ID@48 exceeds\nNODE_ID@56 column\nNODE_ID@63 width\nEOF@68 \n$end@68 ",
  ),
  (
    "blocks on block>\"x\"]-betatop of each other", "NODE_ID@0 blocks\nNODE_ID@7 on\nBLOCK_DIAGRAM_KEY@10 block\nNODE_DSTART@15 >\nSTR@17 x\nNODE_DEND@19 ]\nINVALID@20 ",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:<[\"x\"]>(right)4px;\n  class A blue\n  style B fill:#bb\n          id[\"<f,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 A\nLINK@21 -->\nNODE_ID@24 B\nclassDef@28 classDef \nCLASSDEF_ID@37 blue \nCLASSDEF_STYLEOPTS@42 fill:#6e6ce6,stroke:#333,stroke-width:<[\"x\"]>(right)4px;\nclass@101 class \nCLASSENTITY_IDS@107 A\nSTYLECLASS@108  blue\nstyle@116 style \nSTYLE_ENTITY_IDS@122 B\nSTYLE_DEFINITION_DATA@123  fill:#bb\nNODE_ID@143 id\nNODE_DSTART@145 [\nSTR@147 <f,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n\nSTR@212 \n$end@212 ",
  ),
  (
    "block\n  columns 3\n  Frontend blockArrowId6<[\" \"]>(right) Backend\n  space:2 down<[\" \"]>(down)\n  Disk left<[\" \"]>(left) Database[(\"Database\")]\n\n  classDef front fill:#696,stroke:#333;\n  classDef back fil)))l:#969,stroke:#333;\n  class Frontend front\n  class Backend,Database back\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 Frontend\nNODE_ID@29 blockArrowId6\nBLOCK_ARROW_START@42 <[\nSTR@45  \nDIR@50 right\nBLOCK_ARROW_END@55 ]>\nNODE_ID@57 Backend\nSPACE_BLOCK@67 2\nNODE_ID@75 down\nBLOCK_ARROW_START@79 <[\nSTR@82  \nDIR@87 down\nBLOCK_ARROW_END@91 ]>\nNODE_ID@95 Disk\nNODE_ID@100 left\nBLOCK_ARROW_START@104 <[\nSTR@107  \nDIR@112 left\nBLOCK_ARROW_END@116 ]>\nNODE_ID@118 Database\nNODE_DSTART@126 [(\nSTR@129 Database\nNODE_DEND@138 )]\nclassDef@144 classDef \nCLASSDEF_ID@153 front \nCLASSDEF_STYLEOPTS@159 fill:#696,stroke:#333;\nclassDef@184 classDef \nCLASSDEF_ID@193 back \nCLASSDEF_STYLEOPTS@198 fil)))l:#969,stroke:#333;\nclass@226 class \nCLASSENTITY_IDS@232 Frontend\nSTYLECLASS@240  front\nclass@249 class \nCLASSENTITY_IDS@255 Backend,Database\nSTYLECLASS@271  back\nEOF@277 \n$end@277 ",
  ),
  (
    "block\n        columnsaccDescr {} 3\n        block1[\"Block 1\"]\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(right)\n        block2[\"Block 2\"]",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@14 columnsaccDescr\nNODE_DSTART@30 {\nNODE_DEND@31 }\nNODE_ID@33 3\nNODE_ID@43 block1\nNODE_DSTART@49 [\nSTR@51 Block 1\nNODE_DEND@59 ]\nNODE_ID@69 blockArrow\nBLOCK_ARROW_START@79 <[\nSTR@82 &nbsp;&nbsp;&nbsp;\nDIR@104 right\nBLOCK_ARROW_END@109 ]>\nNODE_ID@119 block2\nNODE_DSTART@125 [\nSTR@127 Block 2\nNODE_DEND@135 ]\nEOF@136 \n$end@136 ",
  ),
  (
    "defaultblock\n${propck\n      }", "NODE_ID@0 defaultblock\nNODE_ID@13 $\nNODE_DSTART@14 {\nINVALID@15 ",
  ),
  (
    "  block\n        A\n    style A fill<[\"x\"]>( x )#969;\n", "BLOCK_DIAGRAM_KEY@2 block\nNODE_ID@16 A\nstyle@22 style \nSTYLE_ENTITY_IDS@28 A\nSTYLE_DEFINITION_DATA@29  fill<[\"x\"]>( x )#969;\nEOF@52 \n$end@52 ",
  ),
  (
    "block\nstroke:#333    id1{{ks \"This is the text in thbox\"}}\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 stroke\nINVALID@12 ",
  ),
  (
    "block\n    block\n      D\n    end\n    A[\"A: I am> a wide one\"]\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@10 block\nNODE_ID@22 D\nend@28 end\n    \nNODE_ID@36 A\nNODE_DSTART@37 [\nSTR@39 A: I am> a wide one\nNODE_DEND@59 ]\nEOF@61 \n$end@61 ",
  ),
  (
    "block\n  columns ents a(\"x\")p3\n  a[\"A label -. \"x\" .-> \"] b:2 c:2 d\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 columns\nNODE_ID@16 ents\nNODE_ID@21 a\nNODE_DSTART@22 (\nSTR@24 x\nNODE_DEND@26 )\nNODE_ID@27 p3\nNODE_ID@32 a\nNODE_DSTART@33 [\nSTR@35 A label -. \nINVALID@47 ",
  ),
  (
    "block\n          id1[\"first\"]  -- \"a label\" -->   id2[\"second\"]\n o     ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1\nNODE_DSTART@19 [\nSTR@21 first\nNODE_DEND@27 ]\nSTART_LINK@30 -- \nLINK_LABEL@33 \"\nSTR@34 a label\nLINK@42  -->   \nNODE_ID@49 id2\nNODE_DSTART@52 [\nSTR@54 second\nNODE_DEND@61 ]\nNODE_ID@64 o\nEOF@70 \n$end@70 ",
  ),
  (
    "block\n    id1((\"This is the texid1t in the circle\"))\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 ((\nSTR@16 This is the texid1t in the circle\nNODE_DEND@50 ))\nEOF@53 \n$end@53 ",
  ),
  (
    "block d-- runtimonfig", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 d\nSTART_LINK@7 -- \nINVALID@10 ",
  ),
  (
    "block\n  blockArrowId<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  bcrrowId5<[\"Label\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 blockArrowId\nBLOCK_ARROW_START@20 <[\nSTR@23 Label\nDIR@32 right\nBLOCK_ARROW_END@37 ]>\nNODE_ID@41 blockArrowId2\nBLOCK_ARROW_START@54 <[\nSTR@57 Label\nDIR@66 left\nBLOCK_ARROW_END@70 ]>\nNODE_ID@74 blockArrowId3\nBLOCK_ARROW_START@87 <[\nSTR@90 Label\nDIR@99 up\nBLOCK_ARROW_END@101 ]>\nNODE_ID@105 blockArrowId4\nBLOCK_ARROW_START@118 <[\nSTR@121 Label\nDIR@130 down\nBLOCK_ARROW_END@134 ]>\nNODE_ID@138 bcrrowId5\nBLOCK_ARROW_START@147 <[\nSTR@150 Label\nDIR@159 x\nBLOCK_ARROW_END@160 ]>\nNODE_ID@164 blockArrowId6\nBLOCK_ARROW_START@177 <[\nSTR@180 Label\nDIR@189 y\nBLOCK_ARROW_END@190 ]>\nNODE_ID@194 blockArrowId7\nBLOCK_ARROW_START@207 <[\nSTR@210 Label\nDIR@219 x\nDIR@220 down\nBLOCK_ARROW_END@226 ]>\nEOF@228 \n$end@228 ",
  ),
  (
    "compound bla bcks of of compound blocupks", "NODE_ID@0 compound\nNODE_ID@9 bla\nNODE_ID@13 bcks\nNODE_ID@18 of\nNODE_ID@21 of\nNODE_ID@24 compound\nNODE_ID@33 blocupks\nEOF@41 \n$end@41 ",
  ),
  (
    "block\n          columnblock\ns 2\n          block1[\"Blocko 1\"]\n          block2[\"Block 2\"]\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 columnblock\nNODE_ID@28 s\nNODE_ID@30 2\nNODE_ID@42 block1\nNODE_DSTART@48 [\nSTR@50 Blocko 1\nNODE_DEND@59 ]\nNODE_ID@71 block2\nNODE_DSTART@77 [\nSTR@79 Block 2\nNODE_DEND@87 ]\nEOF@97 \n$end@97 ",
  ),
  (
    "block-beta\n      blockirst\n        a\n      end\n      block:second\n        b\n      end\n      block:third\n        c\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nNODE_ID@17 blockirst\nNODE_ID@35 a\nend@43 end\n      \nid-block@53 block:\nNODE_ID@59 second\nNODE_ID@74 b\nend@82 end\n      \nid-block@92 block:\nNODE_ID@98 third\nNODE_ID@112 c\nend@120 end\n    \nEOF@128 \n$end@128 ",
  ),
  (
    "blis is th2", "NODE_ID@0 blis\nNODE_ID@5 is\nNODE_ID@8 th2\nEOF@11 \n$end@11 ",
  ),
  (
    "Cmpound block", "NODE_ID@0 Cmpound\nBLOCK_DIAGRAM_KEY@8 block\nEOF@13 \n$end@13 ",
  ),
  (
    "emptylock\n  columns 3\n  blocks", "NODE_ID@0 emptylock\nCOLUMNS@12 3\nNODE_ID@24 blocks\nEOF@30 \n$end@30 ",
  ),
  (
    "blocks mixed w   D\n    eith compound blo>\"x\"]cks", "NODE_ID@0 blocks\nNODE_ID@7 mixed\nNODE_ID@13 w\nNODE_ID@17 D\nNODE_ID@23 eith\nNODE_ID@28 compound\nNODE_ID@37 blo\nNODE_DSTART@40 >\nSTR@42 x\nNODE_DEND@44 ]\nNODE_ID@45 cks\nEOF@48 \n$end@48 ",
  ),
  (
    "block\n  id1[/\"Th\tis is the text in the box\"/]\n  id2[\\\"This is the text in the box\"\\]\n  A[/ ida\"Coristmas\"\\]\n  B[\\\"Go shopping\"/]\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nNODE_DSTART@11 [/\nSTR@14 Th\tis is the text in the box\nNODE_DEND@43 /]\nNODE_ID@48 id2\nNODE_DSTART@51 [\\\nSTR@54 This is the text in the box\nNODE_DEND@82 \\]\nNODE_ID@87 A\nNODE_DSTART@88 [/\nINVALID@90 ",
  ),
  (
    "block\n         columns 2\n          block1[\"BlclassDef a\nck 1\"]\n          block2[\"Block 2\"]\n          ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@15 2\nNODE_ID@35 block1\nNODE_DSTART@41 [\nSTR@43 BlclassDef a\nck 1\nNODE_DEND@61 ]\nNODE_ID@73 block2\nNODE_DSTART@79 [\nSTR@81 Block 2\nNODE_DEND@89 ]\nEOF@101 \n$end@101 ",
  ),
  (
    "block\nk\n    id1[[\"This is the text in the box\"]]\nspace", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 k\nNODE_ID@12 id1\nNODE_DSTART@15 [[\nSTR@18 This is the text in the box\nNODE_DEND@46 ]]\nSPACE_BLOCK@49 1\nEOF@54 \n$end@54 ",
  ),
  (
    "style statements [\\applied to a block", "style@0 style \nSTYLE_ENTITY_IDS@6 statements\nSTYLE_DEFINITION_DATA@16  [\\applied to a block\nEOF@37 \n$end@37 ",
  ),
  (
    "when pn parsing a block diagram graph i[|\"x\"] should handle > ", "NODE_ID@0 when\nNODE_ID@5 pn\nNODE_ID@8 parsing\nNODE_ID@16 a\nBLOCK_DIAGRAM_KEY@18 block\nNODE_ID@24 diagram\nNODE_ID@32 graph\nNODE_ID@38 i\nNODE_DSTART@39 [|\nSTR@42 x\nNODE_DEND@44 ]\nNODE_ID@46 should\nNODE_ID@53 handle\nNODE_DSTART@60 >\nINVALID@61 ",
  ),
  (
    "]>(rroaccDescr { d } blocks with multiple points", "NODE_ID@0 ]\nNODE_DSTART@1 >\nNODE_DEND@2 (\nNODE_ID@3 rroaccDescr\nNODE_DSTART@15 {\nINVALID@16 ",
  ),
  (
    "blocks with different widtblock-betahs", "NODE_ID@0 blocks\nNODE_ID@7 with\nNODE_ID@12 different\nNODE_ID@22 widtblock\nINVALID@31 ",
  ),
  (
    "style stements applied to a block", "style@0 style \nSTYLE_ENTITY_IDS@6 stements\nSTYLE_DEFINITION_DATA@14  applied to a block\nEOF@33 \n$end@33 ",
  ),
  (
    "gives no{{slot to a simple b[(\"x\")]ock", "NODE_ID@0 gives\nNODE_ID@6 no\nNODE_DSTART@8 {{\nINVALID@10 ",
  ),
  (
    "block\n  A sp B\n  A --> B\nace:2 B\n  A-- \"X\" -->", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nNODE_ID@10 sp\nNODE_ID@13 B\nNODE_ID@17 A\nLINK@19 --> \nNODE_ID@23 B\nNODE_ID@25 ace\nSIZE@28 2\nNODE_ID@31 B\nNODE_ID@35 A\nSTART_LINK@36 -- \nLINK_LABEL@39 \"\nSTR@40 X\nLINK@42  -->\nEOF@46 \n$end@46 ",
  ),
  (
    "Compounend\nd bloc", "NODE_ID@0 Compounend\nNODE_ID@11 d\nNODE_ID@13 bloc\nEOF@17 \n$end@17 ",
  ),
  (
    "  block-.->\n    A\n  class A,B a st[yle A fill#969;\n", "BLOCK_DIAGRAM_KEY@2 block\nLINK@7 -.->\n    \nNODE_ID@16 A\nclass@20 class \nCLASSENTITY_IDS@26 A,B\nSTYLECLASS@29  a st[yle A fill#969;\nEOF@51 \n$end@51 ",
  ),
  (
    "block\n        columns 3\n         space\n        middle[\"In the middle\"]\n        space\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nSPACE_BLOCK@33 1\nNODE_ID@47 middle\nNODE_DSTART@53 [\nSTR@55 In the middle\nNODE_DEND@69 ]\nSPACE_BLOCK@79 1\nEOF@93 \n$end@93 ",
  ),
  (
    "block-bclassDef a fill:#f96e-->ta\n          id\n      ", "BLOCK_DIAGRAM_KEY@0 block\nINVALID@5 ",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:4px;\n  class A blue\n  style B fill:#bbf,stroke:#ck1f66,stroke-width:2px,color:#fff,stroke-dasharraclassDef a\ny: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 A\nLINK@21 -->\nNODE_ID@24 B\nclassDef@28 classDef \nCLASSDEF_ID@37 blue \nCLASSDEF_STYLEOPTS@42 fill:#6e6ce6,stroke:#333,stroke-width:4px;\nclass@87 class \nCLASSENTITY_IDS@93 A\nSTYLECLASS@94  blue\nstyle@102 style \nSTYLE_ENTITY_IDS@108 B\nSTYLE_DEFINITION_DATA@109  fill:#bbf,stroke:#ck1f66,stroke-width:2px,color:#fff,stroke-dasharraclassDef a\nNODE_ID@189 y\nINVALID@190 ",
  ),
  (
    "gives no slot to a s  classDef blackimple block", "NODE_ID@0 gives\nNODE_ID@6 no\nNODE_ID@9 slot\nNODE_ID@14 to\nNODE_ID@17 a\nNODE_ID@19 s\nclassDef@22 classDef \nCLASSDEF_ID@31 blackimple \nCLASSDEF_STYLEOPTS@42 block\nEOF@47 \n$end@47 ",
  ),
  (
    "blo on top of each other", "NODE_ID@0 blo\nNODE_ID@4 on\nNODE_ID@7 top\nNODE_ID@11 of\nNODE_ID@14 each\nNODE_ID@19 other\nEOF@24 \n$end@24 ",
  ),
  (
    "block\n  blockArrowId<[\"Label\"\"`>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"Label\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 blockArrowId\nBLOCK_ARROW_START@20 <[\nSTR@23 Label\nMD_STR@31 >(right)\n  blockArrowId2<[\nINVALID@57 ",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6ce6,stroke:#333,stroke-width:4px;\n  class  columns 3\n   A blue\n  style B fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 A\nLINK@21 -->\nNODE_ID@24 B\nclassDef@28 classDef \nCLASSDEF_ID@37 blue \nCLASSDEF_STYLEOPTS@42 fill:#6e6ce6,stroke:#333,stroke-width:4px;\nclass@87 class  \nCLASSENTITY_IDS@94 columns\nSTYLECLASS@101  3\nNODE_ID@107 A\nNODE_ID@109 blue\nstyle@116 style \nSTYLE_ENTITY_IDS@122 B\nSTYLE_DEFINITION_DATA@123  fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\nEOF@196 \n$end@196 ",
  ),
  (
    "blockock-beinterpolateta\n      a\n      \n      block:group\n        c\n      end\n    ",
    "NODE_ID@0 blockock\nINVALID@8 ",
  ),
  (
    "block\n   i-.d1(\"This is the text in the box\")\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@9 i\nSTART_LINK@10 -.\nINVALID@12 ",
  ),
  (
    "block\n  block\n    c  olumns\n    a[\"A label\"] b c d\n  end\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@8 block\nNODE_ID@18 c\nNODE_ID@21 olumns\nNODE_ID@32 a\nNODE_DSTART@33 [\nSTR@35 A label\nNODE_DEND@43 ]\nNODE_ID@45 b\nNODE_ID@47 c\nNODE_ID@49 d\nend@53 end\n\nEOF@57 \n$end@57 ",
  ),
  (
    "block\n          block\n               aBlock[\"AB>\"\u{e9}x\"]lock\"]\n            bBlock[\"BBlock\"]\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@16 block\nNODE_ID@37 aBlock\nNODE_DSTART@43 [\nSTR@45 AB>\nINVALID@49 ",
  ),
  ("blo-->ck2", "NODE_ID@0 blo\nLINK@3 -->\nNODE_ID@6 ck2\nEOF@9 \n$end@9 "),
  (
    "bl end ock\n        columns 3\n      [\\\"x\"/]  space\n        middle[\"In the mle\"]\n        space\n        ",
    "NODE_ID@0 bl\nend@3 end \nNODE_ID@7 ock\nCOLUMNS@19 3\nNODE_DSTART@35 [\\\nSTR@38 x\nNODE_DEND@40 /]\nSPACE_BLOCK@44 1\nNODE_ID@58 middle\nNODE_DSTART@64 [\nSTR@66 In the mle\nNODE_DEND@77 ]\nSPACE_BLOCK@87 1\nEOF@101 \n$end@101 ",
  ),
  (
    "block ,olour ((\"x\"))slleftots", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 ,olour\nNODE_DSTART@13 ((\nSTR@16 x\nNODE_DEND@18 ))\nNODE_ID@20 slleftots\nEOF@29 \n$end@29 ",
  ),
  (
    "e]mpty interpolateblocks==", "NODE_ID@0 e]mpty\nNODE_ID@7 interpolateblocks\nSTART_LINK@24 ==\n$end@26 ",
  ),
  (
    "block\n        coluclassDef mns 3\n        space\n   x     middle[\"In tcolumns autohe middle\"]\n        space\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@14 coluclassDef\nNODE_ID@27 mns\nNODE_ID@31 3\nSPACE_BLOCK@41 1\nNODE_ID@50 x\nNODE_ID@56 middle\nNODE_DSTART@62 [\nSTR@64 In tcolumns autohe middle\nNODE_DEND@90 ]\nSPACE_BLOCK@100 1\nEOF@114 \n$end@114 ",
  ),
  (
    "block\n  co:03lumns 3\n  a b c d\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 co\nSIZE@10 03\nNODE_ID@13 lumns\nNODE_ID@19 3\nNODE_ID@23 a\nNODE_ID@25 b\nNODE_ID@27 c\nNODE_ID@29 d\nEOF@31 \n$end@31 ",
  ),
  (
    "block\n        columns 3\n        space\n        middle[\"In the middle\".]\n        space\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nSPACE_BLOCK@32 1\nNODE_ID@46 middle\nNODE_DSTART@52 [\nSTR@54 In the middle\nINVALID@68 ",
  ),
  (
    "blo[\\\"x\"\\]ck\n  block\n    columnblock\n         s 1\n    a[\"A label\"] b c d\n  ene\")]\nd\n",
    "NODE_ID@0 blo\nNODE_DSTART@3 [\\\nSTR@6 x\nNODE_DEND@8 \\]\nNODE_ID@10 ck\nBLOCK_DIAGRAM_KEY@15 block\nNODE_ID@25 columnblock\nNODE_ID@46 s\nNODE_ID@48 1\nNODE_ID@54 a\nNODE_DSTART@55 [\nSTR@57 A label\nNODE_DEND@65 ]\nNODE_ID@67 b\nNODE_ID@69 c\nNODE_ID@71 d\nNODE_ID@75 ene\"\nNODE_DSTART@79 )\nNODE_DEND@80 ]\nNODE_ID@82 d\nEOF@84 \n$end@84 ",
  ),
  (
    "bl Prock\n  A \n  A s A space B\n  A-->B\n", "NODE_ID@0 bl\nNODE_ID@3 Prock\nNODE_ID@11 A\nNODE_ID@16 A\nNODE_ID@18 s\nNODE_ID@20 A\nSPACE_BLOCK@22 1\nNODE_ID@28 B\nNODE_ID@32 A\nLINK@33 -->\nNODE_ID@36 B\nEOF@38 \n$end@38 ",
  ),
  (
    "compo d blocks 2", "NODE_ID@0 compo\nNODE_ID@6 d\nNODE_ID@8 blocks\nNODE_ID@15 2\nEOF@16 \n$end@16 ",
  ),
  (
    "should log a warning when block width exceeds column w->idth", "NODE_ID@0 should\nNODE_ID@7 log\nNODE_ID@11 a\nNODE_ID@13 warning\nNODE_ID@21 when\nBLOCK_DIAGRAM_KEY@26 block\nNODE_ID@32 width\nNODE_ID@38 exceeds\nNODE_ID@46 column\nNODE_ID@53 w\nINVALID@54 ",
  ),
  (
    "block\n          id1 id1\n          id2\n      ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1\nNODE_ID@20 id1\nNODE_ID@34 id2\nEOF@44 \n$end@44 ",
  ),
  (
    "block\n        colummns 3\n        space\n        middle[\"In class e middle\"]\n        space\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@14 colummns\nNODE_ID@23 3\nSPACE_BLOCK@33 1\nNODE_ID@47 middle\nNODE_DSTART@53 [\nSTR@55 In class e middle\nNODE_DEND@73 ]\nSPACE_BLOCK@83 1\nEOF@97 \n$end@97 ",
  ),
  (
    "block\n  blockArrowId<[\"Label\"]>(right)\n  blockArrowId2<[\"Label\"]>(left)\n  blockArrowId3<[\"Label\"]>(up)\n  blockArrowId4<[\"Label\"]>(down)\n  blockArrowId5<[\"Label\"]>(x)\n  blockArrowId6<[\"Label\"]>(y)\n  b\n  blockArrowId7<[\"Label\"]>(x, down)\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 blockArrowId\nBLOCK_ARROW_START@20 <[\nSTR@23 Label\nDIR@32 right\nBLOCK_ARROW_END@37 ]>\nNODE_ID@41 blockArrowId2\nBLOCK_ARROW_START@54 <[\nSTR@57 Label\nDIR@66 left\nBLOCK_ARROW_END@70 ]>\nNODE_ID@74 blockArrowId3\nBLOCK_ARROW_START@87 <[\nSTR@90 Label\nDIR@99 up\nBLOCK_ARROW_END@101 ]>\nNODE_ID@105 blockArrowId4\nBLOCK_ARROW_START@118 <[\nSTR@121 Label\nDIR@130 down\nBLOCK_ARROW_END@134 ]>\nNODE_ID@138 blockArrowId5\nBLOCK_ARROW_START@151 <[\nSTR@154 Label\nDIR@163 x\nBLOCK_ARROW_END@164 ]>\nNODE_ID@168 blockArrowId6\nBLOCK_ARROW_START@181 <[\nSTR@184 Label\nDIR@193 y\nBLOCK_ARROW_END@194 ]>\nNODE_ID@198 b\nNODE_ID@202 blockArrowId7\nBLOCK_ARROW_START@215 <[\nSTR@218 Label\nDIR@227 x\nDIR@228 down\nBLOCK_ARROW_END@234 ]>\nEOF@236 \n$end@236 ",
  ),
  (
    "block\n  id1[/\"This is the text in the box\"/]\n  id2[\\\"This is the accTitle: ttext in the box\"\\]\n  A[/\"Christmas\"\\]class A, B a\n  B[\\\"Go shopping\"/]\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nNODE_DSTART@11 [/\nSTR@14 This is the text in the box\nNODE_DEND@42 /]\nNODE_ID@47 id2\nNODE_DSTART@50 [\\\nSTR@53 This is the accTitle: ttext in the box\nNODE_DEND@92 \\]\nNODE_ID@97 A\nNODE_DSTART@98 [/\nSTR@101 Christmas\nNODE_DEND@111 \\]\nclass@113 class \nCLASSENTITY_IDS@119 A, B\nSTYLECLASS@123  a\nNODE_ID@128 B\nNODE_DSTART@129 [\\\nSTR@132 Go shopping\nNODE_DEND@144 /]\nEOF@147 \n$end@147 ",
  ),
  (
    "block\n  A space B\n  Arow-->B\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 Arow\nLINK@24 -->\nNODE_ID@27 B\nEOF@29 \n$end@29 ",
  ),
  (
    "bloc(((\"x[(\"x\")]\")))1", "NODE_ID@0 bloc\nNODE_DSTART@4 (((\nSTR@8 x[(\nINVALID@12 ",
  ),
  (
    "block\n       [\\   columns 2\n        block1[\"Block 1\"]\n      ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_DSTART@13 [\\\nINVALID@15 ",
  ),
  (
    "shoulog a warning when block width exceeds comn widthlumn width", "NODE_ID@0 shoulog\nNODE_ID@8 a\nNODE_ID@10 warning\nNODE_ID@18 when\nBLOCK_DIAGRAM_KEY@23 block\nNODE_ID@29 width\nNODE_ID@35 exceeds\nNODE_ID@43 comn\nNODE_ID@48 widthlumn\nNODE_ID@58 width\nEOF@63 \n$end@63 ",
  ),
  (
    "  block\n    A\n    style A  ill#<969;\n", "BLOCK_DIAGRAM_KEY@2 block\nNODE_ID@12 A\nstyle@18 style \nSTYLE_ENTITY_IDS@24 A\nSTYLE_DEFINITION_DATA@25   ill#<969;\nEOF@37 \n$end@37 ",
  ),
  (
    "block\n          blo id1(\"This is the text in the box\")\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 blo\nNODE_ID@20 id1\nNODE_DSTART@23 (\nSTR@25 This is the text in the box\nNODE_DEND@53 )\nEOF@55 \n$end@55 ",
  ),
  (
    "shouinterpolateld log a warning when block width exceblock-betaeds column w<[\"x\"]>(right)idth",
    "NODE_ID@0 shouinterpolateld\nNODE_ID@18 log\nNODE_ID@22 a\nNODE_ID@24 warning\nNODE_ID@32 when\nBLOCK_DIAGRAM_KEY@37 block\nNODE_ID@43 width\nNODE_ID@49 exceblock\nINVALID@58 ",
  ),
  (
    "block\n          block\n            aBlock[\"ABlock\"]\n            block\n              bBlock[\"BBlock\"]\n    [/\"x\"\\]        end\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@16 block\nNODE_ID@34 aBlock\nNODE_DSTART@40 [\nSTR@42 ABlock\nNODE_DEND@49 ]\nBLOCK_DIAGRAM_KEY@63 block\nNODE_ID@83 bBlock\nNODE_DSTART@89 [\nSTR@91 BBlock\nNODE_DEND@98 ]\nNODE_DSTART@104 [/\nSTR@107 x\nNODE_DEND@109 \\]\nend@119 end\n          \nend@133 end\n        \nEOF@145 \n$end@145 ",
  ),
  (
    "compou<[nd blocwith title", "NODE_ID@0 compou\nBLOCK_ARROW_START@6 <[\nINVALID@8 ",
  ),
  (
    "block\n          block\n            aBlock[\"ABlock\"]\n            block\n              bBblock:ock[\"BBlock\"]\n            end\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@16 block\nNODE_ID@34 aBlock\nNODE_DSTART@40 [\nSTR@42 ABlock\nNODE_DEND@49 ]\nBLOCK_DIAGRAM_KEY@63 block\nNODE_ID@83 bBblock\nINVALID@90 ",
  ),
  (
    "block\n   ks id1([\"This is the text in the box\"])\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@9 ks\nNODE_ID@12 id1\nNODE_DSTART@15 ([\nSTR@18 This is the text in the box\nNODE_DEND@46 ])\nEOF@49 \n$end@49 ",
  ),
  (
    "block db edge styleses", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 db\nNODE_ID@9 edge\nNODE_ID@14 styleses\nEOF@22 \n$end@22 ",
  ),
  (
    "block\n          id[\"A label\"]       is is the id2", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id\nNODE_DSTART@18 [\nSTR@20 A label\nNODE_DEND@28 ]\nNODE_ID@36 is\nNODE_ID@39 is\nNODE_ID@42 the\nNODE_ID@46 id2\nEOF@49 \n$end@49 ",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#-..-6e6ce6,stroke:#333,stroke-width:4px;\n  class A blue\n  style B fill:#bbf,stroke:\"`#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 A\nLINK@21 -->\nNODE_ID@24 B\nclassDef@28 classDef \nCLASSDEF_ID@37 blue \nCLASSDEF_STYLEOPTS@42 fill:#-..-6e6ce6,stroke:#333,stroke-width:4px;\nclass@91 class \nCLASSENTITY_IDS@97 A\nSTYLECLASS@98  blue\nstyle@106 style \nSTYLE_ENTITY_IDS@112 B\nSTYLE_DEFINITION_DATA@113  fill:#bbf,stroke:\"`#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\nEOF@188 \n$end@188 ",
  ),
  (
    "block-beta\n          idoke-width:4p\n      ", "BLOCK_DIAGRAM_KEY@0 block-beta\nNODE_ID@21 idoke\nINVALID@26 ",
  ),
  (
    "classDef a\nblock\n  A space B\n  A --> B\n", "classDef@0 classDef \nCLASSDEF_ID@9 a\n\nCLASSDEF_STYLEOPTS@11 block\nNODE_ID@19 A\nSPACE_BLOCK@21 1\nNODE_ID@27 B\nNODE_ID@31 A\nLINK@33 --> \nNODE_ID@37 B\nEOF@39 \n$end@39 ",
  ),
  (
    "block-beta\n       A\n block:outer\n        b1lock:inner\n          a\n        end\n      end\n      block:sibling\n        b\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nNODE_ID@18 A\nid-block@21 block:\nNODE_ID@27 outer\nNODE_ID@41 b1lock\nINVALID@47 ",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B fill:#f9F,stroke:(\"x\")#333,stroke-width:4px\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@20 B\nNODE_DSTART@21 [\nSTR@23 A wide one in the middle\nNODE_DEND@48 ]\nstyle@52 style \nSTYLE_ENTITY_IDS@58 B\nSTYLE_DEFINITION_DATA@59  fill:#f9F,stroke:(\"x\")#333,stroke-width:4px\nEOF@112 \n$end@112 ",
  ),
  (
    "block-beta\n      block:a1\n        block:a2\n          x\n        end\n      end\n      block:b1\n        block:b2\n       y\n        end\n      end\n    ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nid-block@17 block:\nNODE_ID@23 a1\nid-block@34 block:\nNODE_ID@40 a2\nNODE_ID@53 x\nend@63 end\n      \nend@73 end\n      \nid-block@83 block:\nNODE_ID@89 b1\nid-block@100 block:\nNODE_ID@106 b2\nNODE_ID@116 y\nend@126 end\n      \nend@136 end\n    \nEOF@144 \n$end@144 ",
  ),
  (
    "accD\r\nescr {}l(-ck1", "NODE_ID@0 accD\nNODE_ID@6 escr\nNODE_DSTART@11 {\nNODE_DEND@12 }\nNODE_ID@13 l\nNODE_DSTART@14 (-\nINVALID@16 ",
  ),
  (
    "block\n  A\n  style A le A fill:#969,stroke:#k\n    id1[(\"Databa333;\n\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nstyle@12 style \nSTYLE_ENTITY_IDS@18 A\nSTYLE_DEFINITION_DATA@19  le A fill:#969,stroke:#k\nNODE_ID@49 id1\nNODE_DSTART@52 [(\nSTR@55 Databa333;\n\n\nSTR@67 \n$end@67 ",
  ),
  (
    "classDef statements a[pplied to a block", "classDef@0 classDef \nCLASSDEF_ID@9 statements \nCLASSDEF_STYLEOPTS@20 a[pplied to a block\nEOF@39 \n$end@39 ",
  ),
  (
    "block\n          id[\"A label\"]`          id2", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id\nNODE_DSTART@18 [\nSTR@20 A label\nNODE_DEND@28 ]\nNODE_ID@29 `\nNODE_ID@40 id2\nEOF@43 \n$end@43 ",
  ),
  (
    "compound bl-ocks with [/\"x\"\\]title", "NODE_ID@0 compound\nNODE_ID@9 bl\nINVALID@11 ",
  ),
  (
    "blocks with different ths", "NODE_ID@0 blocks\nNODE_ID@7 with\nNODE_ID@12 different\nNODE_ID@22 ths\nEOF@25 \n$end@25 ",
  ),
  (
    "sho>ld ad block.padding from config at call time, not at import time", "NODE_ID@0 sho\nNODE_DSTART@3 >\nINVALID@4 ",
  ),
  (
    "compoublock\nnd blocks with .->itle", "NODE_ID@0 compoublock\nNODE_ID@12 nd\nNODE_ID@15 blocks\nNODE_ID@22 with\nNODE_ID@27 .\nINVALID@28 ",
  ),
  (
    "blo-beta\n      a\n      b\n      blo`\"k:group\n        c\n      end\n    ",
    "NODE_ID@0 blo\nINVALID@3 ",
  ),
  (
    "when parsing a bclassDe fill:#f96ock diagram graph it should handle > ", "NODE_ID@0 when\nNODE_ID@5 parsing\nNODE_ID@13 a\nNODE_ID@15 bclassDe\nNODE_ID@24 fill\nINVALID@28 ",
  ),
  (
    "block\n  columns 3\n  a spach compound blockse b\n  c   d   e\n", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 a\nNODE_ID@22 spach\nNODE_ID@28 compound\nNODE_ID@37 blockse\nNODE_ID@45 b\nNODE_ID@49 c\nNODE_ID@53 d\nNODE_ID@57 e\nEOF@59 \n$end@59 ",
  ),
  (
    "block\n    iclass A,B ad1((\"This is the text in the circle\"le\"))\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 iclass\nNODE_ID@17 A,B\nNODE_ID@21 ad1\nNODE_DSTART@24 ((\nSTR@27 This is the text in the circle\nINVALID@58 ",
  ),
  (
    "should read block.pading from config at call time, not at import time", "NODE_ID@0 should\nNODE_ID@7 read\nBLOCK_DIAGRAM_KEY@12 block\nNODE_ID@17 .pading\nNODE_ID@25 from\nNODE_ID@30 config\nNODE_ID@37 at\nNODE_ID@40 call\nNODE_ID@45 time,\nNODE_ID@51 not\nNODE_ID@55 at\nNODE_ID@58 import\nNODE_ID@65 time\nEOF@69 \n$end@69 ",
  ),
  (
    "block db edge stylupes", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 db\nNODE_ID@9 edge\nNODE_ID@14 stylupes\nEOF@22 \n$end@22 ",
  ),
  (
    "block\ncolumns 1\n           B[\"A widede one in the middle\"]\n  style B fill:#f9F,stroke:#333,stroke-width:4px\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@27 B\nNODE_DSTART@28 [\nSTR@30 A widede one in the middle\nNODE_DEND@57 ]\nstyle@61 style \nSTYLE_ENTITY_IDS@67 B\nSTYLE_DEFINITION_DATA@68  fill:#f9F,stroke:#333,stroke-width:4px\nEOF@116 \n$end@116 ",
  ),
  (
    "block\n          id1\n        id2\n          id3\n <--     ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 id1\nNODE_ID@28 id2\nNODE_ID@42 id3\nSTART_LINK@47 <--     \n$end@55 ",
  ),
  (
    "block\n  c\n  ccolumns 3\n  a[\"A label\"] b:2 c:2 d\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 c\nNODE_ID@12 ccolumns\nNODE_ID@21 3\nNODE_ID@25 a\nNODE_DSTART@26 [\nSTR@28 A label\nNODE_DEND@36 ]\nNODE_ID@38 b\nSIZE@39 2\nNODE_ID@42 c\nSIZE@43 2\nNODE_ID@46 d\nEOF@48 \n$end@48 ",
  ),
  ("Cox--mp\"\"oun d block", "NODE_ID@0 Cox\nSTART_LINK@3 --\nINVALID@5 "),
  (
    "blocks n[|\"x\"]ext to e to each other", "NODE_ID@0 blocks\nNODE_ID@7 n\nNODE_DSTART@8 [|\nSTR@11 x\nNODE_DEND@13 ]\nNODE_ID@14 ext\nNODE_ID@18 to\nNODE_ID@21 e\nNODE_ID@23 to\nNODE_ID@26 each\nNODE_ID@31 other\nEOF@36 \n$end@36 ",
  ),
  (
    "bloright colour [[slots", "NODE_ID@0 bloright\nNODE_ID@9 colour\nNODE_DSTART@16 [[\nINVALID@18 ",
  ),
  (
    "block\n    id1((\"This is the tex  c   d   e\nin thin the circle\"))\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 ((\nSTR@16 This is the tex  c   d   e\nin thin the circle\nNODE_DEND@62 ))\nEOF@65 \n$end@65 ",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n  C\n  end\n  spa[(ce\n  D\n  ID --> D\n  C --> D\n  style B fill:#969,stroke:#333,stroke-width:4px\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@18 db\nNODE_DSTART@20 ((\nSTR@23 DB\nNODE_DEND@26 ))\nNODE_ID@31 blockArrowId6\nBLOCK_ARROW_START@44 <[\nSTR@47 &nbsp;&nbsp;&nbsp;\nDIR@69 down\nBLOCK_ARROW_END@73 ]>\nid-block@77 block:\nNODE_ID@83 ID\nNODE_ID@90 A\nNODE_ID@96 B\nNODE_DSTART@97 [\nSTR@99 A wide one in the middle\nNODE_DEND@124 ]\nNODE_ID@128 C\nend@132 end\n  \nNODE_ID@138 spa\nNODE_DSTART@141 [(\nINVALID@143 ",
  ),
  (
    "comnd blocks of compound blockks", "NODE_ID@0 comnd\nNODE_ID@6 blocks\nNODE_ID@13 of\nNODE_ID@16 compound\nNODE_ID@25 blockks\nEOF@32 \n$end@32 ",
  ),
  (
    "block\n         <-- block1[\"Block 1\"]\n      ", "BLOCK_DIAGRAM_KEY@0 block\nSTART_LINK@15 <-- \nINVALID@19 ",
  ),
  (
    "blocks mixed h compound blocks", "NODE_ID@0 blocks\nNODE_ID@7 mixed\nNODE_ID@13 h\nNODE_ID@15 compound\nNODE_ID@24 blocks\nEOF@30 \n$end@30 ",
  ),
  (
    "block\n  id1>\"Thiis the text in the box\"]\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nNODE_DSTART@11 >\nSTR@13 Thiis the text in the box\nNODE_DEND@39 ]\nEOF@41 \n$end@41 ",
  ),
  (
    "block\n  columns 3\n  a:3\n  block:group1:2\n    columns 2\n    h i j   end\n  g\n  block:group2:3\n    %% columns auto (default)\n    l m n o p q r\n  end\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 a\nSIZE@21 3\nid-block@26 block:\nNODE_ID@32 group1\nSIZE@38 2\nCOLUMNS@45 2\nNODE_ID@59 h\nNODE_ID@61 i\nNODE_ID@63 j\nend@67 end\n  \nNODE_ID@73 g\nid-block@77 block:\nNODE_ID@83 group2\nSIZE@89 3\nNODE_ID@96 %%\nCOLUMNS@99 -1\nNODE_DSTART@112 (\nINVALID@113 ",
  ),
  (
    "blocks on top of ed blocks with titleacothe", "NODE_ID@0 blocks\nNODE_ID@7 on\nNODE_ID@10 top\nNODE_ID@14 of\nNODE_ID@17 ed\nNODE_ID@20 blocks\nNODE_ID@27 with\nNODE_ID@32 titleacothe\nEOF@43 \n$end@43 ",
  ),
  (
    "block\n         id1[\"first\"]  -->   id2[\"second\"]\n      ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@15 id1\nNODE_DSTART@18 [\nSTR@20 first\nNODE_DEND@26 ]\nLINK@29 -->   \nNODE_ID@35 id2\nNODE_DSTART@38 [\nSTR@40 second\nNODE_DEND@47 ]\nEOF@55 \n$end@55 ",
  ),
  ("block_[\\arrow", "NODE_ID@0 block_\nNODE_DSTART@6 [\\\nINVALID@8 "),
  (
    "Arrow blocx\"]]\nks", "NODE_ID@0 Arrow\nNODE_ID@6 blocx\"]]\nNODE_ID@15 ks\nEOF@17 \n$end@17 ",
  ),
  (
    "block\n          columns auo\n        classDef a fill:#f96  block1[\"Block 1\"]\n      ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@16 columns\nNODE_ID@24 auo\nclassDef@36 classDef \nCLASSDEF_ID@45 a \nCLASSDEF_STYLEOPTS@47 fill:#f96  block1[\"Block 1\"]\nEOF@82 \n$end@82 ",
  ),
  (
    "block\n    id1[[\"This is the text in the box\"]]\n[/", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 [[\nSTR@16 This is the text in the box\nNODE_DEND@44 ]]\nNODE_DSTART@47 [/\n$end@49 ",
  ),
  (
    "block-beta\n  column)]s 1\n  A:1\n  B:2\n 3\n  D:4\n  E:3\n  mpounF:2\n  G:1",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nNODE_ID@13 column\nNODE_DSTART@19 )\nNODE_DEND@20 ]\nNODE_ID@21 s\nNODE_ID@23 1\nNODE_ID@27 A\nSIZE@28 1\nNODE_ID@33 B\nSIZE@34 2\nNODE_ID@38 3\nNODE_ID@42 D\nSIZE@43 4\nNODE_ID@48 E\nSIZE@49 3\nNODE_ID@54 mpounF\nSIZE@60 2\nNODE_ID@65 G\nSIZE@66 1\nEOF@68 \n$end@68 ",
  ),
  (
    "block\n  id1 space id2\n  id\"Start\")-->id2(\"Stop\")\n  style id1 fill:#636,stroke:33,stroke-width:4px\n  style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nSPACE_BLOCK@12 1\nNODE_ID@18 id2\nNODE_ID@24 id\"Start\"\nNODE_DSTART@33 )\nINVALID@34 ",
  ),
  (
    "should log a warning when block width exceeds column (((width", "NODE_ID@0 should\nNODE_ID@7 log\nNODE_ID@11 a\nNODE_ID@13 warning\nNODE_ID@21 when\nBLOCK_DIAGRAM_KEY@26 block\nNODE_ID@32 width\nNODE_ID@38 exceeds\nNODE_ID@46 column\nNODE_DSTART@53 (((\nINVALID@56 ",
  ),
  ("bloclockAow", "NODE_ID@0 bloclockAow\nEOF@11 \n$end@11 "),
  (
    "bblock:lock\n          id id1[\"first\"]  -- \"a classDef a fill:#f96label\" -->   id2[\"second\"]\n      ",
    "NODE_ID@0 bblock\nINVALID@6 ",
  ),
  (
    "blok\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#969,stroke:#333,stroke-width:-)4px\n",
    "NODE_ID@0 blok\nCOLUMNS@5 1\nNODE_ID@17 db\nNODE_DSTART@19 ((\nSTR@22 DB\nNODE_DEND@25 ))\nNODE_ID@30 blockArrowId6\nBLOCK_ARROW_START@43 <[\nSTR@46 &nbsp;&nbsp;&nbsp;\nDIR@68 down\nBLOCK_ARROW_END@72 ]>\nid-block@76 block:\nNODE_ID@82 ID\nNODE_ID@89 A\nNODE_ID@95 B\nNODE_DSTART@96 [\nSTR@98 A wide one in the middle\nNODE_DEND@123 ]\nNODE_ID@129 C\nend@133 end\n  \nSPACE_BLOCK@139 1\nNODE_ID@147 D\nNODE_ID@151 ID\nLINK@154 --> \nNODE_ID@158 D\nNODE_ID@162 C\nLINK@164 --> \nNODE_ID@168 D\nstyle@172 style \nSTYLE_ENTITY_IDS@178 B\nSTYLE_DEFINITION_DATA@179  fill:#969,stroke:#333,stroke-width:-)4px\nEOF@221 \n$end@221 ",
  ),
  (
    "style statements appl to a b a blockdefault", "style@0 style \nSTYLE_ENTITY_IDS@6 statements\nSTYLE_DEFINITION_DATA@16  appl to a b a blockdefault\nEOF@43 \n$end@43 ",
  ),
  (
    "bstyle A fill:#f96,stroke:#333lock\n          block\n            aBlock[\"ABlock\"]\n            block\n              bBlock[\"BBlock\"]\n                end\n          end\n        ",
    "NODE_ID@0 bstyle\nNODE_ID@7 A\nNODE_ID@9 fill\nINVALID@13 ",
  ),
  (
    "block\n        .->  id1\n   \n          id2\n B    ", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@14 .\nINVALID@15 ",
  ),
  (
    "block\n          columns 1\n          block1[\"Block a b1\"]\n          block2[\"Blockcolumns 2\"]\n         ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@16 1\nNODE_ID@36 block1\nNODE_DSTART@42 [\nSTR@44 Block a b1\nNODE_DEND@55 ]\nNODE_ID@67 block2\nNODE_DSTART@73 [\nSTR@75 Blockcolumns 2\nNODE_DEND@90 ]\nEOF@101 \n$end@101 ",
  ),
  (
    "classDef statements applied to a b statementslock", "classDef@0 classDef \nCLASSDEF_ID@9 statements \nCLASSDEF_STYLEOPTS@20 applied to a b statementslock\nEOF@49 \n$end@49 ",
  ),
  (
    "block\n        columns 3\n        block1[\"Block 1\"]\n          blockArrow<[\"&nbsp;&nbsp;&nbsp;\"] -. \"x\" .-classDef  (right)\n        block2[\"Block 2\"]",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nNODE_ID@32 block1\nNODE_DSTART@38 [\nSTR@40 Block 1\nNODE_DEND@48 ]\nNODE_ID@60 blockArrow\nBLOCK_ARROW_START@70 <[\nSTR@73 &nbsp;&nbsp;&nbsp;\nINVALID@92 ",
  ),
  (
    "  block\n    A\n    style A<==> fill#969;\n", "BLOCK_DIAGRAM_KEY@2 block\nNODE_ID@12 A\nstyle@18 style \nSTYLE_ENTITY_IDS@24 A\nSTYLE_DEFINITION_DATA@25 <==> fill#969;\nEOF@40 \n$end@40 ",
  ),
  (
    "block\n  columns 3\n  a:3\n  block:group1:2\n    columns 2\n    h i j k\n  end\n  gblock:group2:3\n    %% columns auto (default((()\n    l\" m n o p q r\n  end\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 a\nSIZE@21 3\nid-block@26 block:\nNODE_ID@32 group1\nSIZE@38 2\nCOLUMNS@45 2\nNODE_ID@59 h\nNODE_ID@61 i\nNODE_ID@63 j\nNODE_ID@65 k\nend@69 end\n  \nNODE_ID@75 gblock\nINVALID@81 ",
  ),
  (
    "compound bcks 2---", "NODE_ID@0 compound\nNODE_ID@9 bcks\nNODE_ID@14 2\nLINK@15 ---\nEOF@18 \n$end@18 ",
  ),
  (
    "block\n    id1((\"This is the text in the circle\"))\"))\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 ((\nSTR@16 This is the text in the circle\nNODE_DEND@47 ))\nSTR@50 ))\n\nSTR@53 \n$end@53 ",
  ),
  (
    "[[\"x\"]]lock-beta\n      ao\n  \n      b\n      block:group\n        c\n      end\n   ",
    "NODE_DSTART@0 [[\nSTR@3 x\nNODE_DEND@5 ]]\nNODE_ID@7 lock\nINVALID@11 ",
  ),
  (
    "compound blocclassDef ks with t-..-tle", "NODE_ID@0 compound\nNODE_ID@9 blocclassDef\nNODE_ID@22 ks\nNODE_ID@25 with\nNODE_ID@30 t\nLINK@31 -..-\nNODE_ID@35 tle\nEOF@38 \n$end@38 ",
  ),
  (
    "block\n  id1 space id2\n  id1(\"Start\")-->id2(\"Stop\")\n  stylid1 fill:#636,stroke:#333,stroke-width:4px\n  style id2 fill:#bbf,stroke:#f66,strtroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 id1\nSPACE_BLOCK@12 1\nNODE_ID@18 id2\nNODE_ID@24 id1\nNODE_DSTART@27 (\nSTR@29 Start\nNODE_DEND@35 )\nLINK@36 -->\nNODE_ID@39 id2\nNODE_DSTART@42 (\nSTR@44 Stop\nNODE_DEND@49 )\nNODE_ID@53 stylid1\nNODE_ID@61 fill\nINVALID@65 ",
  ),
  (
    "block\n  A space B\n  A-->B\n  classDef blue fill:#6e6>\"x\"]ce6,stroke:#333,stroke-width:4px;\n  class A blue\n  style,  B fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@8 A\nSPACE_BLOCK@10 1\nNODE_ID@16 B\nNODE_ID@20 A\nLINK@21 -->\nNODE_ID@24 B\nclassDef@28 classDef \nCLASSDEF_ID@37 blue \nCLASSDEF_STYLEOPTS@42 fill:#6e6>\"x\"]ce6,stroke:#333,stroke-width:4px;\nclass@92 class \nCLASSENTITY_IDS@98 A\nSTYLECLASS@99  blue\nNODE_ID@107 style,\nNODE_ID@115 B\nNODE_ID@117 fill\nINVALID@121 ",
  ),
  (
    "block\n    \n    block\n      D\n    end\n    A[\"A: I am a wide o]\n", "BLOCK_DIAGRAM_KEY@0 block\nBLOCK_DIAGRAM_KEY@15 block\nNODE_ID@27 D\nend@33 end\n    \nNODE_ID@41 A\nNODE_DSTART@42 [\nSTR@44 A: I am a wide o]\n\nSTR@62 \n$end@62 ",
  ),
  (
    "block-beta\n  columns 1\n  A:\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2\n   -- \"x\" --> :1",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nCOLUMNS@13 1\nNODE_ID@25 A\nINVALID@26 ",
  ),
  (
    "block\n        columns 3\n        block1[\"Bl one[ock 1\"]\n        blockArrow<[\"&n[\\\"x\"\\]bsp;&nbsp;&nbs]>(right)\n        block2[\"Block 2\"]",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nNODE_ID@32 block1\nNODE_DSTART@38 [\nSTR@40 Bl one[ock 1\nNODE_DEND@53 ]\nNODE_ID@63 blockArrow\nBLOCK_ARROW_START@73 <[\nSTR@76 &n[\\\nINVALID@81 ",
  ),
  (
    "stylA-->e nbsp;atements applied to a block", "NODE_ID@0 stylA\nLINK@5 -->\nNODE_ID@8 e\nNODE_ID@10 nbsp;atements\nNODE_ID@24 applied\nNODE_ID@32 to\nNODE_ID@35 a\nBLOCK_DIAGRAM_KEY@37 block\nEOF@42 \n$end@42 ",
  ),
  (
    "blocks on top of--> eac~~[[\"x\"]]~h other", "NODE_ID@0 blocks\nNODE_ID@7 on\nNODE_ID@10 top\nNODE_ID@14 of\nLINK@16 --> \nNODE_ID@20 eac~~\nNODE_DSTART@25 [[\nSTR@28 x\nNODE_DEND@30 ]]\nNODE_ID@32 ~h\nNODE_ID@35 other\nEOF@40 \n$end@40 ",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide o in the middldown\"]\n  style B fill:#f9F,classDef DEFAULT xstroke:#333,stroke-width:4px\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@20 B\nNODE_DSTART@21 [\nSTR@23 A wide o in the middldown\nNODE_DEND@49 ]\nstyle@53 style \nSTYLE_ENTITY_IDS@59 B\nSTYLE_DEFINITION_DATA@60  fill:#f9F,classDef DEFAULT xstroke:#333,stroke-width:4px\nEOF@126 \n$end@126 ",
  ),
  (
    "b  columns 3\n  alck\n  A spa\tce B\n  A-->B\n", "NODE_ID@0 b\nCOLUMNS@3 3\nNODE_ID@15 alck\nNODE_ID@22 A\nNODE_ID@24 spa\nNODE_ID@28 ce\nNODE_ID@31 B\nNODE_ID@35 A\nLINK@36 -->\nNODE_ID@39 B\nEOF@41 \n$end@41 ",
  ),
  (
    "block\n    id1{{\"ThilinkStyles iblock db edge stys the text in the box\"}}\n",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 {{\nSTR@16 ThilinkStyles iblock db edge stys the text in the box\nNODE_DEND@70 }}\nEOF@73 \n$end@73 ",
  ),
  (
    "block-beta\n  cdownolumns 1\n  A:1\n  B:2\n  Cx:3\n  D:4\n  E:3\n  F:2\n  G:1",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nNODE_ID@13 cdownolumns\nNODE_ID@25 1\nNODE_ID@29 A\nSIZE@30 1\nNODE_ID@35 B\nSIZE@36 2\nNODE_ID@41 Cx\nSIZE@43 3\nNODE_ID@48 D\nSIZE@49 4\nNODE_ID@54 E\nSIZE@55 3\nNODE_ID@60 F\nSIZE@61 2\nNODE_ID@66 G\nSIZE@67 1\nEOF@69 \n$end@69 ",
  ),
  (
    "block\n[( A space:2 B\n  A-- \"X\" -->B\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_DSTART@6 [(\nINVALID@8 ",
  ),
  (
    "should re block.padid1i,ng from config at call time, not at import time", "NODE_ID@0 should\nNODE_ID@7 re\nBLOCK_DIAGRAM_KEY@10 block\nNODE_ID@15 .padid1i,ng\nNODE_ID@27 from\nNODE_ID@32 config\nNODE_ID@39 at\nNODE_ID@42 call\nNODE_ID@47 time,\nNODE_ID@53 not\nNODE_ID@57 at\nNODE_ID@60 import\nNODE_ID@67 time\nEOF@71 \n$end@71 ",
  ),
  (
    "block\nA; clasclassDef ${prop} cor:#ffffff,fill:#000000; class A${prop}", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 A;\nNODE_ID@9 clasclassDef\nNODE_ID@22 $\nNODE_DSTART@23 {\nINVALID@24 ",
  ),
  (
    "block\n        columns in the box\"]\n 1\n        A\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n          columns 3\n            B\n            C\n down           D\n        end",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@14 columns\nNODE_ID@22 in\nNODE_ID@25 the\nNODE_ID@29 box\"]\nNODE_ID@36 1\nNODE_ID@46 A\nNODE_ID@56 blockArrow\nBLOCK_ARROW_START@66 <[\nSTR@69 &nbsp;&nbsp;&nbsp;\nDIR@91 up\nDIR@93 down\nBLOCK_ARROW_END@99 ]>\nBLOCK_DIAGRAM_KEY@109 block\nCOLUMNS@125 3\nNODE_ID@147 B\nNODE_ID@161 C\nNODE_ID@164 down\nNODE_ID@179 D\nend@189 end\nEOF@192 \n$end@192 ",
  ),
  (
    "     B\n    block\n  a b c", "NODE_ID@5 B\nBLOCK_DIAGRAM_KEY@11 block\nNODE_ID@19 a\nNODE_ID@21 b\nNODE_ID@23 c\nEOF@24 \n$end@24 ",
  ),
  (
    "mpound blocks wconstructor title", "NODE_ID@0 mpound\nNODE_ID@7 blocks\nNODE_ID@14 wconstructor\nNODE_ID@27 title\nEOF@32 \n$end@32 ",
  ),
  (
    "blocks next to each othecolumns 0rther", "NODE_ID@0 blocks\nNODE_ID@7 next\nNODE_ID@12 to\nNODE_ID@15 each\nNODE_ID@20 othecolumns\nNODE_ID@32 0rther\nEOF@38 \n$end@38 ",
  ),
  (
    "block\n  columns 3\n  Start((\"Start\")) space:2\n  down<[\" \"]>(down) space:2\n  Decision{{\"Make Decision\"}} right<[\"Yes\"]>(right) Process1[\"Process A\"]\n  downAgain<[\"No\"]>(down) space r3<[\"Do\u{e9}ne\"]>(down)\n  Process2[\"Process B\"] r2<[\"Done\"]>(right) End((\"End\"))\n\n  [(\"x\")]style Start fill:#969;\n  style End fill:#696;\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@8 3\nNODE_ID@20 Start\nNODE_DSTART@25 ((\nSTR@28 Start\nNODE_DEND@34 ))\nSPACE_BLOCK@37 2\nNODE_ID@47 down\nBLOCK_ARROW_START@51 <[\nSTR@54  \nDIR@59 down\nBLOCK_ARROW_END@63 ]>\nSPACE_BLOCK@65 2\nNODE_ID@75 Decision\nNODE_DSTART@83 {{\nSTR@86 Make Decision\nNODE_DEND@100 }}\nNODE_ID@103 right\nBLOCK_ARROW_START@108 <[\nSTR@111 Yes\nDIR@118 right\nBLOCK_ARROW_END@123 ]>\nNODE_ID@125 Process1\nNODE_DSTART@133 [\nSTR@135 Process A\nNODE_DEND@145 ]\nNODE_ID@149 downAgain\nBLOCK_ARROW_START@158 <[\nSTR@161 No\nDIR@167 down\nBLOCK_ARROW_END@171 ]>\nSPACE_BLOCK@173 1\nNODE_ID@179 r3\nBLOCK_ARROW_START@181 <[\nSTR@184 Do\u{e9}ne\nDIR@193 down\nBLOCK_ARROW_END@197 ]>\nNODE_ID@201 Process2\nNODE_DSTART@209 [\nSTR@211 Process B\nNODE_DEND@221 ]\nNODE_ID@223 r2\nBLOCK_ARROW_START@225 <[\nSTR@228 Done\nDIR@236 right\nBLOCK_ARROW_END@241 ]>\nNODE_ID@243 End\nNODE_DSTART@246 ((\nSTR@249 End\nNODE_DEND@253 ))\nNODE_DSTART@259 [(\nSTR@262 x\nNODE_DEND@264 )]\nstyle@266 style \nSTYLE_ENTITY_IDS@272 Start\nSTYLE_DEFINITION_DATA@277  fill:#969;\nstyle@291 style \nSTYLE_ENTITY_IDS@297 End\nSTYLE_DEFINITION_DATA@300  fill:#696;\nEOF@312 \n$end@312 ",
  ),
  (
    "block\n        columns 3\n        space\n        middle[\"In the midddle\"]\n        space\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 3\nSPACE_BLOCK@32 1\nNODE_ID@46 middle\nNODE_DSTART@52 [\nSTR@54 In the midddle\nNODE_DEND@69 ]\nSPACE_BLOCK@79 1\nEOF@93 \n$end@93 ",
  ),
  (
    "block\n23  co[/\"x\"/]lumnsmpound block 3\n  a b c d\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@6 23\nNODE_ID@10 co\nNODE_DSTART@12 [/\nSTR@15 x\nNODE_DEND@17 /]\nNODE_ID@19 lumnsmpound\nBLOCK_DIAGRAM_KEY@31 block\nNODE_ID@37 3\nNODE_ID@41 a\nNODE_ID@43 b\nNODE_ID@45 c\nNODE_ID@47 d\nEOF@49 \n$end@49 ",
  ),
  (
    "block\n   lour slots       id1\n          id2\n         (((\"x\")))id3\nrow      ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@9 lour\nNODE_ID@14 slots\nNODE_ID@26 id1\nNODE_ID@40 id2\nNODE_DSTART@53 (((\nSTR@57 x\nNODE_DEND@59 )))\nNODE_ID@62 id3\nNODE_ID@66 row\nEOF@75 \n$end@75 ",
  ),
  (
    "block\n      id1(\"Tis is the text in the box\")\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@12 id1\nNODE_DSTART@15 (\nSTR@17 Tis is the text in the box\nNODE_DEND@44 )\nEOF@46 \n$end@46 ",
  ),
  (
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B fill:#f9F,stroke:#333,stroke-width:4p4px\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@20 B\nNODE_DSTART@21 [\nSTR@23 A wide one in the middle\nNODE_DEND@48 ]\nstyle@52 style \nSTYLE_ENTITY_IDS@58 B\nSTYLE_DEFINITION_DATA@59  fill:#f9F,stroke:#333,stroke-width:4p4px\nEOF@109 \n$end@109 ",
  ),
  (
    "Arrow cks mixed with cblocks", "NODE_ID@0 Arrow\nNODE_ID@6 cks\nNODE_ID@10 mixed\nNODE_ID@16 with\nNODE_ID@21 cblocks\nEOF@28 \n$end@28 ",
  ),
  (
    "block\n    id1(((\"This is the ytext in the circle\")))\n", "BLOCK_DIAGRAM_KEY@0 block\nNODE_ID@10 id1\nNODE_DSTART@13 (((\nSTR@17 This is the ytext in the circle\nNODE_DEND@49 )))\nEOF@53 \n$end@53 ",
  ),
  (
    "blockclassDef a fill:#f96\n${rop}", "NODE_ID@0 blockclassDef\nNODE_ID@14 a\nNODE_ID@16 fill\nINVALID@20 ",
  ),
  (
    "block-beta\n      a\n      b\n      block:group\n        c\n      end\n   ",
    "BLOCK_DIAGRAM_KEY@0 block-beta\nNODE_ID@17 a\nNODE_ID@25 b\nid-block@33 block:\nNODE_ID@39 group\nNODE_ID@53 c\nend@61 end\n   \nEOF@68 \n$end@68 ",
  ),
  (
    "block\n {\"x\"}         block\n            aBlock[\"ABlock\"]\n            block\n              bBlock[\"BBlock\"]ck1[\"B\n            end\n          en\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nNODE_DSTART@7 {\nSTR@9 x\nNODE_DEND@11 }\nBLOCK_DIAGRAM_KEY@21 block\nNODE_ID@39 aBlock\nNODE_DSTART@45 [\nSTR@47 ABlock\nNODE_DEND@54 ]\nBLOCK_DIAGRAM_KEY@68 block\nNODE_ID@88 bBlock\nNODE_DSTART@94 [\nSTR@96 BBlock\nNODE_DEND@103 ]\nNODE_ID@104 ck1\nNODE_DSTART@107 [\nSTR@109 B\n            end\n          en\n        \nSTR@148 \n$end@148 ",
  ),
  (
    "shoulead block.padding from config at call time, not at import time", "NODE_ID@0 shoulead\nBLOCK_DIAGRAM_KEY@9 block\nNODE_ID@14 .padding\nNODE_ID@23 from\nNODE_ID@28 config\nNODE_ID@35 at\nNODE_ID@38 call\nNODE_ID@43 time,\nNODE_ID@49 not\nNODE_ID@53 at\nNODE_ID@56 import\nNODE_ID@63 time\nEOF@67 \n$end@67 ",
  ),
  (
    "block-beta\n  \"]\n            blo        id\n      ", "BLOCK_DIAGRAM_KEY@0 block-beta\nSTR@14 ]\n            blo        id\n      \nSTR@48 \n$end@48 ",
  ),
  (
    "block\n          block:compoundBlock[\"Compound block\"]\n            columns 1\n            blblock2[\"Block 2\"]\n          end\nnd\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nid-block@16 block:\nNODE_ID@22 compoundBlock\nNODE_DSTART@35 [\nSTR@37 Compound block\nNODE_DEND@52 ]\nCOLUMNS@66 1\nNODE_ID@88 blblock2\nNODE_DSTART@96 [\nSTR@98 Block 2\nNODE_DEND@106 ]\nend@118 end\n\nNODE_ID@122 nd\nEOF@133 \n$end@133 ",
  ),
  (
    "block\n          block:compounclass A adBlock[\"Compound block\"]\n            columns 1\n            block2[\"Block 2\"]\n          end\n     (   ",
    "BLOCK_DIAGRAM_KEY@0 block\nid-block@16 block:\nNODE_ID@22 compounclass\nNODE_ID@35 A\nNODE_ID@37 adBlock\nNODE_DSTART@44 [\nSTR@46 Compound block\nNODE_DEND@61 ]\nCOLUMNS@75 1\nNODE_ID@97 block2\nNODE_DSTART@103 [\nSTR@105 Block 2\nNODE_DEND@113 ]\nend@125 end\n     \nNODE_DSTART@134 (\nINVALID@135 ",
  ),
  (
    "block\n       columns 2\n         ock1[\"Block 1\"]]\n      ", "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@13 2\nNODE_ID@32 ock1\nNODE_DSTART@36 [\nSTR@38 Block 1\nNODE_DEND@46 ]]\nEOF@55 \n$end@55 ",
  ),
  (
    "block\n          block:compoundBlock[\"Compound block\"]\n          olumns 1\n            bloblock2[\"Block 2\"]\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nid-block@16 block:\nNODE_ID@22 compoundBlock\nNODE_DSTART@35 [\nSTR@37 Compound block\nNODE_DEND@52 ]\nNODE_ID@64 olumns\nNODE_ID@71 1\nNODE_ID@85 bloblock2\nNODE_DSTART@94 [\nSTR@96 Block 2\nNODE_DEND@104 ]\nend@116 end\n        \nEOF@128 \n$end@128 ",
  ),
  (
    "block\n        columns 1\n      block: A\n        blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n        block\n          columns 3\n            B\n            C\n            D\n        end",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@14 1\nid-block@30 block:\nNODE_ID@37 A\nNODE_ID@47 blockArrow\nBLOCK_ARROW_START@57 <[\nSTR@60 &nbsp;&nbsp;&nbsp;\nDIR@82 up\nDIR@84 down\nBLOCK_ARROW_END@90 ]>\nBLOCK_DIAGRAM_KEY@100 block\nCOLUMNS@116 3\nNODE_ID@138 B\nNODE_ID@152 C\nNODE_ID@166 D\nend@176 end\nEOF@179 \n$end@179 ",
  ),
  (
    "bend\nocks xed with compounspace:2d blocks", "NODE_ID@0 bend\nNODE_ID@5 ocks\nNODE_ID@10 xed\nNODE_ID@14 with\nNODE_ID@19 compounspace\nSIZE@31 2\nNODE_ID@33 d\nNODE_ID@35 blocks\nEOF@41 \n$end@41 ",
  ),
  (
    "block\n          columns 1\n    -.      block1[\"Block 1\"]\n\n          block\n            columns 2\n              block2[\"Block 2\"]\n            blocks 3\n  a[\"A labe3[\"Block 3\"]\n          end\n        ",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@16 1\nSTART_LINK@30 -.      \nINVALID@38 ",
  ),
  (
    "should log a warning when block width exceeds column width]]", "NODE_ID@0 should\nNODE_ID@7 log\nNODE_ID@11 a\nNODE_ID@13 warning\nNODE_ID@21 when\nBLOCK_DIAGRAM_KEY@26 block\nNODE_ID@32 width\nNODE_ID@38 exceeds\nNODE_ID@46 column\nNODE_ID@53 width]]\nEOF@60 \n$end@60 ",
  ),
  (
    "gives no slot to a simple lock", "NODE_ID@0 gives\nNODE_ID@6 no\nNODE_ID@9 slot\nNODE_ID@14 to\nNODE_ID@17 a\nNODE_ID@19 simple\nNODE_ID@26 lock\nEOF@30 \n$end@30 ",
  ),
  (
    "classDef statements appli) Process1[\"ed to a block", "classDef@0 classDef \nCLASSDEF_ID@9 statements \nCLASSDEF_STYLEOPTS@20 appli) Process1[\"ed to a block\nEOF@50 \n$end@50 ",
  ),
  (
    "block\ncolumns 1\n  db((\"DB\"))\n  blockArrowId6<[\"&nbsp;&nbsp;&nbsp;\"]>(down)\n  block:ID\n    A\n    B[\"A wide one in the middle\"]\n    C\n  end\n  space\n  D\n  ID --> D\n  C --> D\n  style B fill:#969,stroke:#333,s{troke-width:4px\n",
    "BLOCK_DIAGRAM_KEY@0 block\nCOLUMNS@6 1\nNODE_ID@18 db\nNODE_DSTART@20 ((\nSTR@23 DB\nNODE_DEND@26 ))\nNODE_ID@31 blockArrowId6\nBLOCK_ARROW_START@44 <[\nSTR@47 &nbsp;&nbsp;&nbsp;\nDIR@69 down\nBLOCK_ARROW_END@73 ]>\nid-block@77 block:\nNODE_ID@83 ID\nNODE_ID@90 A\nNODE_ID@96 B\nNODE_DSTART@97 [\nSTR@99 A wide one in the middle\nNODE_DEND@124 ]\nNODE_ID@130 C\nend@134 end\n  \nSPACE_BLOCK@140 1\nNODE_ID@148 D\nNODE_ID@152 ID\nLINK@155 --> \nNODE_ID@159 D\nNODE_ID@163 C\nLINK@165 --> \nNODE_ID@169 D\nstyle@173 style \nSTYLE_ENTITY_IDS@179 B\nSTYLE_DEFINITION_DATA@180  fill:#969,stroke:#333,s{troke-width:4px\nEOF@221 \n$end@221 ",
  ),
]
