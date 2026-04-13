#import "../template.typ": conf, stroke-std
#show: conf

#let persona-card(name: "", photo: none, profile: "", behavior: "", needs: "") = block(
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
    name: "Hugo Fernandez (58 años)",
    photo: "images/personas/hugo.png",
    profile: "Transportista independiente desde hace 20 años, trabaja con su hijo (Martín) y tienen 2 camiones.",
    behavior: "Dado que vive en un pueblo con su familia, quiere mantener ese lugar como su base, y tener más viajes pero siempre volviendo a Cochicó.",
    needs: "Quiere expandir su clientela más allá de los productores que ya lo conocen.",
  ),

  persona-card(
    name: "Martín Fernandez (32 años)",
    photo: "images/personas/martin.png",
    profile: "Trabaja como transportista con su padre (Hugo) desde hace 7 años.",
    behavior: "Dado que sus clientes son siempre los mismos, está aburrido de su trabajo.",
    needs: "Quiere tener viajes que lo lleven más lejos, o que un viaje lo lleve a un lugar desde donde pueda conseguir otro trabajo que lo lleve a otro lado, y así ir recorriendo toda la Argentina (el mejor país del mundo) mientras trabaja.",
  ),

  persona-card(
    name: "Daniela Perez (señora de 55 años)",
    photo: "images/personas/daniela.png",
    profile: "Mujer recientemente divorciada que busca mudarse",
    behavior: "Es diseñadora de interiores, por ende, le fascina la decoración y tener sus propias decisiones sobre como quiere tener su nuevo departamento",
    needs: "Busca comprar muebles y electrodomésticos a un precio razonable para su nueva vida",
  ),

  persona-card(
    name: "Florencia Scazzola (mujer de 40 años).",
    photo: "images/personas/florencia.png",
    profile: "Mujer emprendedora que tiene su propio centro de estética",
    behavior: "Le encanta el maquillaje, el skincare y el cuidado personal. Muy interesada en la cultura coreana.",
    needs: "Conseguir productos (skincare, maquillaje, etc) para su nuevo emprendimiento, a un precio mucho menor al que lo conseguiría en el mercado local.",
  ),

  persona-card(
    name: "AgroTransport",
    photo: "images/personas/agrotransport.png",
    profile: "Una empresa que tiene una flota de 10 camiones con transportistas contratados a tiempo completo.",
    behavior: "Tienen empleados que hacen viajes en simultáneo.",
    needs: "Quieren aprovechar mejor sus camiones, pues muchas veces tienen a algunos sin usar por varias semanas, y no quieren seguir desperdiciando esos recursos. Además, cuando ocurre eso, aún así les están pagando a sus empleados por más que no estén haciendo viajes activamente. Quieren hacer un seguimiento de la calidad del servicio que ofrece cada uno de sus empleados.",
  ),

  persona-card(
    name: "Campos Giménez",
    photo: "images/personas/campos-gimenez.png",
    profile: "Una empresa dueña de 300ha de campo",
    behavior: "Trabajan y cosechan múltiples cultivos a lo largo del año.",
    needs: "Transportar la cosecha a plantas de procesamiento y demás destinos estacionalmente.",
  ),

  persona-card(
    name: "Juan Martinez (41 años)",
    photo: "images/personas/juan_martinez.png",
    profile: "Hombre casado con 3 hijos, vive en CABA, y es dueño de un negocio de entregas hace 8 años.
Además de ser el dueño, también es transportista en el negocio.",
    behavior: "Realiza múltiples entregas a corta distancia por día (entre 10 y 20) de paquetes de volumen reducido. Opera en CABA y alrededores principalmente.
Tiene varias vans medianas, así que no lleva volúmenes grandes de producto.
Frecuenta la aplicación en busca de nuevas entregas a corto plazo.",
    needs: "Tener un volumen constante de entregas a muy corto plazo, y recibir pagos rápidos.
Necesita una interfaz simple, que cuente con filtros por ubicación para hacer entregas cortas de bajo/mediano volume, para facilitar el sistema de entregas en su negocio.",
  ),

  persona-card(
    name: "Carolina Souza (35 años)",
    photo: "images/personas/carolina_souza.png",
    profile: "Mujer divorciada con 2 hijos, vive en Buenos Aires. Hace transporte especializado refrigerado desde hace 5 años.",
    behavior: "Hace transporte refrigerado, lleva carga especial y/o sensible. Tiene capacitación para cuidar la carga.
Planifica viajes a corta y mediana distancia (ocasionalmente larga distancia), y cuida la ruta elegida por la carga que lleva.",
    needs: "Necesita hacer viajes planificados con tiempo, así como también tener detalle de la carga que lleva.
Su carga no es común, así que necesita clientes confiables a largo plazo.",
  ),

)
