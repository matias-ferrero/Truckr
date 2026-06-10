== US60: Notificación en Tiempo Real de Pago Recibido

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Notificaciones

*Descripción:*
Como transportista,
quiero recibir un aviso inmediato dentro de la aplicación cuando recibo un pago por un envío realizado,
para enterarme al instante y poder revisar la transacción sin tener que refrescar mi bandeja.

*Criterios de Aceptación:*
+ Si tengo la sesión abierta y el sistema me efectivizó un pago, aparece de inmediato un aviso emergente y se incrementa el contador de notificaciones.
+ El aviso informa que se acreditó un pago por un envío realizado; la bandeja de pagos recibidos (US40) queda siempre accesible desde la navegación lateral (US67) para revisar el detalle de la transferencia.
+ El aviso en pantalla es adicional al pago realizado: si por algún motivo el aviso no llega, la transferencia queda realizada y disponible en mi bandeja.
