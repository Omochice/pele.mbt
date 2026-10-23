#import "../lib.typ": mermaid

#set page(width: 16cm, height: auto, margin: 1cm)

// Each drawing is an SVG fragment on a 24 by 24 grid, stroked in the text color.
#let icons = (
  "logos:aws-lambda": "<path d=\"M5,20L11,4H14L20,20M8,12H14\"/>",
  "logos:aws-s3": "<path d=\"M4,6C4,3 20,3 20,6V18C20,21 4,21 4,18ZM4,6C4,9 20,9 20,6\"/>",
  "server": "<path d=\"M4,4H20V11H4ZM4,13H20V20H4ZM7,7.5H8M7,16.5H8\"/>",
  "fa:fa-car": "<path d=\"M3,15V11L6,6H18L21,11V15ZM7,18A1.5,1.5 0 1 0 7,15M17,18A1.5,1.5 0 1 0 17,15\"/>",
  "fa:fa-user": "<path d=\"M12,12A4,4 0 1 0 12,4A4,4 0 1 0 12,12ZM4,21C4,16 20,16 20,21\"/>",
)

= Icons

`icons` maps each icon name a diagram uses to the SVG fragment drawn for it.
A name the dictionary lacks takes no room in a label, and an architecture service falls back to Mermaid's built-in drawing.

#mermaid(icons: icons, ```
architecture-beta
  group api(logos:aws-lambda)[API]
  service store(logos:aws-s3)[Storage] in api
  service app(server)[App] in api
  service db(database)[Database]
  store:R -- L:app
  app:R -- L:db
```)

#mermaid(icons: icons, ```
flowchart LR
  user[fa:fa-user Customer] -- fa:fa-car drives --> shop[Shop]
  shop --> rental[fa:fa-car Rental fa:fa-plane]
```)
