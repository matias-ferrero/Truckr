== US58: Notificación en Tiempo Real de Oferta Recibida

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Notificaciones

*Descripción:*
Como transportista,
quiero recibir un aviso inmediato dentro de la aplicación cuando un expedidor me envía una oferta de carga,
para enterarme al instante y poder revisarla sin tener que refrescar mi bandeja.

*Criterios de Aceptación:*
+ Si tengo la sesión abierta y un expedidor crea una oferta de carga contra una de mis ventanas de transporte, aparece de inmediato un aviso emergente y se incrementa el contador de notificaciones.
+ El aviso me invita a revisar la oferta en mi bandeja de ofertas recibidas (US10), desde donde puedo aceptarla (US12) o rechazarla.
+ El aviso en pantalla es adicional al registro de la oferta: si por algún motivo el aviso no llega, la oferta igualmente queda creada y disponible en mi bandeja.
