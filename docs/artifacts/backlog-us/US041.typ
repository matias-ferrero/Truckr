== US41: Recupero de Contraseña

*Release:* Release 2 \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como usuario,
quiero poder recuperar mi contraseña en caso de haberla olvidado,
para poder volver a acceder a mi cuenta sin necesidad de contactar a soporte.

*Criterios de Aceptación:*
+ Se permite recuperar la contraseña a través de un proceso de recuperación.
+ Durante el proceso, se valida la dirección de correo electrónico registrada.
+ Si el email está registrado, se envía un correo con un enlace de recuperación de contraseña.
+ El enlace de recuperación tiene una validez limitada.
+ Al final se puede generar una nueva contraseña.
+ La nueva contraseña debe cumplir los mismos requisitos de seguridad que en el registro.
+ Si el email no está registrado, se bloquea la solicitud.
+ Una vez utilizado el enlace de recuperación, queda invalidado.
