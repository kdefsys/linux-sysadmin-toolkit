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
- [auditor_de_integridad.sh](#auditor_de_integridadsh)
- [quarantine_and_lockdown.sh](#quarantine_and_lockdownsh)
- [access_guard.sh](#access_guardsh)

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

  sudo ./auditoria_permisos_peligrosos.sh -d <directorio> [-h]

  Curiosidad Técnica:
  El script destaca por su alta eficiencia al combinar comandos avanzados que evitan la sobrecarga del procesador
  - find ... -exec stat ... {} +; En lugar de ejecutar stat una vez por cada archivo encontrado.
  - mapfile -t: Carga todos los resultados de una sola vez en un array de Bash, evitando el uso de bucles while que son mas lentos
  - uso de realpath para sacar la ruta verdadera.
  - Uso de la expresio archivo="${file%%$'\t'*}", para sacar solo la ruta del archivo contenido en el mapfile

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
   - find "$DIR" -type f -perm -o=rw Busca archivos que son world-readable y world-writable, indicando riesgos de acceso externo.
   - Sticky bit (-k) El script usa [ -k "$directorio" ] para detectar si un directorio compartido solo permite que el propietario de un archivo lo borre, 
   evitando que otros usuarios eliminen archivos ajenos.
   - stat -c "%n|%a|%U|%u|%G|%F": Obtiene información completa de cada archivo, incluyendo permisos legibles, propietario, UID, GID y tipo de archivo.
   - Logs con timestamp Cada ejecución genera un archivo único: detector_YYYY-MM-DD_HH-MM-SS.log, facilitando auditorías periódicas sin sobrescribir resultados previos.
   - getopts :d:cf:h : Implementa un analizador de opciones robusto. Los dos puntos iniciales activan el "modo silencioso", permitiendo al desarrollador capturar errores
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
   - Verificación de contraseña: contrasenia=$(getent shadow "$name" | gawk -F ":" '{print $2}'), forma profesional de consultar bases de datos administrativas.
   - Chequeo de shell y home: [ ! -e "$shell" ] → shell inexistente [ ! -d "$home" ] → home inexistente
   - Identifica configuraciones sospechosas o inconsistentes en usuarios.
   - Logs con timestamp: usuarios_privilegios_YYYY-MM-DD_HH-MM-SS.log permite mantener historial de auditorías y revisiones periódicas.
   - regex [[ "$5" =~ "^(!|\*) ]]
   - El uso de IFS=":" read -r name _ UID _ _ home shell para leer en bucle

___________________________________________________________________________________________________________________________________________________________________________

## **auditor_de_integridad.sh**
   Nivel Experto **Temas:** Monitoreo de integridad (FIM), Bits especiales (SUID/SGID/Sticky), Optimización de búsqueda y comparación

   Descripción Técnica:
   Este script actúa como una herramienta de seguridad preventiva que detecta desviaciones en los privilegios del sistema. Su funcionamiento se basa en la creación de una 
   "Línea Base" (baseline) de archivos con permisos especiales (4000, 2000, 1000). Al realizar escaneos posteriores, el script identifica tres escenarios críticos:
   - Integridad: El archivo existe y mantiene sus permisos originales.
   - Modificación: El archivo ha sufrido un cambio de permisos (posible escalada de privilegios).
   - Incursión: Se detectan binarios con permisos especiales que no estaban registrados en la base de datos de confianza.

   Uso Típico en las empresas:
   Es una herramienta fundamental para el Hardening y el cumplimiento de normativas de seguridad (como PCI-DSS o ISO 27001).
   - Detección de Intrusos: Permite identificar rápidamente si un atacante ha instalado una backdoor con privilegios de root (SUID).
   - Auditoría de Cambios: Ayuda a los administradores de sistemas a verificar que las actualizaciones o instalaciones recientes no hayan alterado la postura de seguridad de los 
   binarios del sistema.
   - Automatización: Se puede programar mediante cron para recibir reportes diarios de cualquier alteración en directorios sensibles como /usr/bin o /sbin.

   Ejemplo de Ejecución:

   sudo ./auditor_de_integridad.sh -g [-h]


   sudo ./auditor_de_integridad.sh -d /usr/bin [-h]

   Curiosidad Técnica:
   - find / -perm /7000: Utiliza el prefijo / para realizar un "OR" lógico. Captura cualquier archivo que tenga al menos uno de los bits especiales activos. El 7 es la suma octal de
   SUID(4) + SGID(2) + Sticky(1).
   - Expansión de Parámetros (% y #): Al usar ${archivo%|*} y ${archivo##*|}, el script procesa los datos directamente en la memoria del shell. Esto es drásticamente más rápido que 
   invocar comandos externos como cut o awk dentro de un bucle que recorre miles de archivos.
   - El uso de la opcion grep -F
   - El uso de una funcion dentro de una susticion de procesos: mapfile -t files < <(escaneo "$DIRECTORIO").

___________________________________________________________________________________________________________________________________________________________________________________

## **quarantine_and_lockdown.sh**
   Nivel: **Avanzado / Incident Response (IR)** **Temas:** Mitigación de Incidentes, Jaulas de Aislamiento, Control de Accesos Securitizado, Automatización de Permisos, 
   Redirección Avanzada de Descriptores de Archivos, getopts.

   Descripción Técnica:
   Este script actúa como un **motor interactivo de mitigación defensiva y respuesta ante incidentes (Incident Response)** dentro del sistema operativo Linux. Su objetivo principal
   es neutralizar de manera inmediata tres vectores de riesgo comunes detectados durante un compromiso de seguridad:
   1. **Aislamiento de Malware/Binarios Inseguros (`-q`):** Detecta si un archivo sospechoso posee permisos especiales activos (`SUID/SGID`) que puedan permitir una escalada de 
   privilegios. De ser así, remueve dichos bits de forma segura, extrae el nombre base del archivo para evitar subprocesos redundantes y lo traslada a una jaula de cuarentena 
   dedicada (`/opt/quarantine`). Una vez allí, despoja el archivo de cualquier permiso de ejecución o lectura (`chmod 000`) y transfiere su propiedad absoluta a `root:root`, 
   dejándolo completamente inofensivo para su posterior análisis forense.
   2. **Revocación Inmediata de Accesos (`-u`):** Bloquea de manera simultánea la contraseña de un usuario sospechoso, altera su shell por defecto a `/usr/sbin/nologin` para impedir
   sesiones interactivas, y fuerza la expiración inmediata de su cuenta en el sistema para cerrar cualquier persistencia (sesiones SSH, tareas cron pendientes, etc.).
   3. **Endurecimiento Masivo de Permisos (`-r`):** Aplica de forma masiva una plantilla de permisos estrictos sobre un directorio crítico. Utiliza una sintaxis optimizada de alta 
   eficiencia para reconfigurar todos los subdirectorios a `755` y todos los archivos regulares a `644`.

   Uso Típico en las empresas:
   En el entorno corporativo y de producción, este script es una herramienta indispensable para los equipos de **SOC (Security Operations Center)** y **SysAdmins / DevSecOps Engineers** 
   en los siguientes contextos:
   * **Respuesta Automatizada ante Intrusiones (SOAR):** Puede ser invocado automáticamente por un sistema de detección de intrusos (como un SIEM o un agente de Wazuh) en el momento 
   exacto en que se detecta una anomalía (por ejemplo, la creación de un binario con SUID no autorizado o actividad inusual de un usuario).
   * **Mitigación del Día a Día:** Resuelve el problema de la lentitud y el error humano durante un incidente. En lugar de que el administrador ejecute manualmente múltiples comandos
   para degradar un archivo, bloquear un usuario y auditar directorios mientras el atacante sigue activo, este script centraliza y ejecuta la mitigación en milisegundos de forma 
   estandarizada.
   * **Hardening Posterior a Despliegues:** Se utiliza para aplicar plantillas de permisos masivas a directorios compartidos o servidores web que han sufrido desconfiguraciones por 
   malas prácticas de desarrollo (como el uso de `chmod 777`).

   Ejemplo de Ejecución:
   El script requiere estrictamente privilegios de superusuario (`root`) para interactuar con las cuentas del sistema y la modificación de permisos en `/opt` y `/var/log`.

   **Ejecución con múltiples banderas simultáneas (Mitigación Completa):**
   sudo ./quarantine_and_lockdown.sh -q /home/usuario/sospechoso.elf -u jdoe -r /var/www/html

   **Ejecución **
   sudo ./quarantine_and_lockdown.sh -q /tmp/backdoor.py

   Curiosidad Técnica:
   El script implementa varias técnicas avanzadas de optimización y manejo de bajo nivel en Linux que optimizan el rendimiento y la seguridad:
   - Uso de las opciones -g y -u en los tests para comprobar si tiene los permisos especiales SETGUID y SETUID activados respectivamente.
   - El uso de chmod, chown
   - El uso de las opciones -L, -s y -e del comando usermod para bloquear la contraseña, cambiar el shell y especificar la fecha de expiracion del usuario respectivamente

_____________________________________________________________________________________________________________________________________________________________________________________

## **access_guard.sh**
   Nivel: **Intermedio/Avanzado** **Temas:** Bash Scripting, Administración de Usuarios y Grupos, Permisos POSIX, SGID, ACLs (Control de Acceso Fino), Auditoría de Seguridad,
   Blindaje e Inmutabilidad.

   Descripcion Tecnica:
   **access_guard.sh** es una herramienta integral de administración del sistema y auditoría de seguridad automatizada escrita en Bash. Su objetivo principal es aplicar de manera
   estricta el principio de **Mínimo Privilegio** (Least Privilege) dentro de entornos de sistemas de archivos Linux. El script se organiza de forma modular mediante un procesador 
   de opciones (getopts) para ofrecer cuatro funcionalidades principales:
   1. **Módulo de Aprovisionamiento:** Crea automáticamente usuarios y grupos, asigna ownership al directorio objetivo (`root:<grupo>`), restringe permisos base (`770`) y configura el
   bit especial SGID (`g+s`) para forzar que todos los archivos futuros hereden la propiedad del grupo.
   2. **Módulo de Control Fino con ACLs:** Concede permisos específicos de lectura y ejecución (`r-x`) a un usuario sobre un directorio mediante ACLs recursivas, y configura la 
   Default ACL para asegurar que los subdirectorios y archivos futuros mantengan la misma restricción.
   3. **Módulo de Auditoría de Permisos Peligrosos:** Escanea de forma recursiva un directorio en busca de tres vectores comunes de riesgo: archivos con permisos SUID/SGID habilitados, 
   archivos/carpetas con permiso de escritura para otros (`o+w`), y archivos huérfanos (sin usuario o grupo válido). Toda la salida se guarda de forma estructurada en un archivo `.log`
   con marca de tiempo usando descriptores de archivo dedicados.
   4. **Módulo de Revocacion y Blindaje:** Revoca inmediatamente el acceso de un usuario en el sistema eliminando de forma exhaustiva sus ACLs explícitas a lo largo del sistema de
   archivos local (`-xdev`), desvinculándolo de todos los grupos secundarios y bloqueando su capacidad de inicio de sesión cambiando su shell a `/usr/sbin/nologin`.

   Uso Típico en las Empresas:
   En empresas de tecnología como TechSecure Labs, la alta rotación de personal, la incorporación continua de desarrolladores y la movilidad entre proyectos generan un fenómeno 
   conocido como **"Permission Creep"** (acumulación progresiva de permisos no requeridos).
   - **Onboarding / Creación de entornos compartidos:** Cuando entra un nuevo equipo de desarrollo, SysAdmins u DevSecOps ejecutan el módulo de aprovisionamiento para crear el entorno
   de trabajo compartido de forma segura y uniforme sin recurrir a permisos globales peligrosos como `777`.
   - **Proyectos temporales o Auditorías internas:** Cuando un auditor externo o un consultor necesita revisar cierta información sensible sin modificarla, se le asigna acceso
   temporal mediante el módulo de ACLs sin alterar el ownership tradicional POSIX.
   - **Revisiones periódicas de cumplimiento y Hardening:** Antes de auditorías de estándares como ISO 27001, SOC 2 o PCI-DSS, el equipo de ciberseguridad ejecuta el módulo de
   auditoría para detectar configuraciones inseguras de archivos (huérfanos o con escritura pública).
   - **Offboarding de empleados:** Cuando un empleado deja la empresa o cambia de departamento, el módulo de blindaje garantiza que el usuario pierda acceso inmediato a todos los
   directorios y no conserve vías de persistencia a través de grupos o ACLs residuales.

   Ejemplo de Ejecucion:

   ```# 1. Módulo de Aprovisionamiento (Crea usuario/grupo y configura SGID en la carpeta)
   sudo ./access_guard.sh -a jperez -g devops -d /var/www/proyecto_alpha

   # 2. Módulo de Control Fino con ACLs (Concede r-x a un usuario específico y herencia predeterminada)
   sudo ./access_guard.sh -c /var/www/proyecto_alpha -u mrodriguez

   # 3. Módulo de Auditoría de Permisos Peligrosos (Escanea vulnerabilidades e imprime reporte .log)
   sudo ./access_guard.sh -s /var/www/proyecto_alpha

   # 4. Módulo de Revocación y Blindaje (Elimina ACLs, remueve grupos secundarios y asigna nologin)
   sudo ./access_guard.sh -r jperez

   # 5. Desplegar la ayuda en consola
   ./access_guard.sh -h
   ```

   Curiosidades Tecnicas:
   El script utiliza varios comandos y constructos avanzados de Bash para garantizar velocidad, precisión y seguridad en la ejecución:
   - **Búsqueda eficiente con -perm -4000 y -perm -2000:**
   En lugar de parsear texto con ls -l (lo cual es lento e inseguro en scripts), el comando find usa máscaras octales bit a bit para identificar exactamente archivos con los bits 
   SUID (4000) o SGID (2000) activos.
   - **Límite de Escaneo al Sistema de Archivos Local (find / -xdev ...):**
   En el módulo de blindaje, al revocar las ACLs del usuario en todo el disco mediante find / -xdev, la bandera -xdev evita que find cruce a otros sistemas de archivos montados 
   (como carpetas NFS en red, /proc, /sys o unidades USB), previniendo bloqueos del sistema o demoras extremas durante la ejecución
   - **Manejo Dual de ACLs POSIX (setfacl en Árbol vs. Plantilla Predeterminada):**
   Para garantizar un control de acceso fino que perdure en el tiempo, el script combina dos modos de ejecución de setfacl:
   	1. Aplicación Recursiva Actual (-R):
   		setfacl -R -m u:"$USUARIO_PERMISOS":r-x "$DIRECTORIO_PERMISOS" 2>/dev/null
   	   La bandera -R (recursiva) recorre todo el árbol de directorios existente en ese momento aplicando el modificador -m para otorgar permisos explícitos de lectura y
   	   ejecución (r-x) al usuario especificado, sin alterar los permisos tradicionales POSIX (propietario/grupo/otros) del resto de archivos.
	2. Herencia Automática para el Futuro (-d / Default ACL):
   		setfacl -d -m u:"$USUARIO_PERMISOS":r-x "$DIRECTORIO_PERMISOS" 2>/dev/null
   	   La bandera -d (Default) define una regla de ACL predeterminada únicamente a nivel de carpeta. Esto funciona como una "plantilla de herencia": cualquier nuevo archivo o
   	   subdirectorio que un usuario cree dentro de esa carpeta en el futuro heredará automáticamente la regla u:usuario:r-x, evitando que el administrador tenga que reejecutar
   	   el script cada vez que se agreguen archivos.

_____________________________________________________________________________________________________________________________________________________________________________________
