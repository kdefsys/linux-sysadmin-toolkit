# 🛠️ linux-sysadmin-toolkit

Framework técnico y suite de herramientas en Bash destinado a la administración avanzada de sistemas Linux, automatización operativa de infraestructura, auditoría forense, mantenimiento preventivo y hardening a nivel de sistema.

---

## 📌 Sobre el Proyecto

Este repositorio **trasciende el scripting convencional**: representa la consolidación de soluciones automatizadas para mitigar vectores de falla y optimizar entornos de producción reales. La arquitectura de este toolkit prioriza métricas críticas de la ingeniería de sistemas: **estabilidad del kernel, trazabilidad de eventos, predictibilidad ante incidentes y optimización en el consumo de recursos**.

Diseñado bajo la filosofía de herramientas internas de nivel corporativo, este portafolio implementa abstracciones eficientes y seguras para el diagnóstico e intervención de sistemas operativos GNU/Linux.

### 🎯 Objetivos de la Suite
* 🚀 **Orquestación y Automatización:** Minimizar la intervención manual en flujos operativos recurrentes del sistema de archivos y del entorno de ejecución.
* 🔍 **Auditoría Exhaustiva:** Proveer telemetría precisa sobre el consumo de almacenamiento, permisos anómalos, rotación defensiva de logs y estructuras críticas del sistema.
* 📊 **Análisis Analítico de Procesos:** Monitorear el comportamiento del planificador y los hilos en tiempo de ejecución para mitigar degradaciones de performance.
* 🛡️ **Hardening & Seguridad:** Fortalecer el sistema mediante políticas estrictas de privilegios, control de acceso y restricción modular en el espacio del kernel.

---

## 📂 Estructura del Repositorio

El toolkit está modularizado por capas operativas para aislar las responsabilidades del sistema y garantizar un despliegue mantenible:

| Módulo | Enfoque Operativo | Descripción Técnica |
| :--- | :--- | :--- |
| `📂 daily-tools` | Mantenimiento Preventivo | Automatización de tareas de rutina, gestión programada de usuarios e instrumentación de políticas de purga y rotación de logs. |
| `📂 shell-core-concepts` | Abstracción Avanzada | Scripts estructurados bajo estándares POSIX/Bash robustos, utilizando pipelines optimizados y procesamiento avanzado de flujos de datos. |
| `📂 symlinks-tool` | Integridad de Filesystems | Diagnóstico, trazabilidad y resolución automática de referencias rotas o huérfanas en despliegues con topologías de directorios complejas. |
| `📂 access-control` | Hardening de Seguridad | Auditoría defensiva para detectar configuraciones inseguras, bits SUID/SGID expuestos y desvíos del principio de menor privilegio. |
| `📂 process-management` | Gestión del Runtime | Monitoreo analítico de estados de procesos, identificación de cuellos de botella y recolección de procesos huérfanos/zombies en caliente. |
| `📂 storage-filesystems` | Subsistema de I/O | Automatización de tareas de bajo nivel asociadas a dispositivos de bloque, layouts de particiones, montajes deterministas y migración de datos. |
| `📂 kernel-hardware-modules` | Kernel Internals | Interacción directa con el espacio del núcleo y abstracciones de hardware a través de pseudo-sistemas de archivos dinámicos. |

---

## 💻 Detalles Técnicos por Módulo

### ⚙️ daily-tools
Automatización orientada a la estabilidad de la infraestructura base:
* Aprovisionamiento y auditoría de cuentas de usuarios del sistema (`/etc/passwd`, `/etc/shadow`).
* Implementación de políticas de retención y truncado de logs para prevenir la saturación de inodos.
* Automatización no interactiva acoplable a daemons de planificación como `cron` o `systemd timers`.

### 🧠 shell-core-concepts
Desarrollo de scripts de alta eficiencia aplicando patrones de diseño en Bash:
* Parsing avanzado de bitácoras del sistema mediante expresiones regulares optimizadas y flujos no bloqueantes.
* Gestión rigurosa de descriptores de archivos, redirecciones complejas (`stderr`, `stdout`) y manejo de señales (*traps*).
* Arquitectura de código limpia: control de flujo defensivo, tipado implícito estricto (`local`, `readonly`) y modularización de funciones.

### 🔗 symlinks-tool
Validación y consistencia del mapa de enlaces del sistema de archivos:
* Algoritmos de búsqueda recursiva eficientes para aislar enlaces simbólicos rotos (*dangling symlinks*).
* Herramientas de remoción segura de punteros huérfanos sin afectar la estructura jerárquica subyacente.
* Mecanismos de auditoría preventiva en entornos de despliegue continuo (*CI/CD*) que dependen fuertemente de enlaces virtuales.

