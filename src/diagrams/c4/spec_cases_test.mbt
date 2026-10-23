// Every source Mermaid's C4 parser specs (mermaid@12.1.0, packages/mermaid/src/diagrams/c4/parser/*.spec.ts) feed the parser,
// as pele runs them in tests/compat/c4, with the model pele's parser builds from it.

///|
test "c4Diagram: should handle a trailing whitespaces after statements" {
  inspect(
    parsed(
      "C4Context \ntitle System Context diagram for Internet Banking System \nPerson(customerA, \"Banking Customer A\", \"A customer of the bank, with personal bank accounts.\") ",
    ),
    content=(
      #|c4Type=C4Context title=System Context diagram for Internet Banking System  accDescr=<unset> rows=4 2
      #|shape alias=customerA label=Banking Customer A kind=person parent=global descr=A customer of the bank, with personal bank accounts.
    ),
  )
}

///|
test "c4Diagram: should handle parameter names that are keywords" {
  inspect(
    parsed("C4Context\ntitle title\nPerson(Person, \"Person\", \"Person\")"),
    content=(
      #|c4Type=C4Context title=title accDescr=<unset> rows=4 2
      #|shape alias=Person label=Person kind=person parent=global descr=Person
    ),
  )
}

///|
test "c4Diagram: should allow default in the parameters" {
  inspect(
    parsed("C4Context\nPerson(default, \"default\", \"default\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=default label=default kind=person parent=global descr=default
    ),
  )
}

///|
test "c4Person: should parse a C4 diagram with one Person correctly" {
  inspect(
    parsed(
      "C4Context\ntitle System Context diagram for Internet Banking System\nPerson(customerA, \"Banking Customer A\", \"A customer of the bank, with personal bank accounts.\")",
    ),
    content=(
      #|c4Type=C4Context title=System Context diagram for Internet Banking System accDescr=<unset> rows=4 2
      #|shape alias=customerA label=Banking Customer A kind=person parent=global descr=A customer of the bank, with personal bank accounts.
    ),
  )
}

///|
test "c4Person: should parse the alias" {
  inspect(
    parsed("C4Context\nPerson(customerA, \"Banking Customer A\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=customerA label=Banking Customer A kind=person parent=global descr=
    ),
  )
}

///|
test "c4Person: should parse the description" {
  inspect(
    parsed(
      "C4Context\nPerson(customerA, \"\", \"A customer of the bank, with personal bank accounts.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=customerA label= kind=person parent=global descr=A customer of the bank, with personal bank accounts.
    ),
  )
}

///|
test "c4Person: should parse a sprite" {
  inspect(
    parsed("C4Context\nPerson(customerA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=customerA label= labelAttr=sprite:users kind=person parent=global descr= sprite=users
    ),
  )
}

