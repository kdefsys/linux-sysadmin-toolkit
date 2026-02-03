## **block-device**

   Scripts de auditoría e inventario de dispositivos de bloque del sistema.
   Permiten identificar discos, particiones y metadatos asociados (UUID, tipo,
   etiquetas), facilitando tareas de diagnóstico, documentación y control del
   almacenamiento
   Herramientas orientadas a la inspección y auditoría de dispositivos de bloque,
   incluyendo identificación de discos y particiones.

## Contenido

- [lsblk_report.sh](#lsblk_reportsh)
- [blkid_inventory.sh](#blkid_inventorysh)
- [device_audit.sh](#device_auditsh)
_____________________________________________________________________________

## **lsblk_report.sh**

  **Descripción Técnica**
  Es un script que auditoría de almacenamiento que analiza el estado de los
  dispositivos de bloque del sistema Linux y genera un reporte estructurado en
  formato .log
 
  El script recopila información detallada sobre:
  - Discos físicos, particiones y dispositivos de loop
  - Jerarquía entre discos y particiones
  - Tamaños y tipos de sistemas de archivos
  - Puntos de montaje
  - Estado lógico del dispositivo: OK, No-inicializado, Riesgo-potencial y
  Uso-temporal

  Además, el script genera un resumen estadístico con:
  - Número total de discos
  - Número de particiones
  - Dispositivos montados vs no montados

  Todo el proceso es no destructivo, enfocado exclusivamente en observación y
  analísis

  **Uso Típico en las empresas**

  - Auditorías periódicas de infraestructura Linux
  - Validar correctamente la inicialización de discos nuevos
  - Detectar particiones creadas pero no montadas
  - Identificar discos sin esquema de particionado
  - Revisiones previas a migraciones o ampliaciones de almacenamiento
  - Generar evidencias técnicas para documentación o compliance
  - Útil para: sysadmins, equipos de infraestructura, soporte N2/N3 y 
  auditoríorías internas de IT

  **Ejemplo de Ejecución**

  sudo ./lsblk_report.sh /var/log/storage-audit

  **Curiosidad Técnica**

  - Se utiliza lsblk -no para obtener una salida limpia y controlada sin 
  encabezados
  - Se emplean arreglos asociativos en gawk para identificar discos padres que
  contienen particiones
  - El estado lógico del disco se determina dinámicamente:
   . Un disco sin particiones -> No-incializado
   . Una partición sin punto de montake -> Riesgo potencial
  - Se usa sed -n '1!G; h; $p' para invertir el orden de salida, mostrando
  primero las particiones y luego los dispositivos físicos
  - El script implementa validaciones robustas: Permisos de ejecución, número
  correcto de parámetros, existencia del directorio de salida y la disponibilidad
  del paquete util-linux

  **Ejemplo de Salida**

   ========Lista de los dispositivos de bloque del sistema========

   Fecha: 20260130-2245
   HOSTNAME: usuario-nuevo
   USER: root

   Lista completa

   sda disk 500G ext4 / sda OK
   sda1 part 100G ext4 /boot sda OK
   sda2 part 399G ext4 / sd OK
   sdb disk 1T           sdb No-inicializado
   loop0 loop 55M squashfs /snap/core uso-temporal

   Numero de discos: 2
   Numero de particiones: 2
   Numero de montados: 3
   Numeor de no montados: 1
 
_____________________________________________________________________________

## **blkid_inventory.sh**
   Nivel: Intermedio-Avanzado
   **Temas:** Linux storage, Block Devices, Filesystems, Auditoría, Bash, gawk, inventarios del sistema

   **Descripción Técnica**

   Es un script de auditoría que genera un inventario confiable de sistemas de archivos presentes en el
   sistema Linux.
   El script identifica de forma única cada dispositio de bloque utilizando información crítica como:

   - DEVICE (/dev/sdXN, /dev/nvmeXpY, etc).
   - UUID
   - TYPE (ext4, xfs, swap, vfat, etc).
   - LABEL (si existe)

   La información se obtiene sin modificar el sistema, utilizando exclusivamente comandos de lectura (blkid) y
   procesamiento estructurado con gawk
   El resultado se almacena en un archivo .log con encabezados descriptivos y salida alineada, apta para auditorías
   técnicas y documentación del estado del sistema.

   **Uso Típico en las empresas**

   - Auditorías de almacenamiento y sistemas de archivos.
   - Documentación previa a migraciones de servidores.
   - Reconstrucción segura del archivo /etc/fstab.
   - Verificación de consistencia de UUIDs tras fallos o reemplazod e discos.
   - Inventarios periódicos de infraestructura linux.
   - Procesos de recuperación ante desastres (DRP).
   - Identificación incorrecta de particiones.
   - falta de documentación del almacenamiento real del sistema.

   **Ejemplo de ejecución**

   sudo ./blkid_inventory.sh /var/log/inventarios

   **Curiosidad Técnica**

   - El script utiliza 'blikd -o export', un formato estructurado pensadopara automatización y scripting.
   - Se emplea gawk con FS="=" y RS=""
   - Se usa switch dentro de gawk, demostrando conocimiento de estructuras propias del lenguaje.
   - Se normalizan los campos vacíos (UUID,LABEL,TYPE) para evitar salidas inconsistentes.
   - La redirección global con exec permite una salida limpia y mantenible hacia el archivo .log
   - Se valida previamente la existencia del comando blkid usando 'command -v', garantizando portabilidad y control
   de errores.

   **Ejemplo de Salida**

   ======== INVENTARIO DE SISTEMA DE ARCHIVOS ========

   FECHA: 20260130_2315

   HOST: servidor-linux

   Usuario: root

   Total de dispositivos: 2



   DEVICE		UUID			TYPE		LABEL

   /dev/sda1		XXXX-XXXX-XXXX		ext4		rootfs
   /dev/sda2		XXXX-XXXX-XXXX		swap		-

   ====================================================================

_____________________________________________________________________________

## **device_audit.sh**
   Nivel: Intermedio
   **Temas:** Dispositivos de bloque, Major/Minor numbers, SCSI, kernel drivers,
   lsblk, lsscsi, /proc, auditoría de almacenamiento

   **Descripción Técnica**

   device_audit.sh es un script de auditoría que analiza los dispositivos de bloque
   presentes en el sistema Linux y genera un reporte técnico consolidado.

   El script recopila información desde distintas capas del sistema:

   - Capa de usuario (lsblk)
   - Kernel (/proc/devices)
   - Subsistema SCSI (lsscsi)
   - Dispositivos especiales (/dev)

   Su objetivo es identificar cómo el kernel reconoce y controla cada dispositivo
   diferenciando entre discos físicos y particiones, mostrando drivers asociados,
   numeros Major/MInor, tipo de transporte, punto de montaje y sistema de archivos

   El resultado se guarda en un archivo de texto para su posterior revisión o
   documentación

   **Uso Típico en las empresas**

   - Auditorías de hardware en servidores Linux
   - Diagnóstico de problemas de almacenamiento
   - Documentación técnica antes de migraciones o cambios
   - Validar qué driver del kernel controla cada disco
   - Verificar configuraciones antes de montar nuevos volúmenes
   - Soporte técnicode segundo nivel (L2/L3)

   **Ejemplos Reales**

   - Un servidor no reconoce correctamente un disco
   - Un nuevo storage fue contectado y se necesita validar su detección
   - Se debe entregar un inventario técnico del servidore a otro equipo
   - Verificar diferencias entre entornos (producción vs pruebas)

   **Ejemplo de Ejecución**  sudo ./device_audit.sh

   **Curiosidad Técnica**

   - El script extrae los números Major y Minor desde lsblk y los cruza con
   /proc/devices para identificar el driver real del kernel que controla el
   dispositivo

   - Solo los discos físicos aparecen en lsscsi
   Las particiones heredan el dispositivo padre, por eso el scrip detecta cuando
   un dispositivo no tiene información SCSI

   - La salida de lsscsi es procesada para extraer:
   Host, Bus, ID SCSI y LUN sin depender de herramientas externas

   **Ejemplo de Salida**

   =========== INFORME DE AUDITORIA DE DISPOSITIVO DE BLOQUE ================

   Device: sda

   Type: block

   Major: 8

   Minor: 0

   Driver: sd

   Transport: sata

   SCSI:
    - host: 2
    - bus: 0
    - id: 0
    - lun: 0

   Montado: NO ESTÁ MONTADO
   FILESYSTEM: 
