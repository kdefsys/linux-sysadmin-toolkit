# acces-control/

Este directorio contiene scripts de **auditoría y control de accesos en sistemas Linux**, centrados en permisos de archivos, usuarios y privilegios. 

Incluye herramientas para:<

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
  Nivel Intermedio-Avanzado **Temas:** Seguridad en Linux, Privilegios Especiales (SUID,SGID), automatizacion con Bash, Procesamiento de datos con GAWK

---

  Descripción Técnica:

Este script es una herramienta de auditoría de seguridad forense diseñada para localizar y clasificar archivos que poseen los bits de permisos SETUID (4000) o 
SETGID (2000). Estos bits son críticos porque permiten que un usuario común ejecute un programa con los privilegios del dueño (root) o del grupo del archivo.

El script escanea un directorio específico de forma recursiva y cruza los resultados con una "Whitelist" (Lista Blanca) de rutas estándar del sistema (como /bin, 
/usr/lib, etc.). Su objetivo principal es detectar "binarios de escalada de privilegios" que un atacante o un software malicioso podría haber plantado en directorios 
inusuales (como /tmp, /var/www o /home) para obtener control total del servidor.

---

  Uso Típico en las empresas:

En el entorno corporativo y de centros de datos, este script se utiliza como parte de las rutinas de Monitoreo de Integridad de Archivos (FIM) y auditorías de cumplimiento 
normativo (como PCI-DSS o ISO 27001).

Contexto específico: Las empresas lo ejecutan mediante tareas cron o herramientas de orquestación (Ansible/Puppet) justo después de realizar actualizaciones de software o de
 forma periódica para asegurar que ningún binario nuevo haya adquirido privilegios elevados de forma no autorizada.

Problemas que resuelve:

  - Detección de Backdoors: Identifica archivos sospechosos que permiten a un usuario normal convertirse en root.
  - Control de Configuración: Detecta cuando un administrador ha instalado herramientas con permisos incorrectos que violan la política de seguridad.
  - Reducción de la Superficie de Ataque: Ayuda a los equipos de seguridad a identificar binarios innecesarios que tienen el bit SUID activo y que podrían ser explotados.

  Ejemplo de Ejecución:

  chmod u+x auditoria_permisos_peligrosos.sh

  sudo ./auditoria_permisos_peligrosos.sh /

  Curiosidad Técnica:
  El script destaca por su alta eficiencia al combinar comandos avanzados que evitan la sobrecarga del procesador
  - find ... -exec stat ... {} +; En lugar de ejecutar stat una vez por cada archivo encontrado.
  - mapfile -t: Carga todos los resultados de una sola vez en un array de Bash, evitando el uso de bucles while que son mas lentos
  - Concatenación Dinámica en gawk ("^" array_rutas[indice]): Dentro del motor de gawk, el script construye expresiones regulares "al vuelo". Al usar el símbolo ^, el script
  realiza una comparación de prefijo: verifica si la ruta del archivo comienza por una de las rutas seguras, permitiendo validar subdirectorios de forma inteligente sin
  necesidad de listar cada archivo individualmente.


______________________________________________________________________________________________________________

## **detector_permisos_inseguros.sh** 
  Nivel Avanzado **Temas:** Gestión de permisos especiales (sticky bit), Procesamiento de Opciones (getopts), Auditoría Recursiva, Referencia de variables.

