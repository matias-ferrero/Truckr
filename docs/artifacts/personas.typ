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
    name: "Hugo Fernandez (64 años)",
    photo: "images/personas/hugo.png",
    profile: "Es un transportista independiente desde hace 30 años que vive en BSAS, trabaja con su hijo (Martín) y tienen 2 camiones.",
    behavior: "Tiene una vida estable con su familia, y quiere mantener ese lugar como su base, y tener más viajes pero siempre volviendo a su casa. Está cerca de jubilarse, así que hace viajes ocasionalmente y no es tan constante.
No es bueno con la técnología, pero quiere expandirse facilmente manteniendo su estilo de vida.",
    needs: "Trabajar con una clientela estable que necesite trabajo ocasional/estacional.
Necesita una interfaz simple y accesible que no le de tantos problemas, incluida una plataforma simple y confiable de pagos.
Además, necesita llevar siempre carga llena o encadenar varios viajes en uno, para aprovechar cada viaje que haga.",
  ),

  persona-card(
    name: "Martín Fernandez (32 años)",
    photo: "images/personas/martin.png",
    profile: "Trabaja como transportista con su padre (Hugo) desde hace 10 años.",
    behavior: "Dado que sus clientes son siempre los mismos, está aburrido de su trabajo. Quiere aprovechar los transportes que hace para viajar y conocer diferentes lugares, a corta, mediana o larga distancia.",
    needs: "Necesita expandir su clientela para tener distintos tipos de viajes, y no le importa sin son recurrentes u ocasionales. Estos viajes pueden ser a cualquier distancia, pero necesita encadenar viajes para que lo lleven a un lugar desde donde pueda conseguir otro, y así sucesivamente, haciendo viajes mientras trabaja.
No conoce los lugares a donde va, así que necesita integración con gps para saber su recorrido.",
  ),

  persona-card(
    name: "Daniela Perez (señora de 55 años)",
    photo: "images/personas/daniela.png",
    profile: "Mujer recientemente divorciada, es diseñadora de interiores y trabaja en el rubro hace años.",
    behavior: "Muchos clientes de ella necesitan amueblado, refacciones, y/o productos para hacer remodelaciones.
Si bien ocasionalmente necesita hacer y/o recibe estos envíos para su trabajo, se le complica hacerlos por su cuenta, aunque tampoco puede permitirse hacer grandes erogaciones de dinero en envíos para no sufrir tantas pérdidas.",
    needs: "Busca hacer y recibir envíos baratos ocasionalmente de forma fácil. Necesita asegurar algunos productos de sus clientes para protegerse de posibles daños.
No es mala con la técnología, puede aprender, pero sería más fácil con una interfaz simple para evitar una curva de aprendizaje empinada.",
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
    profile: "Una empresa con base en BSAS que tiene una flota de 10 camiones con transportistas contratados a tiempo completo, que está en el rubro hace 2 años.",
    behavior: "Tienen empleados que hacen viajes en simultáneo, la empresa los controla desde la base. Reciben peticiones de transporte y despachan un camión a hacer el encargo. Pueden despachar a corta, media o larga distancia, pero siempre buscan planificar sus transportes.
Quieren aprovechar mejor sus camiones, pues muchas veces tienen a algunos sin usar por varias semanas, y no quieren seguir desperdiciando esos recursos.",
    needs: "Necesitan expandir su clientela facilmente para mejorar su ganancia. Para ello también necesitan por hacer seguimiento de los envíos que hacen e hicieron (historial de viajes, características de los productos, etc.). Además, para mejorar su planificación, necesitan hacer un trackeo vía GPS de sus camiones, así como también poder hacer varíos envíos en un solo viaje si es posible, y asegurarlos en caso de daños.",
  ),

  persona-card(
    name: "Campos Giménez",
    photo: "images/personas/campos-gimenez.png",
    profile: "Una empresa dueña de 300ha de campo a las afueras de Rosario.",
    behavior: "Trabajan y cosechan múltiples cultivos a lo largo del año, quieren mejorar la planificación de los envíos de su cosecha, y abaratar los costos de los envíos.",
    needs: "Transportar la cosecha a plantas de procesamiento y demás destinos estacionalmente.",
  ),

  persona-card(
    name: "Juan Martinez (41 años)",
    photo: "images/personas/juan.png",
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
    photo: "images/personas/carolina.png",
    profile: "Mujer divorciada con 2 hijos, vive en Buenos Aires. Hace transporte especializado refrigerado desde hace 5 años.",
    behavior: "Hace transporte refrigerado, lleva carga especial y/o sensible. Tiene capacitación para cuidar la carga.
Planifica viajes a corta y mediana distancia (ocasionalmente larga distancia), y cuida la ruta elegida por la carga que lleva.",
    needs: "Necesita hacer viajes planificados con tiempo, así como también tener detalle de la carga que lleva.
Su carga no es común, así que necesita clientes confiables a largo plazo.",
  ),

  persona-card(
    name: "Manuel Ramos (52 años)",
    photo: "images/personas/manuel.png",
    profile: "Hombre casado, vive en Córdoba, y es dueño de una empresa de distribución de alimentos que lleva 20 años en el rubro.",
    behavior: "Distribuye alimentos controlados con cumplimiento regulatorio (ANMAT, SENASA, etc.) desde puertos/aduanas hasta distribuidores locales. Trabaja bajo los protocolos impuestos y no son modificables (cadena de frío, trazabilidad, etc.)",
    needs: "Transportistas confiables y certificados, con documentación apropiada, capaciados para hacer las entregas.
También necesita tener la trazabilidad completa del envío, y un seguro especializado sobre los productos.",
  ),

  persona-card(
    name: "Sofía Carrasco (24 años)",
    photo: "images/personas/sofia.png",
    profile: "Mujer soltera, vive en BSAS, es estudiante en FIUBA, y trabaja part time en Mercado Libre hace 2 años.",
    behavior: "Quiere mudarse a CABA para estar más cerca de la Facultad y de la oficina, de esa forma puede reducir distancias y ahorrar tiempo.
No tiene problemas con la tecnología, pero no tiene contactos de alguien que le pueda hacer la mudanza.",
    needs: "Servicio barato, accesible y rápido para un flete ocasional de sus cosas a su nuevo departamento.",
  ),

)
