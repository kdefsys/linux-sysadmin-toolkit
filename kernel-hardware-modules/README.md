## **Kernel-hardware-modules**

Este directorio esta dedicado al desarrollo de scripts de auditoria de automatización, auditoría y control de bajo nivel para la gestión de módulos del kernel (sys_modules) y la 
interacción del sistema operativo con el hardware en entornos Linux. El objetivo de las herramientas contenidas aquí es proporcionar un control granular sobre el comportamiento del 
núcleo de forma dinámica, permitiendo la inspección técnica, optimización de recursos en memoria RAM y el endurecimiento (hardening) de la seguridad del sistema mediante la gestión 
de controladores.

CONTENIDO:
- [kernel-module-auditor.sh](#kernel-module_auditorsh)

____________________________________________________________________________________________________________________________________________________________________________________

## **kernel-module-auditor.sh**
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
   - La tubería lsmod | gawk '{print $1}' | grep -qxi "$modulo": Para blindar el script contra falsos positivos, se usa gawk para aislar estrictamente la primera columna de lsmod 
   (donde residen los nombres de los módulos cargados). Luego, grep -x obliga a hacer una coincidencia exacta de toda la línea, evitando que un módulo corto (como lp) de un falso 
   positivo con uno más largo (como lp_vivid). La bandera -q (quiet) asegura que la comprobación sea silenciosa y no altere los logs.

_____________________________________________________________________________________________________________________________________________________________________________________
