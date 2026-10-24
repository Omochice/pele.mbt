// The sources Mermaid's er parser specs parse, as pele v1.8.0 runs them in tests/compat/er, with what pele's parser makes of each.

///|
let spec_cases : Array[(String, String)] = [
  (
    "erDiagram\nISLAND\nMAINLAND", "ok\ndir \"TB\"\nentity \"ISLAND\" id=\"entity-ISLAND-0\" label=\"ISLAND\" alias=\"\" classes=\"default\" styles=[]\nentity \"MAINLAND\" id=\"entity-MAINLAND-1\" label=\"MAINLAND\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"\"\n", "error syntax 2:2\nParse error on line 2:\n \"\"\n-^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got 'WORD'",
  ),
  (
    "erDiagram\n Blo~rf\n", "error syntax 2:5\nParse error on line 2:\n Blo~rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '~'",
  ),
  (
    "erDiagram\n \"Blo~rf\"\n", "ok\ndir \"TB\"\nentity \"Blo~rf\" id=\"entity-Blo~rf-0\" label=\"Blo~rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo~~rf\"\n", "ok\ndir \"TB\"\nentity \"Blo~~rf\" id=\"entity-Blo~~rf-0\" label=\"Blo~~rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf~\"\n", "ok\ndir \"TB\"\nentity \"Blorf~\" id=\"entity-Blorf~-0\" label=\"Blorf~\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo`rf\n", "error syntax 2:5\nParse error on line 2:\n Blo`rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '`'",
  ),
  (
    "erDiagram\n \"Blo`rf\"\n", "ok\ndir \"TB\"\nentity \"Blo`rf\" id=\"entity-Blo`rf-0\" label=\"Blo`rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo``rf\"\n", "ok\ndir \"TB\"\nentity \"Blo``rf\" id=\"entity-Blo``rf-0\" label=\"Blo``rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf`\"\n", "ok\ndir \"TB\"\nentity \"Blorf`\" id=\"entity-Blorf`-0\" label=\"Blorf`\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo!rf\n", "error syntax 2:5\nParse error on line 2:\n Blo!rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '!'",
  ),
  (
    "erDiagram\n \"Blo!rf\"\n", "ok\ndir \"TB\"\nentity \"Blo!rf\" id=\"entity-Blo!rf-0\" label=\"Blo!rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo!!rf\"\n", "ok\ndir \"TB\"\nentity \"Blo!!rf\" id=\"entity-Blo!!rf-0\" label=\"Blo!!rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf!\"\n", "ok\ndir \"TB\"\nentity \"Blorf!\" id=\"entity-Blorf!-0\" label=\"Blorf!\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo@rf\n", "error syntax 2:5\nParse error on line 2:\n Blo@rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '@'",
  ),
  (
    "erDiagram\n \"Blo@rf\"\n", "ok\ndir \"TB\"\nentity \"Blo@rf\" id=\"entity-Blo@rf-0\" label=\"Blo@rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo@@rf\"\n", "ok\ndir \"TB\"\nentity \"Blo@@rf\" id=\"entity-Blo@@rf-0\" label=\"Blo@@rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf@\"\n", "ok\ndir \"TB\"\nentity \"Blorf@\" id=\"entity-Blorf@-0\" label=\"Blorf@\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo#rf\n", "error syntax 2:5\nParse error on line 2:\n Blo#rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got 'BRKT'",
  ),
  (
    "erDiagram\n \"Blo#rf\"\n", "ok\ndir \"TB\"\nentity \"Blo#rf\" id=\"entity-Blo#rf-0\" label=\"Blo#rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo##rf\"\n", "ok\ndir \"TB\"\nentity \"Blo##rf\" id=\"entity-Blo##rf-0\" label=\"Blo##rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf#\"\n", "ok\ndir \"TB\"\nentity \"Blorf#\" id=\"entity-Blorf#-0\" label=\"Blorf#\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo$rf\n", "error syntax 2:5\nParse error on line 2:\n Blo$rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '$'",
  ),
  (
    "erDiagram\n \"Blo$rf\"\n", "ok\ndir \"TB\"\nentity \"Blo$rf\" id=\"entity-Blo$rf-0\" label=\"Blo$rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo$$rf\"\n", "ok\ndir \"TB\"\nentity \"Blo$$rf\" id=\"entity-Blo$$rf-0\" label=\"Blo$$rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf$\"\n", "ok\ndir \"TB\"\nentity \"Blorf$\" id=\"entity-Blorf$-0\" label=\"Blorf$\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo^rf\n", "error syntax 2:5\nParse error on line 2:\n Blo^rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '^'",
  ),
  (
    "erDiagram\n \"Blo^rf\"\n", "ok\ndir \"TB\"\nentity \"Blo^rf\" id=\"entity-Blo^rf-0\" label=\"Blo^rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo^^rf\"\n", "ok\ndir \"TB\"\nentity \"Blo^^rf\" id=\"entity-Blo^^rf-0\" label=\"Blo^^rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf^\"\n", "ok\ndir \"TB\"\nentity \"Blorf^\" id=\"entity-Blorf^-0\" label=\"Blorf^\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo&rf\n", "error syntax 2:5\nParse error on line 2:\n Blo&rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '&'",
  ),
  (
    "erDiagram\n \"Blo&rf\"\n", "ok\ndir \"TB\"\nentity \"Blo&rf\" id=\"entity-Blo&rf-0\" label=\"Blo&rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo&&rf\"\n", "ok\ndir \"TB\"\nentity \"Blo&&rf\" id=\"entity-Blo&&rf-0\" label=\"Blo&&rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf&\"\n", "ok\ndir \"TB\"\nentity \"Blorf&\" id=\"entity-Blorf&-0\" label=\"Blorf&\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo*rf\n", "ok\ndir \"TB\"\nentity \"Blo*rf\" id=\"entity-Blo*rf-0\" label=\"Blo*rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo*rf\"\n", "ok\ndir \"TB\"\nentity \"Blo*rf\" id=\"entity-Blo*rf-0\" label=\"Blo*rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo**rf\"\n", "ok\ndir \"TB\"\nentity \"Blo**rf\" id=\"entity-Blo**rf-0\" label=\"Blo**rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf*\"\n", "ok\ndir \"TB\"\nentity \"Blorf*\" id=\"entity-Blorf*-0\" label=\"Blorf*\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo(rf\n", "error syntax 2:5\nParse error on line 2:\n Blo(rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '('",
  ),
  (
    "erDiagram\n \"Blo(rf\"\n", "ok\ndir \"TB\"\nentity \"Blo(rf\" id=\"entity-Blo(rf-0\" label=\"Blo(rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo((rf\"\n", "ok\ndir \"TB\"\nentity \"Blo((rf\" id=\"entity-Blo((rf-0\" label=\"Blo((rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf(\"\n", "ok\ndir \"TB\"\nentity \"Blorf(\" id=\"entity-Blorf(-0\" label=\"Blorf(\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo)rf\n", "error syntax 2:5\nParse error on line 2:\n Blo)rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got ')'",
  ),
  (
    "erDiagram\n \"Blo)rf\"\n", "ok\ndir \"TB\"\nentity \"Blo)rf\" id=\"entity-Blo)rf-0\" label=\"Blo)rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo))rf\"\n", "ok\ndir \"TB\"\nentity \"Blo))rf\" id=\"entity-Blo))rf-0\" label=\"Blo))rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf)\"\n", "ok\ndir \"TB\"\nentity \"Blorf)\" id=\"entity-Blorf)-0\" label=\"Blorf)\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo-rf\n", "ok\ndir \"TB\"\nentity \"Blo-rf\" id=\"entity-Blo-rf-0\" label=\"Blo-rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo-rf\"\n", "ok\ndir \"TB\"\nentity \"Blo-rf\" id=\"entity-Blo-rf-0\" label=\"Blo-rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo--rf\"\n", "ok\ndir \"TB\"\nentity \"Blo--rf\" id=\"entity-Blo--rf-0\" label=\"Blo--rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf-\"\n", "ok\ndir \"TB\"\nentity \"Blorf-\" id=\"entity-Blorf--0\" label=\"Blorf-\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo=rf\n", "error syntax 2:5\nParse error on line 2:\n Blo=rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '='",
  ),
  (
    "erDiagram\n \"Blo=rf\"\n", "ok\ndir \"TB\"\nentity \"Blo=rf\" id=\"entity-Blo=rf-0\" label=\"Blo=rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo==rf\"\n", "ok\ndir \"TB\"\nentity \"Blo==rf\" id=\"entity-Blo==rf-0\" label=\"Blo==rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf=\"\n", "ok\ndir \"TB\"\nentity \"Blorf=\" id=\"entity-Blorf=-0\" label=\"Blorf=\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo+rf\n", "error syntax 2:5\nParse error on line 2:\n Blo+rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '+'",
  ),
  (
    "erDiagram\n \"Blo+rf\"\n", "ok\ndir \"TB\"\nentity \"Blo+rf\" id=\"entity-Blo+rf-0\" label=\"Blo+rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo++rf\"\n", "ok\ndir \"TB\"\nentity \"Blo++rf\" id=\"entity-Blo++rf-0\" label=\"Blo++rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf+\"\n", "ok\ndir \"TB\"\nentity \"Blorf+\" id=\"entity-Blorf+-0\" label=\"Blorf+\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo[rf\n", "error syntax 2:8\nParse error on line 2:\n Blo[rf\n-------^\nExpecting 'SQE', got 'NEWLINE'",
  ),
  (
    "erDiagram\n \"Blo[rf\"\n", "ok\ndir \"TB\"\nentity \"Blo[rf\" id=\"entity-Blo[rf-0\" label=\"Blo[rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo[[rf\"\n", "ok\ndir \"TB\"\nentity \"Blo[[rf\" id=\"entity-Blo[[rf-0\" label=\"Blo[[rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf[\"\n", "ok\ndir \"TB\"\nentity \"Blorf[\" id=\"entity-Blorf[-0\" label=\"Blorf[\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo]rf\n", "error syntax 2:5\nParse error on line 2:\n Blo]rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got 'SQE'",
  ),
  (
    "erDiagram\n \"Blo]rf\"\n", "ok\ndir \"TB\"\nentity \"Blo]rf\" id=\"entity-Blo]rf-0\" label=\"Blo]rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo]]rf\"\n", "ok\ndir \"TB\"\nentity \"Blo]]rf\" id=\"entity-Blo]]rf-0\" label=\"Blo]]rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf]\"\n", "ok\ndir \"TB\"\nentity \"Blorf]\" id=\"entity-Blorf]-0\" label=\"Blorf]\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo{rf\n", "error syntax 3:1\nParse error on line 3:\n\n^\nExpecting 'ATTRIBUTE_WORD', '?', got '$end'",
  ),
  (
    "erDiagram\n \"Blo{rf\"\n", "ok\ndir \"TB\"\nentity \"Blo{rf\" id=\"entity-Blo{rf-0\" label=\"Blo{rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo{{rf\"\n", "ok\ndir \"TB\"\nentity \"Blo{{rf\" id=\"entity-Blo{{rf-0\" label=\"Blo{{rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf{\"\n", "ok\ndir \"TB\"\nentity \"Blorf{\" id=\"entity-Blorf{-0\" label=\"Blorf{\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo}rf\n", "error syntax 2:5\nParse error on line 2:\n Blo}rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '}'",
  ),
  (
    "erDiagram\n \"Blo}rf\"\n", "ok\ndir \"TB\"\nentity \"Blo}rf\" id=\"entity-Blo}rf-0\" label=\"Blo}rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo}}rf\"\n", "ok\ndir \"TB\"\nentity \"Blo}}rf\" id=\"entity-Blo}}rf-0\" label=\"Blo}}rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf}\"\n", "ok\ndir \"TB\"\nentity \"Blorf}\" id=\"entity-Blorf}-0\" label=\"Blorf}\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo|rf\n", "error syntax 2:5\nParse error on line 2:\n Blo|rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '|'",
  ),
  (
    "erDiagram\n \"Blo|rf\"\n", "ok\ndir \"TB\"\nentity \"Blo|rf\" id=\"entity-Blo|rf-0\" label=\"Blo|rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo||rf\"\n", "ok\ndir \"TB\"\nentity \"Blo||rf\" id=\"entity-Blo||rf-0\" label=\"Blo||rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf|\"\n", "ok\ndir \"TB\"\nentity \"Blorf|\" id=\"entity-Blorf|-0\" label=\"Blorf|\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo/rf\n", "error syntax 2:5\nParse error on line 2:\n Blo/rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '/'",
  ),
  (
    "erDiagram\n \"Blo/rf\"\n", "ok\ndir \"TB\"\nentity \"Blo/rf\" id=\"entity-Blo/rf-0\" label=\"Blo/rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo//rf\"\n", "ok\ndir \"TB\"\nentity \"Blo//rf\" id=\"entity-Blo//rf-0\" label=\"Blo//rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf/\"\n", "ok\ndir \"TB\"\nentity \"Blorf/\" id=\"entity-Blorf/-0\" label=\"Blorf/\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo;rf\n", "error syntax 2:5\nParse error on line 2:\n Blo;rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got ';'",
  ),
  (
    "erDiagram\n \"Blo;rf\"\n", "ok\ndir \"TB\"\nentity \"Blo;rf\" id=\"entity-Blo;rf-0\" label=\"Blo;rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo;;rf\"\n", "ok\ndir \"TB\"\nentity \"Blo;;rf\" id=\"entity-Blo;;rf-0\" label=\"Blo;;rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf;\"\n", "ok\ndir \"TB\"\nentity \"Blorf;\" id=\"entity-Blorf;-0\" label=\"Blorf;\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo:rf\n", "error syntax 2:5\nParse error on line 2:\n Blo:rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got 'COLON'",
  ),
  (
    "erDiagram\n \"Blo:rf\"\n", "ok\ndir \"TB\"\nentity \"Blo:rf\" id=\"entity-Blo:rf-0\" label=\"Blo:rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo::rf\"\n", "ok\ndir \"TB\"\nentity \"Blo::rf\" id=\"entity-Blo::rf-0\" label=\"Blo::rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf:\"\n", "ok\ndir \"TB\"\nentity \"Blorf:\" id=\"entity-Blorf:-0\" label=\"Blorf:\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo'rf\n", "error syntax 2:5\nParse error on line 2:\n Blo'rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '''",
  ),
  (
    "erDiagram\n \"Blo'rf\"\n", "ok\ndir \"TB\"\nentity \"Blo'rf\" id=\"entity-Blo'rf-0\" label=\"Blo'rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo''rf\"\n", "ok\ndir \"TB\"\nentity \"Blo''rf\" id=\"entity-Blo''rf-0\" label=\"Blo''rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf'\"\n", "ok\ndir \"TB\"\nentity \"Blorf'\" id=\"entity-Blorf'-0\" label=\"Blorf'\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo.rf\n", "ok\ndir \"TB\"\nentity \"Blo.rf\" id=\"entity-Blo.rf-0\" label=\"Blo.rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo.rf\"\n", "ok\ndir \"TB\"\nentity \"Blo.rf\" id=\"entity-Blo.rf-0\" label=\"Blo.rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo..rf\"\n", "ok\ndir \"TB\"\nentity \"Blo..rf\" id=\"entity-Blo..rf-0\" label=\"Blo..rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf.\"\n", "ok\ndir \"TB\"\nentity \"Blorf.\" id=\"entity-Blorf.-0\" label=\"Blorf.\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo?rf\n", "error syntax 2:5\nParse error on line 2:\n Blo?rf\n----^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '?'",
  ),
  (
    "erDiagram\n \"Blo?rf\"\n", "ok\ndir \"TB\"\nentity \"Blo?rf\" id=\"entity-Blo?rf-0\" label=\"Blo?rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo??rf\"\n", "ok\ndir \"TB\"\nentity \"Blo??rf\" id=\"entity-Blo??rf-0\" label=\"Blo??rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf?\"\n", "ok\ndir \"TB\"\nentity \"Blorf?\" id=\"entity-Blorf?-0\" label=\"Blorf?\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo¡rf\n", "ok\ndir \"TB\"\nentity \"Blo¡rf\" id=\"entity-Blo¡rf-0\" label=\"Blo¡rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¡rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¡rf\" id=\"entity-Blo¡rf-0\" label=\"Blo¡rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¡¡rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¡¡rf\" id=\"entity-Blo¡¡rf-0\" label=\"Blo¡¡rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf¡\"\n", "ok\ndir \"TB\"\nentity \"Blorf¡\" id=\"entity-Blorf¡-0\" label=\"Blorf¡\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo⁄rf\n", "ok\ndir \"TB\"\nentity \"Blo⁄rf\" id=\"entity-Blo⁄rf-0\" label=\"Blo⁄rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo⁄rf\"\n", "ok\ndir \"TB\"\nentity \"Blo⁄rf\" id=\"entity-Blo⁄rf-0\" label=\"Blo⁄rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo⁄⁄rf\"\n", "ok\ndir \"TB\"\nentity \"Blo⁄⁄rf\" id=\"entity-Blo⁄⁄rf-0\" label=\"Blo⁄⁄rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf⁄\"\n", "ok\ndir \"TB\"\nentity \"Blorf⁄\" id=\"entity-Blorf⁄-0\" label=\"Blorf⁄\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo™rf\n", "ok\ndir \"TB\"\nentity \"Blo™rf\" id=\"entity-Blo™rf-0\" label=\"Blo™rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo™rf\"\n", "ok\ndir \"TB\"\nentity \"Blo™rf\" id=\"entity-Blo™rf-0\" label=\"Blo™rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo™™rf\"\n", "ok\ndir \"TB\"\nentity \"Blo™™rf\" id=\"entity-Blo™™rf-0\" label=\"Blo™™rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf™\"\n", "ok\ndir \"TB\"\nentity \"Blorf™\" id=\"entity-Blorf™-0\" label=\"Blorf™\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo€rf\n", "ok\ndir \"TB\"\nentity \"Blo€rf\" id=\"entity-Blo€rf-0\" label=\"Blo€rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo€rf\"\n", "ok\ndir \"TB\"\nentity \"Blo€rf\" id=\"entity-Blo€rf-0\" label=\"Blo€rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo€€rf\"\n", "ok\ndir \"TB\"\nentity \"Blo€€rf\" id=\"entity-Blo€€rf-0\" label=\"Blo€€rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf€\"\n", "ok\ndir \"TB\"\nentity \"Blorf€\" id=\"entity-Blorf€-0\" label=\"Blorf€\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo£rf\n", "ok\ndir \"TB\"\nentity \"Blo£rf\" id=\"entity-Blo£rf-0\" label=\"Blo£rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo£rf\"\n", "ok\ndir \"TB\"\nentity \"Blo£rf\" id=\"entity-Blo£rf-0\" label=\"Blo£rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo££rf\"\n", "ok\ndir \"TB\"\nentity \"Blo££rf\" id=\"entity-Blo££rf-0\" label=\"Blo££rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf£\"\n", "ok\ndir \"TB\"\nentity \"Blorf£\" id=\"entity-Blorf£-0\" label=\"Blorf£\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo‹rf\n", "ok\ndir \"TB\"\nentity \"Blo‹rf\" id=\"entity-Blo‹rf-0\" label=\"Blo‹rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo‹rf\"\n", "ok\ndir \"TB\"\nentity \"Blo‹rf\" id=\"entity-Blo‹rf-0\" label=\"Blo‹rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo‹‹rf\"\n", "ok\ndir \"TB\"\nentity \"Blo‹‹rf\" id=\"entity-Blo‹‹rf-0\" label=\"Blo‹‹rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf‹\"\n", "ok\ndir \"TB\"\nentity \"Blorf‹\" id=\"entity-Blorf‹-0\" label=\"Blorf‹\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo¢rf\n", "ok\ndir \"TB\"\nentity \"Blo¢rf\" id=\"entity-Blo¢rf-0\" label=\"Blo¢rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¢rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¢rf\" id=\"entity-Blo¢rf-0\" label=\"Blo¢rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¢¢rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¢¢rf\" id=\"entity-Blo¢¢rf-0\" label=\"Blo¢¢rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf¢\"\n", "ok\ndir \"TB\"\nentity \"Blorf¢\" id=\"entity-Blorf¢-0\" label=\"Blorf¢\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo›rf\n", "ok\ndir \"TB\"\nentity \"Blo›rf\" id=\"entity-Blo›rf-0\" label=\"Blo›rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo›rf\"\n", "ok\ndir \"TB\"\nentity \"Blo›rf\" id=\"entity-Blo›rf-0\" label=\"Blo›rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo››rf\"\n", "ok\ndir \"TB\"\nentity \"Blo››rf\" id=\"entity-Blo››rf-0\" label=\"Blo››rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf›\"\n", "ok\ndir \"TB\"\nentity \"Blorf›\" id=\"entity-Blorf›-0\" label=\"Blorf›\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo∞rf\n", "ok\ndir \"TB\"\nentity \"Blo∞rf\" id=\"entity-Blo∞rf-0\" label=\"Blo∞rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∞rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∞rf\" id=\"entity-Blo∞rf-0\" label=\"Blo∞rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∞∞rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∞∞rf\" id=\"entity-Blo∞∞rf-0\" label=\"Blo∞∞rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf∞\"\n", "ok\ndir \"TB\"\nentity \"Blorf∞\" id=\"entity-Blorf∞-0\" label=\"Blorf∞\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloﬁrf\n", "ok\ndir \"TB\"\nentity \"Bloﬁrf\" id=\"entity-Bloﬁrf-0\" label=\"Bloﬁrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloﬁrf\"\n", "ok\ndir \"TB\"\nentity \"Bloﬁrf\" id=\"entity-Bloﬁrf-0\" label=\"Bloﬁrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloﬁﬁrf\"\n", "ok\ndir \"TB\"\nentity \"Bloﬁﬁrf\" id=\"entity-Bloﬁﬁrf-0\" label=\"Bloﬁﬁrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfﬁ\"\n", "ok\ndir \"TB\"\nentity \"Blorfﬁ\" id=\"entity-Blorfﬁ-0\" label=\"Blorfﬁ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo§rf\n", "ok\ndir \"TB\"\nentity \"Blo§rf\" id=\"entity-Blo§rf-0\" label=\"Blo§rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo§rf\"\n", "ok\ndir \"TB\"\nentity \"Blo§rf\" id=\"entity-Blo§rf-0\" label=\"Blo§rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo§§rf\"\n", "ok\ndir \"TB\"\nentity \"Blo§§rf\" id=\"entity-Blo§§rf-0\" label=\"Blo§§rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf§\"\n", "ok\ndir \"TB\"\nentity \"Blorf§\" id=\"entity-Blorf§-0\" label=\"Blorf§\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo‡rf\n", "ok\ndir \"TB\"\nentity \"Blo‡rf\" id=\"entity-Blo‡rf-0\" label=\"Blo‡rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo‡rf\"\n", "ok\ndir \"TB\"\nentity \"Blo‡rf\" id=\"entity-Blo‡rf-0\" label=\"Blo‡rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo‡‡rf\"\n", "ok\ndir \"TB\"\nentity \"Blo‡‡rf\" id=\"entity-Blo‡‡rf-0\" label=\"Blo‡‡rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf‡\"\n", "ok\ndir \"TB\"\nentity \"Blorf‡\" id=\"entity-Blorf‡-0\" label=\"Blorf‡\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo•rf\n", "ok\ndir \"TB\"\nentity \"Blo•rf\" id=\"entity-Blo•rf-0\" label=\"Blo•rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo•rf\"\n", "ok\ndir \"TB\"\nentity \"Blo•rf\" id=\"entity-Blo•rf-0\" label=\"Blo•rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo••rf\"\n", "ok\ndir \"TB\"\nentity \"Blo••rf\" id=\"entity-Blo••rf-0\" label=\"Blo••rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf•\"\n", "ok\ndir \"TB\"\nentity \"Blorf•\" id=\"entity-Blorf•-0\" label=\"Blorf•\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo°rf\n", "ok\ndir \"TB\"\nentity \"Blo°rf\" id=\"entity-Blo°rf-0\" label=\"Blo°rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo°rf\"\n", "ok\ndir \"TB\"\nentity \"Blo°rf\" id=\"entity-Blo°rf-0\" label=\"Blo°rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo°°rf\"\n", "ok\ndir \"TB\"\nentity \"Blo°°rf\" id=\"entity-Blo°°rf-0\" label=\"Blo°°rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf°\"\n", "ok\ndir \"TB\"\nentity \"Blorf°\" id=\"entity-Blorf°-0\" label=\"Blorf°\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloªrf\n", "ok\ndir \"TB\"\nentity \"Bloªrf\" id=\"entity-Bloªrf-0\" label=\"Bloªrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloªrf\"\n", "ok\ndir \"TB\"\nentity \"Bloªrf\" id=\"entity-Bloªrf-0\" label=\"Bloªrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloªªrf\"\n", "ok\ndir \"TB\"\nentity \"Bloªªrf\" id=\"entity-Bloªªrf-0\" label=\"Bloªªrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfª\"\n", "ok\ndir \"TB\"\nentity \"Blorfª\" id=\"entity-Blorfª-0\" label=\"Blorfª\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo·rf\n", "ok\ndir \"TB\"\nentity \"Blo·rf\" id=\"entity-Blo·rf-0\" label=\"Blo·rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo·rf\"\n", "ok\ndir \"TB\"\nentity \"Blo·rf\" id=\"entity-Blo·rf-0\" label=\"Blo·rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo··rf\"\n", "ok\ndir \"TB\"\nentity \"Blo··rf\" id=\"entity-Blo··rf-0\" label=\"Blo··rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf·\"\n", "ok\ndir \"TB\"\nentity \"Blorf·\" id=\"entity-Blorf·-0\" label=\"Blorf·\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloºrf\n", "ok\ndir \"TB\"\nentity \"Bloºrf\" id=\"entity-Bloºrf-0\" label=\"Bloºrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloºrf\"\n", "ok\ndir \"TB\"\nentity \"Bloºrf\" id=\"entity-Bloºrf-0\" label=\"Bloºrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloººrf\"\n", "ok\ndir \"TB\"\nentity \"Bloººrf\" id=\"entity-Bloººrf-0\" label=\"Bloººrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfº\"\n", "ok\ndir \"TB\"\nentity \"Blorfº\" id=\"entity-Blorfº-0\" label=\"Blorfº\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo‚rf\n", "ok\ndir \"TB\"\nentity \"Blo‚rf\" id=\"entity-Blo‚rf-0\" label=\"Blo‚rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo‚rf\"\n", "ok\ndir \"TB\"\nentity \"Blo‚rf\" id=\"entity-Blo‚rf-0\" label=\"Blo‚rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo‚‚rf\"\n", "ok\ndir \"TB\"\nentity \"Blo‚‚rf\" id=\"entity-Blo‚‚rf-0\" label=\"Blo‚‚rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf‚\"\n", "ok\ndir \"TB\"\nentity \"Blorf‚\" id=\"entity-Blorf‚-0\" label=\"Blorf‚\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo≠rf\n", "ok\ndir \"TB\"\nentity \"Blo≠rf\" id=\"entity-Blo≠rf-0\" label=\"Blo≠rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo≠rf\"\n", "ok\ndir \"TB\"\nentity \"Blo≠rf\" id=\"entity-Blo≠rf-0\" label=\"Blo≠rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo≠≠rf\"\n", "ok\ndir \"TB\"\nentity \"Blo≠≠rf\" id=\"entity-Blo≠≠rf-0\" label=\"Blo≠≠rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf≠\"\n", "ok\ndir \"TB\"\nentity \"Blorf≠\" id=\"entity-Blorf≠-0\" label=\"Blorf≠\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo±rf\n", "ok\ndir \"TB\"\nentity \"Blo±rf\" id=\"entity-Blo±rf-0\" label=\"Blo±rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo±rf\"\n", "ok\ndir \"TB\"\nentity \"Blo±rf\" id=\"entity-Blo±rf-0\" label=\"Blo±rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo±±rf\"\n", "ok\ndir \"TB\"\nentity \"Blo±±rf\" id=\"entity-Blo±±rf-0\" label=\"Blo±±rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf±\"\n", "ok\ndir \"TB\"\nentity \"Blorf±\" id=\"entity-Blorf±-0\" label=\"Blorf±\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloœrf\n", "ok\ndir \"TB\"\nentity \"Bloœrf\" id=\"entity-Bloœrf-0\" label=\"Bloœrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloœrf\"\n", "ok\ndir \"TB\"\nentity \"Bloœrf\" id=\"entity-Bloœrf-0\" label=\"Bloœrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloœœrf\"\n", "ok\ndir \"TB\"\nentity \"Bloœœrf\" id=\"entity-Bloœœrf-0\" label=\"Bloœœrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfœ\"\n", "ok\ndir \"TB\"\nentity \"Blorfœ\" id=\"entity-Blorfœ-0\" label=\"Blorfœ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloŒrf\n", "ok\ndir \"TB\"\nentity \"BloŒrf\" id=\"entity-BloŒrf-0\" label=\"BloŒrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloŒrf\"\n", "ok\ndir \"TB\"\nentity \"BloŒrf\" id=\"entity-BloŒrf-0\" label=\"BloŒrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloŒŒrf\"\n", "ok\ndir \"TB\"\nentity \"BloŒŒrf\" id=\"entity-BloŒŒrf-0\" label=\"BloŒŒrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfŒ\"\n", "ok\ndir \"TB\"\nentity \"BlorfŒ\" id=\"entity-BlorfŒ-0\" label=\"BlorfŒ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo∑rf\n", "ok\ndir \"TB\"\nentity \"Blo∑rf\" id=\"entity-Blo∑rf-0\" label=\"Blo∑rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∑rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∑rf\" id=\"entity-Blo∑rf-0\" label=\"Blo∑rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∑∑rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∑∑rf\" id=\"entity-Blo∑∑rf-0\" label=\"Blo∑∑rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf∑\"\n", "ok\ndir \"TB\"\nentity \"Blorf∑\" id=\"entity-Blorf∑-0\" label=\"Blorf∑\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo„rf\n", "ok\ndir \"TB\"\nentity \"Blo„rf\" id=\"entity-Blo„rf-0\" label=\"Blo„rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo„rf\"\n", "ok\ndir \"TB\"\nentity \"Blo„rf\" id=\"entity-Blo„rf-0\" label=\"Blo„rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo„„rf\"\n", "ok\ndir \"TB\"\nentity \"Blo„„rf\" id=\"entity-Blo„„rf-0\" label=\"Blo„„rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf„\"\n", "ok\ndir \"TB\"\nentity \"Blorf„\" id=\"entity-Blorf„-0\" label=\"Blorf„\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo®rf\n", "ok\ndir \"TB\"\nentity \"Blo®rf\" id=\"entity-Blo®rf-0\" label=\"Blo®rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo®rf\"\n", "ok\ndir \"TB\"\nentity \"Blo®rf\" id=\"entity-Blo®rf-0\" label=\"Blo®rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo®®rf\"\n", "ok\ndir \"TB\"\nentity \"Blo®®rf\" id=\"entity-Blo®®rf-0\" label=\"Blo®®rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf®\"\n", "ok\ndir \"TB\"\nentity \"Blorf®\" id=\"entity-Blorf®-0\" label=\"Blorf®\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo†rf\n", "ok\ndir \"TB\"\nentity \"Blo†rf\" id=\"entity-Blo†rf-0\" label=\"Blo†rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo†rf\"\n", "ok\ndir \"TB\"\nentity \"Blo†rf\" id=\"entity-Blo†rf-0\" label=\"Blo†rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo††rf\"\n", "ok\ndir \"TB\"\nentity \"Blo††rf\" id=\"entity-Blo††rf-0\" label=\"Blo††rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf†\"\n", "ok\ndir \"TB\"\nentity \"Blorf†\" id=\"entity-Blorf†-0\" label=\"Blorf†\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloˇrf\n", "ok\ndir \"TB\"\nentity \"Bloˇrf\" id=\"entity-Bloˇrf-0\" label=\"Bloˇrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloˇrf\"\n", "ok\ndir \"TB\"\nentity \"Bloˇrf\" id=\"entity-Bloˇrf-0\" label=\"Bloˇrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloˇˇrf\"\n", "ok\ndir \"TB\"\nentity \"Bloˇˇrf\" id=\"entity-Bloˇˇrf-0\" label=\"Bloˇˇrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfˇ\"\n", "ok\ndir \"TB\"\nentity \"Blorfˇ\" id=\"entity-Blorfˇ-0\" label=\"Blorfˇ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo¥rf\n", "ok\ndir \"TB\"\nentity \"Blo¥rf\" id=\"entity-Blo¥rf-0\" label=\"Blo¥rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¥rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¥rf\" id=\"entity-Blo¥rf-0\" label=\"Blo¥rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¥¥rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¥¥rf\" id=\"entity-Blo¥¥rf-0\" label=\"Blo¥¥rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf¥\"\n", "ok\ndir \"TB\"\nentity \"Blorf¥\" id=\"entity-Blorf¥-0\" label=\"Blorf¥\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÁrf\n", "ok\ndir \"TB\"\nentity \"BloÁrf\" id=\"entity-BloÁrf-0\" label=\"BloÁrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÁrf\"\n", "ok\ndir \"TB\"\nentity \"BloÁrf\" id=\"entity-BloÁrf-0\" label=\"BloÁrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÁÁrf\"\n", "ok\ndir \"TB\"\nentity \"BloÁÁrf\" id=\"entity-BloÁÁrf-0\" label=\"BloÁÁrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÁ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÁ\" id=\"entity-BlorfÁ-0\" label=\"BlorfÁ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo¨rf\n", "ok\ndir \"TB\"\nentity \"Blo¨rf\" id=\"entity-Blo¨rf-0\" label=\"Blo¨rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¨rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¨rf\" id=\"entity-Blo¨rf-0\" label=\"Blo¨rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¨¨rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¨¨rf\" id=\"entity-Blo¨¨rf-0\" label=\"Blo¨¨rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf¨\"\n", "ok\ndir \"TB\"\nentity \"Blorf¨\" id=\"entity-Blorf¨-0\" label=\"Blorf¨\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloˆrf\n", "ok\ndir \"TB\"\nentity \"Bloˆrf\" id=\"entity-Bloˆrf-0\" label=\"Bloˆrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloˆrf\"\n", "ok\ndir \"TB\"\nentity \"Bloˆrf\" id=\"entity-Bloˆrf-0\" label=\"Bloˆrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloˆˆrf\"\n", "ok\ndir \"TB\"\nentity \"Bloˆˆrf\" id=\"entity-Bloˆˆrf-0\" label=\"Bloˆˆrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfˆ\"\n", "ok\ndir \"TB\"\nentity \"Blorfˆ\" id=\"entity-Blorfˆ-0\" label=\"Blorfˆ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloØrf\n", "ok\ndir \"TB\"\nentity \"BloØrf\" id=\"entity-BloØrf-0\" label=\"BloØrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloØrf\"\n", "ok\ndir \"TB\"\nentity \"BloØrf\" id=\"entity-BloØrf-0\" label=\"BloØrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloØØrf\"\n", "ok\ndir \"TB\"\nentity \"BloØØrf\" id=\"entity-BloØØrf-0\" label=\"BloØØrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfØ\"\n", "ok\ndir \"TB\"\nentity \"BlorfØ\" id=\"entity-BlorfØ-0\" label=\"BlorfØ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloπrf\n", "ok\ndir \"TB\"\nentity \"Bloπrf\" id=\"entity-Bloπrf-0\" label=\"Bloπrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloπrf\"\n", "ok\ndir \"TB\"\nentity \"Bloπrf\" id=\"entity-Bloπrf-0\" label=\"Bloπrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloππrf\"\n", "ok\ndir \"TB\"\nentity \"Bloππrf\" id=\"entity-Bloππrf-0\" label=\"Bloππrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfπ\"\n", "ok\ndir \"TB\"\nentity \"Blorfπ\" id=\"entity-Blorfπ-0\" label=\"Blorfπ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo∏rf\n", "ok\ndir \"TB\"\nentity \"Blo∏rf\" id=\"entity-Blo∏rf-0\" label=\"Blo∏rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∏rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∏rf\" id=\"entity-Blo∏rf-0\" label=\"Blo∏rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∏∏rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∏∏rf\" id=\"entity-Blo∏∏rf-0\" label=\"Blo∏∏rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf∏\"\n", "ok\ndir \"TB\"\nentity \"Blorf∏\" id=\"entity-Blorf∏-0\" label=\"Blorf∏\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo“rf\n", "ok\ndir \"TB\"\nentity \"Blo“rf\" id=\"entity-Blo“rf-0\" label=\"Blo“rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo“rf\"\n", "ok\ndir \"TB\"\nentity \"Blo“rf\" id=\"entity-Blo“rf-0\" label=\"Blo“rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo““rf\"\n", "ok\ndir \"TB\"\nentity \"Blo““rf\" id=\"entity-Blo““rf-0\" label=\"Blo““rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf“\"\n", "ok\ndir \"TB\"\nentity \"Blorf“\" id=\"entity-Blorf“-0\" label=\"Blorf“\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo«rf\n", "ok\ndir \"TB\"\nentity \"Blo«rf\" id=\"entity-Blo«rf-0\" label=\"Blo«rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo«rf\"\n", "ok\ndir \"TB\"\nentity \"Blo«rf\" id=\"entity-Blo«rf-0\" label=\"Blo«rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo««rf\"\n", "ok\ndir \"TB\"\nentity \"Blo««rf\" id=\"entity-Blo««rf-0\" label=\"Blo««rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf«\"\n", "ok\ndir \"TB\"\nentity \"Blorf«\" id=\"entity-Blorf«-0\" label=\"Blorf«\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo»rf\n", "ok\ndir \"TB\"\nentity \"Blo»rf\" id=\"entity-Blo»rf-0\" label=\"Blo»rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo»rf\"\n", "ok\ndir \"TB\"\nentity \"Blo»rf\" id=\"entity-Blo»rf-0\" label=\"Blo»rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo»»rf\"\n", "ok\ndir \"TB\"\nentity \"Blo»»rf\" id=\"entity-Blo»»rf-0\" label=\"Blo»»rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf»\"\n", "ok\ndir \"TB\"\nentity \"Blorf»\" id=\"entity-Blorf»-0\" label=\"Blorf»\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloårf\n", "ok\ndir \"TB\"\nentity \"Bloårf\" id=\"entity-Bloårf-0\" label=\"Bloårf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloårf\"\n", "ok\ndir \"TB\"\nentity \"Bloårf\" id=\"entity-Bloårf-0\" label=\"Bloårf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloåårf\"\n", "ok\ndir \"TB\"\nentity \"Bloåårf\" id=\"entity-Bloåårf-0\" label=\"Bloåårf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfå\"\n", "ok\ndir \"TB\"\nentity \"Blorfå\" id=\"entity-Blorfå-0\" label=\"Blorfå\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÅrf\n", "ok\ndir \"TB\"\nentity \"BloÅrf\" id=\"entity-BloÅrf-0\" label=\"BloÅrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÅrf\"\n", "ok\ndir \"TB\"\nentity \"BloÅrf\" id=\"entity-BloÅrf-0\" label=\"BloÅrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÅÅrf\"\n", "ok\ndir \"TB\"\nentity \"BloÅÅrf\" id=\"entity-BloÅÅrf-0\" label=\"BloÅÅrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÅ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÅ\" id=\"entity-BlorfÅ-0\" label=\"BlorfÅ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloßrf\n", "ok\ndir \"TB\"\nentity \"Bloßrf\" id=\"entity-Bloßrf-0\" label=\"Bloßrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloßrf\"\n", "ok\ndir \"TB\"\nentity \"Bloßrf\" id=\"entity-Bloßrf-0\" label=\"Bloßrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloßßrf\"\n", "ok\ndir \"TB\"\nentity \"Bloßßrf\" id=\"entity-Bloßßrf-0\" label=\"Bloßßrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfß\"\n", "ok\ndir \"TB\"\nentity \"Blorfß\" id=\"entity-Blorfß-0\" label=\"Blorfß\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÍrf\n", "ok\ndir \"TB\"\nentity \"BloÍrf\" id=\"entity-BloÍrf-0\" label=\"BloÍrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÍrf\"\n", "ok\ndir \"TB\"\nentity \"BloÍrf\" id=\"entity-BloÍrf-0\" label=\"BloÍrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÍÍrf\"\n", "ok\ndir \"TB\"\nentity \"BloÍÍrf\" id=\"entity-BloÍÍrf-0\" label=\"BloÍÍrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÍ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÍ\" id=\"entity-BlorfÍ-0\" label=\"BlorfÍ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo∂rf\n", "ok\ndir \"TB\"\nentity \"Blo∂rf\" id=\"entity-Blo∂rf-0\" label=\"Blo∂rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∂rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∂rf\" id=\"entity-Blo∂rf-0\" label=\"Blo∂rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∂∂rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∂∂rf\" id=\"entity-Blo∂∂rf-0\" label=\"Blo∂∂rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf∂\"\n", "ok\ndir \"TB\"\nentity \"Blorf∂\" id=\"entity-Blorf∂-0\" label=\"Blorf∂\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÎrf\n", "ok\ndir \"TB\"\nentity \"BloÎrf\" id=\"entity-BloÎrf-0\" label=\"BloÎrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÎrf\"\n", "ok\ndir \"TB\"\nentity \"BloÎrf\" id=\"entity-BloÎrf-0\" label=\"BloÎrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÎÎrf\"\n", "ok\ndir \"TB\"\nentity \"BloÎÎrf\" id=\"entity-BloÎÎrf-0\" label=\"BloÎÎrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÎ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÎ\" id=\"entity-BlorfÎ-0\" label=\"BlorfÎ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloƒrf\n", "ok\ndir \"TB\"\nentity \"Bloƒrf\" id=\"entity-Bloƒrf-0\" label=\"Bloƒrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloƒrf\"\n", "ok\ndir \"TB\"\nentity \"Bloƒrf\" id=\"entity-Bloƒrf-0\" label=\"Bloƒrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloƒƒrf\"\n", "ok\ndir \"TB\"\nentity \"Bloƒƒrf\" id=\"entity-Bloƒƒrf-0\" label=\"Bloƒƒrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfƒ\"\n", "ok\ndir \"TB\"\nentity \"Blorfƒ\" id=\"entity-Blorfƒ-0\" label=\"Blorfƒ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÏrf\n", "ok\ndir \"TB\"\nentity \"BloÏrf\" id=\"entity-BloÏrf-0\" label=\"BloÏrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÏrf\"\n", "ok\ndir \"TB\"\nentity \"BloÏrf\" id=\"entity-BloÏrf-0\" label=\"BloÏrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÏÏrf\"\n", "ok\ndir \"TB\"\nentity \"BloÏÏrf\" id=\"entity-BloÏÏrf-0\" label=\"BloÏÏrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÏ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÏ\" id=\"entity-BlorfÏ-0\" label=\"BlorfÏ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo©rf\n", "ok\ndir \"TB\"\nentity \"Blo©rf\" id=\"entity-Blo©rf-0\" label=\"Blo©rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo©rf\"\n", "ok\ndir \"TB\"\nentity \"Blo©rf\" id=\"entity-Blo©rf-0\" label=\"Blo©rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo©©rf\"\n", "ok\ndir \"TB\"\nentity \"Blo©©rf\" id=\"entity-Blo©©rf-0\" label=\"Blo©©rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf©\"\n", "ok\ndir \"TB\"\nentity \"Blorf©\" id=\"entity-Blorf©-0\" label=\"Blorf©\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo˙rf\n", "ok\ndir \"TB\"\nentity \"Blo˙rf\" id=\"entity-Blo˙rf-0\" label=\"Blo˙rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo˙rf\"\n", "ok\ndir \"TB\"\nentity \"Blo˙rf\" id=\"entity-Blo˙rf-0\" label=\"Blo˙rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo˙˙rf\"\n", "ok\ndir \"TB\"\nentity \"Blo˙˙rf\" id=\"entity-Blo˙˙rf-0\" label=\"Blo˙˙rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf˙\"\n", "ok\ndir \"TB\"\nentity \"Blorf˙\" id=\"entity-Blorf˙-0\" label=\"Blorf˙\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÓrf\n", "ok\ndir \"TB\"\nentity \"BloÓrf\" id=\"entity-BloÓrf-0\" label=\"BloÓrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÓrf\"\n", "ok\ndir \"TB\"\nentity \"BloÓrf\" id=\"entity-BloÓrf-0\" label=\"BloÓrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÓÓrf\"\n", "ok\ndir \"TB\"\nentity \"BloÓÓrf\" id=\"entity-BloÓÓrf-0\" label=\"BloÓÓrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÓ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÓ\" id=\"entity-BlorfÓ-0\" label=\"BlorfÓ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo∆rf\n", "ok\ndir \"TB\"\nentity \"Blo∆rf\" id=\"entity-Blo∆rf-0\" label=\"Blo∆rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∆rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∆rf\" id=\"entity-Blo∆rf-0\" label=\"Blo∆rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∆∆rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∆∆rf\" id=\"entity-Blo∆∆rf-0\" label=\"Blo∆∆rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf∆\"\n", "ok\ndir \"TB\"\nentity \"Blorf∆\" id=\"entity-Blorf∆-0\" label=\"Blorf∆\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÔrf\n", "ok\ndir \"TB\"\nentity \"BloÔrf\" id=\"entity-BloÔrf-0\" label=\"BloÔrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÔrf\"\n", "ok\ndir \"TB\"\nentity \"BloÔrf\" id=\"entity-BloÔrf-0\" label=\"BloÔrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÔÔrf\"\n", "ok\ndir \"TB\"\nentity \"BloÔÔrf\" id=\"entity-BloÔÔrf-0\" label=\"BloÔÔrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÔ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÔ\" id=\"entity-BlorfÔ-0\" label=\"BlorfÔ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo˚rf\n", "ok\ndir \"TB\"\nentity \"Blo˚rf\" id=\"entity-Blo˚rf-0\" label=\"Blo˚rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo˚rf\"\n", "ok\ndir \"TB\"\nentity \"Blo˚rf\" id=\"entity-Blo˚rf-0\" label=\"Blo˚rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo˚˚rf\"\n", "ok\ndir \"TB\"\nentity \"Blo˚˚rf\" id=\"entity-Blo˚˚rf-0\" label=\"Blo˚˚rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf˚\"\n", "ok\ndir \"TB\"\nentity \"Blorf˚\" id=\"entity-Blorf˚-0\" label=\"Blorf˚\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blorf\n", "ok\ndir \"TB\"\nentity \"Blorf\" id=\"entity-Blorf-0\" label=\"Blorf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf\"\n", "ok\ndir \"TB\"\nentity \"Blorf\" id=\"entity-Blorf-0\" label=\"Blorf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf\"\n", "ok\ndir \"TB\"\nentity \"Blorf\" id=\"entity-Blorf-0\" label=\"Blorf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf\"\n", "ok\ndir \"TB\"\nentity \"Blorf\" id=\"entity-Blorf-0\" label=\"Blorf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo¬rf\n", "ok\ndir \"TB\"\nentity \"Blo¬rf\" id=\"entity-Blo¬rf-0\" label=\"Blo¬rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¬rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¬rf\" id=\"entity-Blo¬rf-0\" label=\"Blo¬rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¬¬rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¬¬rf\" id=\"entity-Blo¬¬rf-0\" label=\"Blo¬¬rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf¬\"\n", "ok\ndir \"TB\"\nentity \"Blorf¬\" id=\"entity-Blorf¬-0\" label=\"Blorf¬\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÒrf\n", "ok\ndir \"TB\"\nentity \"BloÒrf\" id=\"entity-BloÒrf-0\" label=\"BloÒrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÒrf\"\n", "ok\ndir \"TB\"\nentity \"BloÒrf\" id=\"entity-BloÒrf-0\" label=\"BloÒrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÒÒrf\"\n", "ok\ndir \"TB\"\nentity \"BloÒÒrf\" id=\"entity-BloÒÒrf-0\" label=\"BloÒÒrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÒ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÒ\" id=\"entity-BlorfÒ-0\" label=\"BlorfÒ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo…rf\n", "ok\ndir \"TB\"\nentity \"Blo…rf\" id=\"entity-Blo…rf-0\" label=\"Blo…rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo…rf\"\n", "ok\ndir \"TB\"\nentity \"Blo…rf\" id=\"entity-Blo…rf-0\" label=\"Blo…rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo……rf\"\n", "ok\ndir \"TB\"\nentity \"Blo……rf\" id=\"entity-Blo……rf-0\" label=\"Blo……rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf…\"\n", "ok\ndir \"TB\"\nentity \"Blorf…\" id=\"entity-Blorf…-0\" label=\"Blorf…\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÚrf\n", "ok\ndir \"TB\"\nentity \"BloÚrf\" id=\"entity-BloÚrf-0\" label=\"BloÚrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÚrf\"\n", "ok\ndir \"TB\"\nentity \"BloÚrf\" id=\"entity-BloÚrf-0\" label=\"BloÚrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÚÚrf\"\n", "ok\ndir \"TB\"\nentity \"BloÚÚrf\" id=\"entity-BloÚÚrf-0\" label=\"BloÚÚrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÚ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÚ\" id=\"entity-BlorfÚ-0\" label=\"BlorfÚ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloærf\n", "ok\ndir \"TB\"\nentity \"Bloærf\" id=\"entity-Bloærf-0\" label=\"Bloærf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloærf\"\n", "ok\ndir \"TB\"\nentity \"Bloærf\" id=\"entity-Bloærf-0\" label=\"Bloærf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloæærf\"\n", "ok\ndir \"TB\"\nentity \"Bloæærf\" id=\"entity-Bloæærf-0\" label=\"Bloæærf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfæ\"\n", "ok\ndir \"TB\"\nentity \"Blorfæ\" id=\"entity-Blorfæ-0\" label=\"Blorfæ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÆrf\n", "ok\ndir \"TB\"\nentity \"BloÆrf\" id=\"entity-BloÆrf-0\" label=\"BloÆrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÆrf\"\n", "ok\ndir \"TB\"\nentity \"BloÆrf\" id=\"entity-BloÆrf-0\" label=\"BloÆrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÆÆrf\"\n", "ok\ndir \"TB\"\nentity \"BloÆÆrf\" id=\"entity-BloÆÆrf-0\" label=\"BloÆÆrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÆ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÆ\" id=\"entity-BlorfÆ-0\" label=\"BlorfÆ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloΩrf\n", "ok\ndir \"TB\"\nentity \"BloΩrf\" id=\"entity-BloΩrf-0\" label=\"BloΩrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloΩrf\"\n", "ok\ndir \"TB\"\nentity \"BloΩrf\" id=\"entity-BloΩrf-0\" label=\"BloΩrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloΩΩrf\"\n", "ok\ndir \"TB\"\nentity \"BloΩΩrf\" id=\"entity-BloΩΩrf-0\" label=\"BloΩΩrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfΩ\"\n", "ok\ndir \"TB\"\nentity \"BlorfΩ\" id=\"entity-BlorfΩ-0\" label=\"BlorfΩ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo¸rf\n", "ok\ndir \"TB\"\nentity \"Blo¸rf\" id=\"entity-Blo¸rf-0\" label=\"Blo¸rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¸rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¸rf\" id=\"entity-Blo¸rf-0\" label=\"Blo¸rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¸¸rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¸¸rf\" id=\"entity-Blo¸¸rf-0\" label=\"Blo¸¸rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf¸\"\n", "ok\ndir \"TB\"\nentity \"Blorf¸\" id=\"entity-Blorf¸-0\" label=\"Blorf¸\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo≈rf\n", "ok\ndir \"TB\"\nentity \"Blo≈rf\" id=\"entity-Blo≈rf-0\" label=\"Blo≈rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo≈rf\"\n", "ok\ndir \"TB\"\nentity \"Blo≈rf\" id=\"entity-Blo≈rf-0\" label=\"Blo≈rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo≈≈rf\"\n", "ok\ndir \"TB\"\nentity \"Blo≈≈rf\" id=\"entity-Blo≈≈rf-0\" label=\"Blo≈≈rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf≈\"\n", "ok\ndir \"TB\"\nentity \"Blorf≈\" id=\"entity-Blorf≈-0\" label=\"Blorf≈\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo˛rf\n", "ok\ndir \"TB\"\nentity \"Blo˛rf\" id=\"entity-Blo˛rf-0\" label=\"Blo˛rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo˛rf\"\n", "ok\ndir \"TB\"\nentity \"Blo˛rf\" id=\"entity-Blo˛rf-0\" label=\"Blo˛rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo˛˛rf\"\n", "ok\ndir \"TB\"\nentity \"Blo˛˛rf\" id=\"entity-Blo˛˛rf-0\" label=\"Blo˛˛rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf˛\"\n", "ok\ndir \"TB\"\nentity \"Blorf˛\" id=\"entity-Blorf˛-0\" label=\"Blorf˛\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloçrf\n", "ok\ndir \"TB\"\nentity \"Bloçrf\" id=\"entity-Bloçrf-0\" label=\"Bloçrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloçrf\"\n", "ok\ndir \"TB\"\nentity \"Bloçrf\" id=\"entity-Bloçrf-0\" label=\"Bloçrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloççrf\"\n", "ok\ndir \"TB\"\nentity \"Bloççrf\" id=\"entity-Bloççrf-0\" label=\"Bloççrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfç\"\n", "ok\ndir \"TB\"\nentity \"Blorfç\" id=\"entity-Blorfç-0\" label=\"Blorfç\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÇrf\n", "ok\ndir \"TB\"\nentity \"BloÇrf\" id=\"entity-BloÇrf-0\" label=\"BloÇrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÇrf\"\n", "ok\ndir \"TB\"\nentity \"BloÇrf\" id=\"entity-BloÇrf-0\" label=\"BloÇrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÇÇrf\"\n", "ok\ndir \"TB\"\nentity \"BloÇÇrf\" id=\"entity-BloÇÇrf-0\" label=\"BloÇÇrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÇ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÇ\" id=\"entity-BlorfÇ-0\" label=\"BlorfÇ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo√rf\n", "ok\ndir \"TB\"\nentity \"Blo√rf\" id=\"entity-Blo√rf-0\" label=\"Blo√rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo√rf\"\n", "ok\ndir \"TB\"\nentity \"Blo√rf\" id=\"entity-Blo√rf-0\" label=\"Blo√rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo√√rf\"\n", "ok\ndir \"TB\"\nentity \"Blo√√rf\" id=\"entity-Blo√√rf-0\" label=\"Blo√√rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf√\"\n", "ok\ndir \"TB\"\nentity \"Blorf√\" id=\"entity-Blorf√-0\" label=\"Blorf√\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo◊rf\n", "ok\ndir \"TB\"\nentity \"Blo◊rf\" id=\"entity-Blo◊rf-0\" label=\"Blo◊rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo◊rf\"\n", "ok\ndir \"TB\"\nentity \"Blo◊rf\" id=\"entity-Blo◊rf-0\" label=\"Blo◊rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo◊◊rf\"\n", "ok\ndir \"TB\"\nentity \"Blo◊◊rf\" id=\"entity-Blo◊◊rf-0\" label=\"Blo◊◊rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf◊\"\n", "ok\ndir \"TB\"\nentity \"Blorf◊\" id=\"entity-Blorf◊-0\" label=\"Blorf◊\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo∫rf\n", "ok\ndir \"TB\"\nentity \"Blo∫rf\" id=\"entity-Blo∫rf-0\" label=\"Blo∫rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∫rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∫rf\" id=\"entity-Blo∫rf-0\" label=\"Blo∫rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo∫∫rf\"\n", "ok\ndir \"TB\"\nentity \"Blo∫∫rf\" id=\"entity-Blo∫∫rf-0\" label=\"Blo∫∫rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf∫\"\n", "ok\ndir \"TB\"\nentity \"Blorf∫\" id=\"entity-Blorf∫-0\" label=\"Blorf∫\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloırf\n", "ok\ndir \"TB\"\nentity \"Bloırf\" id=\"entity-Bloırf-0\" label=\"Bloırf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloırf\"\n", "ok\ndir \"TB\"\nentity \"Bloırf\" id=\"entity-Bloırf-0\" label=\"Bloırf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloıırf\"\n", "ok\ndir \"TB\"\nentity \"Bloıırf\" id=\"entity-Bloıırf-0\" label=\"Bloıırf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfı\"\n", "ok\ndir \"TB\"\nentity \"Blorfı\" id=\"entity-Blorfı-0\" label=\"Blorfı\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo˜rf\n", "ok\ndir \"TB\"\nentity \"Blo˜rf\" id=\"entity-Blo˜rf-0\" label=\"Blo˜rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo˜rf\"\n", "ok\ndir \"TB\"\nentity \"Blo˜rf\" id=\"entity-Blo˜rf-0\" label=\"Blo˜rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo˜˜rf\"\n", "ok\ndir \"TB\"\nentity \"Blo˜˜rf\" id=\"entity-Blo˜˜rf-0\" label=\"Blo˜˜rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf˜\"\n", "ok\ndir \"TB\"\nentity \"Blorf˜\" id=\"entity-Blorf˜-0\" label=\"Blorf˜\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Bloµrf\n", "ok\ndir \"TB\"\nentity \"Bloµrf\" id=\"entity-Bloµrf-0\" label=\"Bloµrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloµrf\"\n", "ok\ndir \"TB\"\nentity \"Bloµrf\" id=\"entity-Bloµrf-0\" label=\"Bloµrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Bloµµrf\"\n", "ok\ndir \"TB\"\nentity \"Bloµµrf\" id=\"entity-Bloµµrf-0\" label=\"Bloµµrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorfµ\"\n", "ok\ndir \"TB\"\nentity \"Blorfµ\" id=\"entity-Blorfµ-0\" label=\"Blorfµ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n BloÂrf\n", "ok\ndir \"TB\"\nentity \"BloÂrf\" id=\"entity-BloÂrf-0\" label=\"BloÂrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÂrf\"\n", "ok\ndir \"TB\"\nentity \"BloÂrf\" id=\"entity-BloÂrf-0\" label=\"BloÂrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BloÂÂrf\"\n", "ok\ndir \"TB\"\nentity \"BloÂÂrf\" id=\"entity-BloÂÂrf-0\" label=\"BloÂÂrf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"BlorfÂ\"\n", "ok\ndir \"TB\"\nentity \"BlorfÂ\" id=\"entity-BlorfÂ-0\" label=\"BlorfÂ\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo≤rf\n", "ok\ndir \"TB\"\nentity \"Blo≤rf\" id=\"entity-Blo≤rf-0\" label=\"Blo≤rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo≤rf\"\n", "ok\ndir \"TB\"\nentity \"Blo≤rf\" id=\"entity-Blo≤rf-0\" label=\"Blo≤rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo≤≤rf\"\n", "ok\ndir \"TB\"\nentity \"Blo≤≤rf\" id=\"entity-Blo≤≤rf-0\" label=\"Blo≤≤rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf≤\"\n", "ok\ndir \"TB\"\nentity \"Blorf≤\" id=\"entity-Blorf≤-0\" label=\"Blorf≤\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo¯rf\n", "ok\ndir \"TB\"\nentity \"Blo¯rf\" id=\"entity-Blo¯rf-0\" label=\"Blo¯rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¯rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¯rf\" id=\"entity-Blo¯rf-0\" label=\"Blo¯rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¯¯rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¯¯rf\" id=\"entity-Blo¯¯rf-0\" label=\"Blo¯¯rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf¯\"\n", "ok\ndir \"TB\"\nentity \"Blorf¯\" id=\"entity-Blorf¯-0\" label=\"Blorf¯\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo≥rf\n", "ok\ndir \"TB\"\nentity \"Blo≥rf\" id=\"entity-Blo≥rf-0\" label=\"Blo≥rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo≥rf\"\n", "ok\ndir \"TB\"\nentity \"Blo≥rf\" id=\"entity-Blo≥rf-0\" label=\"Blo≥rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo≥≥rf\"\n", "ok\ndir \"TB\"\nentity \"Blo≥≥rf\" id=\"entity-Blo≥≥rf-0\" label=\"Blo≥≥rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf≥\"\n", "ok\ndir \"TB\"\nentity \"Blorf≥\" id=\"entity-Blorf≥-0\" label=\"Blorf≥\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo˘rf\n", "ok\ndir \"TB\"\nentity \"Blo˘rf\" id=\"entity-Blo˘rf-0\" label=\"Blo˘rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo˘rf\"\n", "ok\ndir \"TB\"\nentity \"Blo˘rf\" id=\"entity-Blo˘rf-0\" label=\"Blo˘rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo˘˘rf\"\n", "ok\ndir \"TB\"\nentity \"Blo˘˘rf\" id=\"entity-Blo˘˘rf-0\" label=\"Blo˘˘rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf˘\"\n", "ok\ndir \"TB\"\nentity \"Blorf˘\" id=\"entity-Blorf˘-0\" label=\"Blorf˘\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo÷rf\n", "ok\ndir \"TB\"\nentity \"Blo÷rf\" id=\"entity-Blo÷rf-0\" label=\"Blo÷rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo÷rf\"\n", "ok\ndir \"TB\"\nentity \"Blo÷rf\" id=\"entity-Blo÷rf-0\" label=\"Blo÷rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo÷÷rf\"\n", "ok\ndir \"TB\"\nentity \"Blo÷÷rf\" id=\"entity-Blo÷÷rf-0\" label=\"Blo÷÷rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf÷\"\n", "ok\ndir \"TB\"\nentity \"Blorf÷\" id=\"entity-Blorf÷-0\" label=\"Blorf÷\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n Blo¿rf\n", "ok\ndir \"TB\"\nentity \"Blo¿rf\" id=\"entity-Blo¿rf-0\" label=\"Blo¿rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¿rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¿rf\" id=\"entity-Blo¿rf-0\" label=\"Blo¿rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo¿¿rf\"\n", "ok\ndir \"TB\"\nentity \"Blo¿¿rf\" id=\"entity-Blo¿¿rf-0\" label=\"Blo¿¿rf\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blorf¿\"\n", "ok\ndir \"TB\"\nentity \"Blorf¿\" id=\"entity-Blorf¿-0\" label=\"Blorf¿\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"a~`!@#$^&*()-=+[]{}|/;:'.?¡⁄™€£‹¢›∞ﬁ§‡•°ª·º‚≠±œŒ∑„®†ˇ¥Á¨ˆˆØπ∏“«»åÅßÍ∂ÎƒÏ©˙Ó∆Ô˚¬Ò…ÚæÆΩ¸≈π˛çÇ√◊∫ı˜µÂ≤¯≥˘÷¿\"\n",
    "ok\ndir \"TB\"\nentity \"a~`!@#$^&*()-=+[]{}|/;:'.?¡⁄™€£‹¢›∞ﬁ§‡•°ª·º‚≠±œŒ∑„®†ˇ¥Á¨ˆˆØπ∏“«»åÅßÍ∂ÎƒÏ©˙Ó∆Ô˚¬Ò…ÚæÆΩ¸≈π˛çÇ√◊∫ı˜µÂ≤¯≥˘÷¿\" id=\"entity-a~`!@#$^&*()-=+[]{}|/;:'.?¡⁄™€£‹¢›∞ﬁ§‡•°ª·º‚≠±œŒ∑„®†ˇ¥Á¨ˆˆØπ∏“«»åÅßÍ∂ÎƒÏ©˙Ó∆Ô˚¬Ò…ÚæÆΩ¸≈π˛çÇ√◊∫ı˜µÂ≤¯≥˘÷¿-0\" label=\"a~`!@#$^&*()-=+[]{}|/;:'.?¡⁄™€£‹¢›∞ﬁ§‡•°ª·º‚≠±œŒ∑„®†ˇ¥Á¨ˆˆØπ∏“«»åÅßÍ∂ÎƒÏ©˙Ó∆Ô˚¬Ò…ÚæÆΩ¸≈π˛çÇ√◊∫ı˜µÂ≤¯≥˘÷¿\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\n \"Blo%rf\"\n", "error syntax 2:2\nParse error on line 2:\n \"Blo%rf\"\n-^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got 'WORD'",
  ),
  (
    "erDiagram\n \"Blo\\rf\"\n", "error syntax 2:2\nParse error on line 2:\n \"Blo\\rf\"\n-^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got 'WORD'",
  ),
  (
    "erDiagram\n \"Blo\nrf\"\n", "error syntax 2:2\nParse error on line 2:\n \"Blo\n-^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got 'WORD'",
  ),
  (
    "erDiagram\n \"Blo\rrf\"\n", "error syntax 2:2\nParse error on line 2:\n \"Blo\rrf\"\n-^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got 'WORD'",
  ),
  (
    "erDiagram\n \"Blo\u{8}rf\"\n", "error syntax 2:2\nParse error on line 2:\n \"Blo\u{8}rf\"\n-^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got 'WORD'",
  ),
  (
    "erDiagram\n \"Blo\u{b}rf\"\n", "error syntax 2:2\nParse error on line 2:\n \"Blo\u{b}rf\"\n-^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got 'WORD'",
  ),
  (
    "erDiagram\nDUCK-BILLED_PLATYPUS\n", "ok\ndir \"TB\"\nentity \"DUCK-BILLED_PLATYPUS\" id=\"entity-DUCK-BILLED_PLATYPUS-0\" label=\"DUCK-BILLED_PLATYPUS\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\nfoo[\"bar\"]\n", "ok\ndir \"TB\"\nentity \"foo\" id=\"entity-foo-0\" label=\"foo\" alias=\"bar\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\nfoo ||--o| bar : rel\nbuzz foo[\"batman\"]\n", "ok\ndir \"TB\"\nentity \"foo\" id=\"entity-foo-0\" label=\"foo\" alias=\"batman\" classes=\"default\" styles=[]\nentity \"bar\" id=\"entity-bar-1\" label=\"bar\" alias=\"\" classes=\"default\" styles=[]\nentity \"buzz\" id=\"entity-buzz-2\" label=\"buzz\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-foo-0\" \"rel\" \"entity-bar-1\" ZERO_OR_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nbuzz foo[\"batman\"]\nfoo ||--o| bar : rel\n", "ok\ndir \"TB\"\nentity \"buzz\" id=\"entity-buzz-0\" label=\"buzz\" alias=\"\" classes=\"default\" styles=[]\nentity \"foo\" id=\"entity-foo-1\" label=\"foo\" alias=\"batman\" classes=\"default\" styles=[]\nentity \"bar\" id=\"entity-bar-2\" label=\"bar\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-foo-1\" \"rel\" \"entity-bar-2\" ZERO_OR_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\n_foo\n", "ok\ndir \"TB\"\nentity \"_foo\" id=\"entity-_foo-0\" label=\"_foo\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\nBOOK {\nstring myBookTitle\nstring MYBOOKSUBTITLE_1\nstring author-ref[name](1)\n}",
    "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"myBookTitle\" keys=[] comment=\"\"\n  attr \"string\" \"MYBOOKSUBTITLE_1\" keys=[] comment=\"\"\n  attr \"string\" \"author-ref[name](1)\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nBOOK{\nstring *title}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"*title\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nBOOK {\nid *the_Primary_Key}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"id\" \"*the_Primary_Key\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nBUILDING {\npublic.geometry(point,4326) location}", "ok\ndir \"TB\"\nentity \"BUILDING\" id=\"entity-BUILDING-0\" label=\"BUILDING\" alias=\"\" classes=\"default\" styles=[]\n  attr \"public.geometry(point,4326)\" \"location\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nBOOK {\nstring 0author\n}", "error syntax 3:8\nParse error on line 3:\nstring 0author\n-------^\nExpecting 'ATTRIBUTE_WORD', '?', got '0'",
  ),
  (
    "erDiagram\nBOOK {\nstring -author\n}", "error syntax 3:8\nParse error on line 3:\nstring -author\n-------^\nExpecting 'ATTRIBUTE_WORD', '?', got '-'",
  ),
  (
    "erDiagram\nBOOK {\nstring [author\n}", "error syntax 3:8\nParse error on line 3:\nstring [author\n-------^\nExpecting 'ATTRIBUTE_WORD', '?', got '['",
  ),
  (
    "erDiagram\nBOOK {\nstring ]author\n}", "error syntax 3:8\nParse error on line 3:\nstring ]author\n-------^\nExpecting 'ATTRIBUTE_WORD', '?', got ']'",
  ),
  (
    "erDiagram\nBOOK {\nstring (author\n}", "error syntax 3:8\nParse error on line 3:\nstring (author\n-------^\nExpecting 'ATTRIBUTE_WORD', '?', got '('",
  ),
  (
    "erDiagram\nBOOK {\nstring )author\n}", "error syntax 3:8\nParse error on line 3:\nstring )author\n-------^\nExpecting 'ATTRIBUTE_WORD', '?', got ')'",
  ),
  (
    "erDiagram\nHOTEL {\nstring `geo.accuracy`\n}", "ok\ndir \"TB\"\nentity \"HOTEL\" id=\"entity-HOTEL-0\" label=\"HOTEL\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"geo.accuracy\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nHOTEL {\nstring `geo.accuracy` PK \"the comment\"\n}", "ok\ndir \"TB\"\nentity \"HOTEL\" id=\"entity-HOTEL-0\" label=\"HOTEL\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"geo.accuracy\" keys=[\"PK\"] comment=\"the comment\"",
  ),
  (
    "erDiagram\nHOTEL {\n`my.type` address\n}", "ok\ndir \"TB\"\nentity \"HOTEL\" id=\"entity-HOTEL-0\" label=\"HOTEL\" alias=\"\" classes=\"default\" styles=[]\n  attr \"my.type\" \"address\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nPERSON {\nstring? alias\n}", "ok\ndir \"TB\"\nentity \"PERSON\" id=\"entity-PERSON-0\" label=\"PERSON\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string?\" \"alias\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nPERSON {\nstring? alias UK \"optional display name\"\n}", "ok\ndir \"TB\"\nentity \"PERSON\" id=\"entity-PERSON-0\" label=\"PERSON\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string?\" \"alias\" keys=[\"UK\"] comment=\"optional display name\"",
  ),
  (
    "erDiagram\nBOOK {\nstring title\n}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"title\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nBOOK {\nstring title PK\n}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"title\" keys=[\"PK\"] comment=\"\"",
  ),
  (
    "erDiagram\nBOOK {\nstring title \"comment\"\n}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"title\" keys=[] comment=\"comment\"",
  ),
  (
    "erDiagram\nBOOK {\nstring title PK \"comment\"\n}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"title\" keys=[\"PK\"] comment=\"comment\"",
  ),
  (
    "erDiagram\nBOOK {\nint fk_title FK \n\nstring pk_author PK\nstring uk_address UK\nfloat pk_price PK \"comment\"\n}",
    "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"int\" \"fk_title\" keys=[\"FK\"] comment=\"\"\n  attr \"string\" \"pk_author\" keys=[\"PK\"] comment=\"\"\n  attr \"string\" \"uk_address\" keys=[\"UK\"] comment=\"\"\n  attr \"float\" \"pk_price\" keys=[\"PK\"] comment=\"comment\"",
  ),
  (
    "erDiagram\nCUSTOMER {\nint customer_number PK, FK \"comment1\"\ndatetime customer_status_start_datetime PK,UK, FK\ndatetime customer_status_end_datetime PK , UK \"comment3\"\nstring customer_firstname\nstring customer_lastname \"comment5\"\n}",
    "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\n  attr \"int\" \"customer_number\" keys=[\"PK\",\"FK\"] comment=\"comment1\"\n  attr \"datetime\" \"customer_status_start_datetime\" keys=[\"PK\",\"UK\",\"FK\"] comment=\"\"\n  attr \"datetime\" \"customer_status_end_datetime\" keys=[\"PK\",\"UK\"] comment=\"comment3\"\n  attr \"string\" \"customer_firstname\" keys=[] comment=\"\"\n  attr \"string\" \"customer_lastname\" keys=[] comment=\"comment5\"",
  ),
  (
    "erDiagram\nBOOK {\ntype~T~ type\noption~T~ readable \"comment\"\nstring id PK\n}",
    "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"type~T~\" \"type\" keys=[] comment=\"\"\n  attr \"option~T~\" \"readable\" keys=[] comment=\"comment\"\n  attr \"string\" \"id\" keys=[\"PK\"] comment=\"\"",
  ),
  (
    "erDiagram\nBOOK {\nstring[] readers FK \"comment\"\nstring[] authors FK\n}",
    "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string[]\" \"readers\" keys=[\"FK\"] comment=\"comment\"\n  attr \"string[]\" \"authors\" keys=[\"FK\"] comment=\"\"",
  ),
  (
    "erDiagram\nBOOK {\ncharacter(10) isbn FK\nvarchar(5) postal_code \"Five digits\"\n}",
    "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"character(10)\" \"isbn\" keys=[\"FK\"] comment=\"\"\n  attr \"varchar(5)\" \"postal_code\" keys=[] comment=\"Five digits\"",
  ),
  (
    "erDiagram\nBOOK {\nstring title\nstring author\nfloat price\n}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"title\" keys=[] comment=\"\"\n  attr \"string\" \"author\" keys=[] comment=\"\"\n  attr \"float\" \"price\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nBOOK {\nstring title\n}\nBOOK {\nstring author\nfloat price\n}",
    "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"title\" keys=[] comment=\"\"\n  attr \"string\" \"author\" keys=[] comment=\"\"\n  attr \"float\" \"price\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nBOOK {}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\nBOOK{}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\nBOOK         {}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]",
  ),
  (
    "erDiagram\nBOOK {\n  \n\n  string title\n\n  \n}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"title\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nBOOK{string title}", "ok\ndir \"TB\"\nentity \"BOOK\" id=\"entity-BOOK-0\" label=\"BOOK\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"title\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nCAR ||--o{ DRIVER : \"insured for\"", "ok\ndir \"TB\"\nentity \"CAR\" id=\"entity-CAR-0\" label=\"CAR\" alias=\"\" classes=\"default\" styles=[]\nentity \"DRIVER\" id=\"entity-DRIVER-1\" label=\"DRIVER\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CAR-0\" \"insured for\" \"entity-DRIVER-1\" ZERO_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nCAR ||--o{ DRIVER : \"insured for\"\nDRIVER ||--|| LICENSE : has",
    "ok\ndir \"TB\"\nentity \"CAR\" id=\"entity-CAR-0\" label=\"CAR\" alias=\"\" classes=\"default\" styles=[]\nentity \"DRIVER\" id=\"entity-DRIVER-1\" label=\"DRIVER\" alias=\"\" classes=\"default\" styles=[]\nentity \"LICENSE\" id=\"entity-LICENSE-2\" label=\"LICENSE\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CAR-0\" \"insured for\" \"entity-DRIVER-1\" ZERO_OR_MORE IDENTIFYING ONLY_ONE\nrel \"entity-DRIVER-1\" \"has\" \"entity-LICENSE-2\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nTEACHER }o--o{ STUDENT : \"is teacher of\"", "ok\ndir \"TB\"\nentity \"TEACHER\" id=\"entity-TEACHER-0\" label=\"TEACHER\" alias=\"\" classes=\"default\" styles=[]\nentity \"STUDENT\" id=\"entity-STUDENT-1\" label=\"STUDENT\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-TEACHER-0\" \"is teacher of\" \"entity-STUDENT-1\" ZERO_OR_MORE IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nNODE ||--o{ NODE : \"leads to\"", "ok\ndir \"TB\"\nentity \"NODE\" id=\"entity-NODE-0\" label=\"NODE\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-NODE-0\" \"leads to\" \"entity-NODE-0\" ZERO_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\n      accTitle: graph title\n      accDescr: this graph is about stuff\n      TEACHER }o--o{ STUDENT : \"is teacher of\"",
    "ok\ndir \"TB\"\naccTitle \"graph title\"\naccDescr \"this graph is about stuff\"\nentity \"TEACHER\" id=\"entity-TEACHER-0\" label=\"TEACHER\" alias=\"\" classes=\"default\" styles=[]\nentity \"STUDENT\" id=\"entity-STUDENT-1\" label=\"STUDENT\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-TEACHER-0\" \"is teacher of\" \"entity-STUDENT-1\" ZERO_OR_MORE IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\n      accTitle: graph title\n      accDescr { this graph is\n        about\n        stuff\n        }\n\n      TEACHER }o--o{ STUDENT : \"is teacher of\"",
    "ok\ndir \"TB\"\naccTitle \"graph title\"\naccDescr \"this graph is\\nabout\\nstuff\"\nentity \"TEACHER\" id=\"entity-TEACHER-0\" label=\"TEACHER\" alias=\"\" classes=\"default\" styles=[]\nentity \"STUDENT\" id=\"entity-STUDENT-1\" label=\"STUDENT\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-TEACHER-0\" \"is teacher of\" \"entity-STUDENT-1\" ZERO_OR_MORE IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nCAR ||--o{ PERSON : \"insured for\"\nCAR }o--|| PERSON : \"owned by\"",
    "ok\ndir \"TB\"\nentity \"CAR\" id=\"entity-CAR-0\" label=\"CAR\" alias=\"\" classes=\"default\" styles=[]\nentity \"PERSON\" id=\"entity-PERSON-1\" label=\"PERSON\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CAR-0\" \"insured for\" \"entity-PERSON-1\" ZERO_OR_MORE IDENTIFYING ONLY_ONE\nrel \"entity-CAR-0\" \"owned by\" \"entity-PERSON-1\" ONLY_ONE IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nA ||--|{ B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONE_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nA ||..o{ B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ZERO_OR_MORE NON_IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nA |o..o{ B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ZERO_OR_MORE NON_IDENTIFYING ZERO_OR_ONE",
  ),
  (
    "erDiagram\nA |o--|{ B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONE_OR_MORE IDENTIFYING ZERO_OR_ONE",
  ),
  (
    "erDiagram\nA }|--|| B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONLY_ONE IDENTIFYING ONE_OR_MORE",
  ),
  (
    "erDiagram\nA }o--|| B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONLY_ONE IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nA }o..o| B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ZERO_OR_ONE NON_IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nA }|..o| B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ZERO_OR_ONE NON_IDENTIFYING ONE_OR_MORE",
  ),
  (
    "erDiagram\nA |o..|| B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONLY_ONE NON_IDENTIFYING ZERO_OR_ONE",
  ),
  (
    "erDiagram\nA ||..|| B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONLY_ONE NON_IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nA ||--o| B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ZERO_OR_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nA |o..o| B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ZERO_OR_ONE NON_IDENTIFYING ZERO_OR_ONE",
  ),
  (
    "erDiagram\nA }o--o{ B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ZERO_OR_MORE IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nA }|..|{ B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONE_OR_MORE NON_IDENTIFYING ONE_OR_MORE",
  ),
  (
    "erDiagram\nA }o--|{ B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONE_OR_MORE IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nA }|..o{ B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ZERO_OR_MORE NON_IDENTIFYING ONE_OR_MORE",
  ),
  (
    "erDiagram\nA one or zero to many B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ZERO_OR_MORE IDENTIFYING ZERO_OR_ONE",
  ),
  (
    "erDiagram\nA one or many optionally to zero or one B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ZERO_OR_ONE NON_IDENTIFYING ONE_OR_MORE",
  ),
  (
    "erDiagram\nA zero or more to zero or many B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ZERO_OR_MORE IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nA many(0) to many(1) B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONE_OR_MORE IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nA many optionally to one B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONLY_ONE NON_IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nA only one optionally to 1+ B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONE_OR_MORE NON_IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nA 0+ optionally to 1 B : has", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"has\" \"entity-B-1\" ONLY_ONE NON_IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nCUSTOMER 1--one or more DELIVERY-ADDRESS : has", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"DELIVERY-ADDRESS\" id=\"entity-DELIVERY-ADDRESS-1\" label=\"DELIVERY-ADDRESS\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-DELIVERY-ADDRESS-1\" ONE_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nCUSTOMER 1..one or more DELIVERY-ADDRESS : has", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"DELIVERY-ADDRESS\" id=\"entity-DELIVERY-ADDRESS-1\" label=\"DELIVERY-ADDRESS\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-DELIVERY-ADDRESS-1\" ONE_OR_MORE NON_IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nCUSTOMER 1.-one or more DELIVERY-ADDRESS : has", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"DELIVERY-ADDRESS\" id=\"entity-DELIVERY-ADDRESS-1\" label=\"DELIVERY-ADDRESS\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-DELIVERY-ADDRESS-1\" ONE_OR_MORE NON_IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nCUSTOMER 1-.one or more DELIVERY-ADDRESS : has", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"DELIVERY-ADDRESS\" id=\"entity-DELIVERY-ADDRESS-1\" label=\"DELIVERY-ADDRESS\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-DELIVERY-ADDRESS-1\" ONE_OR_MORE NON_IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\na many to 1 1: label", "ok\ndir \"TB\"\nentity \"a\" id=\"entity-a-0\" label=\"a\" alias=\"\" classes=\"default\" styles=[]\nentity \"1\" id=\"entity-1-1\" label=\"1\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-a-0\" \"label\" \"entity-1-1\" ONLY_ONE IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\na many to 1 12: label", "ok\ndir \"TB\"\nentity \"a\" id=\"entity-a-0\" label=\"a\" alias=\"\" classes=\"default\" styles=[]\nentity \"12\" id=\"entity-12-1\" label=\"12\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-a-0\" \"label\" \"entity-12-1\" ONLY_ONE IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nHOUSE ||--|{ ROOM : contains", "ok\ndir \"TB\"\nentity \"HOUSE\" id=\"entity-HOUSE-0\" label=\"HOUSE\" alias=\"\" classes=\"default\" styles=[]\nentity \"ROOM\" id=\"entity-ROOM-1\" label=\"ROOM\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-HOUSE-0\" \"contains\" \"entity-ROOM-1\" ONE_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nHOUSE one to one ROOM : contains", "ok\ndir \"TB\"\nentity \"HOUSE\" id=\"entity-HOUSE-0\" label=\"HOUSE\" alias=\"\" classes=\"default\" styles=[]\nentity \"ROOM\" id=\"entity-ROOM-1\" label=\"ROOM\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-HOUSE-0\" \"contains\" \"entity-ROOM-1\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\n PERSON ||..o{ POSSESSION : owns", "ok\ndir \"TB\"\nentity \"PERSON\" id=\"entity-PERSON-0\" label=\"PERSON\" alias=\"\" classes=\"default\" styles=[]\nentity \"POSSESSION\" id=\"entity-POSSESSION-1\" label=\"POSSESSION\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-PERSON-0\" \"owns\" \"entity-POSSESSION-1\" ZERO_OR_MORE NON_IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\n PERSON many optionally to many POSSESSION : owns", "ok\ndir \"TB\"\nentity \"PERSON\" id=\"entity-PERSON-0\" label=\"PERSON\" alias=\"\" classes=\"default\" styles=[]\nentity \"POSSESSION\" id=\"entity-POSSESSION-1\" label=\"POSSESSION\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-PERSON-0\" \"owns\" \"entity-POSSESSION-1\" ZERO_OR_MORE NON_IDENTIFYING ZERO_OR_MORE",
  ),
  (
    "erDiagram\nA xxx B : has", "error syntax 2:9\nParse error on line 2:\nA xxx B : has\n--------^\nExpecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got 'COLON'",
  ),
  (
    "erDiagram\n        CUSTOMER\n        style CUSTOMER color:red\n      ", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[\"color:red\"]",
  ),
  (
    "erDiagram\n        CUSTOMER\n        style CUSTOMER color:red,stroke:blue,fill:#f9f\n      ",
    "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[\"color:red\",\"stroke:blue\",\"fill:#f9f\"]",
  ),
  (
    "erDiagram\n        CUSTOMER\n        style CUSTOMER color:red\n        style CUSTOMER fill:#f9f\n      ",
    "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[\"color:red\",\"fill:#f9f\"]",
  ),
  (
    "erDiagram\nCUSTOMER\nclass CUSTOMER myClass", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default myClass\" styles=[]",
  ),
  (
    "erDiagram\nCUSTOMER\nclass CUSTOMER firstClass, secondClass, thirdClass", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default firstClass secondClass thirdClass\" styles=[]",
  ),
  (
    "erDiagram\nCUSTOMER\nclass CUSTOMER firstClass\nclass CUSTOMER secondClass",
    "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default firstClass secondClass\" styles=[]",
  ),
  (
    "erDiagram\n        ENTITY1\n        ENTITY2\n        classDef default fill:#f9f\n      ",
    "ok\ndir \"TB\"\nentity \"ENTITY1\" id=\"entity-ENTITY1-0\" label=\"ENTITY1\" alias=\"\" classes=\"default\" styles=[]\nentity \"ENTITY2\" id=\"entity-ENTITY2-1\" label=\"ENTITY2\" alias=\"\" classes=\"default\" styles=[]\nclass \"default\" styles=[\"fill:#f9f\"] text=[]",
  ),
  (
    "erDiagram\n        classDef myClass fill:#f9f, stroke: red, color: pink\n      ",
    "ok\ndir \"TB\"\nclass \"myClass\" styles=[\"fill:#f9f\",\"stroke:red\",\"color:pink\"] text=[\"color:pink\"]",
  ),
  (
    "erDiagram\n        classDef firstClass,secondClass fill:#f9f, stroke: red, color: pink\n       ",
    "ok\ndir \"TB\"\nclass \"firstClass\" styles=[\"fill:#f9f\",\"stroke:red\",\"color:pink\"] text=[\"color:pink\"]\nclass \"secondClass\" styles=[\"fill:#f9f\",\"stroke:red\",\"color:pink\"] text=[\"color:pink\"]",
  ),
  (
    "erDiagram\nCUSTOMER:::myClass", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default myClass\" styles=[]",
  ),
  (
    "erDiagram\nCUSTOMER:::myClass {}", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default myClass\" styles=[]",
  ),
  (
    "erDiagram\nCUSTOMER:::myClass {\nstring name\n}", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default myClass\" styles=[]\n  attr \"string\" \"name\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nCUSTOMER:::firstClass,secondClass", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default firstClass secondClass\" styles=[]",
  ),
  (
    "erDiagram\nc[CUSTOMER]:::myClass", "ok\ndir \"TB\"\nentity \"c\" id=\"entity-c-0\" label=\"c\" alias=\"CUSTOMER\" classes=\"default myClass\" styles=[]",
  ),
  (
    "erDiagram\nCUSTOMER:::myClass ||--o{ PERSON:::myClass : allows", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default myClass\" styles=[]\nentity \"PERSON\" id=\"entity-PERSON-1\" label=\"PERSON\" alias=\"\" classes=\"default myClass\" styles=[]\nrel \"entity-CUSTOMER-0\" \"allows\" \"entity-PERSON-1\" ZERO_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nCUSTOMER ||--|{ ORDER : \"\"", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"ORDER\" id=\"entity-ORDER-1\" label=\"ORDER\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"\" \"entity-ORDER-1\" ONE_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nCUSTOMER ||--|{ ORDER : \"places\"", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"ORDER\" id=\"entity-ORDER-1\" label=\"ORDER\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"places\" \"entity-ORDER-1\" ONE_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nCUSTOMER ||--|{ ORDER : places", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"ORDER\" id=\"entity-ORDER-1\" label=\"ORDER\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"places\" \"entity-ORDER-1\" ONE_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nPROJECT u--o{ TEAM_MEMBER : \"parent\"", "ok\ndir \"TB\"\nentity \"PROJECT\" id=\"entity-PROJECT-0\" label=\"PROJECT\" alias=\"\" classes=\"default\" styles=[]\nentity \"TEAM_MEMBER\" id=\"entity-TEAM_MEMBER-1\" label=\"TEAM_MEMBER\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-PROJECT-0\" \"parent\" \"entity-TEAM_MEMBER-1\" ZERO_OR_MORE IDENTIFYING MD_PARENT",
  ),
  (
    "erDiagram\n__proto__ ||--|{ ORDER : place", "ok\ndir \"TB\"\nentity \"__proto__\" id=\"entity-__proto__-0\" label=\"__proto__\" alias=\"\" classes=\"default\" styles=[]\nentity \"ORDER\" id=\"entity-ORDER-1\" label=\"ORDER\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-__proto__-0\" \"place\" \"entity-ORDER-1\" ONE_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nconstructor ||--|{ ORDER : place", "ok\ndir \"TB\"\nentity \"constructor\" id=\"entity-constructor-0\" label=\"constructor\" alias=\"\" classes=\"default\" styles=[]\nentity \"ORDER\" id=\"entity-ORDER-1\" label=\"ORDER\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-constructor-0\" \"place\" \"entity-ORDER-1\" ONE_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nprototype ||--|{ ORDER : place", "ok\ndir \"TB\"\nentity \"prototype\" id=\"entity-prototype-0\" label=\"prototype\" alias=\"\" classes=\"default\" styles=[]\nentity \"ORDER\" id=\"entity-ORDER-1\" label=\"ORDER\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-prototype-0\" \"place\" \"entity-ORDER-1\" ONE_OR_MORE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nCUSTOMER }|..|{ DELIVERY-ADDRESS : has\n1", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"DELIVERY-ADDRESS\" id=\"entity-DELIVERY-ADDRESS-1\" label=\"DELIVERY-ADDRESS\" alias=\"\" classes=\"default\" styles=[]\nentity \"1\" id=\"entity-1-2\" label=\"1\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-DELIVERY-ADDRESS-1\" ONE_OR_MORE NON_IDENTIFYING ONE_OR_MORE",
  ),
  (
    "erDiagram\nCUSTOMER }|..|{ DELIVERY-ADDRESS : has\nu", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"DELIVERY-ADDRESS\" id=\"entity-DELIVERY-ADDRESS-1\" label=\"DELIVERY-ADDRESS\" alias=\"\" classes=\"default\" styles=[]\nentity \"u\" id=\"entity-u-2\" label=\"u\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-DELIVERY-ADDRESS-1\" ONE_OR_MORE NON_IDENTIFYING ONE_OR_MORE",
  ),
  (
    "erDiagram\nCUSTOMER }|..|{ DELIVERY-ADDRESS : has\n2.5", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"DELIVERY-ADDRESS\" id=\"entity-DELIVERY-ADDRESS-1\" label=\"DELIVERY-ADDRESS\" alias=\"\" classes=\"default\" styles=[]\nentity \"2.5\" id=\"entity-2.5-2\" label=\"2.5\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-DELIVERY-ADDRESS-1\" ONE_OR_MORE NON_IDENTIFYING ONE_OR_MORE",
  ),
  (
    "erDiagram\nCUSTOMER }|..|{ DELIVERY-ADDRESS : has\n1.5", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"DELIVERY-ADDRESS\" id=\"entity-DELIVERY-ADDRESS-1\" label=\"DELIVERY-ADDRESS\" alias=\"\" classes=\"default\" styles=[]\nentity \"1.5\" id=\"entity-1.5-2\" label=\"1.5\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-DELIVERY-ADDRESS-1\" ONE_OR_MORE NON_IDENTIFYING ONE_OR_MORE",
  ),
  (
    "erDiagram\nCUSTOMER }|..|{ DELIVERY-ADDRESS : has\n0.1", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"DELIVERY-ADDRESS\" id=\"entity-DELIVERY-ADDRESS-1\" label=\"DELIVERY-ADDRESS\" alias=\"\" classes=\"default\" styles=[]\nentity \"0.1\" id=\"entity-0.1-2\" label=\"0.1\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-DELIVERY-ADDRESS-1\" ONE_OR_MORE NON_IDENTIFYING ONE_OR_MORE",
  ),
  (
    "erDiagram\nCUSTOMER }|..|{ DELIVERY-ADDRESS : has\n99.99", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"DELIVERY-ADDRESS\" id=\"entity-DELIVERY-ADDRESS-1\" label=\"DELIVERY-ADDRESS\" alias=\"\" classes=\"default\" styles=[]\nentity \"99.99\" id=\"entity-99.99-2\" label=\"99.99\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-DELIVERY-ADDRESS-1\" ONE_OR_MORE NON_IDENTIFYING ONE_OR_MORE",
  ),
  (
    "erDiagram\nu {\nstring name\nint id\n}", "ok\ndir \"TB\"\nentity \"u\" id=\"entity-u-0\" label=\"u\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"name\" keys=[] comment=\"\"\n  attr \"int\" \"id\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\n1 {\nstring name\nint id\n}", "ok\ndir \"TB\"\nentity \"1\" id=\"entity-1-0\" label=\"1\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"name\" keys=[] comment=\"\"\n  attr \"int\" \"id\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\n2.5 {\nstring name\nint id\n}", "ok\ndir \"TB\"\nentity \"2.5\" id=\"entity-2.5-0\" label=\"2.5\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"name\" keys=[] comment=\"\"\n  attr \"int\" \"id\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\n1.5 {\nstring value\n}", "ok\ndir \"TB\"\nentity \"1.5\" id=\"entity-1.5-0\" label=\"1.5\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"value\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nCUSTOMER ||--|| u : has", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"u\" id=\"entity-u-1\" label=\"u\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-u-1\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nu ||--|| ORDER : places", "ok\ndir \"TB\"\nentity \"u\" id=\"entity-u-0\" label=\"u\" alias=\"\" classes=\"default\" styles=[]\nentity \"ORDER\" id=\"entity-ORDER-1\" label=\"ORDER\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-u-0\" \"places\" \"entity-ORDER-1\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nu ||--|| v : connects", "ok\ndir \"TB\"\nentity \"u\" id=\"entity-u-0\" label=\"u\" alias=\"\" classes=\"default\" styles=[]\nentity \"v\" id=\"entity-v-1\" label=\"v\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-u-0\" \"connects\" \"entity-v-1\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nCUSTOMER ||--|| 1 : has", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"1\" id=\"entity-1-1\" label=\"1\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-1-1\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\n1 ||--|| ORDER : places", "ok\ndir \"TB\"\nentity \"1\" id=\"entity-1-0\" label=\"1\" alias=\"\" classes=\"default\" styles=[]\nentity \"ORDER\" id=\"entity-ORDER-1\" label=\"ORDER\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-1-0\" \"places\" \"entity-ORDER-1\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\n1 ||--|| 2 : connects", "ok\ndir \"TB\"\nentity \"1\" id=\"entity-1-0\" label=\"1\" alias=\"\" classes=\"default\" styles=[]\nentity \"2\" id=\"entity-2-1\" label=\"2\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-1-0\" \"connects\" \"entity-2-1\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\nCUSTOMER ||--|| 2.5 : has", "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"2.5\" id=\"entity-2.5-1\" label=\"2.5\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-CUSTOMER-0\" \"has\" \"entity-2.5-1\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\n1.5 ||--|| ORDER : places", "ok\ndir \"TB\"\nentity \"1.5\" id=\"entity-1.5-0\" label=\"1.5\" alias=\"\" classes=\"default\" styles=[]\nentity \"ORDER\" id=\"entity-ORDER-1\" label=\"ORDER\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-1.5-0\" \"places\" \"entity-ORDER-1\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\n2.5 ||--|| 5.5 : connects", "ok\ndir \"TB\"\nentity \"2.5\" id=\"entity-2.5-0\" label=\"2.5\" alias=\"\" classes=\"default\" styles=[]\nentity \"5.5\" id=\"entity-5.5-1\" label=\"5.5\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-2.5-0\" \"connects\" \"entity-5.5-1\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\n              CUSTOMER ||--o{ 1 : places\n              1 ||--|{ u : contains\n              u {\n                string name\n                int quantity\n              }\n              \"2.5\" ||--|| ORDER : processes\n              ORDER {\n                int id\n                date created\n              }\n        ",
    "ok\ndir \"TB\"\nentity \"CUSTOMER\" id=\"entity-CUSTOMER-0\" label=\"CUSTOMER\" alias=\"\" classes=\"default\" styles=[]\nentity \"1\" id=\"entity-1-1\" label=\"1\" alias=\"\" classes=\"default\" styles=[]\nentity \"u\" id=\"entity-u-2\" label=\"u\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"name\" keys=[] comment=\"\"\n  attr \"int\" \"quantity\" keys=[] comment=\"\"\nentity \"2.5\" id=\"entity-2.5-3\" label=\"2.5\" alias=\"\" classes=\"default\" styles=[]\nentity \"ORDER\" id=\"entity-ORDER-4\" label=\"ORDER\" alias=\"\" classes=\"default\" styles=[]\n  attr \"int\" \"id\" keys=[] comment=\"\"\n  attr \"date\" \"created\" keys=[] comment=\"\"\nrel \"entity-CUSTOMER-0\" \"places\" \"entity-1-1\" ZERO_OR_MORE IDENTIFYING ONLY_ONE\nrel \"entity-1-1\" \"contains\" \"entity-u-2\" ONE_OR_MORE IDENTIFYING ONLY_ONE\nrel \"entity-2.5-3\" \"processes\" \"entity-ORDER-4\" ONLY_ONE IDENTIFYING ONLY_ONE",
  ),
  (
    "erDiagram\n              ENTITY {\n                string name1\n                int value2\n                float point3_5\n              }\n        ",
    "ok\ndir \"TB\"\nentity \"ENTITY\" id=\"entity-ENTITY-0\" label=\"ENTITY\" alias=\"\" classes=\"default\" styles=[]\n  attr \"string\" \"name1\" keys=[] comment=\"\"\n  attr \"int\" \"value2\" keys=[] comment=\"\"\n  attr \"float\" \"point3_5\" keys=[] comment=\"\"",
  ),
  (
    "erDiagram\nsubgraph Group\nA\nB\nend", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nsubgraph \"Group\" title=\"Group\" dir=- nodes=[\"A\",\"B\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph \"Some Title\"\nA\nB\nend", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nsubgraph \"Some Title\" title=\"Some Title\" dir=- nodes=[\"A\",\"B\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph id [Title]\nA\nB\nend", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nsubgraph \"id\" title=\"Title\" dir=- nodes=[\"A\",\"B\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph \"Group 1.5\"\nA\nend", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nsubgraph \"Group 1.5\" title=\"Group 1.5\" dir=- nodes=[\"A\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph Group\n\nA\n\nB\n\nend", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nsubgraph \"Group\" title=\"Group\" dir=- nodes=[\"A\",\"B\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph Group\nA\nend   \n", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nsubgraph \"Group\" title=\"Group\" dir=- nodes=[\"A\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph empty\nend", "ok\ndir \"TB\"\nsubgraph \"empty\" title=\"empty\" dir=- nodes=[] classes=[] styles=[]",
  ),
  (
    "erDiagram subgraph WithRL\ndirection RL\nA\nB\nend", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nsubgraph \"WithRL\" title=\"WithRL\" dir=\"RL\" nodes=[\"A\",\"B\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph Group\nA }|--|| B : \"relates to\"\nend", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"relates to\" \"entity-B-1\" ONLY_ONE IDENTIFYING ONE_OR_MORE\nsubgraph \"Group\" title=\"Group\" dir=- nodes=[\"A\",\"B\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph Group\nA\nend\nA }|--|| B : \"relates to\"\n", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"relates to\" \"entity-B-1\" ONLY_ONE IDENTIFYING ONE_OR_MORE\nsubgraph \"Group\" title=\"Group\" dir=- nodes=[\"A\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph G1\n  A\nend\nsubgraph G2\n  B\nend\nG1 }|--|| G2 : \"relates to\"\n",
    "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nentity \"G1\" id=\"entity-G1-2\" label=\"G1\" alias=\"\" classes=\"default\" styles=[]\nentity \"G2\" id=\"entity-G2-3\" label=\"G2\" alias=\"\" classes=\"default\" styles=[]\nrel \"G1\" \"relates to\" \"G2\" ONLY_ONE IDENTIFYING ONE_OR_MORE\nsubgraph \"G1\" title=\"G1\" dir=- nodes=[\"A\"] classes=[] styles=[]\nsubgraph \"G2\" title=\"G2\" dir=- nodes=[\"B\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph G1\n  A\nend\nsubgraph G2\n  B\nend\nA }|--|| B : \"relates to\"\n",
    "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"relates to\" \"entity-B-1\" ONLY_ONE IDENTIFYING ONE_OR_MORE\nsubgraph \"G1\" title=\"G1\" dir=- nodes=[\"A\"] classes=[] styles=[]\nsubgraph \"G2\" title=\"G2\" dir=- nodes=[\"B\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph Group\nA\nend\nGroup }|--|| B : \"relates to\"\n", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"Group\" id=\"entity-Group-1\" label=\"Group\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-2\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"Group\" \"relates to\" \"entity-B-2\" ONLY_ONE IDENTIFYING ONE_OR_MORE\nsubgraph \"Group\" title=\"Group\" dir=- nodes=[\"A\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph Group\n  A }|--|| B : \"r1\"\n  B }|--|| C : \"r2\"\nend",
    "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nentity \"C\" id=\"entity-C-2\" label=\"C\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"r1\" \"entity-B-1\" ONLY_ONE IDENTIFYING ONE_OR_MORE\nrel \"entity-B-1\" \"r2\" \"entity-C-2\" ONLY_ONE IDENTIFYING ONE_OR_MORE\nsubgraph \"Group\" title=\"Group\" dir=- nodes=[\"A\",\"B\",\"C\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph outer\n  A\n  subgraph inner\n    B\n  end\nend", "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nsubgraph \"inner\" title=\"inner\" dir=- nodes=[\"B\"] classes=[] styles=[]\nsubgraph \"outer\" title=\"outer\" dir=- nodes=[\"A\",\"inner\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph outer\n    A\n      B\n  subgraph inner\n        C\n  end\nend",
    "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nentity \"C\" id=\"entity-C-2\" label=\"C\" alias=\"\" classes=\"default\" styles=[]\nsubgraph \"inner\" title=\"inner\" dir=- nodes=[\"C\"] classes=[] styles=[]\nsubgraph \"outer\" title=\"outer\" dir=- nodes=[\"A\",\"B\",\"inner\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph outer\n  subgraph inner\n    A }|--|| B : \"relates to\"\n  end\nend",
    "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"relates to\" \"entity-B-1\" ONLY_ONE IDENTIFYING ONE_OR_MORE\nsubgraph \"inner\" title=\"inner\" dir=- nodes=[\"A\",\"B\"] classes=[] styles=[]\nsubgraph \"outer\" title=\"outer\" dir=- nodes=[\"inner\"] classes=[] styles=[]",
  ),
  (
    "erDiagram\nsubgraph outer\n  A\n  subgraph inner\n    B\n  end\nend\nA }|--|| B : \"relates to\"\n",
    "ok\ndir \"TB\"\nentity \"A\" id=\"entity-A-0\" label=\"A\" alias=\"\" classes=\"default\" styles=[]\nentity \"B\" id=\"entity-B-1\" label=\"B\" alias=\"\" classes=\"default\" styles=[]\nrel \"entity-A-0\" \"relates to\" \"entity-B-1\" ONLY_ONE IDENTIFYING ONE_OR_MORE\nsubgraph \"inner\" title=\"inner\" dir=- nodes=[\"B\"] classes=[] styles=[]\nsubgraph \"outer\" title=\"outer\" dir=- nodes=[\"A\",\"inner\"] classes=[] styles=[]",
  ),
]
