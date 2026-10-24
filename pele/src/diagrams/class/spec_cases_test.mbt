// The parses, graphs and members Mermaid's class specs ask for, as pele v1.8.0 runs them in tests/compat/class, with what pele makes of each.
// A session is the statements of one spec on one model, in order.

///|
let spec_sessions : Array[Array[(String, String, String)]] = [
  [
    (
      "parse", "classDiagram\nclass __proto__", "direction=TB title=- accTitle=- accDescr=-\nclass __proto__ type= label=__proto__ css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "parse", "classDiagram\nnamespace __proto__ {\n\tclass A\n}", "direction=TB title=- accTitle=- accDescr=-\nclass __proto__ type= label=__proto__ css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass A type= label=A css=default parent=__proto__ link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nns __proto__ label=__proto__ parent=- explicit=true classes=[A] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass constructor", "direction=TB title=- accTitle=- accDescr=-\nclass constructor type= label=constructor css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
    (
      "parse", "classDiagram\nnamespace constructor {\n\tclass A\n}", "direction=TB title=- accTitle=- accDescr=-\nclass constructor type= label=constructor css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass A type= label=A css=default parent=constructor link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nns constructor label=constructor parent=- explicit=true classes=[A] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nnamespace `A::B` {\n\tclass `IPC::Sender`\n}", "direction=TB title=- accTitle=- accDescr=-\nclass IPC::Sender type= label=IPC::Sender css=default parent=A::B link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nns A::B label=A::B parent=- explicit=true classes=[IPC::Sender] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class01:::exClass", "direction=TB title=- accTitle=- accDescr=-\nclass Class01 type= label=Class01 css=default exClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1:::exClass {\nint : test\nstring : foo\ntest()\nfoo()\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default exClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int : test|||;|string : foo|||] methods=[|test|||;|foo|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass01 <|-- Class02\ncssClass \"Class01\" exClass",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class01 type= label=Class01 css=default exClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class01 Class02 t1=1 t2=none line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class01\n cssClass \"Class01\" exClass", "direction=TB title=- accTitle=- accDescr=-\nclass Class01 type= label=Class01 css=default exClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class01\n class Class02\n cssClass \"Class01,Class02\" exClass",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class01 type= label=Class01 css=default exClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default exClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class01\n class Class02\n style Class01 fill:#f9f,stroke:#333,stroke-width:4px",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class01 type= label=Class01 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#f9f;stroke:#333;stroke-width:4px] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class01\n cssClass \"Class01\" pink\n classDef pink fill:#f9f",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class01 type= label=Class01 css=default pink parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#f9f] members=[] methods=[]\ndef pink styles=[fill:#f9f] text=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class01:::pink\n classDef pink fill:#f9f", "direction=TB title=- accTitle=- accDescr=-\nclass Class01 type= label=Class01 css=default pink parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#f9f] members=[] methods=[]\ndef pink styles=[fill:#f9f] text=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class01:::pink\n classDef pink fill:#f9f,stroke:#333,stroke-width:6px",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class01 type= label=Class01 css=default pink parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#f9f;stroke:#333;stroke-width:6px] members=[] methods=[]\ndef pink styles=[fill:#f9f,stroke:#333,stroke-width:6px] text=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class01:::pink\n cssClass \"Class01\" bold\n classDef pink fill:#f9f\n classDef bold stroke:#333,stroke-width:6px",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class01 type= label=Class01 css=default pink bold parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#f9f;stroke:#333;stroke-width:6px] members=[] methods=[]\ndef pink styles=[fill:#f9f] text=[]\ndef bold styles=[stroke:#333,stroke-width:6px] text=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\n        namespace Company.Project {\n          class User {\n            +login(username: String, password: String)\n            +logout()\n          }\n        }\n        namespace Company.Project.Module {\n          class Admin {\n            +addUser(user: User)\n            +removeUser(user: User)\n          }\n        }",
      "direction=TB title=- accTitle=- accDescr=-\nclass User type= label=User css=default parent=Company.Project link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|login|username: String, password: String||;+|logout|||]\nclass Admin type= label=Admin css=default parent=Company.Project.Module link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|addUser|user: User||;+|removeUser|user: User||]\nns Company label=Company parent=- explicit=false classes=[] notes=[] children=[Company.Project]\nns Company.Project label=Project parent=Company explicit=true classes=[User] notes=[] children=[Company.Project.Module]\nns Company.Project.Module label=Module parent=Company.Project explicit=true classes=[Admin] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\n    namespace Company.Project.Module {\n        class GenericClass~T~ {\n            +addItem(item: T)\n            +getItem() T\n        }\n    }",
      "direction=TB title=- accTitle=- accDescr=-\nclass GenericClass type=T label=GenericClass css=default parent=Company.Project.Module link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|addItem|item: T||;+|getItem|||T]\nns Company label=Company parent=- explicit=false classes=[] notes=[] children=[Company.Project]\nns Company.Project label=Project parent=Company explicit=false classes=[] notes=[] children=[Company.Project.Module]\nns Company.Project.Module label=Module parent=Company.Project explicit=true classes=[GenericClass] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "      classDiagram\n        namespace Company.Project.Module.SubModule {\n          class Report {\n            +generatePDF(data: List)\n            +generateCSV(data: List)\n          }\n        }\n        namespace Company.Project.Module {\n          class Admin {\n            +generateReport()\n          }\n        }\n        Admin --> Report : generates",
      "direction=TB title=- accTitle=- accDescr=-\nclass Report type= label=Report css=default parent=Company.Project.Module.SubModule link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|generatePDF|data: List||;+|generateCSV|data: List||]\nclass Admin type= label=Admin css=default parent=Company.Project.Module link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|generateReport|||]\nrel Admin Report t1=none t2=3 line=0 titles=none/none title=generates\nns Company label=Company parent=- explicit=false classes=[] notes=[] children=[Company.Project]\nns Company.Project label=Project parent=Company explicit=false classes=[] notes=[] children=[Company.Project.Module]\nns Company.Project.Module label=Module parent=Company.Project explicit=true classes=[Admin] notes=[] children=[Company.Project.Module.SubModule]\nns Company.Project.Module.SubModule label=SubModule parent=Company.Project.Module explicit=true classes=[Report] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\n        namespace Outer {\n          namespace Inner {\n            class Foo {\n              +bar()\n            }\n          }\n          class Baz {\n            +qux()\n          }\n        }",
      "direction=TB title=- accTitle=- accDescr=-\nclass Foo type= label=Foo css=default parent=Outer.Inner link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|bar|||]\nclass Baz type= label=Baz css=default parent=Outer link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|qux|||]\nns Outer label=Outer parent=- explicit=true classes=[Baz] notes=[] children=[Outer.Inner]\nns Outer.Inner label=Inner parent=Outer explicit=true classes=[Foo] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\n          namespace Company.Engineering.Backend {\n            class Developer {\n              +writeCode()\n            }\n          }\n          namespace Company {\n            class CEO {\n              +makeDecisions()\n            }\n          }",
      "direction=TB title=- accTitle=- accDescr=-\nclass Developer type= label=Developer css=default parent=Company.Engineering.Backend link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|writeCode|||]\nclass CEO type= label=CEO css=default parent=Company link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|makeDecisions|||]\nns Company label=Company parent=- explicit=true classes=[CEO] notes=[] children=[Company.Engineering]\nns Company.Engineering label=Engineering parent=Company explicit=false classes=[] notes=[] children=[Company.Engineering.Backend]\nns Company.Engineering.Backend label=Backend parent=Company.Engineering explicit=true classes=[Developer] notes=[] children=[]",
    ),
    (
      "graph", "false", "node Company label=Company group=true shape=rect parentId=- parent=-1 class=- color=-\nnode Company.Engineering.Backend label=Company.Engineering.Backend group=true shape=rect parentId=- parent=-1 class=- color=-\nnode Developer label=Developer group=false shape=classBox parentId=Company.Engineering.Backend parent=1 class=Developer color=0\nnode CEO label=CEO group=false shape=classBox parentId=Company parent=0 class=CEO color=1",
    ),
  ],
  [
    (
      "parse", "classDiagram\n          namespace Company.Engineering.Backend {\n            class Developer\n          }\n          namespace Company {\n            class CEO\n          }",
      "direction=TB title=- accTitle=- accDescr=-\nclass Developer type= label=Developer css=default parent=Company.Engineering.Backend link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass CEO type= label=CEO css=default parent=Company link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nns Company label=Company parent=- explicit=true classes=[CEO] notes=[] children=[Company.Engineering]\nns Company.Engineering label=Engineering parent=Company explicit=false classes=[] notes=[] children=[Company.Engineering.Backend]\nns Company.Engineering.Backend label=Backend parent=Company.Engineering explicit=true classes=[Developer] notes=[] children=[]",
    ),
    (
      "graph", "false", "node Company label=Company group=true shape=rect parentId=- parent=-1 class=- color=-\nnode Company.Engineering.Backend label=Company.Engineering.Backend group=true shape=rect parentId=- parent=-1 class=- color=-\nnode Developer label=Developer group=false shape=classBox parentId=Company.Engineering.Backend parent=1 class=Developer color=0\nnode CEO label=CEO group=false shape=classBox parentId=Company parent=0 class=CEO color=1",
    ),
  ],
  [
    (
      "parse", "classDiagram\n        namespace A.B {\n          class Foo\n        }",
      "direction=TB title=- accTitle=- accDescr=-\nclass Foo type= label=Foo css=default parent=A.B link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nns A label=A parent=- explicit=false classes=[] notes=[] children=[A.B]\nns A.B label=B parent=A explicit=true classes=[Foo] notes=[] children=[]",
    ),
    (
      "graph", "true", "node A label=A group=true shape=rect parentId=- parent=-1 class=- color=-\nnode A.B label=B group=true shape=rect parentId=A parent=0 class=- color=-\nnode Foo label=Foo group=false shape=classBox parentId=A.B parent=1 class=Foo color=0",
    ),
  ],
  [
    (
      "parse", "classDiagram\n        namespace Auth[\"Authentication Service\"] {\n          class UserService {\n            +login()\n          }\n        }",
      "direction=TB title=- accTitle=- accDescr=-\nclass UserService type= label=UserService css=default parent=Auth link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|login|||]\nns Auth label=Authentication Service parent=- explicit=true classes=[UserService] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\n            accTitle: My Title\n            accDescr: My Description",
      "direction=TB title=- accTitle=My Title accDescr=My Description",
    ),
  ],
  [
    (
      "parse", "classDiagram\n            accTitle: My Title\n            accDescr {\n              This is my multi\n              line description\n            }",
      "direction=TB title=- accTitle=My Title accDescr=This is my multi\nline description",
    ),
  ],
  [
    (
      "parse", "classDiagram\n        namespace Company.Project.Module {\n          class User\n          class Admin\n        }\n          Admin --> User : manages",
      "direction=TB title=- accTitle=- accDescr=-\nclass User type= label=User css=default parent=Company.Project.Module link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Admin type= label=Admin css=default parent=Company.Project.Module link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Admin User t1=none t2=3 line=0 titles=none/none title=manages\nns Company label=Company parent=- explicit=false classes=[] notes=[] children=[Company.Project]\nns Company.Project label=Project parent=Company explicit=false classes=[] notes=[] children=[Company.Project.Module]\nns Company.Project.Module label=Module parent=Company.Project explicit=true classes=[User,Admin] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass `Car`", "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Ca-r", "direction=TB title=- accTitle=- accDescr=-\nclass Ca-r type= label=Ca-r css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass `A_Car`", "direction=TB title=- accTitle=- accDescr=-\nclass A_Car type= label=A_Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Foo1 {\n  You can use\n  several lines\n..\nas you want\nand group\n==\nthings together.\n__\nYou can have as many groups\nas you want\n--\nEnd of class\n}\n\nclass User {\n.. Simple Getter ..\n+ getName()\n+ getAddress()\n.. Some setter ..\n+ setName()\n__ private data __\nint age\n-- encrypted --\nString password\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Foo1 type= label=Foo1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|You can use|||;|several lines|||;|..|||;|as you want|||;|and group|||;|==|||;|things together.|||;|__|||;|You can have as many groups|||;|as you want|||;-|-|||;|End of class|||] methods=[]\nclass User type= label=User css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|.. Simple Getter ..|||;|.. Some setter ..|||;|__ private data __|||;|int age|||;-|- encrypted --|||;|String password|||] methods=[+| getName|||;+| getAddress|||;+| setName|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"]", "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"]\nclass C2[\"Class 2 with chars @?\"]\n",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C2 type= label=Class 2 with chars @? css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"]\nC1: member1",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|member1|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"]\n<<interface>> C1\nC1 : int member1",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[|int member1|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"]:::styleClass",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default styleClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"]\nC1 : int member1\ncssClass \"C1\" styleClass",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default styleClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int member1|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"]\nC1 : int member1\nclass C2[\"Long long long long long long long long long long label\"]\ncssClass \"C1,C2\" styleClass",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default styleClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int member1|||] methods=[]\nclass C2 type= label=Long long long long long long long long long long label css=default styleClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"]:::styleClass1\nclass C2[\"Class 2 !@#$%^&*() label\"]:::styleClass2",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default styleClass1 parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C2 type= label=Class 2 !@#$%^&*() label css=default styleClass2 parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1~T~\ncssClass \"C1~T~\" styleClass", "direction=TB title=- accTitle=- accDescr=-\nclass C1 type=T label=C1 css=default styleClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1~T~:::styleClass", "direction=TB title=- accTitle=- accDescr=-\nclass C1 type=T label=C1 css=default styleClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1~T~\nclick C1~T~ call someFunction()", "direction=TB title=- accTitle=- accDescr=-\nclass C1 type=T label=C1 css=default clickable parent=- link=- target=- callback=true tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1~T~\nclick C1~T~ call cb() \"a tip\"", "direction=TB title=- accTitle=- accDescr=-\nclass C1 type=T label=C1 css=default clickable parent=- link=- target=- callback=true tooltip=a tip annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1~T~\nlink C1~T~ \"https://example.com\"", "direction=TB title=- accTitle=- accDescr=-\nclass C1 type=T label=C1 css=default clickable parent=- link=https://example.com/ target=_blank callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class with text label\"]\nclass C2[\"Class with text label\"]\nclass C3[\"Class with text label\"]",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C2 type= label=Class with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C3 type= label=Class with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"OneWord\"]\nclass C2[\"With, Comma\"]\nclass C3[\"With (Brackets)\"]\nclass C4[\"With [Brackets]\"]\nclass C5[\"With {Brackets}\"]\nclass C6[\" \"]\nclass C7[\"With 1 number\"]\nclass C8[\"With . period...\"]\nclass C9[\"With - dash\"]\nclass C10[\"With _ underscore\"]\nclass C11[\"With ' single quote\"]\nclass C12[\"With ~!@#$%^&*()_+=-/?\"]\nclass C13[\"With Città foreign language\"]\n",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=OneWord css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C2 type= label=With, Comma css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C3 type= label=With (Brackets) css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C4 type= label=With [Brackets] css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C5 type= label=With {Brackets} css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C6 type= label=  css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C7 type= label=With 1 number css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C8 type= label=With . period... css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C9 type= label=With - dash css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C10 type= label=With _ underscore css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C11 type= label=With ' single quote css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C12 type= label=With ~!@#$%^&*()_+=-/? css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C13 type= label=With Città foreign language css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass11 <|.. Class12\nnote for Class11 \"test\"\n",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class11 type= label=Class11 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class12 type= label=Class12 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class11 Class12 t1=1 t2=none line=1 titles=none/none title=-\nnote note0 class=Class11 text=test index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nnote \"test\"\n", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=test index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: direction. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: direction. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: classDiagram. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: classDiagram. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: classDiagram-v2. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: classDiagram-v2. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: namespace. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: namespace. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: {}. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: {}. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: {. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: {. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: }. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: }. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: (). It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: (). It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: (. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: (. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: ). It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: ). It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: []. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: []. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: [. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: [. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: ]. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: ]. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: class. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: class. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: \n. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: \n. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: cssClass. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: cssClass. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: callback. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: callback. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: link. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: link. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: click. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: click. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: note. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: note. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: note for. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: note for. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: <<. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: <<. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: >>. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: >>. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: call . It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: call . It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: ~. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: ~. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: ~Generic~. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: ~Generic~. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: _self. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: _self. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: _blank. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: _blank. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: _parent. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: _parent. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: _top. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: _top. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: <|. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: <|. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: |>. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: |>. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: >. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: >. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: <. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: <. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: *. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: *. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: o. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: o. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: \\. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: \\. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: --. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: --. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: ... It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: ... It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: -->. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: -->. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: --|>. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: --|>. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: : label. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: : label. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: :::. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: :::. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: .. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: .. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: +. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: +. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: alphaNum. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: alphaNum. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: !. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: !. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: 0123. It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: 0123. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: function(). It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: function(). It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                     note \"This is a keyword: function(arg1, arg2). It truly is.\"\n                  ",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=This is a keyword: function(arg1, arg2). It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"direction\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=direction index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"classDiagram\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=classDiagram index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"classDiagram-v2\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=classDiagram-v2 index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"namespace\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=namespace index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"{}\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text={} index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"{\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text={ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"}\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=} index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"()\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=() index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"(\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=( index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \")\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=) index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"[]\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=[] index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"[\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=[ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"]\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=] index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"class\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=class index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"\n\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=\n index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"cssClass\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=cssClass index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"callback\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=callback index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"link\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=link index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"click\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=click index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"note\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=note index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"note for\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=note for index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"<<\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=<< index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \">>\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=>> index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"call \"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=call  index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"~\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=~ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"~Generic~\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=~Generic~ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"_self\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=_self index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"_blank\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=_blank index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"_parent\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=_parent index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"_top\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=_top index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"<|\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=<| index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"|>\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=|> index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \">\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=> index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"<\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=< index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"*\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=* index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"o\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=o index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"\\\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=\\ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"--\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=-- index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"..\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=.. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"-->\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=--> index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"--|>\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=--|> index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \": label\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=: label index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \":::\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=::: index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \".\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"+\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=+ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"alphaNum\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=alphaNum index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"!\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=! index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"0123\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=0123 index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"function()\"", "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=function() index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                      note \"function(arg1, arg2)\"",
      "direction=TB title=- accTitle=- accDescr=-\nnote note0 class=- text=function(arg1, arg2) index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: direction. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: direction. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: classDiagram. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: classDiagram. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: classDiagram-v2. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: classDiagram-v2. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: namespace. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: namespace. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: {}. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: {}. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: {. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: {. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: }. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: }. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: (). It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: (). It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: (. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: (. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: ). It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: ). It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: []. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: []. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: [. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: [. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: ]. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: ]. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: class. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: class. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: \n. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: \n. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: cssClass. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: cssClass. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: callback. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: callback. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: link. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: link. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: click. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: click. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: note. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: note. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: note for. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: note for. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: <<. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: <<. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: >>. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: >>. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: call . It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: call . It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: ~. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: ~. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: ~Generic~. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: ~Generic~. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: _self. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: _self. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: _blank. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: _blank. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: _parent. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: _parent. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: _top. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: _top. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: <|. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: <|. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: |>. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: |>. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: >. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: >. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: <. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: <. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: *. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: *. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: o. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: o. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: \\. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: \\. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: --. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: --. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: ... It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: ... It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: -->. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: -->. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: --|>. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: --|>. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: : label. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: : label. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: :::. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: :::. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: .. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: .. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: +. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: +. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: alphaNum. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: alphaNum. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: !. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: !. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: 0123. It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: 0123. It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: function(). It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: function(). It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   class Something {\n                     int id\n                     string name\n                   }\n                   note for Something \"This is a keyword: function(arg1, arg2). It truly is.\"\n                   ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=This is a keyword: function(arg1, arg2). It truly is. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"direction\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=direction index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"classDiagram\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=classDiagram index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"classDiagram-v2\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=classDiagram-v2 index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"namespace\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=namespace index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"{}\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text={} index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"{\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text={ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"}\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=} index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"()\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=() index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"(\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=( index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \")\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=) index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"[]\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=[] index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"[\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=[ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"]\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=] index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"class\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=class index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"\n\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=\n index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"cssClass\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=cssClass index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"callback\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=callback index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"link\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=link index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"click\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=click index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"note\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=note index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"note for\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=note for index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"<<\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=<< index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \">>\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=>> index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"call \"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=call  index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"~\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=~ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"~Generic~\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=~Generic~ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"_self\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=_self index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"_blank\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=_blank index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"_parent\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=_parent index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"_top\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=_top index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"<|\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=<| index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"|>\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=|> index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \">\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=> index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"<\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=< index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"*\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=* index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"o\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=o index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"\\\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=\\ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"--\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=-- index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"..\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=.. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"-->\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=--> index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"--|>\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=--|> index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \": label\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=: label index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \":::\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=::: index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \".\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=. index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"+\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=+ index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"alphaNum\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=alphaNum index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"!\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=! index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"0123\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=0123 index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"function()\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=function() index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                    class Something {\n                      int id\n                      string name\n                    }\n                    note for Something \"function(arg1, arg2)\"\n                    ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Something type= label=Something css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|string name|||] methods=[]\nnote note0 class=Something text=function(arg1, arg2) index=0 parent=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note direction", "error: Parse error on line 2:\n                   note direction\n------------------------^\nExpecting 'STR', got 'ALPHA'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note classDiagram", "error: Parse error on line 2:\n                   note classDiagram\n------------------------^\nExpecting 'STR', got 'CLASS_DIAGRAM'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note classDiagram-v2", "error: Parse error on line 2:\n                   note classDiagram-v2\n------------------------^\nExpecting 'STR', got 'CLASS_DIAGRAM'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note namespace", "error: Parse error on line 2:\n                   note namespace\n------------------------^\nExpecting 'STR', got 'NAMESPACE'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note {}", "error: Lexical error on line 2. Unrecognized text.\n                   note {}\n------------------------^",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note {", "error: Lexical error on line 2. Unrecognized text.\n                   note {\n------------------------^",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note }", "error: Lexical error on line 2. Unrecognized text.\n                   note }\n------------------------^",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note ()", "error: Parse error on line 2:\n                   note ()\n------------------------^\nExpecting 'STR', got 'LOLLIPOP'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note (", "error: Lexical error on line 2. Unrecognized text.\n                   note (\n------------------------^",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note )", "error: Lexical error on line 2. Unrecognized text.\n                   note )\n------------------------^",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note []", "error: Parse error on line 2:\n                   note []\n------------------------^\nExpecting 'STR', got 'SQS'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note [", "error: Parse error on line 2:\n                   note [\n------------------------^\nExpecting 'STR', got 'SQS'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note ]", "error: Parse error on line 2:\n                   note ]\n------------------------^\nExpecting 'STR', got 'SQE'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note class", "error: Parse error on line 2:\n                   note class\n------------------------^\nExpecting 'STR', got 'CLASS'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note \n", "error: Parse error on line 2:\n                   note \n-----------------------^\nExpecting 'STR', got 'NEWLINE'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note cssClass", "error: Parse error on line 2:\n                   note cssClass\n------------------------^\nExpecting 'STR', got 'CSSCLASS'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note callback", "error: Parse error on line 2:\n                   note callback\n------------------------^\nExpecting 'STR', got 'CALLBACK'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note link", "error: Parse error on line 2:\n                   note link\n------------------------^\nExpecting 'STR', got 'LINK'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note click", "error: Parse error on line 2:\n                   note click\n------------------------^\nExpecting 'STR', got 'CLICK'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note note", "error: Parse error on line 2:\n                   note note\n------------------------^\nExpecting 'STR', got 'NOTE'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note note for", "error: Parse error on line 2:\n                   note note for\n------------------------^\nExpecting 'STR', got 'NOTE_FOR'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note <<", "error: Parse error on line 2:\n                   note <<\n------------------------^\nExpecting 'STR', got 'ANNOTATION_START'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note >>", "error: Parse error on line 2:\n                   note >>\n------------------------^\nExpecting 'STR', got 'ANNOTATION_END'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note call ", "error: Parse error on line 2:\n                   note call \n-----------------------------^\nExpecting 'STR', got 'CALLBACK_NAME'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note ~", "error: Parse error on line 2:\n                   note ~\n-------------------------^\nExpecting 'STR', got 'GENERICTYPE'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note ~Generic~", "error: Parse error on line 2:\n                   note ~Generic~\n-------------------------^\nExpecting 'STR', got 'GENERICTYPE'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note _self", "error: Parse error on line 2:\n                   note _self\n------------------------^\nExpecting 'STR', got 'LINK_TARGET'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note _blank", "error: Parse error on line 2:\n                   note _blank\n------------------------^\nExpecting 'STR', got 'LINK_TARGET'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note _parent", "error: Parse error on line 2:\n                   note _parent\n------------------------^\nExpecting 'STR', got 'LINK_TARGET'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note _top", "error: Parse error on line 2:\n                   note _top\n------------------------^\nExpecting 'STR', got 'LINK_TARGET'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note <|", "error: Parse error on line 2:\n                   note <|\n------------------------^\nExpecting 'STR', got 'EXTENSION'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note |>", "error: Parse error on line 2:\n                   note |>\n------------------------^\nExpecting 'STR', got 'EXTENSION'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note >", "error: Parse error on line 2:\n                   note >\n------------------------^\nExpecting 'STR', got 'DEPENDENCY'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note <", "error: Parse error on line 2:\n                   note <\n------------------------^\nExpecting 'STR', got 'DEPENDENCY'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note *", "error: Parse error on line 2:\n                   note *\n------------------------^\nExpecting 'STR', got 'COMPOSITION'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note o", "error: Parse error on line 2:\n                   note o\n------------------------^\nExpecting 'STR', got 'AGGREGATION'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note \\", "error: Parse error on line 2:\n                   note \\\n------------------------^\nExpecting 'STR', got 'PUNCTUATION'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note --", "error: Parse error on line 2:\n                   note --\n------------------------^\nExpecting 'STR', got 'LINE'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note ..", "error: Parse error on line 2:\n                   note ..\n------------------------^\nExpecting 'STR', got 'DOTTED_LINE'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note -->", "error: Parse error on line 2:\n                   note -->\n------------------------^\nExpecting 'STR', got 'LINE'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note --|>", "error: Parse error on line 2:\n                   note --|>\n------------------------^\nExpecting 'STR', got 'LINE'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note : label", "error: Parse error on line 2:\n                   note : label\n------------------------^\nExpecting 'STR', got 'LABEL'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note :::", "error: Parse error on line 2:\n                   note :::\n------------------------^\nExpecting 'STR', got 'STYLE_SEPARATOR'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note .", "error: Parse error on line 2:\n                   note .\n------------------------^\nExpecting 'STR', got 'DOT'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note +", "error: Parse error on line 2:\n                   note +\n------------------------^\nExpecting 'STR', got 'PLUS'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note alphaNum", "error: Parse error on line 2:\n                   note alphaNum\n------------------------^\nExpecting 'STR', got 'ALPHA'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note !", "error: Parse error on line 2:\n                   note !\n------------------------^\nExpecting 'STR', got 'PUNCTUATION'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note 0123", "error: Parse error on line 2:\n                   note 0123\n------------------------^\nExpecting 'STR', got 'ALPHA'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note function()", "error: Parse error on line 2:\n                   note function()\n------------------------^\nExpecting 'STR', got 'ALPHA'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n                   note function(arg1, arg2)", "error: Parse error on line 2:\n                   note function(arg1, arg2)\n------------------------^\nExpecting 'STR', got 'ALPHA'",
    ),
  ],
  [
    (
      "parse", "classDiagram\n          direction RL\n          class A", "direction=RL title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\n          class B", "direction=TB title=- accTitle=- accDescr=-\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car{\n+int wheels\n}", "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|int wheels|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car{\n+size()\n}", "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|size|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car{\n+int wheels\n}\nCar : +ArrayList size()\n",
      "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|int wheels|||] methods=[+|ArrayList size|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Dummy_Class {\nString data\nvoid methods()\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Dummy_Class type= label=Dummy_Class css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|String data|||] methods=[|void methods|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Flight {\nint flightNumber\ndatetime departureTime\ngetDepartureTime() datetime\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Flight type= label=Flight css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int flightNumber|||;|datetime departureTime|||] methods=[|getDepartureTime|||datetime]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 {\nint testMember\ntest()\nstring fooMember\nfoo()\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int testMember|||;|string fooMember|||] methods=[|test|||;|foo|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"] {\n+member1\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|member1|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"] {\n<<interface>>\n+member1\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[+|member1|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "%% Comment\n        classDiagram\n        class Class1 {\n          int : test\n          string : foo\n          test()\n          foo()\n        }",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int : test|||;|string : foo|||] methods=[|test|||;|foo|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 {\nint : test\nstring : foo\ntest()\nfoo()\n\n}\n%% Comment\n",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int : test|||;|string : foo|||] methods=[|test|||;|foo|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 {\nint : test\nstring : foo\ntest()\nfoo()\n}\n%% Comment",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int : test|||;|string : foo|||] methods=[|test|||;|foo|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\n\n\n%% Comment\n\nclass Class1 {\nint : test\nstring : foo\ntest()\nfoo()\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int : test|||;|string : foo|||] methods=[|test|||;|foo|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\n%% Comment Class1 <|-- Class02\nclass Class1 {\nint : test\nstring : foo\ntest()\nfoo()\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int : test|||;|string : foo|||] methods=[|test|||;|foo|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 {\n%% Comment Class1 <|-- Class02\nint : test\nstring : foo\ntest()\nfoo()\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|%% Comment Class1 <|-- Class02|||;|int : test|||;|string : foo|||] methods=[|test|||;|foo|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 \nclick Class1 href \"google.com\" ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=google.com target=_blank callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 \nclick Class1 href \"google.com\" \"A Tooltip\" ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=google.com target=_blank callback=false tooltip=A Tooltip annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nclick Class1 href \"google.com\" \"A tooltip\" _self",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=google.com target=_self callback=false tooltip=A tooltip annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 \nclick Class1 call functionCall() ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=- target=- callback=true tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 \nclick Class1 call functionCall() \"A Tooltip\" ",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=- target=- callback=true tooltip=A Tooltip annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nclick Class1 call functionCall(test, test1, test2)",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=- target=- callback=true tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nclick Class1 call functionCall(\"test0\", test1, test2) \"A Tooltip\"",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=- target=- callback=true tooltip=A Tooltip annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\n<<interface>> Class1", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : int test\nClass1 : test()\n<<interface>> Class1",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[|int test|||] methods=[|test|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 {\n<<interface>>\n}", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 {\n<<interface>>\nint : test\ntest()\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[|int : test|||] methods=[|test|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Shape\n<<interface>> Shape\nShape : noOfVertices\nShape : draw()",
      "direction=TB title=- accTitle=- accDescr=-\nclass Shape type= label=Shape css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[|noOfVertices|||] methods=[|draw|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Shape{\n    <<interface>>\n    noOfVertices\n    draw()\n}\nclass Color{\n    <<enumeration>>\n    RED\n    BLUE\n    GREEN\n    WHITE\n    BLACK\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Shape type= label=Shape css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[|noOfVertices|||] methods=[|draw|||]\nclass Color type= label=Color css=default parent=- link=- target=- callback=false tooltip=- annotations=[enumeration] styles=[] members=[|RED|||;|BLUE|||;|GREEN|||;|WHITE|||;|BLACK|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Shape <<interface>>", "direction=TB title=- accTitle=- accDescr=-\nclass Shape type= label=Shape css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Shape <<interface>> {\n    noOfVertices\n    draw()\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Shape type= label=Shape css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[|noOfVertices|||] methods=[|draw|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Shape <<interface>> {\n}", "direction=TB title=- accTitle=- accDescr=-\nclass Shape type= label=Shape css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car\nCar : wheels", "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|wheels|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nCar : wheels", "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|wheels|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nCar : int wheels", "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int wheels|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car\nCar : int wheels", "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int wheels|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass actual\nactual : -int privateMember\nactual : +int publicMember\nactual : #int protectedMember\nactual : ~int privatePackage",
      "direction=TB title=- accTitle=- accDescr=-\nclass actual type= label=actual css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[-|int privateMember|||;+|int publicMember|||;#|int protectedMember|||;~|int privatePackage|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car\nCar : -List~Wheel~ wheels", "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[-|List~Wheel~ wheels|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car\nCar : GetSize()", "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[|GetSize|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Object\nObject : getObject() Object", "direction=TB title=- accTitle=- accDescr=-\nclass Object type= label=Object css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[|getObject|||Object]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Object\nObject : getObjects() Object[]", "direction=TB title=- accTitle=- accDescr=-\nclass Object type= label=Object css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[|getObjects|||Object[]]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass actual\nactual : -privateMethod()\nactual : +publicMethod()\nactual : #protectedMethod()\n",
      "direction=TB title=- accTitle=- accDescr=-\nclass actual type= label=actual css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[-|privateMethod|||;+|publicMethod|||;#|protectedMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()*", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod||*|]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()$", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod||$|]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car\nCar : +setWheels(List~Wheel~ wheels)", "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|setWheels|List~Wheel~ wheels||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car\nCar : +getWheels() List~Wheel~", "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[+|getWheels|||List~Wheel~]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car {\nList~Wheel~ wheels\nsetWheels(List~Wheel~ wheels)\n+getWheels() List~Wheel~\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|List~Wheel~ wheels|||] methods=[|setWheels|List~Wheel~ wheels||;+|getWheels|||List~Wheel~]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass EmptyClass {}", "direction=TB title=- accTitle=- accDescr=-\nclass EmptyClass type= label=EmptyClass css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car~T~", "direction=TB title=- accTitle=- accDescr=-\nclass Car type=T label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car~T~\nDriver -- Car : drives >\nCar *-- Wheel : have 4 >\nCar -- Person : < owns",
      "direction=TB title=- accTitle=- accDescr=-\nclass Car type=T label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Driver type= label=Driver css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Wheel type= label=Wheel css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Person type= label=Person css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Driver Car t1=none t2=none line=0 titles=none/none title=drives >\nrel Car Wheel t1=2 t2=none line=0 titles=none/none title=have 4 >\nrel Car Person t1=none t2=none line=0 titles=none/none title=< owns",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass `Car`~T~\nDriver -- `Car` : drives >\n`Car` *-- Wheel : have 4 >\n`Car` -- Person : < owns",
      "direction=TB title=- accTitle=- accDescr=-\nclass Car type=T label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Driver type= label=Driver css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Wheel type= label=Wheel css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Person type= label=Person css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Driver Car t1=none t2=none line=0 titles=none/none title=drives >\nrel Car Wheel t1=2 t2=none line=0 titles=none/none title=have 4 >\nrel Car Person t1=none t2=none line=0 titles=none/none title=< owns",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Dummy_Class~T~ {\nString data\nvoid methods()\n}\n\nclass Flight {\nInteger flightNumber\nDate departureTime\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Dummy_Class type=T label=Dummy_Class css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|String data|||] methods=[|void methods|||]\nclass Flight type= label=Flight css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|Integer flightNumber|||;|Date departureTime|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass `Dummy_Class`~T~ {\nString data\n  void methods()\n}\n\nclass Flight {\n   flightNumber : Integer\n   departureTime : Date\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Dummy_Class type=T label=Dummy_Class css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|String data|||] methods=[|void methods|||]\nclass Flight type= label=Flight css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|flightNumber : Integer|||;|departureTime : Date|||] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nnamespace Namespace1 { class Class1 }\nnamespace Namespace2 { class Class1\n}\nnamespace Namespace3 {\nclass Class1 {\nint : test\nstring : foo\ntest()\nfoo()\n}\n}\nnamespace Namespace4 {\nclass Class1 {\nint : test\nstring : foo\ntest()\nfoo()\n}\nclass Class2 {\nint : test\nstring : foo\ntest()\nfoo()\n}\n}\n",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=Namespace4 link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int : test|||;|string : foo|||;|int : test|||;|string : foo|||] methods=[|test|||;|foo|||;|test|||;|foo|||]\nclass Class2 type= label=Class2 css=default parent=Namespace4 link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int : test|||;|string : foo|||] methods=[|test|||;|foo|||]\nns Namespace1 label=Namespace1 parent=- explicit=true classes=[Class1] notes=[] children=[]\nns Namespace2 label=Namespace2 parent=- explicit=true classes=[Class1] notes=[] children=[]\nns Namespace3 label=Namespace3 parent=- explicit=true classes=[Class1] notes=[] children=[]\nns Namespace4 label=Namespace4 parent=- explicit=true classes=[Class1,Class2] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\n\nnamespace space {\n    class Square~Shape~{\n        int id\n        List~int~ position\n        setPoints(List~int~ points)\n        getPoints() List~int~\n    }\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Square type=Shape label=Square css=default parent=space link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int id|||;|List~int~ position|||] methods=[|setPoints|List~int~ points||;|getPoints|||List~int~]\nns space label=space parent=- explicit=true classes=[Square] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass1 <|-- Class02\nClass03 *-- Class04\nClass05 o-- Class06\nClass07 .. Class08\nClass09 -- Class1",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class03 type= label=Class03 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class04 type= label=Class04 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class05 type= label=Class05 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class06 type= label=Class06 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class07 type= label=Class07 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class08 type= label=Class08 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class09 type= label=Class09 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class1 Class02 t1=1 t2=none line=0 titles=none/none title=-\nrel Class03 Class04 t1=2 t2=none line=0 titles=none/none title=-\nrel Class05 Class06 t1=0 t2=none line=0 titles=none/none title=-\nrel Class07 Class08 t1=none t2=none line=1 titles=none/none title=-\nrel Class09 Class1 t1=none t2=none line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n`Class1` <|-- Class02\nClass03 *-- Class04\nClass05 o-- Class06\nClass07 .. Class08\nClass09 -- Class1",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class03 type= label=Class03 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class04 type= label=Class04 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class05 type= label=Class05 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class06 type= label=Class06 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class07 type= label=Class07 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class08 type= label=Class08 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class09 type= label=Class09 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class1 Class02 t1=1 t2=none line=0 titles=none/none title=-\nrel Class03 Class04 t1=2 t2=none line=0 titles=none/none title=-\nrel Class05 Class06 t1=0 t2=none line=0 titles=none/none title=-\nrel Class07 Class08 t1=none t2=none line=1 titles=none/none title=-\nrel Class09 Class1 t1=none t2=none line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass1~T~ <|-- Class02", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type=T label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class1 Class02 t1=1 t2=none line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Car\nDriver -- Car : drives >\nCar *-- Wheel : have 4 >\nCar -- Person : < owns",
      "direction=TB title=- accTitle=- accDescr=-\nclass Car type= label=Car css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Driver type= label=Driver css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Wheel type= label=Wheel css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Person type= label=Person css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Driver Car t1=none t2=none line=0 titles=none/none title=drives >\nrel Car Wheel t1=2 t2=none line=0 titles=none/none title=have 4 >\nrel Car Person t1=none t2=none line=0 titles=none/none title=< owns",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass1 <|-- Class02", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class1 Class02 t1=1 t2=none line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass11 <|.. Class12\nClass13 --> Class14\nClass15 ..> Class16\nClass17 ..|> Class18\nClass19 <--* Class20",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class11 type= label=Class11 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class12 type= label=Class12 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class13 type= label=Class13 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class14 type= label=Class14 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class15 type= label=Class15 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class16 type= label=Class16 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class17 type= label=Class17 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class18 type= label=Class18 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class19 type= label=Class19 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class20 type= label=Class20 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class11 Class12 t1=1 t2=none line=1 titles=none/none title=-\nrel Class13 Class14 t1=none t2=3 line=0 titles=none/none title=-\nrel Class15 Class16 t1=none t2=3 line=1 titles=none/none title=-\nrel Class17 Class18 t1=none t2=1 line=1 titles=none/none title=-\nrel Class19 Class20 t1=3 t2=2 line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass1 \"1\" *-- \"many\" Class02 : contains\nClass03 o-- Class04 : aggregation\nClass05 --> \"1\" Class06",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class03 type= label=Class03 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class04 type= label=Class04 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class05 type= label=Class05 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class06 type= label=Class06 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class1 Class02 t1=2 t2=none line=0 titles=1/many title=contains\nrel Class03 Class04 t1=0 t2=none line=0 titles=none/none title=aggregation\nrel Class05 Class06 t1=none t2=3 line=0 titles=none/1 title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass11 <|.. Class12\nClass13 <.. Class14\nClass15 ..|> Class16\nClass17 ..> Class18\nClass19 .. Class20",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class11 type= label=Class11 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class12 type= label=Class12 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class13 type= label=Class13 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class14 type= label=Class14 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class15 type= label=Class15 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class16 type= label=Class16 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class17 type= label=Class17 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class18 type= label=Class18 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class19 type= label=Class19 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class20 type= label=Class20 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class11 Class12 t1=1 t2=none line=1 titles=none/none title=-\nrel Class13 Class14 t1=3 t2=none line=1 titles=none/none title=-\nrel Class15 Class16 t1=none t2=1 line=1 titles=none/none title=-\nrel Class17 Class18 t1=none t2=3 line=1 titles=none/none title=-\nrel Class19 Class20 t1=none t2=none line=1 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass1 o.. Class02", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class1 Class02 t1=0 t2=none line=1 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass1 *--* Class02", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class1 Class02 t1=2 t2=2 line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass1 -- Class02", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class1 Class02 t1=none t2=none line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass1 --|> Class02", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class1 Class02 t1=none t2=1 line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass1 <|-- Class02\nClass03 *-- Class04\nClass05 o-- Class06\nClass07 .. Class08\nClass09 -- Class10",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class03 type= label=Class03 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class04 type= label=Class04 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class05 type= label=Class05 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class06 type= label=Class06 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class07 type= label=Class07 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class08 type= label=Class08 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class09 type= label=Class09 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class10 type= label=Class10 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class1 Class02 t1=1 t2=none line=0 titles=none/none title=-\nrel Class03 Class04 t1=2 t2=none line=0 titles=none/none title=-\nrel Class05 Class06 t1=0 t2=none line=0 titles=none/none title=-\nrel Class07 Class08 t1=none t2=none line=1 titles=none/none title=-\nrel Class09 Class10 t1=none t2=none line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nClass01~T~ <|-- Class02", "direction=TB title=- accTitle=- accDescr=-\nclass Class01 type=T label=Class01 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Class02 type= label=Class02 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel Class01 Class02 t1=1 t2=none line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\n<<interface>> Class1", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : int test\nClass1 : test()\n<<interface>> Class1",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[|int test|||] methods=[|test|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 {\n<<interface>>\n}", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[] methods=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 {\n<<interface>>\nint : test\ntest()\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[|int : test|||] methods=[|test|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1 {\nint : test\nstring : foo\ntest()\nfoo()\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int : test|||;|string : foo|||] methods=[|test|||;|foo|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()*", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod||*|]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()$", "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod||$|]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nlink Class1 \"google.com\"",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=google.com target=_blank callback=false tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nclick Class1 href \"google.com\"",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=google.com target=_blank callback=false tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nlink Class1 \"google.com\" \"A tooltip\"",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=google.com target=_blank callback=false tooltip=A tooltip annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nclick Class1 href \"google.com\" \"A tooltip\"",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=google.com target=_blank callback=false tooltip=A tooltip annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nclick Class1 href \"google.com\" \"A tooltip\" _self",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=google.com target=_self callback=false tooltip=A tooltip annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nclick Class1 href \"google.com\"",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=google.com target=_blank callback=false tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nclick Class1 href \"google.com\" _self",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=google.com target=_self callback=false tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nlink Class1 \"google.com\" \"A tooltip\" _self",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=google.com target=_self callback=false tooltip=A tooltip annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\ncallback Class1 \"functionCall\"",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=- target=- callback=true tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nclick Class1 call functionCall()",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=- target=- callback=true tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nclick Class1 call functionCall(\"test0\", test1, test2)",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=- target=- callback=true tooltip=- annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass Class1\nClass1 : someMethod()\nclick Class1 call functionCall() \"A tooltip\"",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default clickable parent=- link=- target=- callback=true tooltip=A tooltip annotations=[] styles=[] members=[] methods=[|someMethod|||]",
    ),
  ],
  [
    (
      "parse", "classDiagram\nnamespace Namespace1 {\nclass Class1 {\nint : test\nstring : foo\ntest()\nfoo()\n}\nclass Class2\n}",
      "direction=TB title=- accTitle=- accDescr=-\nclass Class1 type= label=Class1 css=default parent=Namespace1 link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|int : test|||;|string : foo|||] methods=[|test|||;|foo|||]\nclass Class2 type= label=Class2 css=default parent=Namespace1 link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nns Namespace1 label=Namespace1 parent=- explicit=true classes=[Class1,Class2] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\n      A1 --> B1\n      namespace A {\n        class A1 {\n          +foo : string\n        }\n        class A2 {\n          +bar : int\n        }\n      }\n      namespace B {\n        class B1 {\n          +foo : bool\n        }\n        class B2 {\n          +bar : float\n        }\n      }\n      A2 --> B2",
      "direction=TB title=- accTitle=- accDescr=-\nclass A1 type= label=A1 css=default parent=A link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|foo : string|||] methods=[]\nclass B1 type= label=B1 css=default parent=B link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|foo : bool|||] methods=[]\nclass A2 type= label=A2 css=default parent=A link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|bar : int|||] methods=[]\nclass B2 type= label=B2 css=default parent=B link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|bar : float|||] methods=[]\nrel A1 B1 t1=none t2=3 line=0 titles=none/none title=-\nrel A2 B2 t1=none t2=3 line=0 titles=none/none title=-\nns A label=A parent=- explicit=true classes=[A1,A2] notes=[] children=[]\nns B label=B parent=- explicit=true classes=[B1,B2] notes=[] children=[]",
    ),
  ],
  [
    (
      "parse", "classDiagram\n  class C1[\"Class 1 with text label\"]\n  C1 -->  C2\n      ",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C2 type= label=C2 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel C1 C2 t1=none t2=3 line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n  class C1[\"Class 1 with text label\"]\n  class C2[\"Class 2 with chars @?\"]\n  C1 -->  C2\n      ",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C2 type= label=Class 2 with chars @? css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel C1 C2 t1=none t2=3 line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n  class C1[\"Class 1 with text label\"] {\n    +member1\n  }\n  C1 -->  C2\n      ",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|member1|||] methods=[]\nclass C2 type= label=C2 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel C1 C2 t1=none t2=3 line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\n  class C1[\"Class 1 with text label\"] {\n    <<interface>>\n    +member1\n  }\n  C1 -->  C2\n      ",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[+|member1|||] methods=[]\nclass C2 type= label=C2 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel C1 C2 t1=none t2=3 line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"]:::styleClass {\n  +member1\n}\nC1 -->  C2\n  ",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default styleClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|member1|||] methods=[]\nclass C2 type= label=C2 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel C1 C2 t1=none t2=3 line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"] {\n  +member1\n}\nC1 --> C2\ncssClass \"C1\" styleClass\n  ",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default styleClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|member1|||] methods=[]\nclass C2 type= label=C2 css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel C1 C2 t1=none t2=3 line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"] {\n  +member1\n}\nclass C2[\"Long long long long long long long long long long label\"]\nC1 --> C2\ncssClass \"C1,C2\" styleClass\n  ",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default styleClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|member1|||] methods=[]\nclass C2 type= label=Long long long long long long long long long long label css=default styleClass parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel C1 C2 t1=none t2=3 line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class 1 with text label\"]:::styleClass1 {\n  +member1\n}\nclass C2[\"Class 2 !@#$%^&*() label\"]:::styleClass2\nC1 --> C2\n  ",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class 1 with text label css=default styleClass1 parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[+|member1|||] methods=[]\nclass C2 type= label=Class 2 !@#$%^&*() label css=default styleClass2 parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel C1 C2 t1=none t2=3 line=0 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"Class with text label\"]\nclass C2[\"Class with text label\"]\nclass C3[\"Class with text label\"]\nC1 --> C2\nC3 ..> C2\n  ",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=Class with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C2 type= label=Class with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C3 type= label=Class with text label css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel C1 C2 t1=none t2=3 line=0 titles=none/none title=-\nrel C3 C2 t1=none t2=3 line=1 titles=none/none title=-",
    ),
  ],
  [
    (
      "parse", "classDiagram\nclass C1[\"OneWord\"]\nclass C2[\"With, Comma\"]\nclass C3[\"With (Brackets)\"]\nclass C4[\"With [Brackets]\"]\nclass C5[\"With {Brackets}\"]\nclass C6[\" \"]\nclass C7[\"With 1 number\"]\nclass C8[\"With . period...\"]\nclass C9[\"With - dash\"]\nclass C10[\"With _ underscore\"]\nclass C11[\"With ' single quote\"]\nclass C12[\"With ~!@#$%^&*()_+=-/?\"]\nclass C13[\"With Città foreign language\"]\n",
      "direction=TB title=- accTitle=- accDescr=-\nclass C1 type= label=OneWord css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C2 type= label=With, Comma css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C3 type= label=With (Brackets) css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C4 type= label=With [Brackets] css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C5 type= label=With {Brackets} css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C6 type= label=  css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C7 type= label=With 1 number css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C8 type= label=With . period... css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C9 type= label=With - dash css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C10 type= label=With _ underscore css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C11 type= label=With ' single quote css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C12 type= label=With ~!@#$%^&*()_+=-/? css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass C13 type= label=With Città foreign language css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
    ),
  ],
]

