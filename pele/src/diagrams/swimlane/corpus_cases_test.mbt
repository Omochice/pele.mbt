// Mermaid's documentation examples in pele's corpus (tests/corpus/swimlane-docs.json), with a hash of what pele v1.12.0's render gives each at its natural width and at a host width of 480.

///|
let docs_examples : Array[(String, String, String)] = [
  (
    (
      #|swimlane-beta LR
      #|  subgraph Customer
      #|    Browse[Browse catalogue]
      #|    Pay[Pay]
      #|  end
      #|  subgraph Warehouse
      #|    Pick[Pick items]
      #|    Ship[Ship order]
      #|  end
      #|  subgraph Finance
      #|    Invoice[Raise invoice]
      #|  end
      #|  Browse --> Pay
      #|  Pay --> Pick
      #|  Pick --> Ship
      #|  Pay --> Invoice
      #|
    ),
    "197ea4bf",
    "38e6124d",
  ),
  (
    (
      #|---
      #|config:
      #|  theme: default
      #|  look: classic
      #|---
      #|swimlane-beta LR
      #|  subgraph Customer
      #|    Browse[Browse catalogue]
      #|    Pay[Pay]
      #|  end
      #|  subgraph Warehouse
      #|    Pick[Pick items]
      #|    Ship[Ship order]
      #|  end
      #|  subgraph Finance
      #|    Invoice[Raise invoice]
      #|  end
      #|  Browse --> Pay
      #|  Pay --> Pick
      #|  Pick --> Ship
      #|  Pay --> Invoice
      #|
    ),
    "197ea4bf",
    "38e6124d",
  ),
  (
    (
      #|swimlane-beta LR
      #|  subgraph Customer
      #|    request[Request service]
      #|    receive[Receive update]
      #|  end
      #|
      #|  subgraph Support
      #|    triage[Triage request]
      #|    answer[Send answer]
      #|  end
      #|
      #|  subgraph Engineering
      #|    investigate[Investigate issue]
      #|    fix[Prepare fix]
      #|  end
      #|
      #|  request --> triage
      #|  triage -->|Known issue| answer
      #|  triage -->|Needs code change| investigate
      #|  investigate --> fix --> answer
      #|  answer --> receive
      #|
    ),
    "1b17a88d",
    "b4d0fe72",
  ),
  (
    (
      #|swimlane-beta
      #|  subgraph Sales
      #|    lead[Qualify lead]
      #|    quote[Prepare quote]
      #|  end
      #|
    ),
    "5ea04f1c",
    "5ea04f1c",
  ),
  (
    (
      #|swimlane-beta LR
      #|  subgraph sales [Sales team]
      #|    lead[Qualify lead]
      #|    quote[Prepare quote]
      #|  end
      #|
      #|  subgraph finance [Finance team]
      #|    review[Review terms]
      #|    approve[Approve quote]
      #|  end
      #|
      #|  lead --> quote --> review --> approve
      #|
    ),
    "2878bcc3",
    "55d717b6",
  ),
  (
    (
      #|swimlane-beta LR
      #|  subgraph Intake
      #|    start([Start])
      #|    task[Do work]
      #|    fix[Fix issues]
      #|  end
      #|
      #|  subgraph Review
      #|    decision{Ready?}
      #|  end
      #|
      #|  subgraph Complete
      #|    done((Done))
      #|  end
      #|
      #|  start --> task --> decision
      #|  decision -->|Yes| done
      #|  decision -->|No| fix
      #|  fix --> task
      #|
    ),
    "c862962e",
    "958002a9",
  ),
  (
    (
      #|swimlane-beta LR
      #|  subgraph Buyer
      #|    choose[Choose product]
      #|    pay[Pay invoice]
      #|  end
      #|
      #|  subgraph Store
      #|    reserve[Reserve stock]
      #|    ship[Ship product]
      #|  end
      #|
      #|  choose --> reserve
      #|  reserve -->|Invoice ready| pay
      #|  pay --> ship
      #|
    ),
    "c25d875a",
    "83fbc159",
  ),
  (
    (
      #|swimlane-beta LR
      #|  accTitle: Support escalation
      #|  accDescr: A request starts with the customer, is triaged by support, and may be escalated to engineering.
      #|
      #|  subgraph Customer
      #|    request[Open request]
      #|  end
      #|
      #|  subgraph Support
      #|    triage[Triage]
      #|  end
      #|
      #|  subgraph Engineering
      #|    resolve[Resolve]
      #|  end
      #|
      #|  request --> triage --> resolve
      #|
    ),
    "af2b84c8",
    "af2b84c8",
  ),
  (
    (
      #|swimlane-beta LR
      #|  subgraph Customer
      #|    submit[Submit order]
      #|    confirm[Confirm delivery]
      #|  end
      #|
      #|  subgraph Store
      #|    check[Check order]
      #|    pack[Pack items]
      #|  end
      #|
      #|  subgraph Carrier
      #|    collect[Collect package]
      #|    deliver[Deliver package]
      #|  end
      #|
      #|  submit --> check --> pack --> collect --> deliver --> confirm
      #|
    ),
    "73394154",
    "e4c1d4b0",
  ),
  (
    (
      #|swimlane-beta LR
      #|  subgraph Applicant
      #|    apply[Submit application]
      #|    sign[Sign agreement]
      #|  end
      #|
      #|  subgraph Reviewer
      #|    screen[Screen application]
      #|    decide{Approved?}
      #|  end
      #|
      #|  subgraph System
      #|    create[Create account]
      #|    notify[Send welcome email]
      #|  end
      #|
      #|  apply -->|Application received| screen
      #|  screen --> decide
      #|  decide -->|Approved| create --> notify --> sign
      #|  decide -->|Needs changes| apply
      #|
    ),
    "0f1c9920",
    "d5d58d3e",
  ),
  (
    (
      #|swimlane-beta TB
      #|  subgraph Intake
      #|    collect[Collect request]
      #|    validate[Validate details]
      #|  end
      #|
      #|  subgraph Review
      #|    review[Review request]
      #|    decide{Ready?}
      #|  end
      #|
      #|  subgraph Delivery
      #|    schedule[Schedule work]
      #|    complete[Complete work]
      #|  end
      #|
      #|  collect --> validate --> review --> decide
      #|  decide -->|Yes| schedule --> complete
      #|  decide -->|No| collect
      #|
    ),
    "0304566b",
    "fa6f9bd5",
  ),
  (
    (
      #|swimlane-beta LR
      #|  subgraph ops [Operations]
      #|    intake[Receive request]
      #|    plan[Plan work]
      #|  end
      #|
      #|  subgraph legal [Legal]
      #|    review[Review contract]
      #|  end
      #|
      #|  intake --> plan --> review
      #|
      #|  classDef attention fill:#fff2cc,stroke:#d6a500,color:#111;
      #|  class review attention;
      #|
    ),
    "dc85892b",
    "4e41c704",
  ),
  (
    (
      #|swimlane-beta LR
      #|  subgraph Support
      #|    classify{Can support solve it?}
      #|    respond[Respond to customer]
      #|  end
      #|
      #|  subgraph Product
      #|    prioritize[Prioritize fix]
      #|  end
      #|
      #|  subgraph Engineering
      #|    implement[Implement fix]
      #|  end
      #|
      #|  classify -->|Yes| respond
      #|  classify -->|No| prioritize --> implement --> respond
      #|
    ),
    "11e66e5d",
    "0a3560e9",
  ),
]
