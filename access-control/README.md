# acces-control/

Este directorio contiene scripts de **auditoría y control de accesos en sistemas Linux**, centrados en permisos de archivos, usuarios y privilegios. 

Incluye herramientas para:

- Detectar archivos con **SETUID y SETGID activos** y clasificarlos según su ubicación.
- Identificar archivos o directorios **world-writable** y verificar la presencia del **sticky bit** en directorios compartidos.  
- Auditar la **consistencia de usuarios**, UIDs, privilegios, shells y home directories, detectando cuentas críticas o inconsistentes.

Los scripts generan logs detallados con información útil para **auditorías de seguridad y mantenimiento de sistemas**, simulando escenarios reales que un sysadmin puede encontrar en entornos de producción.

 Contenido:

- [auditoria_permisos_peligrosos.sh](#auditoria_permisos_peligrosossh)
- [detector_permisos_inseguros.sh](#detector_permisos_insegurossh)
- [auditoria_usuarios_privilegios.sh](#auditoria_usuarios_privilegiossh)

-------------------------------------------------------------------------------------------------------------

## **auditoria_permisos_peligrosos.sh**
  Nivel Intermedio **Temas:** SETUID, SETGID, permisos de archivos, auditoría de seguridad en Linux

---

  Descripción Técnica:

Este script realiza una **auditoría completa de archivos con bits SETUID o SETGID activos** en un directorio dado o en todo el sistema.  
Genera un log con información detallada de cada archivo encontrado:

- Ruta completa
- Usuario propietario
- Grupo propietario
- Permisos en notación octal
- UID del propietario

Además, clasifica los archivos en:

- [OK] → Archivos ubicados en rutas estándar ('/bin', '/sbin', '/usr/bin', '/usr/sbin', '/lib', '/lib64', '/usr/lib', '/usr/lib64').  
- [CRITICO] → Archivos fuera de las rutas estándar, que podrían representar un **riesgo de seguridad**.

El script utiliza:

- **find**: para localizar archivos con permisos SETUID/SETGID.
- **stat**: para extraer información completa de cada archivo.
- **expresiones regulares y bucles**: para clasificar los archivos según su ubicación. 
- **logs con timestamp**: cada ejecución genera un archivo único, evitando sobrescribir resultados anteriores.

---

  Uso Típico en las Empresas:

- **Auditorías de seguridad periódicas:** Permite a un sysadmin identificar archivos que podrían ser usados para elevación de privilegios.  
- **Prevención de ataques internos:** Detecta archivos con permisos especiales fuera de rutas estándar que podrían ser modificados o explotados por usuarios maliciosos.  
- **Automatización:** Se puede ejecutar periódicamente mediante cron jobs o integrarse en scripts de gestión de seguridad centralizada.  
- **Contexto real:** Empresas con múltiples servidores o aplicaciones críticas pueden detectar rápidamente configuraciones inseguras antes de que sean explotadas.

**Ejemplo de ejecución:**

 `bash
sudo ./auditoria_permisos_peligrosos.sh /

______________________________________________________________________________________________________________

## **detector_permisos_inseguros.sh** 
  Nivel Intermedio **Temas:** permisos de archivos, world-writable, sticky bit, auditoría de seguridad en    Linux

---

  Descripción Técnica:

Este script analiza un **directorio dado** para detectar archivos o directorios con **permisos inseguros** que podrían comprometer la seguridad del sistema.  
Genera un log con información detallada de cada elemento inseguro, incluyendo:

- Ruta completa
- Permisos en formato legible ('-rw-rw-rw-')
- Propietario
- UID
- GID
- Tipo de archivo (regular, directorio, symlink, etc.)

Además, verifica directorios **especiales de uso compartido** ('/tmp', /var/tmp', '/shared') y comprueba si **tienen activo el sticky bit**. Si no lo tienen, los marca como [CRITICO].

El script soporta **opciones de línea de comando**:

- -d <directorio> → Analiza archivos world-writable en ese directorio.
- -c → Verifica directorios especiales con sticky bit.
- -f <directorio> → Permite **activar el sticky bit automáticamente** con confirmación del usuario.

---

   Uso Típico en las Empresas:

- **Auditorías periódicas de seguridad:** Detecta archivos o directorios donde cualquier usuario pueda escribir ('world-writable') y directorios compartidos sin sticky bit.
- **Prevención de sabotaje interno:** Evita que un usuario borre o modifique archivos de otro en directorios compartidos. 
- **Gestión de permisos automatizada:** Con la opción '-f', se puede aplicar sticky bit de manera controlada y segura.
- **Contexto real:** En servidores multiusuario, entornos de desarrollo compartidos o sistemas con carpetas temporales públicas, este script ayuda a **reducir vectores de ataque locales** y mantener la integridad de los datos.

**Ejemplo de ejecución:**

  bash

  Detectar archivos world-writable en /home:

./detector_permisos_inseguros.sh -d /home

 Verificar directorios especiales con sticky bit:

./detector_permisos_inseguros.sh -c

  Aplicar sticky bit a /tmp si falta:

./detector_permisos_inseguros.sh -f /tmp

   Curiosidad Técnica:

find "$DIR" -type f \( -perm -o=r -and -perm -o=w \)
Busca archivos que son world-readable y world-writable, indicando riesgos de acceso externo.

Sticky bit (-k)
El script usa [ -k "$directorio" ] para detectar si un directorio compartido solo permite que el propietario de un archivo lo borre, evitando que otros usuarios eliminen archivos ajenos.

stat -c "%n|%A|%U|%u|%g|%F"
Obtiene información completa de cada archivo, incluyendo permisos legibles, propietario, UID, GID y tipo de archivo.

Logs con timestamp
Cada ejecución genera un archivo único: detector_YYYY-MM-DD_HH-MM-SS.log, facilitando auditorías periódicas sin sobrescribir resultados previos.

Salida de ejemplo:

=====Búsqueda de archivos inseguros=====
/home/usuario/test.txt|-rw-rw-rw-|usuario|1001|1001|regular file
[CRITICO] /shared/datos_compartidos|-rwxrwxrwx|admin|0|0|directory
[OK] /tmp/logs_temp|-rwxrwxrwt|root|0|0|directory

______________________________________________________________________________________________________________

## **auditoria_usuarios_privilegios.sh** 
  Nivel Intermedio **Temas:** usuarios, UIDs, privilegios, auditoría de cuentas, administración de Linux

---

   Descripción Técnica:

Este script realiza una **auditoría completa de los usuarios y privilegios del sistema**, analizando los archivos clave '/etc/passwd', '/etc/shadow' y '/etc/group'.

Para cada usuario, genera un reporte con:

- Usuario
- UID
- Shell
- Home
- Naturaleza del usuario (humano o sistema)
- Estado de contraseña
- Estado del shell y home

Detecta automáticamente situaciones críticas, incluyendo:

- Usuarios con UID 0 que no sean 'root' → riesgo de **privilegios indebidos**. 
- Cuentas sin contraseña o bloqueadas incorrectamente → riesgo de **acceso no autorizado**.
- Usuarios sin home válido o con shell inexistente → posible **inconsistencia o configuración incorrecta**.

El log generado tiene **fecha y hora**, evitando sobrescribir auditorías previas y facilitando revisiones periódicas.

---

   Uso Típico en las Empresas:

- **Auditorías internas de cuentas:** Garantiza que solo 'root' tenga privilegios de administrador y que todas las cuentas de usuario sean válidas.
- **Prevención de brechas de seguridad:** Detecta cuentas huérfanas, sin home, con shell inválida o con privilegios indebidos.
- **Cumplimiento de normativas:** Útil para empresas que requieren auditorías periódicas de usuarios por estándares internos o externos.
- **Automatización:** Se puede integrar en scripts de gestión de usuarios o cron jobs para revisiones regulares.

**Ejemplo de ejecución:**

  bash
sudo ./auditoria_usuarios_privilegios.sh

  Curiosidad Técnica:

- Rangos de UID: 1000–60000 → usuarios humanos
<1000 → usuarios del sistema
Esto permite diferenciar cuentas normales de cuentas del sistema automáticamente.

- Verificación de contraseña: contra=$(gawk -F: -v u="$usuario" '$1==u {print $2}' /etc/shadow)
Detecta si la contraseña está vacía, bloqueada (! o *) o correcta.

- Chequeo de shell y home:
[ ! -e "$shell" ] → shell inexistente
[ ! -d "$home" ] → home inexistente

-Identifica configuraciones sospechosas o inconsistentes en usuarios.
-Logs con timestamp:
usuarios_privilegios_YYYY-MM-DD_HH-MM-SS.log permite mantener historial de auditorías y revisiones periódicas.

  Salida de ejemplo:

juan::1001::/bin/bash::/home/juan::HUMANA::OK::BIEN HECHO
backup::0::/usr/sbin/nologin::/var/backup::sistema::CRITICO POR ESCALA DE PRIVILEGIO::BIEN HECHO
maluser::1002::/bin/fakeshell::/home/maluser::HUMANA::OK::SOSPECHOSO(NO EXISTE SU SHELL)

