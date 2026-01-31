## **block-device**

   Scripts de auditoría e inventario de dispositivos de bloque del sistema.
   Permiten identificar discos, particiones y metadatos asociados (UUID, tipo,
   etiquetas), facilitando tareas de diagnóstico, documentación y control del
   almacenamiento
   Herramientas orientadas a la inspección y auditoría de dispositivos de bloque,
   incluyendo identificación de discos y particiones.

## Contenido

- [lsblk_report.sh](#lsblk_reportsh)
_____________________________________________________________________________

## **lsblk_report.sh"

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
