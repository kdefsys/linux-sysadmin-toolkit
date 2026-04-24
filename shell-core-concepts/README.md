# shell-core-concepts 

En esta sección se encuentran los scripts que contienen temas fundamentales
en el manejo de bash.
Su objetivo es hacer ver que se posee un amplio conociemiento de comandos del
shell bash, de la línea de comandos y de scripting.

# Contenido

- [auditar_archivos_criticos.sh](#auditar_archivos_criticossh)
- [analizar_logs_servicios.sh](#analizar_logs_serviciossh)
- [limpieza_selectiva_archivos.sh](#limpieza_selectiva_archivossh)
- [auditoria_avanzada.sh](#auditoria_avanzadash)
- [log_rote.sh](#log_rotesh)
_____________________________________________________________________________

## **auditar_archivos_criticos.sh**
   Nivel Avanzado **Temas:** find, pipelines, stat,
   gawk, timestamps, exclusión de rutas, auditoría de archivos

   Descripción Técnica:
   Este script realiza una auditoria de archivos criticos dentro de un directorio dado
   Busca archivos de configuración y logs ('*.conf', '*.cnf', '*.log'), excluyendo rutas
   temporales ('*/tmp/*') y filtra aquellos que han sido modificados en las ultimas 24 
   horas.
   Para cada archivo detectado, el script obtiene información detallada como:
   - Ruta completa del archivo
   - Tamaño lógico del archivo
   - Fecha y hora exacta de la última modificación
   Toda la información relevante se guarda en un archivo de log con nombre dinamico, 
   permitiendo mantener un historial de auditorías por fecha.
   El procesamiento se realiza mediante tuberias, sin modificar ni eliminar archivos del
   sistema, lo que lo hace seguro para entornos productivos.

   Uso Típico en las Empresas:
   - Auditorías de seguridad en servidores Linux.
   - Detección de cambios no autorizados en archivos de configuración
   - Monitoreo de modificaciones fuera de horario laboral
   - Análisis forense básico ante incidentes
   - Servidores compartidos o legacy sin monitoreo centralizado

   Es especialmente útil en equipos de sysadmin, soporte N2/N3 y seguridad como paso
   previo a investigaciones más profundas o como tarea programada (cron) 

   Curiosidad Técnica:
   - 'stat -c '%n|%s|%y|%Y' para obtener múltiples atributos del archivo en una sola
   llamada
   - 'date +%s' para trabajar con timestamps Unix
   - 'gawk' para comprimir los atributos con un OFS adecuado

   Ejemplo de Ejecución:
   ./auditar_archivos_criticos.sh directorio

_____________________________________________________________________________

## **analizar_logs_servicios.sh**
   Nivel Avanzado **Temas:** find, grep, tuberias,
   filtrado de logs, patrones de búsqueda, ordenamiento

   Descripción Técnica:
   Este script realiza un análisis automatizado de logs de servicios dentro de un
   directorio específico.
   Busca archivos de log activos ('*.log', '*.log.*'), excluyendo archivos comprimidos
   ('*.gz'), y analiza cada uno en busca de un patron definido por el usuario.
   Para cada archivo encontrado, el script cuenta de forma insensible a mayusculas la cantidad
   de ocurrencias del patrón, y luego ordena los resultados por cantidad de coincidencias
   de forma descendente, permitiendo identificar rápidamente los servicios o logs más
   problemáticos.
   Los resultados se almacenan en un archivo de salida cuyo nombre incluye el hostname
   del servidor y la fecha, facilitando auditorías y trazabilidad en entornos con
   múltiples máquinas.

   Uso Típico en las empresas:
   - Diagnóstico rápido de fallos en servicios productivos
   - Análisis inicial ante incidentes de seguridad
   - Detección de errores recurrentes en logs
   - Soporte N2/N3 en servidores Linux
   - Entornos sin sistemas centralizados de logging (ELK,Graylog,etc).

   Es común ejecutarlo manualmente durante indicentes o integrarlo en rutinas automatizadas
   para priorizar qué servicios requieren atención inmediada

   Curiosidad Técnica:
   Un punto interesante del script es el uso de 'grep -Hic' que permite:
   - Procesar múltiples archivos de forma eficiente
   - Contar ocurrencias por archivo en una sola pasada
   - Evitar abrir logs manualmente uno por uno
   - La opcion -H, nos ayuda a que incluso si el find solo encuentra un archivo,
   la salida mantenga el formato archivo:conteo, lo cual evita que el sort se
   rompa.

   Además, el uso de 'sort -k 2nr' ordena los resultados basándose únicamente en el
   número de coincidencias, lo que convierte una gran cantidad de logs crudos en un
   reporte claro y accionable en segundos.

_____________________________________________________________________________

## **limpieza_selectiva_archivos.sh**
   Nivel Avanzado **Temas:** find, du, tuberias,
   mantenimiento de disco, validaciones, logs dinámicos, interacción con el usuario

   Descripcion Tecnica
   Este script realiza una limpiesza selectiva y controlada de archivos antiguos dentro
   de un directorio especificado.
   Esta diseñado para identificar archivos que suelen acumularse en servidores de 
   aplicaciones, como backups, dumps y archivos temporales, y que pueden provocar
   saturacion de disco si no se gestionan correctamente.
   El script filtra archivos que:
    - Coinciden con patrones comunes de respaldo y temporales
    - Tienen más de *N* dias de antiguedad
    - Ocupan más de 1 MB de espacio en disco.

   Antes de eliminar cualquier archivo, el script genera un resumen previo que incluye
   la cantidad de archivos candidatos y el espacio total ocupado, calculado mediante 'du'
   y procesamiento por tuberia.
   Toda la operación queda registrada en un log con nombre dinamico, permitiendo
   trazabilidad y auditoría posterior.

   Uso Típico en las empresas:
   - Prevención de discos llenos en servidores de aplicaciones
   - Mantenimiento programado en servidores legacy
   - Limpieza manual controlada en entornos productivos
   - Soporte N2/N3 durante incidentes de espacio
   - Preparación de servidores antes de backups o migraciones

   Es especialmente útil en empresas donde:
   - Las aplicaciones generan archivos temporales sin políticas automáticas de limpieza
   - No existe monitoreo proactivo de uso de disco
   - Los equipos de infraestructura deben actuar rápidamente sin borrar archivos por 
   error

   Curiosidad Técnica:
   Un punto interesante del script es el uso de 'du -hcb' junto con 'xargs', que permite
   calcular el espacio real total ocupado por multiples archivos de forma eficiente
   Además, el flujo basado en tuberias evita almacenar grandes volúmenes de datos en
   memoria y refleja una mentalidad de procesamiento por streams, muy comun en scripts
   profesionales de administracion de sistemas.
   El uso de confirmacion interactiva antes de la eliminacion es una practica habitual en
   entornos productivos para evitar pérdidas accidentales de datos.

_____________________________________________________________________________

## **auditoria_avanzada.sh**
   Nivel Avanzado **Temas:** find, stat, du, xarfs, sort,
   gawk, auditoría de disco, análisis de archivos, scripting bash

   Descripción Técnica:
   Este script realiza una auditoría avanzada del uso de disco en servidores Linux
   Recibe 3 parámetros: un directrio base, un tamaño mínimo en MB y un numero de dias de
   antiguedad
   El script identifica archivos que superan cierto tamaño y que han sido modificados
   recientemente, obteniendo informacion detallada como: Ruta del archivo, tamaño real
   en bytes, tamaño de bloque, Fecha de última modificación y UID del propietario
   Luego ordena los resultados por tamaño, calcula el espacio total ocupado,
   identifica el archivo más grande y genera un reporte detallado en un archivo log.

   Uso Típico en empresas:
   Es utilizado por sysadmins y equipos de infraestructura para detectar archivos
   problemáticos que crecen silenciosamente en servidores productivos.
   - Servidores de aplicaciones donde los logs o dumps crecen sin rotación.
   - Servidores de bases de datos donde archivos temporales no se limpian.
   - Máquinas virtuales cercanas a quedarse sin espacio en disco.
   - Auditorías preventivas antes de incidentes de 'disco lleno'.
   Permite tomar decisiones rápidas como:
   - Qué archivos eliminar
   - Qué usuarios están generando más consumo
   - Qué servicios están causando el crecimiento

_____________________________________________________________________________

## **log_rote.sh**
   Nivel Intermedio-Avanzado **Temas:** mapfile, file Descriptors, Globbing, Compresion (gzip)
   y Gestión de Rutas Dinámicas

   Descripción Técnica:
   Este script es una utilidad de administración de sistemas diseñada para la rotación automatizada 
   de archivos de registro. Su objetivo principal es evitar la saturación de los sistemas de archivos 
   mediante la identificación de logs antiguos (basándose en su fecha de última modificación), su 
   compresión individual para reducir el espacio en disco y su posterior organización en directorios 
   de histórico fechados. El script implementa un sistema de auditoría mediante un descriptor de archivo 
   independiente para registrar cada acción realizada.

   Uso Típico en empresas:
   En entornos de producción, las aplicaciones (como servidores Apache, Nginx o microservicios en Java/Python) 
   generan gigabytes de registros de acceso (access.log) y errores (error.log) diariamente. Sin un sistema de rotación:

   - Saturación de Disco: Un solo archivo de log podría llenar el almacenamiento provocando la caída
   de los servicios
   - Degradación de Performance: Abrir o buscar dentro de archivos de texto de varios gigabytes es
   ineficiente para el sistema operativo.

   Problemas que resuelve:
   - Automatiza la limpieza sin intervención manual del SysAdmin
   - Mantiene la trazabilidad de los logs viejos comprimiéndolos, permitiendo consultarlos en el futuro si hay
   auditorías legales o técnicas.
   - Separa los registros críticos de la consola mediante un flujo de log propio (rotacion_ejecucion.log)

   Ejemplo de ejecución:

   chmod u+x log_rote.sh

   ./log_rote.sh /var/log/myapp 7

   Curiosidad Técnica:
   - exec 3>>"$REPORTE": Abre el descriptor de archivo 3 apuntando al log. Esto permite usar >&3 en cualquier
   parte del código para escribir en el log sin tener que abrir y cerrar el archivo constantemente o usar >>
   - mapfile -t archivos_logs < <(find ...): Es la forma más eficiente de capturar la salida de un comando en un arreglo. 
   Evita problemas con nombres de archivos que contienen espacios y es mucho más rápido que leer línea por línea en un 
   bucle while.
   - xargs -0 gzip: Se utiliza printf "%s\0" combinado con xargs -0 para procesar archivos de forma segura. El carácter 
   nulo \0 garantiza que el script no falle incluso si los archivos tienen caracteres especiales o espacios en sus rutas.
   - Gestión de Bloques (The Space Paradox): Es importante notar que en archivos muy pequeños (pocos KB), el tamaño reportado 
   por du puede parecer mayor tras la rotación. Esto se debe al overhear del sistema de archivos: cada nuevo archivo comprimido 
   y el directorio de destino ocupan al menos un bloque de disco (usualmente 4KB), independientemente del peso real de los datos.

__________________________________________________________________________________________________________________________________
