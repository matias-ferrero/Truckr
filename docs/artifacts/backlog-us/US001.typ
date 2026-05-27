== US1: Registrarse

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Cuenta

*Descripción:*
Como usuario (expedidor o transportista),
quiero poder registrarme en la plataforma,
para acceder a los servicios de Truckr y satisfacer mis necesidades de transporte.

*Criterios de Aceptación:*
+ Se pueden ingresar todos los datos necesarios: email, nombre completo y contraseña.
+ Si el email ya existe en el sistema, el registro falla y se muestra un mensaje de error claro.
+ La contraseña debe cumplir todos los siguientes requisitos; de lo contrario el registro falla con un mensaje indicando qué requisito no se cumple:
  - Tiene al menos 8 caracteres.
  - Incluye al menos una mayúscula (A–Z).
  - Incluye al menos una minúscula (a–z).
  - Incluye al menos un número (0–9).
+ Al completar el registro exitosamente, el usuario es redirigido al dashboard correspondiente a su rol.
+ Todos los campos del formulario son obligatorios y se validan antes de enviar.
