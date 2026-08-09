## **Kernel-hardware-modules**

Este directorio esta dedicado al desarrollo de scripts de auditoria de automatización, auditoría y control de bajo nivel para la gestión de módulos del kernel (sys_modules) y la 
interacción del sistema operativo con el hardware en entornos Linux. El objetivo de las herramientas contenidas aquí es proporcionar un control granular sobre el comportamiento del 
núcleo de forma dinámica, permitiendo la inspección técnica, optimización de recursos en memoria RAM y el endurecimiento (hardening) de la seguridad del sistema mediante la gestión 
de controladores.

CONTENIDO:
- [kernel_module_auditor.sh](#kernel_module_auditorsh)
- [kernel_boot_persister.sh](#kernel_boot_persistersh)
- [kernel_dependency_cascade_analyzer.sh](#kernel_dependency_cascade_analyzersh)
- [kernel_security_integrity_auditor.sh](#kernel_security_integrity_auditorsh)
- [scsi_storage_auditor.sh](#scsi_storage_auditorsh)
- [usb_security_guard.sh](#usb_security_guardsh)
____________________________________________________________________________________________________________________________________________________________________________________

## **kernel_module_auditor.sh**
   Nivel "Intermedio - Avanzado" **Temas:** Kernel Hardening, Sysfs/kernel Modules Administration, I/O Redirection (File Descriptors).

   Descripción Técnica:
   Este script actúa como un auditor de seguridad automatizado y táctico para el espacio del núcleo de Linux (Ring 0). Su objetivo principal es mitigar el aumento de la superficie 
   de ataque del sistema operativo mediante la detección, inspección y remoción dinámica de módulos del kernel (.ko) que se encuentren cargados de manera innecesaria en la memoria 
   RAM (como drivers de hardware obsoleto o periféricos no autorizados).

   La herramienta valida privilegios de superusuario, procesa argumentos posicionales de forma dinámica y genera un reporte de auditoría centralizado aislando el flujo de datos 
   mediante un descriptor de archivos persistente, garantizando que el entorno de ejecución en la terminal permanezca limpio.

   Uso Tíico en las empresas:
   En entornos corporativos y de infraestructura crítica (como servidores de bases de datos, clusters de Kubernetes o entornos financieros), las políticas de Kernel Hardening exigen 
   que los servidores corran exclusivamente con los controladores esenciales para su función (por ejemplo, omitiendo drivers de sonido, cámaras web, disqueteras o gamepads).

   Una empresa utilizaría este script integrado en sus flujos de despliegue continuo (CI/CD) o tareas cron de mantenimiento para:
   - Auditar el cumplimiento de normativas de seguridad (Compliance): Asegurar que ningún servidor en producción tenga activos módulos vulnerables o en desuso.
   - Mitigación automatizada de Shadow Hardware: Si un atacante o usuario interno conecta un dispositivo USB no autorizado (como un Keylogger por hardware o un módem), el script 
   puede detectar y descargar el driver de la RAM inmediatamente antes de que el dispositivo pueda interactuar con el sistema operativo.

   Ejemplo de Ejecución:

   sudo ./kernel_module_auditor.sh joydev uvcvideo floppy

   Curiosidad Técnica:
   Este script implementa dos conceptos avanzados de administración y scripting en Linux:
   - exec 3>>"$REPORTE" (Descriptores de Archivos Personalizados): En lugar de hacer un común echo "..." >> archivo.log en cada línea, el script abre el descriptor de archivos 
   número 3 apuntando al log en modo append. Usar >&3 canaliza la salida directamente a ese canal de forma eficiente y limpia. Al final, exec 3>&- cierra el descriptor de manera 
   segura para liberar recursos del sistema.
   - La tubería lsmod | gawk '{print $1}' | grep -ixq "$modulo": Para blindar el script contra falsos positivos, se usa gawk para aislar estrictamente la primera columna de lsmod 
   (donde residen los nombres de los módulos cargados). Luego, grep -x obliga a hacer una coincidencia exacta de toda la línea, evitando que un módulo corto (como lp) de un falso 
   positivo con uno más largo (como lp_vivid). La bandera -q (quiet) asegura que la comprobación sea silenciosa y no altere los logs.
   - El uso de la opcion -F para especificar los campos en el comando modinfo: -F description y -F license
   - El uso de modprobe -r "$modulo", para descargar el modulo de la memoria RAM.

_____________________________________________________________________________________________________________________________________________________________________________________

## **kernel_boot_persister.sh**
   Nivel "Avanzado" **Temas:** Kernel Boot Persistence, Hardware Introspection (PCI/USB Bus), Advanced Bash Privileges, Regular Expressions.

   Descripción:
   Este script automatiza la persistencia y el aprovisionamiento dinámico de configuraciones del espacio del núcleo (Kernel Space) en sistemas GNU/Linux. Su objetivo es doble: 
   permite inyectar módulos de forma permanente para el arranque del sistema o aplicar un baneo estricto (blacklist) sobre controladores no deseados.
   A diferencia de configuraciones estáticas comunes, el script ejecuta una Fase de Diagnóstico de Hardware previa mediante introspección de buses físicos (USB y PCI/PCIe) y 
   análisis de metadatos binarios (modinfo alias) para verificar si el módulo solicitado tiene coherencia con los componentes físicos reales del equipo. Finalmente, aplica los 
   cambios en caliente sobre la memoria RAM para evitar reinicios innecesarios.

   Uso Típico en las Empresas:
   En la administración de servidores corporativos, centros de datos y hardening de infraestructura, los cambios volátiles con modprobe no son viables ya que ante un corte de 
   energía o mantenimiento programado, la configuración se perdería.
   - Provisionamiento Automatizado de Hardware: Configurar servidores en masa para que carguen automáticamente drivers de red de alto rendimiento (e1000e) o almacenamiento (nvme) 
   desde el arranque, validando primero si la tarjeta física está instalada en el rack.
   - Hardening de Puestos de Trabajo y Kioscos: Bloquear permanentemente módulos propensos a ataques o fugas de datos (como almacenamiento masivo USB, cámaras web o drivers de juego) 
   inyectando directivas de blacklist inquebrantables, reduciendo la superficie de ataque de la compañía de manera drástica.

   Ejemplo de Ejecución:

   sudo ./kernel_boot_persister.sh --blacklist uvcvideo

   Curiosidad Técnica:
   Este desarrollo implementa tres técnicas avanzadas de administración de sistemas e interpretación en Bash:
   1. La inyección segura con tee: En Linux, hacer sudo echo "texto" > /etc/archivo.conf falla porque la redirección > la ejecuta el shell del usuario sin privilegios. El script 
   resuelve esto usando echo "..." | tee "$ARCHIVO_CONF" >/dev/null. Al anteponer el sudo al script completo, tee hereda los permisos para abrir y escribir en zonas restringidas del 
   sistema de archivos real (/etc/modprobe.d y /etc/modules-load.d).
   2. Introspección por Expresiones Regulares Extendidas (grep -qiE): Al interrogar los buses de hardware con lsusb o lspci, se aplica una sola tubería con el flag -E para evaluar 
   múltiples patrones lógicos mediante operadores OR (video|camera|wireless|vga), logrando mapear en una sola línea de código si el dispositivo físico existe.
   3. Mapeo de Firmas Binarias (modinfo -F alias): Como "Plan B" de diagnóstico, si el módulo no está en las listas predefinidas, el script inspecciona los metadatos del archivo 
   binario comprimido del controlador en disco para extraer sus registros de alias de hardware. Si el driver cuenta con alias válidos, el script deduce programáticamente que 
   interactúa con elementos físicos.
   4. El directorio para blacklist es /etc/modprobe.d y el archivo debe llamarse: /etc/modprobe.d/blacklis-$MODULO.conf", cuyo contenido debe tener este formato 'blacklist $MODULO'
   5. El directorio de persistencia en boot tiene es /etc/modules-load.d y el archivo debe llamarse: /etc/modules-load.d/$MODULO.conf, cuyo contenido solo debe tener el nombre del
   modulo

____________________________________________________________________________________________________________________________________________________________________________________

## **kernel_dependency_cascade_analyzer.sh**
   Nivel "Intermedio/Avanzado" **Temas:** Módulos del kernel, Gestión de dependencias en RAM, Triage de incidentes, Automatización con Bash y gawk

   Descripcion Técnica:
   Este script realiza una auditoría y descarga en cascada segura de módulos del kernel Linux cargados en memoria RAM. Al intentar descargar un módulo raíz o crítico del que dependen
   otros subsistemas, el sistema operativo rechaza la operación por recursos ocupados. El script resuelve esto mapeando en tiempo real el árbol de dependencias activas
   (`módulos "hijos"`) mediante la inspección de la tabla del kernel (`lsmod`) y ejecutando una remoción ordenada paso a paso. Si un módulo dependiente no puede ser descargado por
   estar en uso activo, la herramienta aborta el proceso inmediatamente para evitar inestabilidad en el sistema. Además, en caso de que el módulo objetivo no esté cargado, realiza
   un diagnóstico en disco para extraer sus metadatos y prerrequisitos requeridos (`modinfo`).

   Uso Típico en las empresas:
   En entornos corporativos y servidores de producción (especialmente en SOCs, respuesta a incidentes y administración de infraestructura Linux), esta herramienta se utiliza en los
   siguientes escenarios:
   - **Aislamiento de Controladores Maliciosos o Vulnerables:** En un incidente de ciberseguridad donde se detecta un módulo de kernel sospechoso (rootkit en espacio de kernel o
   driver comprometido), el equipo de SecOps puede descargarlo en caliente sin tener que reiniciar el servidor de producción.
   - **Mantenimiento y Unload de Hardware Sin Reinicio:** Al realizar mantenimiento de tarjetas de red (NICs), HBAs de almacenamiento o GPUs, permite descargar la pila completa de
   controladores dependientes de forma limpia antes de realizar hot-swapping o actualización de drivers.
   - **Prevención de Kernel Panics:** Evita que los administradores fuercen la descarga de módulos críticos de forma errónea, bloqueando el proceso de descarga si algún proceso del
   sistema mantiene bloqueado un driver dependiente.

   Ejemplo de Ejecucion:

   ```
   # Dar permisos de ejecución
   chmod +x kernel_dependency_cascade_analyzer.sh

   # Ejecución obligatoria con privilegios de superusuario (root/sudo)
   sudo ./kernel_dependency_cascade_analyzer.sh <nombre_del_modulo>

   # Ejemplo 1: Módulo con dependencias en RAM
   sudo ./kernel_dependency_cascade_analyzer.sh snd_pcm

   # Ejemplo 2: Módulo no cargado actualmente
   sudo ./kernel_dependency_cascade_analyzer.sh e1000e

   ```

   Curiosidad Técnica:

   - **Procesamiento dinámico del árbol con gawk y split:**
   `mapfile -t dependientes < <(lsmod 2>/dev/null | gawk '{print $1, $4}' | gawk -v mod="$MODULO" '{ if(mod == $1){ split($2,arreglo,","); for(indice in arreglo){printf "%s\n", arreglo[indice]} }}')`
   En lugar de usar tuberías complejas con cut, tr o sed, el script utiliza la función interna split() de gawk para tomar la cuarta columna de lsmod (que contiene los dependientes
   delimitados por comas ,), fragmentarla en un arreglo en memoria e imprimir cada submódulo en una nueva línea. Esto permite que mapfile capture directamente la lista limpia dentro
   de un array de Bash.
   - **Diferenciación de Dependencias vs Prerrequisitos:** El script maneja dos direcciones conceptuales de dependencias:
   1. Dependientes activos (RAM): Obtenidos desde lsmod (módulos cargados encima del objetivo).
   2. Prerrequisitos estáticos (Disco): Obtenidos con modinfo -F depends (módulos que el objetivo necesita abajo para poder iniciar).
   - Uso de modprobe -r
   - Uso de ${dependencias[*]}, para que me de como resultado todo en una sola cadena.

____________________________________________________________________________________________________________________________________________________________________________________

## **kernel_security_integrity_auditor.sh**
   **Nivel "Avanzado"** **Temas:** Kernel Modules, Tainted Kernel Flags, Digital Signatures, Hardware & Driver Security, Modprobe Persistence, System Hardening.

   Descripción Técnica:
   Este script realiza una auditoría integral de seguridad sobre la memoria RAM y la capa del kernel Linux. Examina el estado de contaminación (tainted flags) del kernel a nivel 
   global y por módulo individual, valida las licencias de software (GPL vs. Propietario) y verifica la presencia de firmas digitales para mitigar la ejecución de rootkits o
   controladores no verificados. Adicionalmente, audita las reglas de persistencia en /etc/modprobe.d/ y /etc/modules-load.d/, detectando conflictos de ejecución (módulos activos
   cargados que figuran en listas negras) y eliminando/reportando configuraciones huérfanas con parámetros obsoletos o inválidos. Si se ejecuta con el parámetro --strict, aplica
   remediación automática descargando dinámicamente los módulos en riesgo.

   Uso Típico en las empresas:
   Se utiliza en entornos corporativos, servidores de producción e infraestructura crítica (Fintech, PCI-DSS, ISO 27001) como un control de cumplimiento (compliance check) continuo 
   dentro de la canalización DevSecOps o mediante tareas programadas de Cron. Resuelve problemas del día a día como la detección temprana de controladores propietarios o maliciosos
   inyectados en RAM, la mitigación de vectores de ataque por carga arbitraria de módulos en caliente y la limpieza de configuraciones residuales tras actualizaciones del kernel o
   desinstalación de software, evitando comportamientos erráticos o vulnerabilidades en el sistema operativo.

   Ejemplo de ejecución:

   ```
   # Otorgar permisos de ejecución
   chmod +x kernel_security_integrity_auditor.sh

   # Modo Auditoría (Lectura y reporte informativo)
   sudo ./kernel_security_integrity_auditor.sh

   # Modo Mitigación Estricta (Intenta remover automáticamente los módulos no conformes)
   sudo ./kernel_security_integrity_auditor.sh --strict
   ```

   Curiosidad Técnica:

   - /proc/sys/kernel/tainted: Este archivo devuelve una máscara de bits entera que representa el estado de integridad del kernel. Si devuelve 0, el kernel está completamente limpio.
   Un valor distinto de cero indica banderas de contaminación (por ejemplo, 1 para módulos sin licencia GPL, 8192 para módulos no firmados o 512 para fallos previos en RAM).
   - modinfo -F license y verificación de signer: La bandera -F (field) extrae únicamente el valor del campo especificado de la cabecera ELF del módulo. El script analiza si el
   parámetro contiene "GPL" y busca la presencia del parámetro signer para asegurar que el archivo .ko fue compilado con claves criptográficas autorizadas.
   - /sys/module/<modulo>/taint: Permite leer individualmente la bandera específica que un módulo inyectó al kernel, evitando falsos positivos al aislar únicamente los drivers
   culpables de alterar la RAM.
   - mapfile -t modulos < <(lsmod | gawk 'NR>1 {print $1}'): Carga de manera eficiente la primera columna de la salida de lsmod (los nombres de los módulos cargados en RAM)
   directamente en un arreglo de Bash, omitiendo la cabecera mediante NR>1 y previniendo problemas de word splitting.
   - Parseo dinámico con gawk: En la fase 02, el script procesa sintácticamente las directivas de configuración (blacklist, options, install, alias) interpretando el índice exacto
   de la columna según el comando utilizado en los archivos .conf para validar la existencia real del módulo objetivo mediante modinfo.
   - Uso del grep -rqE "^\s*blacklist\s+${modulo}\b" /etc/modprobe.d/*.conf 2>/dev/null: para que nos imprima todas las lineas que cumplen esa expresion regular usando Globbing en
   el directorio especificado.
   - grep -vE '^\s*#|^\s*$' "$ARCHIVO": Para evitar las lineas que sean comentarios y las lineas vacias.
   - Uso de unset modulos: Para eliminar el contenido del mapfile modulos

_____________________________________________________________________________________________________________________________________________________________________________________

## **scsi_storage_auditor.sh**
   Nivel "Avanzado" **Temas:** Subsistema SCSI, Infraestructura de udev, Sistema de archivos Sysfs (`/sys`), Enlaces Persistentes (`/dev/disk/by-id`), Procesamiento de streams (`gawk`).

   Descripción Técnica:
   Este script es una herramienta de auditoría forense y de infraestructura en caliente de bajo nivel. Su objetivo principal es mapear la ruta lógica de un dispositivo de bloque 
   (`/dev/sdX`) hacia sus orígenes físicos y virtuales dentro del sistema operativo.
   El script automatiza tres tareas críticas:
   1. Extrae y descompone la dirección jerárquica **HCTL** (`[Host:Channel:Target:LUN]`) del dispositivo usando `lsscsi`.
   2. Realiza una introspección directa en la memoria RAM (dentro de `/sys/devices/` mediante `udevadm`) para obtener la telemetría del hardware, determinando el modelo de fábrica, 
   tamaño en sectores y la naturaleza física del almacenamiento (`SSD/FLASH` o `MECANICO/HDD`).
   3. Rastreará y aislará los enlaces simbólicos persistentes en `/dev/disk/by-id/` asociados al disco para garantizar operaciones de montaje seguras.

   Uso Típico en las empresas:
   En entornos corporativos y centros de datos (Datacenters), los servidores se conectan a cabinas de almacenamiento masivo externas (SAN) mediante redes de fibra óptica o iSCSI. 
   Estas cabinas inyectan constantemente nuevos volúmenes lógicos (LUNs) al sistema.
   * **Inestabilidad de nombres tradicionales:** Los nombres como `/dev/sdb` o `/dev/sdc` son volátiles y pueden cambiar de orden de manera asíncrona entre reinicios del kernel. 
   Si un administrador configura un servicio crítico o el archivo `/etc/fstab` apuntando a `/dev/sdb`, el servidor podría fallar o corromper datos tras un mantenimiento. Este 
   script mitiga el error humano proveyendo instantáneamente las rutas `/dev/disk/by-id/` idóneas e indestructibles para la configuración.
   * **Auditoría de rendimiento express:** Permite a los ingenieros de DevOps y SysAdmins verificar en segundos si un disco asignado a una base de datos es realmente un estado 
   sólido (SSD) o un disco mecánico lento, consultando directamente la mente del kernel en `/sys` sin interrumpir los servicios.

   Ejemplo de Ejecución:

   sudo ./scsi_storage_auditor.sh sda

   Curiosidad Técnica:
   * Redirección de Procesos No Bloqueante (< <(...)): En lugar de generar archivos temporales o usar tuberías tradicionales (|) que levantan subshells donde se pueden perder 
   las variables, el script utiliza Process Substitution para pasarle la salida de lsscsi de forma directa a gawk como si fuera un archivo de lectura plano.
   * Inyección de expresiones regulares dinámicas en gawk: En la Fase 1, el comando gawk utiliza la función interna gsub(/[\[\]]/, "", cadena) para limpiar y eliminar quirúrgicamente 
   los corchetes de la dirección SCSI mediante expresiones regulares antes de aplicar el comando split(). Esto garantiza que los índices numéricos queden limpios y puros en el array.
   * Auditoría de enlaces por patrón exacto: En la Fase 3, el filtro de búsqueda utiliza un grep -iE optimizado con anclajes de fin de línea ($) y patrones específicos para 
   particiones: /${NOMBRE}$|/${NOMBRE}p[0-9]|/${NOMBRE}[0-9]. Esto evita falsos positivos (por ejemplo, que al auditar el disco sda se terminen listando los enlaces de un disco 
   llamado sdaa o sdab).

_____________________________________________________________________________________________________________________________________________________________________________________

## **usb_security_guard.sh**
   Nivel "Avanzado" **Temas:** Subsistema de almacenamiento masivo USB, Introspección de sysfs (removable), Propiedades de Hardware dinámicas (udevadm), Expresiones Regulares

   Descripción Técnica:
   Este desarrollo implementa una auditoría defensiva automatizada en caliente sobre dispositivos de bloque individuales. El script lee la telemetría del kernel almacenada en la 
   memoria RAM para identificar si un disco es de almacenamiento fijo o removible. Si se trata de un medio extraíble (Pendrive/Disco Externo), intercepta la jerarquía de hardware 
   de abajo hacia arriba en el bus USB para extraer identificadores físicos únicos invariables de fábrica: Vendor ID, Product ID y el número de serie de la unidad.

   Uso Típico en las empresas:
   Utilizado activamente por los equipos de Ciberseguridad (SecOps) y Auditoría Forense Informática como un mecanismo de primer nivel en políticas de Data Loss Prevention (DLP) y 
   control de medios perimetrales.
   - Detección de exfiltración de datos no autorizada: El script permite aislar de forma programática las firmas exactas del fabricante del hardware de almacenamiento masivo que se 
   conecta a las estaciones de trabajo de la empresa.
   - Inyección de logs para correlación de eventos (SIEM): Al extraer de manera confiable el número de serie único y los identificadores de producto, la salida del script es ideal 
   para ser parseada y enviada a herramientas centrales de monitoreo (como Splunk o Elastic Stack) para generar alertas de incidentes de seguridad y auditorías de inventario de 
   hardware en tiempo real.

   Ejemplo de Ejecución:

   sudo ./usb_security_guard.sh sdb

   Curiosidades Técnicas:
   * **Evaluación Aritmética Avanzada (`(( ... ))`):** En lugar de usar los operadores clásicos de texto (`[ "$VARIABLE" -eq 0 ]`), el script utiliza la sintaxis de evaluación 
   aritmética nativa de Bash `if (( ARCHIVO_VIRTUAL == 0 ))`. Esto optimiza el rendimiento del script al procesar el valor numérico binario (`0` o `1`) del estado `removable` 
   directamente en el procesador, sin necesidad de invocar subprocesos de comparación de cadenas.
   * **Mapeo de Atributos del Padre con Filtro de Instancia Única (`grep -m1`):** El comando `udevadm info -a` genera un volcado masivo de texto ascendente recorriendo todos los 
   dispositivos padres en el árbol de `/sys`. Para evitar colisiones o sobreescrituras (ya que múltiples controladores de la placa madre pueden tener campos como `serial`), 
   el script implementa `grep -m1`. Esto le ordena al motor de búsqueda detenerse inmediatamente tras la primera coincidencia, aislando quirúrgicamente los datos del dispositivo 
   periférico físico más cercano.
   * **Estrategia Defensiva de Fallback Automático (`[[ -z ... ]]`):** El script implementa un mecanismo de redundancia industrial en la **Fase 3**. Si por restricciones de permisos 
   en la arquitectura de hardware el modo clásico de lectura de atributos de `udevadm` retorna una cadena vacía, el script lo detecta dinámicamente mediante el flag `-z` y activa 
   un plan de contingencia que extrae los identificadores directamente desde la base de datos de propiedades de entorno con `-q property`.

_____________________________________________________________________________________________________________________________________________________________________________________
