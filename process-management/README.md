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
   - Lógica en gawk: Se utiliza un arreglo asociativo (arreglo[$2]+=1) dentro de gawk para agrupar y contar zombies por su PPID en una sola pasada, lo cual es extremadamente 
   eficiente en sistemas con miles de procesos.
   - ps -eo ... --no-headers: El uso de --no-headers es vital en scripts para evitar que el encabezado de las columnas (PID, PPID...) sea interpretado como un proceso real.

_____________________________________________________________________________

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
   - ps -eo ...,etimes: La columna etimes es fundamental; a diferencia de time, esta devuelve el tiempo transcurrido desde el inicio del proceso en segundos absolutos, lo que 
   permite hacer comparaciones matemáticas directas sin necesidad de parsear formatos complejos de horas y minutos.
   - while read -r pid ... comando: Al final de la lista de variables, la variable comando actúa como un "sumidero", capturando todo el texto restante de la línea. Esto garantiza 
   que la ruta completa y los argumentos del comando original se mantengan íntegros, incluso si contienen espacios.
   - [[ "$estado" =~ ^(S|R|D) ]]: Se utiliza una expresión regular extendida para filtrar los estados de proceso. Esto permite evaluar múltiples condiciones en una sola línea de 
   código, haciendo el script más eficiente.
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

   ./monitoreo_cpu_memoria.sh /var/log/metrics 25 20

   Curiosidad Técnica:
   - read SUMA_CPU SUMA_MEM <<< "$TOTALES": El uso de este Here String evita la creación de un subshell (lo que ocurriría con un pipe |), permitiendo que los valores calculados 
   por gawk persistan en el hilo principal del script.
   - split($3, cpu, " ") en gawk: Esta técnica de manipulación de cadenas permite limpiar las etiquetas del reporte (como "CPU:" o "%") para realizar operaciones matemáticas 
   puras sobre los valores decimales, demostrando un manejo avanzado de procesamiento de texto.

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