///|
let spec_members : Array[(String, String, String)] = [
  ("getTime()", "method", "|getTime||||method|getTime()|"),
  ("+getTime()", "method", "+|getTime||||method|+getTime()|"),
  ("-getTime()", "method", "-|getTime||||method|-getTime()|"),
  ("#getTime()", "method", "#|getTime||||method|#getTime()|"),
  ("~getTime()", "method", "~|getTime||||method|~getTime()|"),
  (
    "getTime()$", "method", "|getTime||$||method|getTime()|text-decoration:underline;",
  ),
  ("getTime()*", "method", "|getTime||*||method|getTime()|font-style:italic;"),
  ("getTime(int)", "method", "|getTime|int|||method|getTime(int)|"),
  ("+getTime(int)", "method", "+|getTime|int|||method|+getTime(int)|"),
  ("-getTime(int)", "method", "-|getTime|int|||method|-getTime(int)|"),
  ("#getTime(int)", "method", "#|getTime|int|||method|#getTime(int)|"),
  ("~getTime(int)", "method", "~|getTime|int|||method|~getTime(int)|"),
  (
    "getTime(int)$", "method", "|getTime|int|$||method|getTime(int)|text-decoration:underline;",
  ),
  (
    "getTime(int)*", "method", "|getTime|int|*||method|getTime(int)|font-style:italic;",
  ),
  (
    "getTime(int count)", "method", "|getTime|int count|||method|getTime(int count)|",
  ),
  (
    "+getTime(int count)", "method", "+|getTime|int count|||method|+getTime(int count)|",
  ),
  (
    "-getTime(int count)", "method", "-|getTime|int count|||method|-getTime(int count)|",
  ),
  (
    "#getTime(int count)", "method", "#|getTime|int count|||method|#getTime(int count)|",
  ),
  (
    "~getTime(int count)", "method", "~|getTime|int count|||method|~getTime(int count)|",
  ),
  (
    "getTime(int count)$", "method", "|getTime|int count|$||method|getTime(int count)|text-decoration:underline;",
  ),
  (
    "getTime(int count)*", "method", "|getTime|int count|*||method|getTime(int count)|font-style:italic;",
  ),
  (
    "getTime(count int)", "method", "|getTime|count int|||method|getTime(count int)|",
  ),
  (
    "+getTime(count int)", "method", "+|getTime|count int|||method|+getTime(count int)|",
  ),
  (
    "-getTime(count int)", "method", "-|getTime|count int|||method|-getTime(count int)|",
  ),
  (
    "#getTime(count int)", "method", "#|getTime|count int|||method|#getTime(count int)|",
  ),
  (
    "~getTime(count int)", "method", "~|getTime|count int|||method|~getTime(count int)|",
  ),
  (
    "getTime(count int)$", "method", "|getTime|count int|$||method|getTime(count int)|text-decoration:underline;",
  ),
  (
    "getTime(count int)*", "method", "|getTime|count int|*||method|getTime(count int)|font-style:italic;",
  ),
  (
    "getTime(string text, int count)", "method", "|getTime|string text, int count|||method|getTime(string text, int count)|",
  ),
  (
    "+getTime(string text, int count)", "method", "+|getTime|string text, int count|||method|+getTime(string text, int count)|",
  ),
  (
    "-getTime(string text, int count)", "method", "-|getTime|string text, int count|||method|-getTime(string text, int count)|",
  ),
  (
    "#getTime(string text, int count)", "method", "#|getTime|string text, int count|||method|#getTime(string text, int count)|",
  ),
  (
    "~getTime(string text, int count)", "method", "~|getTime|string text, int count|||method|~getTime(string text, int count)|",
  ),
  (
    "getTime(string text, int count)$", "method", "|getTime|string text, int count|$||method|getTime(string text, int count)|text-decoration:underline;",
  ),
  (
    "getTime(string text, int count)*", "method", "|getTime|string text, int count|*||method|getTime(string text, int count)|font-style:italic;",
  ),
  (
    "getTime() DateTime", "method", "|getTime|||DateTime|method|getTime() : DateTime|",
  ),
  (
    "+getTime() DateTime", "method", "+|getTime|||DateTime|method|+getTime() : DateTime|",
  ),
  (
    "-getTime() DateTime", "method", "-|getTime|||DateTime|method|-getTime() : DateTime|",
  ),
  (
    "#getTime() DateTime", "method", "#|getTime|||DateTime|method|#getTime() : DateTime|",
  ),
  (
    "~getTime() DateTime", "method", "~|getTime|||DateTime|method|~getTime() : DateTime|",
  ),
  (
    "getTime() DateTime$", "method", "|getTime||$|DateTime|method|getTime() : DateTime|text-decoration:underline;",
  ),
  (
    "getTime()  DateTime*", "method", "|getTime||*|DateTime|method|getTime() : DateTime|font-style:italic;",
  ),
  (
    "getTimes(List~T~)", "method", "|getTimes|List~T~|||method|getTimes(List<T>)|",
  ),
  (
    "+getTimes(List~T~)", "method", "+|getTimes|List~T~|||method|+getTimes(List<T>)|",
  ),
  (
    "-getTimes(List~T~)", "method", "-|getTimes|List~T~|||method|-getTimes(List<T>)|",
  ),
  (
    "#getTimes(List~T~)", "method", "#|getTimes|List~T~|||method|#getTimes(List<T>)|",
  ),
  (
    "~getTimes(List~T~)", "method", "~|getTimes|List~T~|||method|~getTimes(List<T>)|",
  ),
  (
    "getTimes(List~T~)$", "method", "|getTimes|List~T~|$||method|getTimes(List<T>)|text-decoration:underline;",
  ),
  (
    "getTimes(List~T~)*", "method", "|getTimes|List~T~|*||method|getTimes(List<T>)|font-style:italic;",
  ),
  (
    "getTimes(List~T~, List~OT~)", "method", "|getTimes|List~T~, List~OT~|||method|getTimes(List<T>, List<OT>)|",
  ),
  (
    "+getTimes(List~T~, List~OT~)", "method", "+|getTimes|List~T~, List~OT~|||method|+getTimes(List<T>, List<OT>)|",
  ),
  (
    "-getTimes(List~T~, List~OT~)", "method", "-|getTimes|List~T~, List~OT~|||method|-getTimes(List<T>, List<OT>)|",
  ),
  (
    "#getTimes(List~T~, List~OT~)", "method", "#|getTimes|List~T~, List~OT~|||method|#getTimes(List<T>, List<OT>)|",
  ),
  (
    "~getTimes(List~T~, List~OT~)", "method", "~|getTimes|List~T~, List~OT~|||method|~getTimes(List<T>, List<OT>)|",
  ),
  (
    "getTimes(List~T~, List~OT~)$", "method", "|getTimes|List~T~, List~OT~|$||method|getTimes(List<T>, List<OT>)|text-decoration:underline;",
  ),
  (
    "getTimes(List~T~, List~OT~)*", "method", "|getTimes|List~T~, List~OT~|*||method|getTimes(List<T>, List<OT>)|font-style:italic;",
  ),
  (
    "getTimetableList(List~List~T~~)", "method", "|getTimetableList|List~List~T~~|||method|getTimetableList(List<List<T>>)|",
  ),
  (
    "+getTimetableList(List~List~T~~)", "method", "+|getTimetableList|List~List~T~~|||method|+getTimetableList(List<List<T>>)|",
  ),
  (
    "-getTimetableList(List~List~T~~)", "method", "-|getTimetableList|List~List~T~~|||method|-getTimetableList(List<List<T>>)|",
  ),
  (
    "#getTimetableList(List~List~T~~)", "method", "#|getTimetableList|List~List~T~~|||method|#getTimetableList(List<List<T>>)|",
  ),
  (
    "~getTimetableList(List~List~T~~)", "method", "~|getTimetableList|List~List~T~~|||method|~getTimetableList(List<List<T>>)|",
  ),
  (
    "getTimetableList(List~List~T~~)$", "method", "|getTimetableList|List~List~T~~|$||method|getTimetableList(List<List<T>>)|text-decoration:underline;",
  ),
  (
    "getTimetableList(List~List~T~~)*", "method", "|getTimetableList|List~List~T~~|*||method|getTimetableList(List<List<T>>)|font-style:italic;",
  ),
  (
    "getTimes(List~K, V~)", "method", "|getTimes|List~K, V~|||method|getTimes(List<K, V>)|",
  ),
  (
    "+getTimes(List~K, V~)", "method", "+|getTimes|List~K, V~|||method|+getTimes(List<K, V>)|",
  ),
  (
    "-getTimes(List~K, V~)", "method", "-|getTimes|List~K, V~|||method|-getTimes(List<K, V>)|",
  ),
  (
    "#getTimes(List~K, V~)", "method", "#|getTimes|List~K, V~|||method|#getTimes(List<K, V>)|",
  ),
  (
    "~getTimes(List~K, V~)", "method", "~|getTimes|List~K, V~|||method|~getTimes(List<K, V>)|",
  ),
  (
    "getTimes(List~K, V~)$", "method", "|getTimes|List~K, V~|$||method|getTimes(List<K, V>)|text-decoration:underline;",
  ),
  (
    "getTimes(List~K, V~)*", "method", "|getTimes|List~K, V~|*||method|getTimes(List<K, V>)|font-style:italic;",
  ),
  (
    "getTimes() List~T~", "method", "|getTimes|||List~T~|method|getTimes() : List<T>|",
  ),
  (
    "+getTimes() List~T~", "method", "+|getTimes|||List~T~|method|+getTimes() : List<T>|",
  ),
  (
    "-getTimes() List~T~", "method", "-|getTimes|||List~T~|method|-getTimes() : List<T>|",
  ),
  (
    "#getTimes() List~T~", "method", "#|getTimes|||List~T~|method|#getTimes() : List<T>|",
  ),
  (
    "~getTimes() List~T~", "method", "~|getTimes|||List~T~|method|~getTimes() : List<T>|",
  ),
  (
    "getTimes() List~T~$", "method", "|getTimes||$|List~T~|method|getTimes() : List<T>|text-decoration:underline;",
  ),
  (
    "getTimes() List~T~*", "method", "|getTimes||*|List~T~|method|getTimes() : List<T>|font-style:italic;",
  ),
  (
    "getTimetableList() List~List~T~~", "method", "|getTimetableList|||List~List~T~~|method|getTimetableList() : List<List<T>>|",
  ),
  (
    "+getTimetableList() List~List~T~~", "method", "+|getTimetableList|||List~List~T~~|method|+getTimetableList() : List<List<T>>|",
  ),
  (
    "-getTimetableList() List~List~T~~", "method", "-|getTimetableList|||List~List~T~~|method|-getTimetableList() : List<List<T>>|",
  ),
  (
    "#getTimetableList() List~List~T~~", "method", "#|getTimetableList|||List~List~T~~|method|#getTimetableList() : List<List<T>>|",
  ),
  (
    "~getTimetableList() List~List~T~~", "method", "~|getTimetableList|||List~List~T~~|method|~getTimetableList() : List<List<T>>|",
  ),
  (
    "getTimetableList() List~List~T~~$", "method", "|getTimetableList||$|List~List~T~~|method|getTimetableList() : List<List<T>>|text-decoration:underline;",
  ),
  (
    "getTimetableList() List~List~T~~*", "method", "|getTimetableList||*|List~List~T~~|method|getTimetableList() : List<List<T>>|font-style:italic;",
  ),
  (
    "std::map ~int,string~ pMap;", "attribute", "|std::map ~int,string~ pMap;||||attribute|std::map <int,string> pMap;|",
  ),
  (
    "getTime~T~(this T, int seconds)$ DateTime", "method", "|getTime~T~|this T, int seconds|$|DateTime|method|getTime<T>(this T, int seconds) : DateTime|text-decoration:underline;",
  ),
  ("name String", "attribute", "|name String||||attribute|name String|"),
  ("+name String", "attribute", "+|name String||||attribute|+name String|"),
  ("#name String", "attribute", "#|name String||||attribute|#name String|"),
  ("-name String", "attribute", "-|name String||||attribute|-name String|"),
  ("~name String", "attribute", "~|name String||||attribute|~name String|"),
  (
    "name String$", "attribute", "|name String||$||attribute|name String|text-decoration:underline;",
  ),
  (
    "name String*", "attribute", "|name String||*||attribute|name String|font-style:italic;",
  ),
]

