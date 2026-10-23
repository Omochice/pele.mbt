#import "../lib.typ": mermaid

#set page(width: 16cm, height: auto, margin: 1cm)

= Sequence diagram

#mermaid(```
sequenceDiagram
  autonumber
  actor User
  participant Web
  participant API
  User->>Web: Open the dashboard
  activate Web
  Web->>API: GET /reports
  alt cached
    API-->>Web: 200 from cache
  else fresh
    API->>API: Build the report
    API-->>Web: 200
  end
  Note over Web,API: Both sides log the request
  Web-->>User: Render the reports
  deactivate Web
```)