### 🛡️ access-control
Mitigación de riesgos y análisis post-incidente (*Incident Response*):
* Escaneo automatizado del sistema de archivos en busca de binarios con elevación de privilegios no autorizada.
* Evaluación de máscaras de creación de archivos (`umask`) y permisos laxos en archivos críticos de configuración.
* Generación de reportes de cumplimiento (*compliance*) basados en estándares de endurecimiento de sistemas informáticos.

### 📊 process-management
Auditoría del espacio de usuario en tiempo real sin degradación del throughput de los servicios activos:
* Inspección analítica de procesos con alto consumo de CPU/RAM o tiempos de ejecución que violan los SLAs operativos.
* Monitoreo del ciclo de vida de los procesos para la detección e interrupción controlada de hilos en estado `Z` (Zombie).
* Recolección de métricas operativas directamente desde el planificador del sistema operativo para una toma de decisiones informada.

### 💾 storage-filesystems
Gestión y automatización del ciclo de vida del almacenamiento secundario:
* Manipulación de tablas de particiones y aprovisionamiento automatizado de dispositivos de bloque.
* Rutinas de montaje determinista y configuración dinámica del archivo de inicialización de sistemas de archivos (`/etc/fstab`).
* Scripts de contingencia para la replicación y migración de datos minimizando la ventana de indisponibilidad técnica.

### 🔌 kernel-hardware-modules
Desarrollo de herramientas de automatización de bajo nivel destinadas a la auditoría, control dinámico de módulos del kernel (`sys_modules`) y telemetría de hardware.

* **Inspección de la Memoria del Núcleo:** Análisis y mapeo dinámico del estado de los controladores activos inspeccionando las tablas expuestas en `/proc/modules`.
* **Inyección y Remoción Dinámica:** Orquestación en caliente para la carga (`insmod`/`modprobe`) y descarga (`rmmod`) de controladores, administrando de forma nativa la resolución de árboles de dependencias de objetos ELF.
* **Ingeniería Inversa de Metadatos (.ko):** Extracción automatizada de firmas binarias, licencias, autores y parámetros en tiempo de compilación directamente de los objetos del kernel (`modinfo`).
* **Políticas de Blacklisting Operativo:** Mecanismos automáticos para anular vectores de ataque basados en hardware o protocolos heredados vulnerables (desactivación física de controladores USB específicos, FireWire, thunderbolt no autorizado).
* **Auditoría e Interrogación de Hardware:** Descubrimiento topológico exhaustivo de los buses del sistema e interfaces de hardware interconectadas en la placa base (`lspci`, `lsusb`, `lshw`, `dmidecode`, `lscpu`).

> 💡 **Abstracciones de Interfaces del Kernel:**
> El toolkit aprovecha la filosofía UNIX donde "todo es un archivo" para automatizar y alterar el comportamiento del sistema operativo en tiempo de ejecución a través de:
> * `/proc`: Telemetría no bloqueante sobre el estado global del hardware, memoria del kernel y entorno de ejecución de procesos (`/proc/cpuinfo`, `/proc/meminfo`).
> * `/sys`: Control reactivo y manipulación al vuelo de parámetros de hardware (modificación de gobernadores de energía de la CPU, escalado de frecuencia y control de energía en puertos físicos).
> * `/dev`: Gestión determinista de nodos de dispositivos orientados a bloques y caracteres.

---

## ⚠️ Directrices de Ejecución y Seguridad

* **Elevación de Privilegios:** Debido a la interacción con llamadas al sistema y la manipulación de subsistemas críticos, la ejecución de múltiples scripts requiere capacidades administrativas (`CAP_SYS_ADMIN`, `root` o privilegios validados vía `sudo`).
* **Aislamiento de Entornos:** Está estrictamente recomendado validar la lógica de las herramientas en entornos controlados de laboratorio (*Staging*/*Sandboxing*) antes de integrarlos en nodos de producción crítica.
* **Compatibilidad de Arquitectura:** Suite optimizada de forma nativa para plataformas **GNU/Linux**.

---

## 🎯 Declaración del Portafolio Técnico

Este repositorio consolida un portafolio de ingeniería enfocado en demostrar empíricamente:
1. Comprensión profunda de la arquitectura interna de sistemas GNU/Linux y la interacción kernel-hardware.
2. Dominio avanzado del desarrollo seguro de automatizaciones y herramientas CLI robustas en ambientes distribuidos.
3. Criterio sólido de ingeniería orientado al hardening de seguridad, la resiliencia operativa y la mitigación proactiva de incidentes.