///|
test "every spec session builds the model and graph pele builds" {
  let wrong = []
  for s, steps in spec_sessions {
    let db = @class.ClassDb::new()
    for step in steps {
      let (kind, arg, expected) = step
      let actual = if kind == "parse" {
        try {
          @class.parse_class(arg, db)
          db_dump(db)
        } catch {
          @errors.PeleError(failure) => "error: " + failure.message
        }
      } else {
        graph_dump(@class.build_class_graph(db, hierarchical=arg == "true"))
      }
      if actual != expected {
        wrong.push("session \{s}: \{kind} \{arg}\n\{actual}\n!=\n\{expected}")
      }
    }
  }
  inspect(wrong.join("\n\n"), content="")
}

///|
test "every member a spec reads is split as pele splits it" {
  for case in spec_members {
    let (input, kind, expected) = case
    let read = @class.ClassMember::new(
      input,
      if kind == "method" {
        Method
      } else {
        Attribute
      },
    )
    let details = read.display_details()
    let member_type = match read.member_type {
      Method => "method"
      Attribute => "attribute"
    }
    assert_eq(
      "\{read.visibility}|\{read.id}|\{read.parameters}|\{read.classifier}|\{read.return_type}|\{member_type}|\{details.display_text}|\{details.css_style}",
      expected,
      msg=input,
    )
  }
}
