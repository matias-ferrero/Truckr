#import "../template.typ": conf, stroke-std
#show: conf

#let persona-card(
  name: "",
  photo: none,
  profile: "",
  behavior: "",
  needs: "",
) = block(
  width: 100%,
  inset: 10pt,
  radius: 6pt,
  stroke: stroke-std,
  fill: luma(248),
  breakable: false,
)[
  #text(weight: "bold", size: 11pt)[#name]
  #v(6pt)
  #if photo != none {
    image(photo, width: 100%)
  } else {
    rect(width: 60pt, height: 60pt, stroke: stroke-std, fill: luma(220))[
      #align(center + horizon)[#text(size: 8pt, fill: luma(120))[foto]]
    ]
  }
  #v(6pt)
  #grid(
    columns: (auto, 1fr),
    column-gutter: 4pt,
    row-gutter: 4pt,
    [*Perfil:*], [#profile],
    [*Comportamiento:*], [#behavior],
    [*Necesidades:*], [#needs],
  )
]

= Personas

#grid(
  columns: (1fr, 1fr),
  column-gutter: 12pt,
  row-gutter: 12pt,

  persona-card(
    name: "Hugo (58 años)",
    photo: "images/personas/hugo.png",
    profile: "Transportista independiente desde hace 20 años, trabaja con su hijo (Martín) y tienen 2 camiones.",
    behavior: "Vive en un pueblo con su familia, quiere mantener ese lugar como su base, y tener más viajes pero siempre volviendo a Cochicó.",
    needs: "Expandir su clientela más allá de los productores que ya lo conocen.",
  ),

  persona-card(
    name: "Martín (hijo de Hugo)",
    photo: "images/personas/martin.png",
    profile: "Trabaja como transportista con su padre (Hugo) desde hace 7 años.",
    behavior: "Sus clientes son siempre los mismos y está aburrido de su trabajo.",
    needs: "Tener viajes que lo lleven más lejos, o encadenar viajes que lo lleven a recorrer toda la Argentina mientras trabaja.",
  ),

  persona-card(
    name: "Daniela Perez (55 años)",
    photo: "images/personas/daniela.png",
    profile: "Mujer recientemente divorciada que busca mudarse.",
    behavior: "Es diseñadora de interiores; le fascina la decoración y tomar sus propias decisiones sobre su nuevo departamento.",
    needs: "Comprar muebles y electrodomésticos a un precio razonable para su nueva vida.",
  ),

  persona-card(
    name: "Florencia Scazzola (40 años)",
    photo: "images/personas/florencia.png",
    profile: "Mujer emprendedora que tiene su propio centro de estética.",
    behavior: "Le encanta el maquillaje, el skincare y el cuidado personal. Muy interesada en la cultura coreana.",
    needs: "Conseguir productos (skincare, maquillaje, etc.) para su emprendimiento a un precio mucho menor al del mercado local.",
  ),

  persona-card(
    name: "AgroTransport",
    photo: "images/personas/agrotransport.png",
    profile: "Una empresa que tiene una flota de 10 camiones con transportistas contratados a tiempo completo.",
    behavior: "Tienen empleados que hacen viajes en simultáneo.",
    needs: "Aprovechar mejor sus camiones —muchas veces sin uso por semanas— sin desperdiciar recursos ni nómina ociosa. También quieren hacer seguimiento de la calidad del servicio de cada empleado.",
  ),

  persona-card(
    name: "Campos Giménez",
    photo: "images/personas/campos-gimenez.png",
    profile: "Una empresa dueña de 300ha de campo.",
    behavior: "Trabajan y cosechan múltiples cultivos a lo largo del año.",
    needs: "Transportar la cosecha a plantas de procesamiento y demás destinos estacionalmente.",
  ),
)
