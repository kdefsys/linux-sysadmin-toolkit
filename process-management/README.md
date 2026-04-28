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
   Nivel "Avanzado" **Temas:** Procesos, CPU, Memoria, Auditoría, Bash avanzado,
   bc, filtros de texto

   Descripción Técnica:

   Este script permite auditar el consumo de CPU y memoria de los procesos en un
   sistema Linux, detectando aquellos que superen los umbrales definidos por el
   usuario.
   Genera un reporte detallado en un archivo log que incluy: PID, UID, porcentaje
   de CPU, porcentaje de memoria, tiempo de ejecución y comando. Además, indica
   un nivel de severidad para cada proceso (OK, Observación, Crítico) basado en
   el consumo relativo a los umbrales.

   Uso Típico en las empresas:

   Se puede utilizar en servidores de producción para:
   - Detectar procesos qye consumen excesivamente CPU o memoria.
   - Prevenir degradación del rendimiento de servicios críticos.
   - Proporcionar informes periódicos para el equipo de sistemas.
   - Monitoreo de servidores multiusuario donde varios procesos compiten por
   recursos.

   Ejemplo de ejecución
 
   ./monitoreo_cpu_memoria.sh /var/log 0.1 4

   Curiosidad Técnica:

   - El script utiliza bc -l para operaciones con decimales y comparaciones de
   consumo, ya que bash no soporta números decimales en (( )).
   - Filtra procesos ignorando procesos del mismo script.
   - gawl se usa para acumular totales de CPU y memoria, permitiendo un resumen
   rápido en el log.
   - Redirecciones y tee aseguran que la salida se almacene y se muestre en pantalla
   simultáneamente

   Ejemplo de salida:

   ========LISTADO DE PROCESOS QUE SUPERAN LOS UMBRALES========

   Fecha: 20260130-2105
   Host: servidor01
   Parámetros de entrada: /var/log 0.1 4
   -------------------------------------
   1234  1001 0.03 25.0 3600 /usr/bin/pythin3 Observacion OK
   2345  1002 0.4 12.0 7200 /usr/bin/java Critico Critico

   El total de consumo de CPU y de MEM respectivamente fue: 0.43 37.0

_____________________________________________________________________________
