## **Kernel-hardware-modules**

Este directorio esta dedicado al desarrollo de scripts de auditoria de automatización, auditoría y control de bajo nivel para la gestión de módulos del kernel (sys_modules) y la 
interacción del sistema operativo con el hardware en entornos Linux. El objetivo de las herramientas contenidas aquí es proporcionar un control granular sobre el comportamiento del 
núcleo de forma dinámica, permitiendo la inspección técnica, optimización de recursos en memoria RAM y el endurecimiento (hardening) de la seguridad del sistema mediante la gestión 
de controladores.

CONTENIDO:
- [kernel_module_auditor.sh](#kernel_module_auditorsh)
- [kernel_boot_persister.sh](#kernel_boot_persistersh)
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
   - La tubería lsmod | gawk '{print $1}' | grep -qxi "$modulo": Para blindar el script contra falsos positivos, se usa gawk para aislar estrictamente la primera columna de lsmod 
   (donde residen los nombres de los módulos cargados). Luego, grep -x obliga a hacer una coincidencia exacta de toda la línea, evitando que un módulo corto (como lp) de un falso 
   positivo con uno más largo (como lp_vivid). La bandera -q (quiet) asegura que la comprobación sea silenciosa y no altere los logs.

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

____________________________________________________________________________________________________________________________________________________________________________________
