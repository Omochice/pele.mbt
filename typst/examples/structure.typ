#import "../lib.typ": mermaid

#set page(width: 18cm, height: auto, margin: 1cm)

= Class diagram

#mermaid(```
classDiagram
  namespace Company.Engineering.Backend {
    class Developer {
      +writeCode()
    }
  }
  namespace Company.Engineering.Frontend {
    class Designer {
      +createMockup()
    }
  }
  namespace Company.Engineering {
    class TechLead {
      +planSprint()
    }
  }
  TechLead --> Developer : leads
  TechLead --> Designer : leads
```)

= Architecture diagram

Icons are drawn in the text color of the theme.

#mermaid(```
architecture-beta
  group api(cloud)[API]
  service db(database)[Database] in api
  service disk1(disk)[Storage] in api
  service server(server)[Server] in api
  db:L -- R:server
  disk1:T -- B:server
```)

= Entity relationship diagram

#mermaid(```
erDiagram
  CUSTOMER ||--o{ ORDER : places
  ORDER ||--|{ LINE-ITEM : contains
  CUSTOMER {
    string name
    string email
  }
  ORDER {
    int id
    date placed
  }
```)
