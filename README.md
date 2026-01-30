# Sysadmin Projects

Repositorio técnico orientado a administración de sistemas Linux, enfocado en
automatización operativa, auditoría, mantenimiento preventivo, seguridad y 
análisis de infraestructura a nivel de sistema.

Este proyecto no se limita a scripting: representa tareas reales que un Sysadmin
enfrenta en entornos productivos, donde la prioridad es la estabilidad, 
trazabilidad, uso eficiente de recursos y respuesta ante incidentes.

## Objetivo del repositorio

Centralizar herramientas prácticas que permitan:

- Automatizar tareas repetitivas del sistema
- Auditar uso de disco, permisos, logs y archivos críticos
- Analizar comportamientos anómalos en servidores
- Prevenir fallos por saturación de recursos
- Mantener orden, trazabilidad y control operativo
- Mantener un sistema seguro en cuanto a permisos y privilegios de usuarios.

El repositorio simula un toolkit interno de Sysadmin junior-intermedio, similar
a lo que se encuentra en equipos de infraestructura reales.

## Estructura del Repositorio

[daily-tools](#daily-tools)
[shell-core-concepts](#shell-core-concepts)
[symlinks-tool](#symlinks-tools)
[acces-control](#access-control)
[process-management](#process-management)

## **daily-tools**
   Herramientas de uso cotidiano para la administración del sistema:
   - Gestión de usuarios y permisos
   - Limpieza y rotación de logs
   - Monitoreo básico de procesos
   - Automatización de tareas administrativas recurrentes

   Pensado para scripts que podrían ejecutarse manualmente o programarse con
   cron 

_____________________________________________________________________________

## **shell-core-concepts**
   Scripts que aplican conceptos fundamentales allow de scripting en Bash:
   - Procesamiento avanzado de logs
   - Auditorías del sistema de archivos
   - Uso de redirecciones, pipes, expresiones regulares y control de flujo
   - Automatización orientada a análisis y diagnósticos

   Esta sección prioriza la lógica, robustez y buenas prácticas de scripting

_____________________________________________________________________________

## **symlinks-tools**
   Herramientas especializadas para la gestión de enlaces simbólicos:
   - Detección de symlinks rotos
   - Limpieza de enlaces huerfános
   - Verificación y reconstrucción de enlaces críticos

   Útil en sistemas con despliegues complejos o estructuras de directorios
   extensas.

_____________________________________________________________________________

## **access-control**
   Scripts enfocados en seguridad y control de acceso:
   - Auditoría de permisos peligrosos
   - Detección de configuraciones inseguras
   - Revisión de usuarios con privilegios elevados

   Orientados a tareas de hardening y revisión post-incidente

_____________________________________________________________________________

## **process-management**
   - Contiene scripts avanzados orientados a la gestión y auditoría de procesos
   en sistemas Linux.
   - Están diseñados para monitorear, auditar y analizar el comportamiento de
   procesos en tiempo de ejecución, identificar problemas de performance,
   problemas de tiempo excesivos y de detectar procesos zombies.
   - SU objetivo es proveer herramientas prácticas que permitan a un sysadmin 
   tomar decisiones informadas sobre la administración de recursos del sistema,
   optimización de procesos y mitigación de riesgos operativos, sin afectar la
   continuidad de los servicios
_____________________________________________________________________________

## **Consideraciones**
   - Varios scripts requieren privilegios elevados ('root' o 'sudo')
   - Se recomienda revisar cada script antes de ejecutarlo en entornos
   productivos
   - Diseñado para sistemas GNU/Linux


## **Objetivo del Repositorio**
   Este repositorio forma parte de un portafolio técnico personal y busca
   demostrar:
   - Conocimiento práctico de Linux
   - Capacidad de automatización con Bash
   - Enfoque en seguridad y mantenimiento
   - Organización y documentación profesional
