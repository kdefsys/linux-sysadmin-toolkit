# linux-sysadmin-toolkit

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

- [daily-tools](#daily-tools)
- [shell-core-concepts](#shell-core-concepts)
- [symlinks-tool](#symlinks-tools)
- [acces-control](#access-control)
- [process-management](#process-management)
- [storage-filesystems](#storage-filesystems)
- [kernel-hardware-modules](#kernel-hardware-modules)

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

## **storage-filesystems**
   - Contiene scripts de dispositivos de bloque, particiones, montaje, etc.
   - Esta orientado al gestión de almacenamiento en sistemas Linux
   - Su objetivo es documentar y automatizar tareas críticas del alamacenamiento
   - Permite recuperación de fallos, migraciones de discos y muchas cosas más.
_____________________________________________________________________________

## **kernel-hardware-modules**
   Este directorio esta dedicado al desarrollo de scripts de auditoria de automatización, auditoría y control de bajo nivel para la gestión de módulos del kernel (`sys_modules`) 
   y la interacción del sistema operativo con el hardware en entornos Linux.
   El objetivo de las herramientas contenidas aquí es proporcionar un control granular sobre el comportamiento del núcleo de forma dinámica, permitiendo la inspección técnica, 
   optimización de recursos en memoria RAM y el endurecimiento (*hardening*) de la seguridad del sistema mediante la gestión de controladores.

   ENFOQUE:
   Los scripts de este módulo se centran en interactuar con las abstracciones del kernel a través de las siguientes áreas clave:
   * **Inspección en Tiempo Real:** Análisis del estado actual de la memoria RAM respecto a los controladores activos empleando interfaces de bajo nivel y `/proc/modules`.
   * **Gestión Dinámica de Módulos:** Automatización para la inserción, remoción y resolución de dependencias de controladores en caliente sin necesidad de reiniciar el sistema.
   * **Auditoría y Fichas Técnicas:** Extracción de metadatos de archivos de objetos del kernel (`.ko`) para evaluar autores, licencias, firmas de seguridad y parámetros aceptados.
   * **Hardening & Seguridad (Blacklisting):** Creación de políticas para mitigar vectores de ataque mediante la desactivación automatizada de módulos heredados, puertos vulnerables o 
   protocolos no utilizados (FireWire, USB específicos, etc.).
   * **Detección y Auditoría de Hardware:** Aquí entran scripts que interrogan al hardware para saber que hay conectado físicamente a la placa madre, veremos algunas herramientas como
   (lspci, lsusb, lshw, dmidecode, lscpu, etc)
   * **Interfaces del kernel con el hardware: ** Linux expone el hardware y los módulos como si fueran archivos de texto. Los scripts de esta seccion pueden automatizar la lectura y
   modificacion de:
	- /proc: Para ver los estados del hardware y del entorno del kernel en tiempo real. (ej. /proc/cpuinfo, /proc/meminfo, /proc/modules)
	- /sys: Para modificar el comportamiento del hardware al vuelo (por ejemplo, scripts para cambiar el perfil de energia de la CPU, controlar el brillo de la pantalla, o apagar
 	un puerto USB por completo desde la terminal).
	- /dev: Gestión de archivos de dispositivos de caracteres y bloques.

____________________________________________________________________________________________________________________________________________________________________________________

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

