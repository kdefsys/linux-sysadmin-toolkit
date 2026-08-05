# process-management

## **Descripción**

Este directorio contiene herramientas y laboratorios enfocados en la 
**gestión, auditoría y monitoreo de procesos en sistemas Linux**, una de las 
responsabilidades centrales de un **Linux System Administrator /SRE** en 
entornos productivos.

## **Contenido**

- [detectar_procesos_zombie.sh](#detectar_procesos_zombiesh)
- [auditoria_procesos_largos.sh](#auditoria_procesos_largossh)
- [monitoreo_cpu_memoria.sh](#monitoreo_cpu_memoriash)
- [mapeo_jerarquico.sh](#mapeo_jerarquicosh)
- [anti_mutation_watchdog.sh](#anti_mutation_watchdogsh)
- [process_resource_governor.sh](#process_resource_governorsh)
_____________________________________________________________________________

## **detectar_procesos_zombie.sh**
   Nivel Intermedio **Temas:** Gestión de Procesos, Redirección de descriptores, Procesamiento de texto con gawk, Automatización de logs

   Descripcion Técnica:
   Este script es una herramienta de monitoreo proactivo diseñada para analizar la tabla de procesos de un sistema Linux. Su objetivo principal es detectar 
   procesos en estado Zombie (Z), los cuales son procesos que han terminado su ejecución pero cuya entrada permanece en la tabla de procesos porque su padre 
   no ha leído su estado de salida.
   El script recolecta información detallada (PID, PPID, UID, etc.), clasifica la gravedad de la situación basándose en la acumulación de zombies por proceso
   padre y genera un reporte fechado. Además, realiza una validación lógica contra un umbral de alerta definido por el usuario para determinar si existe un riesgo 
   operativo inminente.

   Uso Típico en empresas:
   - Detección temprana de fallas en servicios
     - Servicios mal programados que no recolectan procesos hijos
   - Prevención de degradación del sistema 
     - Acumulación de zombies puede agotar la tabla de procesos
   - Auditorías periódicas de salud del sistema
     - Parte de rutinas de monitoreo preventivo
   - Análisis post-incidente
     - Identificar qué servicios o proceso padre genera zombies
   - Infraestructura crítica
     - Servidores de aplicaciones, bases de datos, middleware y sistemas legacy.

   Los problemas que resuelve en el día a día:
   - Diagnóstivo rápido sin revisar procesos manualmente
   - Evidencia documentada mediante log
   - Soporte a decisiones operativas (reinicio de servidores, escalamiento)

   Ejemplo de Ejecución:

   ./detectar_procesos_zombie.sh /var/log/monitor 10

   Curiosidad Técnica:
   El script utiliza varias técnicas avanzadas de Bash que vale la pena destacar:
   - exec 3>>"$REPORTE": En lugar de usar >> en cada línea, abrimos un descriptor de archivo personalizado (el número 3). Esto centraliza la escritura 
   al log y hace el código más limpio.
   - mapfile -t ... < <(...): Combina un Process Substitution con mapfile para cargar la salida de ps directamente en un arreglo de Bash, evitando el uso de archivos temporales.
   - Lógica en gawk: Se utiliza un arreglo asociativo (arreglo[$2]++) dentro de gawk para agrupar y contar zombies por su PPID en una sola pasada, lo cual es extremadamente 
   eficiente en sistemas con miles de procesos.
   - ps -eo ... --no-headers: El uso de --no-headers es vital en scripts para evitar que el encabezado de las columnas (PID, PPID...) sea interpretado como un proceso real.
   - El uso de esta parte: gawk 'BEGIN{OFS="|"} $4~"^Z"{ $6=""; for(i=6; i<=NF; i++) $6 = $6 (i==6 ? "" : " ") $i; print $1, $2, $3, $4, $5, $6}' para controlar los cmds con espacios
   y si el ps no arroja nada.	 
   - Si se puede usar el redireccionamiento dentro del gawk
_______________________________________________________________________________________________________________________________________________________________________________

## **auditoria_procesos_largos.sh**
   Nivel Avanzado **Temas:** Gestión de Procesos, Aritmética de Bash, Expresiones Regulares, Redirección de Descriptores

   Descripción Técnica

   Este script es una herramienta de monitoreo de rendimiento y salud del sistema. Su función principal es inspeccionar la tabla de procesos en tiempo real para localizar aquellos 
   que han estado activos por un periodo superior al límite establecido por el administrador.
   El script realiza un filtrado inteligente descartando hilos del kernel (Kernel Threads), procesos detenidos o zombies, y se excluye a sí mismo de la lista. Calcula el impacto en el servidor y genera un reporte detallado que incluye métricas de consumo de CPU y memoria, asignando un nivel de severidad (OK, OBSERVACIÓN o ALERTA) basado en un umbral de 
   tolerancia.

   Uso Típico en las empresas:
 
   En un entorno corporativo, este script es vital para el equipo de Operaciones de TI y SysAdmins por las siguientes razones:
   - Detección de "Procesos Fugados" (Runaway Processes): Identifica aplicaciones que han entrado en un bucle infinito o que no han liberado recursos después de terminar su tarea.
   - Gestión de Sesiones Huérfanas: Localiza procesos de usuarios que se desconectaron del sistema pero dejaron aplicaciones corriendo innecesariamente, consumiendo RAM y CPU.
   - Control de Backups y ETLs: Permite saber si un proceso crítico de respaldo o carga de datos está tomando mucho más tiempo del habitual, lo cual podría indicar un cuello de 
   botella en el almacenamiento o la red.
   - Prevención de Degradación de Servicio: Ayuda a evitar que el servidor se vuelva lento por la acumulación de procesos antiguos que compiten por el planificador del sistema.

   Ejemplo de Ejecución:

   ./auditoria_procesos_largos.sh /var/log 120 10

   Curiosidad Técnica:
   El script utiliza una combinación de técnicas de Bash de alto rendimiento:
   - SCRIPT="$(basename "$0")": Para guardar el archivo del script
   - ps -eo ...,etimes: La columna etimes es fundamental; a diferencia de time, esta devuelve el tiempo transcurrido desde el inicio del proceso en segundos absolutos, lo que 
   permite hacer comparaciones matemáticas directas sin necesidad de parsear formatos complejos de horas y minutos.
   - Uso del if implícito de gawk: gawk -v t="$TIEMPO" -v script="$SCRIPT" 'BEGIN{OFS="|"} $8~/^(S|R|D)/ && $4>t && $9!~/^\[.*\]/ && $0!~script
   - $8 =~ /^(S|R|D)/: Se utiliza una expresión regular extendida para filtrar los estados de proceso. Esto permite evaluar múltiples condiciones en una sola línea de 
   código, haciendo el script más eficiente.
   - $4>t: Para que el etimes sea mayor al tiempo especificado
   - $9!~/^\[.*\]/: Para que el comando no sea un comando del sistema del kernel [...].
   - $0!~script: Para que la linea completa del proceso no contenga el nombre de nuestro script
   - exec 3>>"${REPORTE}": Se abre un descriptor de archivo personalizado (3) para la escritura del log. Esto es mucho más eficiente que usar >> en cada línea, ya que el archivo 
   permanece abierto durante la ejecución del script, reduciendo las operaciones de apertura/cierre de disco.

_____________________________________________________________________________

## **monitoreo_cpu_memoria.sh**
   Nivel "Avanzado" **Temas:** Aritmética de punto flotante(bc), Funciones con retorno de estado, gawk para agregacion de datos, Redireccion de descriptores.

   Descripción Técnica:
   Este script es un monitor de rendimiento de alta precisión. A diferencia de las herramientas estándar que redondean valores, este script utiliza la calculadora de precisión 
   arbitraria (bc) para evaluar el consumo de CPU y RAM con decimales.
   Implementa una función de evaluación que clasifica cada proceso en tres estados de severidad (OK, OBSERVACIÓN, CRÍTICO) basándose en un multiplicador dinámico (1.5x del umbral).
   Al finalizar, realiza un post-procesamiento de la data mediante gawk para entregar un resumen del consumo total de los recursos afectados.

   Uso Típico en las empresas:
   En entornos de producción, las empresas lo utilizan para:
   - Identificación de procesos "gastadores": Detectar aplicaciones que, sin estar fallando, consumen más recursos de los proyectados (fugas de memoria o picos de CPU).
   - Alertamiento preventivo: Correr el script mediante una tarea programada (cron) para generar logs históricos que permitan analizar la estabilidad del servidor durante horas pico.
   - Diagnóstico de aplicaciones: Verificar si una actualización de software ha incrementado el consumo de recursos base comparado con versiones anteriores.

   Ejemplo de ejecución:

   ./monitoreo_cpu_memoria.sh -d /var/log/metrics -m 25 -c 20

   Curiosidad Técnica:
   - El uso de bc para operar numeros decimales: local es_ok=$(echo "$consumo <= $umbral" | bc -l) y local es_obs=$(echo "$consumo <= ($umbral * 1.5)" | bc -l)
   - El uso de mapfile -t procesos < <(ps -eo pid,ppid,pcpu,pmem,etimes,cmd --no-headers: Uso de --no-headers, para que no imprima el encabezado.
   - Luego se hizo el uso de gawk con un if implicito que tenia esta forma: gawk -v script="$SCRIPT" 'BEGIN{OFS="|"} $0!~script{$6=""; for(i=6;i<=NF;++i) $6 = $6 (i==6 ? "" : " ") $i; print $1, $2, $3, $4, $5, $6}'
   - Luego para continuar con la tuberia se hizo un while para poner los estados
   - LC_ALL=C sort -t "|" -k 3,3nr -k 4,4nr: Como los porcentajes pueden ser decimales, se usa la variable LC_ALLC=C para que pueda ordenar numeros decimales.
________________________________________________________________________________________

## **mapeo_jerarquico.sh**
   Nivel Senior **Temas:** Recursividad, Arreglos asociativos (declare -A), Word Splitting controlado y Árboles de Procesos.

   Descripción Técnica:
   Este script realiza una reconstrucción lógica del árbol de procesos del sistema (Process Tree) partiendo desde la raíz del Kernel (PPID 0). A diferencia de comandos estándar 
   como pstree, este desarrollo implementa un motor de recursividad en Bash que audita la salud de cada rama.
   Su objetivo principal es identificar relaciones de herencia y detectar "fugas de hijos", una condición donde un proceso padre genera una cantidad desproporcionada de subprocesos,
   lo que puede indicar un error de programación (fork bomb accidental) o un servicio fuera de control.

   Uso típico en las empresas:
   En un entorno corporativo, un administrador de sistemas o ingeniero de SRE (Site Reliability Engineering) utilizaría este script para:
   - Diagnóstico de Servidores Web/App: Identificar si servicios como Apache, Nginx o trabajadores de PHP-FPM están creando demasiados hilos que saturan la tabla de procesos.
   - Limpieza de Procesos Huérfanos: Localizar ramas de procesos que han perdido a su padre original y han sido adoptados por systemd (PID 1), permitiendo rastrear su origen antes 
   de terminarlos.
   - Troubleshooting de Aplicaciones Legacy: Entender cómo una aplicación antigua despliega sus procesos internos para optimizar la asignación de recursos en contenedores o máquinas
   virtuales.

   Ejemplo de ejecución:

   ./mapeo_jerarquico.sh 10

   Curiosidad Técnica:
   - Recursividad con ident_hijo: El script utiliza una variable de nivel que se incrementa en cada llamada recursiva. Esto permite calcular dinámicamente el prefijo de espacios,
   creando una jerarquía visual perfecta sin usar herramientas externas de formato.
   - Arreglos Asociativos para Relaciones: Se utiliza declare -A procesos_padre para mapear los PIDs. La "curiosidad" es que el valor guardado es un String de PIDs separados
   por espacios; al usar for hijo in ${procesos_padre[$padre]} (sin comillas), se aprovecha el Word Splitting intencional de Bash para iterar sobre una lista dinámica de longitud
   variable.
   - El proceso Raíz (0): El script inicia la recursión en el PID 0. En linux, el PID 0 es el Swapper o Idle Process. Capturar esta raíz permite mapear absolutamente todo el bosque
   de procesos del sistema.

_________________________________________________________________________________________________________________________________________________

## **anti_mutation_watchdog.sh**
   Nivel "Avanzado / Forense" **Temas:** Análisis Dinámico de `/proc`, Monitoreo Asíncrono de Filesystem, Contención Activa (`SIGSTOP`), Manejo de Señales Posix (`trap`), Estructuración de
   Logs JSON en Caliente.

   Descripción Técnica:
   Este script implementa un sistema activo de detección y contención temprana de anomalías (HIDS a nivel de procesos) diseñado para mitigar ráfagas de mutación en el sistema de archivos 
   (comportamiento típicamente asociado a variantes de *Ransomware*) y ejecuciones sospechosas. Su objetivo principal es cerrar la ventana de exposición mediante dos reglas de auditoría 
   concurrentes:
   1. **Auditoría Estática de `/proc` (Regla 1):** Escanea el estado de los descriptores ejecutables (`/proc/[PID]/exe`) en todo el sistema para identificar binarios que han sido eliminados 
   de disco inmediatamente después de entrar en ejecución (enmascaramiento forénfico) o que se ejecutan desde zonas volátiles no estándar como `/tmp` o `/dev/shm`.
   2. **Correlación de Descriptores de Archivos Dinámicos (Regla 2):** Monitorea de manera asíncrona una ruta crítica del sistema de archivos. Al detectar un volumen de modificaciones que 
   supera el umbral paramétrico en un intervalo de tiempo reducido, realiza un rastreo milimétrico sobre los descriptores numéricos de archivos abiertos en `/proc/[PID]/fd/` de cada proceso 
   activo. Una vez identificado el proceso agresor, le inyecta de forma inmediata una señal de suspensión física (`SIGSTOP`) al proceso hijo y a su árbol primario (`PPID`) para neutralizar 
   la amenaza en memoria RAM antes de que continúe alterando datos, exportando los hallazgos en un reporte forense JSON bien estructurado mediante la captura limpia de señales de 
   interrupción (`trap`).

   Uso Típico en las empresas:
   En entornos corporativos, este script se despliega como un agente ligero de endurecimiento (*hardening*) y respuesta ante incidentes en servidores de archivos críticos (como servidores 
   Samba, repositorios de almacenamiento NFS, carpetas de carga de aplicaciones web o bases de datos no productivas).
   * **Contexto específico:** Se utiliza principalmente en servidores Linux que carecen de agentes EDR comerciales pesados, actuando como una contramedida reactiva de bajo consumo de 
   recursos que complementa las políticas de respaldos.
   * **Problemas del día a día que resuelve:** * Previene la destrucción masiva de información corporativa provocada por un binario malicioso que logre evadir los filtros perimetrales 
   tradicionales.
   * Automatiza la primera línea de respuesta (aislamiento del proceso agresor), dándole tiempo valioso al equipo del SOC para analizar la memoria del proceso suspendido sin perder los 
   archivos ni apagar el servidor.
   * Detecta intrusiones donde el atacante intenta borrar sus propias herramientas de ejecución del disco (`(deleted)`) para ocultarse de los comandos tradicionales de auditoría como 
   `ps` o `top`.

   Ejemplo de Ejecución:

   sudo ./anti_mutation_watchdog.sh -d /shared/archivos_criticos -u 5 -f /etc/watchdog/lista_blanca.txt [-h]

   Curiosidad Técnica:
   El script destaca por el uso eficiente de estructuras nativas del sistema operativo Linux y optimizaciones lógicas avanzadas para evitar colisiones de tiempo (race conditions):
   1. trap cerrar_json_valido SIGINT SIGTERM: Implementa el control de señales POSIX a nivel del kernel. Cuando el administrador detiene el monitoreo mediante Ctrl+C (SIGINT), el script 
   no muere de golpe corrupting el archivo de auditoría; en su lugar, intercepta la señal, invoca un procesamiento por flujo de líneas con sed -i '$ s/,$//' para remover la última coma 
   huérfana de la estructura en caliente, concatena el corchete de cierre ] y sanitiza el archivo convirtiéndolo en un arreglo JSON sintácticamente válido para herramientas SIEM.
   2. for fd_path in /proc/$PID_CHECK/fd/[0-9]* : En lugar de invocar costosas tuberías externas (| grep) que generan subprocesos hijos ralentizando el bucle de contención en microsegundos 
   cruciales, el script realiza una expansión de comodines puramente numérica sobre la tabla de descriptores directamente en Bash. Combinado con el operador de coincidencia 
   nativo [[ "$FD_TARGET" == "$DIR_CRITICO"* ]], evalúa las rutas en memoria RAM a una velocidad crítica, permitiendo atrapar procesos veloces como un bucle persistente de dd o un 
   cifrador concurrente antes de que cierren sus manejadores de archivos.
   3. break 2: Uso estratégico de la ruptura multinivel de bucles. Al localizar el primer descriptor de archivo apuntando a la zona crítica, aborta instantáneamente tanto la revisión de 
   descriptores del proceso actual como la búsqueda global de procesos del sistema para proceder directamente al aislamiento con kill -STOP.

___________________________________________________________________________________________________________________________________________________________________________________________

## **process_resource_governor.sh**
   Nivel: "Avanzado" **Temas:** Control de procesos, Señales POSIX, Concurrencia, Descriptores de Archivos, Arreglos Asociativos, gawk y bc.

   Descripción Técnica:
   Este script actúa como un demonio (daemon) o servicio en tiempo real que patrulla de manera asíncrona los procesos del sistema operativo. Su objetivo principal es mitigar y 
   contener de forma automatizada los procesos abusivos que sufren bucles infinitos, colgaduras o fugas de recursos, evitando que saturen la CPU del servidor.
   1. **Monitoreo Asíncrono:** Cada 4 segundos, el guardián toma una captura de rendimiento cruzando el uso de CPU (`pcpu`) y el tiempo de ejecución persistente del proceso (`etimes`).
   2. **Mitigación Inicial (Advertencia):** Si un proceso supera los umbrales configurados por primera vez, el script reduce su prioridad al mínimo absoluto (`renice +19`), 
   permitiendo que el planificador del Kernel (*Scheduler*) balancee la carga hacia tareas prioritarias sin destruir el proceso legítimo.
   3. **Escalada de Fuerza (Aislamiento):** Si en el siguiente ciclo el proceso persiste evadiendo el control con prioridad mínima, el script determina que está colgado o es 
   malicioso, enviando una señal de terminación limpia (`SIGTERM`) para fulminarlo. Mantiene un contador interno global indexado en un arreglo asociativo para asegurar que la 
   historia forense de cada PID no se pierda entre subshells.

   Uso Típico en las empresas:
   En entornos corporativos y servidores de producción (Web, Base de Datos, Cloud), las empresas se enfrentan diariamente a alertas de monitorización por saturación de hardware. 
   Este script resolvería problemas críticos del día a día como:
   * **Bugs de Aplicación en Producción:** Hilos de ejecución mal programados (por ejemplo, consultas SQL mal optimizadas, scripts de backend en Python o Node.js con bucles `while` 
   infinitos) que bloquean los núcleos del procesador.
   * **Garantía de Alta Disponibilidad (SLA):** Evita que un solo usuario o proceso secundario (como una tarea cron de respaldos/backups pesada a mitad del día) sature el servidor e 
   interfiera con las peticiones de los clientes legítimos, manteniendo el sistema usable.
   * **Mitigación ante Denegaciones de Servicio Internas:** Actúa como una capa automatizada de primera respuesta ante procesos desbocados, dándole tiempo al Administrador de 
   Sistemas (SysAdmin) de reaccionar sin necesidad de apagar o reiniciar el servidor completo de emergencia.

   Ejemplo de Ejecución:
   Para iniciar el demonio en modo guardián, se le deben pasar estrictamente 3 argumentos: el umbral de CPU (en porcentaje), el tiempo máximo de gracia (en segundos) y la ruta del 
   directorio donde escribirá su bitácora forense de auditoría.
   sudo ./process_resource_governor.sh 40 5 /tmp

   Curiosidad Técnica:
   El script destaca por emplear comandos complejos combinados con buenas prácticas de rendimiento explicadas en la literatura de administración avanzada de Linux:
   1. exec 3>>"$REPORTE" y >&3: En lugar de abrir y cerrar el archivo de log con >> en cada línea del bucle (lo cual causa un abuso de operaciones de Entrada/Salida en disco), este 
   comando abre un Descriptor de Archivo Personalizado (File Descriptor 3) persistente en la memoria del Kernel. Toda la salida redirigida a >&3 se escribe de manera ultra óptima.
   2. Reconstrucción Dinámica de Comandos con gawk:
   	gawk '{cmd_full=""; for (i=6; i<=NF; ++i) cmd_full=(cmd_full ? cmd_full" " : "")$i; print $1"|"$2"|"$3"|"$4"|"$5"|"cmd_full}'
  	El comando ps entrega los argumentos del proceso al final. Si un comando contiene espacios en blanco (ej. python3 exploit.py --run), un extractor simple rompería las variables. 
   	Este bucle iterativo de gawk une dinámicamente desde el sexto campo hasta el final de la línea (NF), encapsulando el comando entero antes de enviarlo por la tubería.
   3. Sustitución de Procesos No Bloqueante (done < <()): Al alimentar el ciclo while final mediante < <(...) en lugar de una tubería tradicional (ps | while), se evita la 
   creación de un subshell independiente. Esto asegura que el mapa de memoria del arreglo asociativo (declare -A estados_procesos) guarde los estados globalmente y no se destruya 
   al terminar la lectura.
   4. trap cerramos_el_reporte SIGINT: Intercepta la señal de terminación de teclado (Ctrl + C) para ejecutar una función destructora que vuelca estadísticas finales (conteo real de 
   penalizaciones con la variable $VARIACIONES), limpia el descriptor de archivo (exec 3>&-) y cierra el programa de manera íntegra y elegante.
   5. El uso de kill -0 "$p" para reiniciar si el proceso finalizo antes de los 4 segundos.
   6. Uso de bc -l para operar numeros decimales

_____________________________________________________________________________________________________________________________________________________________________________________
