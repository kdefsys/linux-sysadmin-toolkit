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
   Nivel Avanzado 
   
   Descripcion:

   En sistemas Linux en producción, los procesos zombis indican problemas en la
   gestión del ciclo de vida de procesos padre-hijo
   Aunque no consumen CPU ni memoria, si ocupan entradas en la tabla de procesos,
   lo que en casos extremos puede impedir la creación de nuevos procesos.

   El script permite detectar, auditar y reportar procesos zombis de forma
   segura y profesional.
   El script identifica procesos en estado Z (zombie), recopilar información
   relevante y generar un reporte claro y accionable para el sysadmin
   El script no debe matar procesos directamente (un zombie no puede ser eliminado
   con kill), sino ayudar al diagnóstico.

   Entradas:
   1. Un directorio de salida para logs
   2. Un umbral mínimo de zombis (numero entero)

   Ejemplo de ejecución:
   ./detectar_procesos_zombie.sh /var/log/auditorias 3

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

   Curiosidad Técnica:
   - ps -eo pid,ppid,uid,cmd,start,stat
   - stat == "Z"
   - Agrupación por PPID
   awk '{print $2}' | sort -n | uniq -c

   - Uso de Sustitución de procesos: done < <(echo "$PADRES")

   Salida de Ejemplo:

   ========Procesos Zombies========
   Fecha y hora de publicación: 20260130_2145
   Total de zombis detectados: 7
   Agrupación por procesos padre
   PPID: 1023 | Cantidad de hijos zombie: 2 (OBSERVACIÓN)
   PPID: 2045 | Cantidad de hijos zombie: 5 (ADVERTENCIA)

   Lista complea de procesos zombis con sus datos:

   3456 1023 1001 /usr/bin/app-worker 10:22
   3467 1023 1001 /usr/bin/app-worker 10:22
   5678 2045 1002 /usr/bin/legacy_service 09:10

   Se superó el umbral de 5: riesgo operativo

_____________________________________________________________________________

## **auditoria_procesos_largos.sh**
   Nivel Avanzado **Temas:** Procesos Linux, Auditoría, Filtrado, Bash Scripting
   y ps/awk/gawk

   Descripción Técnica

   Este script audita procesos de larga ejecución en sistemas linux y genera un
   reporte detallado en formato legible.
   Su objetivo es permitir a un sysadmin identificar procesos que se están ejecutando
   por más tiempo del esperado, clasificarlos según nivel de severidad y preparar
   información para decisiones posteriores, sin necesidad de matar los procesos
   El script filtra procesos en estado activo ('R'), durmiendo ('S') o en espera
   de I/O ('D'), excluye procesos internos ('[cmd]') y el mismo script, y calcula
   el tiempo de ejecución en segundos para compararlo con un umbral definido por
   el usuario.

   Uso Típico en las empresas:
 
   Se utiliza en servidores de producción o entornos críticos donde procesos largos
   pueden:
   - Indicar cuellos de botella en servicios
   - Saturar recursos como CPU, memoria o I/O
   - Prevenir riesgos operativos antes de que afecten usuarios finales.

   Ejemplo de Ejecución:

   'bash'
   ./auditoria_procesos_largos.sh /var/log 120 10

   Curiosidad Técnica

   - ps -eo pid,ppid,uid,etimes,start,pcpu,pmem,stat,cmd --no-headers permite
   extraer columnas exactas de los procesos y evita la cabecera, facilitando su
   procesamiento con while read
   - La condición [[ ! "$Cmd" =~ ^\[.*\]$ && "$Cmd" != "$0"] evita contar procesos
   internos del kernel y el mismo script, eliminando falsos positivos
   - La variable Etimes extraída por ps se compara con el parámetro TIME convertido
   a segundos, usando (( )) para operaciones aritméticas en Bash

   Salida de ejemplo:

   ========PROCESOS CON EXCESO DE TIEMPO EJECUTÁNDOSE========
   Fecha: 2026-01-30_21:45
   Host: servidor_principal
   Parámetros usados: /var/log 120 10

   Procesos Detectados:
   1234 1 10000 7380 09:10 0.0 0.1 apache2
   5678 1 1000  8450 08:50 0.1 0.2 mysqld

   Cantidad de procesos totales: 2
   Nivel de severidad: OBSERVACIÓN

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