---

  Descripción Técnica:
  Este script es una herramienta de auditoría avanzada diseñada para identificar fallos de seguridad en los permisos del sistema de archivos. Se centra en la 
  detección de archivos con permisos de lectura/escritura para "otros" (world-writable) y en la verificación de la presencia del Sticky Bit en directorios críticos.
  El script utiliza una arquitectura modular basada en funciones y una interfaz de comandos profesional mediante getopts. Su objetivo es prevenir la manipulación no 
  autorizada de archivos en entornos compartidos, asegurando que solo los propietarios de los archivos puedan eliminarlos en directorios temporales o compartidos.

  - Ruta completa
  - Permisos en formato legible ('-rw-rw-rw-')
  - Propietario
  - UID
  - GID
  - Tipo de archivo (regular, directorio, symlink, etc.)

  Además, verifica directorios **especiales de uso compartido** ('/tmp', /var/tmp', '/shared') y comprueba si **tienen activo el sticky bit**. Si no lo tienen, los marca 
  como [CRITICO].
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

   Ejemplo de ejecución:

   Detectar archivos world-writable en /home:

   ./detector_permisos_inseguros.sh -d /home

   Verificar directorios especiales con sticky bit:

   ./detector_permisos_inseguros.sh -c

   Aplicar sticky bit a /tmp si falta:

   ./detector_permisos_inseguros.sh -f /tmp

   Curiosidad Técnica:
   - find "$DIR" -type f \( -perm -o=r -and -perm -o=w \) Busca archivos que son world-readable y world-writable, indicando riesgos de acceso externo.
   - Sticky bit (-k) El script usa [ -k "$directorio" ] para detectar si un directorio compartido solo permite que el propietario de un archivo lo borre, 
   evitando que otros usuarios eliminen archivos ajenos.
   - stat -c "%n|%A|%U|%u|%G|%F": Obtiene información completa de cada archivo, incluyendo permisos legibles, propietario, UID, GID y tipo de archivo.
   - Logs con timestamp Cada ejecución genera un archivo único: detector_YYYY-MM-DD_HH-MM-SS.log, facilitando auditorías periódicas sin sobrescribir resultados previos.
   - getopts :d:cf: : Implementa un analizador de opciones robusto. Los dos puntos iniciales activan el "modo silencioso", permitiendo al desarrollador capturar errores
   de argumentos faltantes de forma personalizada.
   - Optimización con mapfile y stat.

______________________________________________________________________________________________________________

## **auditoria_usuarios_privilegios.sh** 
  Nivel Avanzado **Temas:** Seguridad de identidades, Gestión de /etc/shadow, Funciones con paso por referencia (local -n), Auditoría de sistemas

---

   Descripción Técnica:

   Este script realiza una inspección profunda de la base de datos de usuarios de un sistema Linux. A diferencia de un listado simple, el script cruza información de 
   /etc/passwd y /etc/shadow para evaluar la salud de cada cuenta. Su objetivo es detectar tres vectores de riesgo principales: escalada de privilegios (usuarios con UID 0
   que no son root), debilidad de acceso (contraseñas vacías o cuentas mal bloqueadas) e inconsistencias de configuración (rutas de shell o directorios home que no existen 
   físicamente).
   El script destaca por su arquitectura modular, utilizando funciones independientes para evaluar la seguridad de la cuenta y la integridad de la configuración, lo que facilita 
   su mantenimiento y escalabilidad.

---

   Uso Típico en las Empresas:
   En un entorno corporativo de TI o ciberseguridad, este script es fundamental para el cumplimiento de normativas de control de acceso.
   - Contexto de uso: Se utiliza habitualmente en procesos de Onboarding/Offboarding de empleados para verificar que no queden cuentas activas sin contraseña, y en auditorías 
   de SRE (Site Reliability Engineering) para asegurar que las cuentas de servicio del sistema tengan sus rutas técnicas (home y shell) correctamente configuradas.
   - Detección de "Backdoor Users": Encuentra atacantes que hayan creado usuarios con UID 0 para tener privilegios de root sin usar la cuenta oficial.
   - Limpieza de Cuentas Huérfanas: Identifica cuentas de antiguos empleados cuyo directorio home ha sido borrado pero el usuario sigue existiendo en el sistema.
   - Cumplimiento de Políticas de Password: Asegura que no existan cuentas críticas con el campo de contraseña en blanco, lo que permitiría el acceso sin credenciales.

   Ejemplo de ejecución:

   sudo ./auditoria_usuarios_privilegios.sh

   Curiosidad Técnica:
   - Rangos de UID: 1000–60000 → usuarios humanos <1000 → usuarios del sistema Esto permite diferenciar cuentas normales de cuentas del sistema automáticamente.
   - Verificación de contraseña: contrasenia=$(getent shadow "$name" | cut -d ":" -f 2), forma profesional de consultar bases de datos administrativas.
   - Chequeo de shell y home: [ ! -e "$shell" ] → shell inexistente [ ! -d "$home" ] → home inexistente
   - Identifica configuraciones sospechosas o inconsistentes en usuarios.
   - Logs con timestamp: usuarios_privilegios_YYYY-MM-DD_HH-MM-SS.log permite mantener historial de auditorías y revisiones periódicas.
   - regex [[ "$5" =~ "^(!|\*) ]]"

___________________________________________________________________________________________________________________________________________________________________________
