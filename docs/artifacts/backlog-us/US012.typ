== US12: Aceptación de Oferta de Envío

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Aceptar Envío

*Descripción:*
Como transportista,
quiero poder aceptar una oferta de envío,
para comprometerme a realizarlo y generar ingresos.

*Criterios de Aceptación:*
+ Una vez seleccionada una oferta (US10), se puede aceptar mediante un botón claramente visible.
+ Al aceptar la oferta, se notifica al expedidor que su oferta fue aceptada y se habilita el flujo de pago (US8).
+ El envío aceptado aparece en la sección de "listado de envíos" del transportista (visible en el dashboard, US27).
+ Al aceptarse una oferta, las ofertas restantes de la carga asociada del expedidor, son canceladas.
+ Al aceptarse una oferta, automaticamente sera generado un envío en estado "pendiente de pago".