///|
test "c4Person: should parse a link" {
  inspect(
    parsed(
      "C4Context\nPerson(customerA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=customerA label= labelAttr=link:https://github.com/mermaidjs kind=person parent=global descr= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4Person: should parse tags" {
  inspect(
    parsed("C4Context\nPerson(customerA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=customerA label= labelAttr=tags:tag1,tag2 kind=person parent=global descr= tags=tag1,tag2
    ),
  )
}

///|
test "c4Person: should keep named attributes that land in an earlier positional slot" {
  inspect(
    parsed(
      "C4Context\nPerson(customerA, \"Banking Customer A\", \"A customer.\", $tags=\"v1.0+internal\", $link=\"https://example.com\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=customerA label=Banking Customer A kind=person parent=global descr=A customer. tags=v1.0+internal link=https://example.com
    ),
  )
}

///|
test "c4PersonExt: should parse a C4 diagram with one Person_Ext correctly" {
  inspect(
    parsed(
      "C4Context\ntitle System Context diagram for Internet Banking System\nPerson_Ext(customerA, \"Banking Customer A\", \"A customer of the bank, with personal bank accounts.\")",
    ),
    content=(
      #|c4Type=C4Context title=System Context diagram for Internet Banking System accDescr=<unset> rows=4 2
      #|shape alias=customerA label=Banking Customer A kind=external_person parent=global descr=A customer of the bank, with personal bank accounts.
    ),
  )
}

///|
test "c4PersonExt: should parse the alias" {
  inspect(
    parsed("C4Context\nPerson_Ext(customerA, \"Banking Customer A\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=customerA label=Banking Customer A kind=external_person parent=global descr=
    ),
  )
}

///|
test "c4PersonExt: should parse the description" {
  inspect(
    parsed(
      "C4Context\nPerson_Ext(customerA, \"\", \"A customer of the bank, with personal bank accounts.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=customerA label= kind=external_person parent=global descr=A customer of the bank, with personal bank accounts.
    ),
  )
}

///|
test "c4PersonExt: should parse a sprite" {
  inspect(
    parsed("C4Context\nPerson_Ext(customerA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=customerA label= labelAttr=sprite:users kind=external_person parent=global descr= sprite=users
    ),
  )
}

///|
test "c4PersonExt: should parse a link" {
  inspect(
    parsed(
      "C4Context\nPerson_Ext(customerA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=customerA label= labelAttr=link:https://github.com/mermaidjs kind=external_person parent=global descr= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4PersonExt: should parse tags" {
  inspect(
    parsed("C4Context\nPerson_Ext(customerA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=customerA label= labelAttr=tags:tag1,tag2 kind=external_person parent=global descr= tags=tag1,tag2
    ),
  )
}

///|
test "c4System: should parse a C4 diagram with one System correctly" {
  inspect(
    parsed(
      "C4Context\ntitle System Context diagram for Internet Banking System\nSystem(SystemAA, \"Internet Banking System\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=System Context diagram for Internet Banking System accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse the alias" {
  inspect(
    parsed("C4Context\nSystem(SystemAA, \"Internet Banking System\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system parent=global descr=
    ),
  )
}

///|
test "c4System: should parse the description" {
  inspect(
    parsed(
      "C4Context\nSystem(SystemAA, \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= kind=system parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse a sprite" {
  inspect(
    parsed("C4Context\nSystem(SystemAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=sprite:users kind=system parent=global descr= sprite=users
    ),
  )
}

///|
test "c4System: should parse a link" {
  inspect(
    parsed(
      "C4Context\nSystem(SystemAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=link:https://github.com/mermaidjs kind=system parent=global descr= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4System: should parse tags" {
  inspect(
    parsed("C4Context\nSystem(SystemAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=tags:tag1,tag2 kind=system parent=global descr= tags=tag1,tag2
    ),
  )
}

///|
test "c4System: should parse a C4 diagram with one System correctly (2)" {
  inspect(
    parsed(
      "C4Context\ntitle System Context diagram for Internet Banking System\nSystemDb(SystemAA, \"Internet Banking System\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=System Context diagram for Internet Banking System accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system_db parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse the alias (2)" {
  inspect(
    parsed("C4Context\nSystemDb(SystemAA, \"Internet Banking System\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system_db parent=global descr=
    ),
  )
}

///|
test "c4System: should parse the description (2)" {
  inspect(
    parsed(
      "C4Context\nSystemDb(SystemAA, \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= kind=system_db parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse a sprite (2)" {
  inspect(
    parsed("C4Context\nSystemDb(SystemAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=sprite:users kind=system_db parent=global descr= sprite=users
    ),
  )
}

///|
test "c4System: should parse a link (2)" {
  inspect(
    parsed(
      "C4Context\nSystemDb(SystemAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=link:https://github.com/mermaidjs kind=system_db parent=global descr= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4System: should parse tags (2)" {
  inspect(
    parsed("C4Context\nSystemDb(SystemAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=tags:tag1,tag2 kind=system_db parent=global descr= tags=tag1,tag2
    ),
  )
}

///|
test "c4System: should parse a C4 diagram with one System correctly (3)" {
  inspect(
    parsed(
      "C4Context\ntitle System Context diagram for Internet Banking System\nSystemQueue(SystemAA, \"Internet Banking System\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=System Context diagram for Internet Banking System accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse the alias (3)" {
  inspect(
    parsed("C4Context\nSystemQueue(SystemAA, \"Internet Banking System\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system_queue parent=global descr=
    ),
  )
}

///|
test "c4System: should parse the description (3)" {
  inspect(
    parsed(
      "C4Context\nSystemQueue(SystemAA, \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= kind=system_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse a sprite (3)" {
  inspect(
    parsed("C4Context\nSystemQueue(SystemAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=sprite:users kind=system_queue parent=global descr= sprite=users
    ),
  )
}

///|
test "c4System: should parse a link (3)" {
  inspect(
    parsed(
      "C4Context\nSystemQueue(SystemAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=link:https://github.com/mermaidjs kind=system_queue parent=global descr= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4System: should parse tags (3)" {
  inspect(
    parsed("C4Context\nSystemQueue(SystemAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=tags:tag1,tag2 kind=system_queue parent=global descr= tags=tag1,tag2
    ),
  )
}

///|
test "c4System: should parse a C4 diagram with one System correctly (4)" {
  inspect(
    parsed(
      "C4Context\ntitle System Context diagram for Internet Banking System\nSystem_Ext(SystemAA, \"Internet Banking System\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=System Context diagram for Internet Banking System accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=external_system parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse the alias (4)" {
  inspect(
    parsed("C4Context\nSystem_Ext(SystemAA, \"Internet Banking System\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=external_system parent=global descr=
    ),
  )
}

///|
test "c4System: should parse the description (4)" {
  inspect(
    parsed(
      "C4Context\nSystem_Ext(SystemAA, \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= kind=external_system parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse a sprite (4)" {
  inspect(
    parsed("C4Context\nSystem_Ext(SystemAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=sprite:users kind=external_system parent=global descr= sprite=users
    ),
  )
}

///|
test "c4System: should parse a link (4)" {
  inspect(
    parsed(
      "C4Context\nSystem_Ext(SystemAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=link:https://github.com/mermaidjs kind=external_system parent=global descr= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4System: should parse tags (4)" {
  inspect(
    parsed("C4Context\nSystem_Ext(SystemAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=tags:tag1,tag2 kind=external_system parent=global descr= tags=tag1,tag2
    ),
  )
}

///|
test "c4System: should parse a C4 diagram with one System correctly (5)" {
  inspect(
    parsed(
      "C4Context\ntitle System Context diagram for Internet Banking System\nSystemDb_Ext(SystemAA, \"Internet Banking System\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=System Context diagram for Internet Banking System accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=external_system_db parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse the alias (5)" {
  inspect(
    parsed("C4Context\nSystemDb_Ext(SystemAA, \"Internet Banking System\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=external_system_db parent=global descr=
    ),
  )
}

///|
test "c4System: should parse the description (5)" {
  inspect(
    parsed(
      "C4Context\nSystemDb_Ext(SystemAA, \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= kind=external_system_db parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse a sprite (5)" {
  inspect(
    parsed("C4Context\nSystemDb_Ext(SystemAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=sprite:users kind=external_system_db parent=global descr= sprite=users
    ),
  )
}

///|
test "c4System: should parse a link (5)" {
  inspect(
    parsed(
      "C4Context\nSystemDb_Ext(SystemAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=link:https://github.com/mermaidjs kind=external_system_db parent=global descr= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4System: should parse tags (5)" {
  inspect(
    parsed("C4Context\nSystemDb_Ext(SystemAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=tags:tag1,tag2 kind=external_system_db parent=global descr= tags=tag1,tag2
    ),
  )
}

///|
test "c4System: should parse a C4 diagram with one System correctly (6)" {
  inspect(
    parsed(
      "C4Context\ntitle System Context diagram for Internet Banking System\nSystemQueue_Ext(SystemAA, \"Internet Banking System\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=System Context diagram for Internet Banking System accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=external_system_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse the alias (6)" {
  inspect(
    parsed("C4Context\nSystemQueue_Ext(SystemAA, \"Internet Banking System\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=external_system_queue parent=global descr=
    ),
  )
}

///|
test "c4System: should parse the description (6)" {
  inspect(
    parsed(
      "C4Context\nSystemQueue_Ext(SystemAA, \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= kind=external_system_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments.
    ),
  )
}

///|
test "c4System: should parse a sprite (6)" {
  inspect(
    parsed("C4Context\nSystemQueue_Ext(SystemAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=sprite:users kind=external_system_queue parent=global descr= sprite=users
    ),
  )
}

///|
test "c4System: should parse a link (6)" {
  inspect(
    parsed(
      "C4Context\nSystemQueue_Ext(SystemAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=link:https://github.com/mermaidjs kind=external_system_queue parent=global descr= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4System: should parse tags (6)" {
  inspect(
    parsed("C4Context\nSystemQueue_Ext(SystemAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label= labelAttr=tags:tag1,tag2 kind=external_system_queue parent=global descr= tags=tag1,tag2
    ),
  )
}

///|
test "c4Container: should parse a C4 diagram with one Container correctly" {
  inspect(
    parsed(
      "C4Context\ntitle Container diagram for Internet Banking Container\nContainer(ContainerAA, \"Internet Banking Container\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=Container diagram for Internet Banking Container accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=container parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Container: should parse the alias" {
  inspect(
    parsed("C4Context\nContainer(ContainerAA, \"Internet Banking Container\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=container parent=global descr= techn=
    ),
  )
}

///|
test "c4Container: should parse the technology" {
  inspect(
    parsed("C4Context\nContainer(ContainerAA, \"\", \"Java\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=container parent=global descr= techn=Java
    ),
  )
}

///|
test "c4Container: should parse the description" {
  inspect(
    parsed(
      "C4Context\nContainer(ContainerAA, \"\", \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=container parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=
    ),
  )
}

///|
test "c4Container: should parse a sprite" {
  inspect(
    parsed("C4Context\nContainer(ContainerAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=sprite:users kind=container parent=global descr= techn= sprite=users
    ),
  )
}

///|
test "c4Container: should parse a link" {
  inspect(
    parsed(
      "C4Context\nContainer(ContainerAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=link:https://github.com/mermaidjs kind=container parent=global descr= techn= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4Container: should parse tags" {
  inspect(
    parsed("C4Context\nContainer(ContainerAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=tags:tag1,tag2 kind=container parent=global descr= techn= tags=tag1,tag2
    ),
  )
}

///|
test "c4Container: should parse a C4 diagram with one Container correctly (2)" {
  inspect(
    parsed(
      "C4Context\ntitle Container diagram for Internet Banking Container\nContainerDb(ContainerAA, \"Internet Banking Container\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=Container diagram for Internet Banking Container accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=container_db parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Container: should parse the alias (2)" {
  inspect(
    parsed(
      "C4Context\nContainerDb(ContainerAA, \"Internet Banking Container\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=container_db parent=global descr= techn=
    ),
  )
}

///|
test "c4Container: should parse the technology (2)" {
  inspect(
    parsed("C4Context\nContainerDb(ContainerAA, \"\", \"Java\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=container_db parent=global descr= techn=Java
    ),
  )
}

///|
test "c4Container: should parse the description (2)" {
  inspect(
    parsed(
      "C4Context\nContainerDb(ContainerAA, \"\", \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=container_db parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=
    ),
  )
}

///|
test "c4Container: should parse a sprite (2)" {
  inspect(
    parsed("C4Context\nContainerDb(ContainerAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=sprite:users kind=container_db parent=global descr= techn= sprite=users
    ),
  )
}

///|
test "c4Container: should parse a link (2)" {
  inspect(
    parsed(
      "C4Context\nContainerDb(ContainerAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=link:https://github.com/mermaidjs kind=container_db parent=global descr= techn= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4Container: should parse tags (2)" {
  inspect(
    parsed("C4Context\nContainerDb(ContainerAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=tags:tag1,tag2 kind=container_db parent=global descr= techn= tags=tag1,tag2
    ),
  )
}

///|
test "c4Container: should parse a C4 diagram with one Container correctly (3)" {
  inspect(
    parsed(
      "C4Context\ntitle Container diagram for Internet Banking Container\nContainerQueue(ContainerAA, \"Internet Banking Container\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=Container diagram for Internet Banking Container accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=container_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Container: should parse the alias (3)" {
  inspect(
    parsed(
      "C4Context\nContainerQueue(ContainerAA, \"Internet Banking Container\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=container_queue parent=global descr= techn=
    ),
  )
}

///|
test "c4Container: should parse the technology (3)" {
  inspect(
    parsed("C4Context\nContainerQueue(ContainerAA, \"\", \"Java\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=container_queue parent=global descr= techn=Java
    ),
  )
}

///|
test "c4Container: should parse the description (3)" {
  inspect(
    parsed(
      "C4Context\nContainerQueue(ContainerAA, \"\", \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=container_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=
    ),
  )
}

///|
test "c4Container: should parse a sprite (3)" {
  inspect(
    parsed("C4Context\nContainerQueue(ContainerAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=sprite:users kind=container_queue parent=global descr= techn= sprite=users
    ),
  )
}

///|
test "c4Container: should parse a link (3)" {
  inspect(
    parsed(
      "C4Context\nContainerQueue(ContainerAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=link:https://github.com/mermaidjs kind=container_queue parent=global descr= techn= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4Container: should parse tags (3)" {
  inspect(
    parsed("C4Context\nContainerQueue(ContainerAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=tags:tag1,tag2 kind=container_queue parent=global descr= techn= tags=tag1,tag2
    ),
  )
}

///|
test "c4Container: should parse a C4 diagram with one Container correctly (4)" {
  inspect(
    parsed(
      "C4Context\ntitle Container diagram for Internet Banking Container\nContainer_Ext(ContainerAA, \"Internet Banking Container\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=Container diagram for Internet Banking Container accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=external_container parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Container: should parse the alias (4)" {
  inspect(
    parsed(
      "C4Context\nContainer_Ext(ContainerAA, \"Internet Banking Container\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=external_container parent=global descr= techn=
    ),
  )
}

///|
test "c4Container: should parse the technology (4)" {
  inspect(
    parsed("C4Context\nContainer_Ext(ContainerAA, \"\", \"Java\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=external_container parent=global descr= techn=Java
    ),
  )
}

///|
test "c4Container: should parse the description (4)" {
  inspect(
    parsed(
      "C4Context\nContainer_Ext(ContainerAA, \"\", \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=external_container parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=
    ),
  )
}

///|
test "c4Container: should parse a sprite (4)" {
  inspect(
    parsed("C4Context\nContainer_Ext(ContainerAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=sprite:users kind=external_container parent=global descr= techn= sprite=users
    ),
  )
}

///|
test "c4Container: should parse a link (4)" {
  inspect(
    parsed(
      "C4Context\nContainer_Ext(ContainerAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=link:https://github.com/mermaidjs kind=external_container parent=global descr= techn= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4Container: should parse tags (4)" {
  inspect(
    parsed("C4Context\nContainer_Ext(ContainerAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=tags:tag1,tag2 kind=external_container parent=global descr= techn= tags=tag1,tag2
    ),
  )
}

///|
test "c4Container: should parse a C4 diagram with one Container correctly (5)" {
  inspect(
    parsed(
      "C4Context\ntitle Container diagram for Internet Banking Container\nContainerDb_Ext(ContainerAA, \"Internet Banking Container\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=Container diagram for Internet Banking Container accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=external_container_db parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Container: should parse the alias (5)" {
  inspect(
    parsed(
      "C4Context\nContainerDb_Ext(ContainerAA, \"Internet Banking Container\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=external_container_db parent=global descr= techn=
    ),
  )
}

///|
test "c4Container: should parse the technology (5)" {
  inspect(
    parsed("C4Context\nContainerDb_Ext(ContainerAA, \"\", \"Java\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=external_container_db parent=global descr= techn=Java
    ),
  )
}

///|
test "c4Container: should parse the description (5)" {
  inspect(
    parsed(
      "C4Context\nContainerDb_Ext(ContainerAA, \"\", \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=external_container_db parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=
    ),
  )
}

///|
test "c4Container: should parse a sprite (5)" {
  inspect(
    parsed("C4Context\nContainerDb_Ext(ContainerAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=sprite:users kind=external_container_db parent=global descr= techn= sprite=users
    ),
  )
}

///|
test "c4Container: should parse a link (5)" {
  inspect(
    parsed(
      "C4Context\nContainerDb_Ext(ContainerAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=link:https://github.com/mermaidjs kind=external_container_db parent=global descr= techn= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4Container: should parse tags (5)" {
  inspect(
    parsed("C4Context\nContainerDb_Ext(ContainerAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=tags:tag1,tag2 kind=external_container_db parent=global descr= techn= tags=tag1,tag2
    ),
  )
}

///|
test "c4Container: should parse a C4 diagram with one Container correctly (6)" {
  inspect(
    parsed(
      "C4Context\ntitle Container diagram for Internet Banking Container\nContainerQueue_Ext(ContainerAA, \"Internet Banking Container\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=Container diagram for Internet Banking Container accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=external_container_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Container: should parse the alias (6)" {
  inspect(
    parsed(
      "C4Context\nContainerQueue_Ext(ContainerAA, \"Internet Banking Container\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label=Internet Banking Container kind=external_container_queue parent=global descr= techn=
    ),
  )
}

///|
test "c4Container: should parse the technology (6)" {
  inspect(
    parsed("C4Context\nContainerQueue_Ext(ContainerAA, \"\", \"Java\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=external_container_queue parent=global descr= techn=Java
    ),
  )
}

///|
test "c4Container: should parse the description (6)" {
  inspect(
    parsed(
      "C4Context\nContainerQueue_Ext(ContainerAA, \"\", \"\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= kind=external_container_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=
    ),
  )
}

///|
test "c4Container: should parse a sprite (6)" {
  inspect(
    parsed("C4Context\nContainerQueue_Ext(ContainerAA, $sprite=\"users\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=sprite:users kind=external_container_queue parent=global descr= techn= sprite=users
    ),
  )
}

///|
test "c4Container: should parse a link (6)" {
  inspect(
    parsed(
      "C4Context\nContainerQueue_Ext(ContainerAA, $link=\"https://github.com/mermaidjs\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=link:https://github.com/mermaidjs kind=external_container_queue parent=global descr= techn= link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4Container: should parse tags (6)" {
  inspect(
    parsed("C4Context\nContainerQueue_Ext(ContainerAA, $tags=\"tag1,tag2\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=ContainerAA label= labelAttr=tags:tag1,tag2 kind=external_container_queue parent=global descr= techn= tags=tag1,tag2
    ),
  )
}

///|
test "c4Component: should parse a C4 diagram with one Component correctly" {
  inspect(
    parsed(
      "C4Component\ntitle Component diagram for Internet Banking Component\nComponent(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=component parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Component: should handle a trailing whitespaces after Component" {
  inspect(
    parsed(
      "C4Component \ntitle Component diagram for Internet Banking Component \nComponent(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\") ",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component  accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=component parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Component: should parse a C4 diagram with one Component correctly (2)" {
  inspect(
    parsed(
      "C4Component\ntitle Component diagram for Internet Banking Component\nComponentDb(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=component_db parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Component: should handle a trailing whitespaces after Component (2)" {
  inspect(
    parsed(
      "C4Component \ntitle Component diagram for Internet Banking Component \nComponentDb(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\") ",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component  accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=component_db parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Component: should parse a C4 diagram with one Component correctly (3)" {
  inspect(
    parsed(
      "C4Component\ntitle Component diagram for Internet Banking Component\nComponentQueue(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=component_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Component: should handle a trailing whitespaces after Component (3)" {
  inspect(
    parsed(
      "C4Component \ntitle Component diagram for Internet Banking Component \nComponentQueue(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\") ",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component  accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=component_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Component: should parse a C4 diagram with one Component correctly (4)" {
  inspect(
    parsed(
      "C4Component\ntitle Component diagram for Internet Banking Component\nComponent_Ext(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=external_component parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Component: should handle a trailing whitespaces after Component (4)" {
  inspect(
    parsed(
      "C4Component \ntitle Component diagram for Internet Banking Component \nComponent_Ext(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\") ",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component  accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=external_component parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Component: should parse a C4 diagram with one Component correctly (5)" {
  inspect(
    parsed(
      "C4Component\ntitle Component diagram for Internet Banking Component\nComponentDb_Ext(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=external_component_db parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Component: should handle a trailing whitespaces after Component (5)" {
  inspect(
    parsed(
      "C4Component \ntitle Component diagram for Internet Banking Component \nComponentDb_Ext(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\") ",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component  accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=external_component_db parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Component: should parse a C4 diagram with one Component correctly (6)" {
  inspect(
    parsed(
      "C4Component\ntitle Component diagram for Internet Banking Component\nComponentQueue_Ext(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\")",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=external_component_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Component: should handle a trailing whitespaces after Component (6)" {
  inspect(
    parsed(
      "C4Component \ntitle Component diagram for Internet Banking Component \nComponentQueue_Ext(ComponentAA, \"Internet Banking Component\", \"Technology\", \"Allows customers to view information about their bank accounts, and make payments.\") ",
    ),
    content=(
      #|c4Type=C4Component title=Component diagram for Internet Banking Component  accDescr=<unset> rows=4 2
      #|shape alias=ComponentAA label=Internet Banking Component kind=external_component_queue parent=global descr=Allows customers to view information about their bank accounts, and make payments. techn=Technology
    ),
  )
}

///|
test "c4Boundary: should parse a C4 diagram with one Boundary correctly" {
  inspect(
    parsed(
      "C4Context\ntitle System Context diagram for Internet Banking System\nBoundary(b1, \"BankBoundary\") {\nSystem(SystemAA, \"Internet Banking System\")\n}",
    ),
    content=(
      #|c4Type=C4Context title=System Context diagram for Internet Banking System accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system parent=b1 descr=
      #|boundary alias=b1 label=BankBoundary parent=global type=system
    ),
  )
}

///|
test "c4Boundary: should parse the alias" {
  inspect(
    parsed(
      "C4Context\nBoundary(b1, \"BankBoundary\") {\nSystem(SystemAA, \"Internet Banking System\")\n}",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system parent=b1 descr=
      #|boundary alias=b1 label=BankBoundary parent=global type=system
    ),
  )
}

///|
test "c4Boundary: should parse the type" {
  inspect(
    parsed(
      "C4Context\nBoundary(b1, \"\", \"company\") {\nSystem(SystemAA, \"Internet Banking System\")\n}",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system parent=b1 descr=
      #|boundary alias=b1 label= parent=global type=company
    ),
  )
}

///|
test "c4Boundary: should parse a link" {
  inspect(
    parsed(
      "C4Context\nBoundary(b1, $link=\"https://github.com/mermaidjs\") {\nSystem(SystemAA, \"Internet Banking System\")\n}",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system parent=b1 descr=
      #|boundary alias=b1 label= labelAttr=link:https://github.com/mermaidjs parent=global type=system link=https://github.com/mermaidjs
    ),
  )
}

///|
test "c4Boundary: should parse tags" {
  inspect(
    parsed(
      "C4Context\nBoundary(b1, $tags=\"tag1,tag2\") {\nSystem(SystemAA, \"Internet Banking System\")\n}",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system parent=b1 descr=
      #|boundary alias=b1 label= labelAttr=tags:tag1,tag2 parent=global type=system tags=tag1,tag2
    ),
  )
}

///|
test "c4Boundary: should resolve a boundary alias as a relation endpoint" {
  inspect(
    parsed(
      "C4Context\nBoundary(b1, \"BankBoundary\") {\nSystem(SystemAA, \"Internet Banking System\")\n}\nRel(b1, SystemAA, \"Contains\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=SystemAA label=Internet Banking System kind=system parent=b1 descr=
      #|boundary alias=b1 label=BankBoundary parent=global type=system
      #|rel type=rel from=b1 to=SystemAA label=Contains techn= descr=
    ),
  )
}

///|
test "c4NamedAttributes: keeps $tags a string when the description is omitted" {
  inspect(
    parsed("C4Context\nSystem(s, \"S\", $tags=\"cylinder\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=s label=S kind=system parent=global tags=cylinder
    ),
  )
}

///|
test "c4NamedAttributes: keeps $tags a string when the description is given" {
  inspect(
    parsed("C4Context\nSystem(s, \"S\", \"desc\", $tags=\"cylinder\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=s label=S kind=system parent=global descr=desc tags=cylinder
    ),
  )
}

///|
test "c4NamedAttributes: still stores the description as text when it is the one named" {
  inspect(
    parsed("C4Context\nSystem(s, \"S\", $descr=\"a description\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=s label=S kind=system parent=global descr=a description
    ),
  )
}

///|
test "c4NamedAttributes: keeps $sprite and $link strings on a container" {
  inspect(
    parsed(
      "C4Container\nContainer(c, \"C\", $sprite=\"browser\", $link=\"https://x.test\")",
    ),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=c label=C kind=container parent=global sprite=browser link=https://x.test
    ),
  )
}

///|
test "c4NamedAttributes: keeps a relationship $tags a string when techn and descr are omitted" {
  inspect(
    parsed(
      "C4Context\nPerson(a, \"A\")\nPerson(b, \"B\")\nRel(a, b, \"uses\", $tags=\"async\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=person parent=global descr=
      #|shape alias=b label=B kind=person parent=global descr=
      #|rel type=rel from=a to=b label=uses descr= tags=async
    ),
  )
}

///|
test "c4NamedAttributes: keeps a named $descr that lands in an earlier slot" {
  inspect(
    parsed("C4Container\nContainer(c, \"C\", $descr=\"a description\")"),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=c label=C kind=container parent=global descr=a description
    ),
  )
}

///|
test "c4NamedAttributes: still defaults descr to empty when it is genuinely absent" {
  inspect(
    parsed("C4Container\nContainer(c, \"C\", $techn=\"Java\")"),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=c label=C kind=container parent=global descr= techn=Java
    ),
  )
}

///|
test "c4NamedAttributes: keeps a named $descr on a relationship, where techn also comes first" {
  inspect(
    parsed(
      "C4Context\nPerson(a, \"A\")\nPerson(b, \"B\")\nRel(a, b, \"uses\", $descr=\"how it is used\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=person parent=global descr=
      #|shape alias=b label=B kind=person parent=global descr=
      #|rel type=rel from=a to=b label=uses descr=how it is used
    ),
  )
}

///|
test "c4NamedAttributes: System(x, \"L\", $descr=\"V\")" {
  inspect(
    parsed("C4Context\nSystem(x, \"L\", $descr=\"V\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=system parent=global descr=V
    ),
  )
}

///|
test "c4NamedAttributes: System(x, \"L\", $tags=\"V\")" {
  inspect(
    parsed("C4Context\nSystem(x, \"L\", $tags=\"V\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=system parent=global tags=V
    ),
  )
}

///|
test "c4NamedAttributes: System(x, \"L\", $sprite=\"V\")" {
  inspect(
    parsed("C4Context\nSystem(x, \"L\", $sprite=\"V\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=system parent=global sprite=V
    ),
  )
}

///|
test "c4NamedAttributes: System(x, \"L\", $link=\"V\")" {
  inspect(
    parsed("C4Context\nSystem(x, \"L\", $link=\"V\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=system parent=global link=V
    ),
  )
}

///|
test "c4NamedAttributes: Person(x, \"L\", $descr=\"V\")" {
  inspect(
    parsed("C4Context\nPerson(x, \"L\", $descr=\"V\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=person parent=global descr=V
    ),
  )
}

///|
test "c4NamedAttributes: Person(x, \"L\", $tags=\"V\")" {
  inspect(
    parsed("C4Context\nPerson(x, \"L\", $tags=\"V\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=person parent=global tags=V
    ),
  )
}

///|
test "c4NamedAttributes: Person(x, \"L\", $sprite=\"V\")" {
  inspect(
    parsed("C4Context\nPerson(x, \"L\", $sprite=\"V\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=person parent=global sprite=V
    ),
  )
}

///|
test "c4NamedAttributes: Person(x, \"L\", $link=\"V\")" {
  inspect(
    parsed("C4Context\nPerson(x, \"L\", $link=\"V\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=person parent=global link=V
    ),
  )
}

///|
test "c4NamedAttributes: Container(x, \"L\", $descr=\"V\")" {
  inspect(
    parsed("C4Container\nContainer(x, \"L\", $descr=\"V\")"),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=container parent=global descr=V
    ),
  )
}

///|
test "c4NamedAttributes: Container(x, \"L\", $techn=\"V\")" {
  inspect(
    parsed("C4Container\nContainer(x, \"L\", $techn=\"V\")"),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=container parent=global descr= techn=V
    ),
  )
}

///|
test "c4NamedAttributes: Container(x, \"L\", $tags=\"V\")" {
  inspect(
    parsed("C4Container\nContainer(x, \"L\", $tags=\"V\")"),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=container parent=global descr= tags=V
    ),
  )
}

///|
test "c4NamedAttributes: Container(x, \"L\", $sprite=\"V\")" {
  inspect(
    parsed("C4Container\nContainer(x, \"L\", $sprite=\"V\")"),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=container parent=global descr= sprite=V
    ),
  )
}

///|
test "c4NamedAttributes: Container(x, \"L\", $link=\"V\")" {
  inspect(
    parsed("C4Container\nContainer(x, \"L\", $link=\"V\")"),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=container parent=global descr= link=V
    ),
  )
}

///|
test "c4NamedAttributes: Component(x, \"L\", $descr=\"V\")" {
  inspect(
    parsed("C4Component\nComponent(x, \"L\", $descr=\"V\")"),
    content=(
      #|c4Type=C4Component title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=component parent=global descr=V
    ),
  )
}

///|
test "c4NamedAttributes: Component(x, \"L\", $techn=\"V\")" {
  inspect(
    parsed("C4Component\nComponent(x, \"L\", $techn=\"V\")"),
    content=(
      #|c4Type=C4Component title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=component parent=global descr= techn=V
    ),
  )
}

///|
test "c4NamedAttributes: Component(x, \"L\", $tags=\"V\")" {
  inspect(
    parsed("C4Component\nComponent(x, \"L\", $tags=\"V\")"),
    content=(
      #|c4Type=C4Component title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=component parent=global descr= tags=V
    ),
  )
}

///|
test "c4NamedAttributes: Component(x, \"L\", $sprite=\"V\")" {
  inspect(
    parsed("C4Component\nComponent(x, \"L\", $sprite=\"V\")"),
    content=(
      #|c4Type=C4Component title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=component parent=global descr= sprite=V
    ),
  )
}

///|
test "c4NamedAttributes: Component(x, \"L\", $link=\"V\")" {
  inspect(
    parsed("C4Component\nComponent(x, \"L\", $link=\"V\")"),
    content=(
      #|c4Type=C4Component title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=L kind=component parent=global descr= link=V
    ),
  )
}

///|
test "c4NamedAttributes: System_Boundary(x, \"L\", $type=\"V\")" {
  inspect(
    parsed(
      "C4Context\nSystem_Boundary(x, \"L\", $type=\"V\") {\nContainer(i, \"I\")\n}",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=i label=I kind=container parent=x descr= techn=
      #|boundary alias=x label=L parent=global type=V
    ),
  )
}

///|
test "c4NamedAttributes: System_Boundary(x, \"L\", $tags=\"V\")" {
  inspect(
    parsed(
      "C4Context\nSystem_Boundary(x, \"L\", $tags=\"V\") {\nContainer(i, \"I\")\n}",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=i label=I kind=container parent=x descr= techn=
      #|boundary alias=x label=L parent=global type=SYSTEM tags=V
    ),
  )
}

///|
test "c4NamedAttributes: System_Boundary(x, \"L\", $link=\"V\")" {
  inspect(
    parsed(
      "C4Context\nSystem_Boundary(x, \"L\", $link=\"V\") {\nContainer(i, \"I\")\n}",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=i label=I kind=container parent=x descr= techn=
      #|boundary alias=x label=L parent=global type=SYSTEM link=V
    ),
  )
}

///|
test "c4NamedAttributes: Container_Boundary(x, \"L\", $type=\"V\")" {
  inspect(
    parsed(
      "C4Container\nContainer_Boundary(x, \"L\", $type=\"V\") {\nContainer(i, \"I\")\n}",
    ),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=i label=I kind=container parent=x descr= techn=
      #|boundary alias=x label=L parent=global type=V
    ),
  )
}

///|
test "c4NamedAttributes: Container_Boundary(x, \"L\", $tags=\"V\")" {
  inspect(
    parsed(
      "C4Container\nContainer_Boundary(x, \"L\", $tags=\"V\") {\nContainer(i, \"I\")\n}",
    ),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=i label=I kind=container parent=x descr= techn=
      #|boundary alias=x label=L parent=global type=CONTAINER tags=V
    ),
  )
}

///|
test "c4NamedAttributes: Container_Boundary(x, \"L\", $link=\"V\")" {
  inspect(
    parsed(
      "C4Container\nContainer_Boundary(x, \"L\", $link=\"V\") {\nContainer(i, \"I\")\n}",
    ),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=i label=I kind=container parent=x descr= techn=
      #|boundary alias=x label=L parent=global type=CONTAINER link=V
    ),
  )
}

///|
test "c4NamedAttributes: Node(x, \"L\", $type=\"V\")" {
  inspect(
    parsed(
      "C4Deployment\nNode(x, \"L\", $type=\"V\") {\nContainer(i, \"I\")\n}",
    ),
    content=(
      #|c4Type=C4Deployment title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=i label=I kind=container parent=x descr= techn=
      #|boundary alias=x label=L parent=global type=V descr= nodeType=node
    ),
  )
}

///|
test "c4NamedAttributes: Node(x, \"L\", $descr=\"V\")" {
  inspect(
    parsed(
      "C4Deployment\nNode(x, \"L\", $descr=\"V\") {\nContainer(i, \"I\")\n}",
    ),
    content=(
      #|c4Type=C4Deployment title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=i label=I kind=container parent=x descr= techn=
      #|boundary alias=x label=L parent=global descr=V nodeType=node
    ),
  )
}

///|
test "c4NamedAttributes: Node(x, \"L\", $tags=\"V\")" {
  inspect(
    parsed(
      "C4Deployment\nNode(x, \"L\", $tags=\"V\") {\nContainer(i, \"I\")\n}",
    ),
    content=(
      #|c4Type=C4Deployment title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=i label=I kind=container parent=x descr= techn=
      #|boundary alias=x label=L parent=global descr= tags=V nodeType=node
    ),
  )
}

///|
test "c4NamedAttributes: Node(x, \"L\", $sprite=\"V\")" {
  inspect(
    parsed(
      "C4Deployment\nNode(x, \"L\", $sprite=\"V\") {\nContainer(i, \"I\")\n}",
    ),
    content=(
      #|c4Type=C4Deployment title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=i label=I kind=container parent=x descr= techn=
      #|boundary alias=x label=L parent=global descr= sprite=V nodeType=node
    ),
  )
}

///|
test "c4NamedAttributes: Node(x, \"L\", $link=\"V\")" {
  inspect(
    parsed(
      "C4Deployment\nNode(x, \"L\", $link=\"V\") {\nContainer(i, \"I\")\n}",
    ),
    content=(
      #|c4Type=C4Deployment title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=i label=I kind=container parent=x descr= techn=
      #|boundary alias=x label=L parent=global descr= link=V nodeType=node
    ),
  )
}

///|
test "c4NamedAttributes: Rel(a, b, \"uses\", $techn=\"V\")" {
  inspect(
    parsed(
      "C4Context\nPerson(a, \"A\")\nPerson(b, \"B\")\nRel(a, b, \"uses\", $techn=\"V\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=person parent=global descr=
      #|shape alias=b label=B kind=person parent=global descr=
      #|rel type=rel from=a to=b label=uses techn=V descr=
    ),
  )
}

///|
test "c4NamedAttributes: Rel(a, b, \"uses\", $descr=\"V\")" {
  inspect(
    parsed(
      "C4Context\nPerson(a, \"A\")\nPerson(b, \"B\")\nRel(a, b, \"uses\", $descr=\"V\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=person parent=global descr=
      #|shape alias=b label=B kind=person parent=global descr=
      #|rel type=rel from=a to=b label=uses descr=V
    ),
  )
}

///|
test "c4NamedAttributes: Rel(a, b, \"uses\", $tags=\"V\")" {
  inspect(
    parsed(
      "C4Context\nPerson(a, \"A\")\nPerson(b, \"B\")\nRel(a, b, \"uses\", $tags=\"V\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=person parent=global descr=
      #|shape alias=b label=B kind=person parent=global descr=
      #|rel type=rel from=a to=b label=uses descr= tags=V
    ),
  )
}

///|
test "c4NamedAttributes: Rel(a, b, \"uses\", $sprite=\"V\")" {
  inspect(
    parsed(
      "C4Context\nPerson(a, \"A\")\nPerson(b, \"B\")\nRel(a, b, \"uses\", $sprite=\"V\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=person parent=global descr=
      #|shape alias=b label=B kind=person parent=global descr=
      #|rel type=rel from=a to=b label=uses descr= sprite=V
    ),
  )
}

///|
test "c4NamedAttributes: Rel(a, b, \"uses\", $link=\"V\")" {
  inspect(
    parsed(
      "C4Context\nPerson(a, \"A\")\nPerson(b, \"B\")\nRel(a, b, \"uses\", $link=\"V\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=person parent=global descr=
      #|shape alias=b label=B kind=person parent=global descr=
      #|rel type=rel from=a to=b label=uses descr= link=V
    ),
  )
}
