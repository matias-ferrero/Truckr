# Informe de Avance



---
# Demo

Se leera en el Backlog, cada US con sus criterios de aceptacion para hacer la demo de dicha feature en el proyecto.

---

## Backoffice:

"Tenemos un admin hardcodeado" (futura US crear uno)
## US39 - Admin revisa users


## US40 - Impersonar usuario



---
## Carry Over de Sprint 1:

### US3 - Modificar Perfil

Check!

---
## Como Transportista (Carrier)
### US14 - Registro de Vehiculo

Check!

### US14.1 - Visualizar mi Flota

Check!
- Tema de la imagen anda pero tuve que descargar una dependencia (mal dockerizado)
- La pantalla de Mi Flota, debe ser una historia de usuario por si sola.
crear admin
### US14.2 - Editar Vehiculo de mi Flota

Check!

### US9 - Publicar Ventana de Transporte

Check!

### US9.1 - Ver mis Ventanas de Transporte

Check!

### US9.2 - Editar una Ventana de Transporte

Check!

### US9.3 - Ocultar una Ventana de Transporte

Check!
- No es despublicar, que sea ocultar! Queda raro sino. Esta pantalla tambien deberia ser un US mas -> check!
### US9.4 - Eliminar una Ventana de Transporte

Se puede eliminar una ventana que NO tenga ofertas de shippers en ella.
(Borrar ventana: `La Plata - Mar del Plata`)

---
## Como Expedidor (Shipper)

### US6 - Detalles de Transportistas

Check! Al ir a mis Cargas y encontrar transportistas compatibles, tiene un boton para ir al perfil

(Ya ni tengo que buscar la url `http://localhost:5173/carriers/1` y se ven todos los detalles)

---
## Home's
### US38 - Landing Page

Como user no logueado... check!
### US36 - Dashboard del Expedidor

Va a estar como pseudo incompleta! (Muchos botones a agregar)
### US37 - Dashboard del Transportista

Va a estar como pseudo incompleta! (Muchos botones a agregar)

---
# Sprint 2
### US27 - Publicar Carga

Se crea una carga correctamente! Check!

### US27.1 - Ver mis Cargas

Check!

### US27.2 - Filtrado de mis Cargas

Check!

### US27.3 - Ver Detalles de una Carga

Check!

### US6.1 - Busqueda de Ventanas Compatibles con mi Carga

Check! Pero, cambio de contrato. Se cambio el search, ahora es automatico por compatibilidad.
- Si aprieto la Carga creada en dashboard, me busca los transportistas disponibles compatibles (shortcut)
- Otro camino, ir a ver todas mis cargas y clickear en una especifica

### US7 - Ofertar Retiro de una Carga

Check!
