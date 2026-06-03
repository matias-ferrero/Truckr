== US57: Aviso en Tiempo Real de Respuesta a mi Oferta

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Reservar Transportista

*Descripción:*
Como expedidor,
quiero recibir un aviso inmediato dentro de la aplicación cuando el transportista acepta o rechaza la oferta que le envié (US7),
para enterarme al instante sin tener que refrescar la pantalla ni salir a revisar mi correo.

*Criterios de Aceptación:*
+ Si tengo la sesión abierta y el transportista acepta mi oferta (US12), aparece de inmediato un aviso emergente y se incrementa el contador de notificaciones, indicándome que puedo continuar con el pago (US8).
+ Si el transportista rechaza mi oferta, aparece de inmediato un aviso emergente equivalente que me informa el rechazo, para que pueda ofertar contra otra ventana.
+ Cuando el transportista acepta una oferta y, en consecuencia, se rechazan automáticamente las demás ofertas pendientes sobre la misma carga, cada expedidor afectado recibe su propio aviso de rechazo dirigido únicamente a él.
+ El aviso es de entrega inmediata y best-effort: si no tengo la sesión abierta en ese momento, no recibo el aviso emergente; no se guarda un historial persistente de avisos.
