# partitions/

## **Contenido**

- [auditoria_disk_partitions.sh](#auditoria_disk_partitionssh)
- [partition-risk-check.sh](#partition-risk-checksh)
____________________________________________________________________________________________________________________

## **auditoria_disk_partitions.sh**
   Nivel: Intermedio-Avanzado
   **Temas:** lsblk, parted, arrays asociativos, scripting, auditoría de discos, logging

   **Descripcion Técnica**

   Este script audita los discos físicos del sistema linux y genera un reporte detallado del estado del
   almacenamiento

   - Detecta discos reales del sistema (excluye dispositivos loop, ram, rom).
   - Obtiene su tamaño total
   - Detecta el tipo de tabla de particiones (GPT, MBR o desconocido)
   - Lista todas sus particiones, indicando:
	- Nombre
	- Tamaño
	- Tipo de partición (Linux, EFI, swap, etc)
   - Detecta discos sin particiones y los marca como advertencia
   - Muestra el reporte en el directorio que entra como parámetro de entrada en un archivo .log

   **Uso Típico en las empresas**

   - Auditoría previa a:
	- migraciones de servidores
	- ampliaciones de almacenamiento
	- instalación de servicios críticos (bases de datos, kubernetes, virtualización)
   - Revisión e servidores heredados donde no existen documentación confiable.
   - Validación del estado del disco
   - Soporte técnico y troubleshooting cuando:
	- Un disco no es reconocido correctamente
	- Hay dudas sobre el esquema de particiones

   **Ejemplo de Ejecución**

   sudo ./auditoria_disk_partitions.sh

   **Curiosidad Técnica**

   - usamos el lsblk -o pttype para el tipo de tabla de particiones, pero era mejor usar 'parted -s/dev/sdX print'
   - Se usa arrays asociativosen Bash para contar particiones por disco, evitando múltiples llamadas a comandos externos

____________________________________________________________________________________________________________________"

## **partition-risk-check.sh**
   Nivel: Avanzado
   **Temas:** Particiones de discos, tabla MBR/GPT, filesystems, auditoria preventiva, diseño de layout, lsblk,
   bash scripting 

   **Descripción Técnica**

   Script de auditoria avanzada que analiza el estado del particionado y el diseño lógico del almacenamiento en
   sistemas linux.

   Actuá como un **pre-fligth check** antes de realizar operaciones críticas como:

   - Ampliación de discos
   - Modificaciones sobre LVM
   - Creación o montaje de nuevos sistemas de archivos
   - Migraciones de datos

   El script evalúa 3 capas fundamentales:

   1. **Riesgo estructural**
	- Detecta discos sin particiones o con una sola partición
	- Identifica discos con tabla MBR que pueden causar problemas en discos grandes.
	
   2. **Riesgo operacional**
	- Detecta particiones sin filesystems
	- Detecta particiones con filesystems no montadas.

   3. **Diseño crítico del sistema de archivos**
	- Evalúa si '/' y '/var' comparten la misma partición
	- Verifica si '/boot' está correctamente separado

   Clasifica los hallazgos en **OK**, **WARNING**, **CRITICAL**, y genera un reporte estructurado para toma de
   deceisiones.

   **Uso Típico en las empresas**

   - Servidores Linux en producción
   - Ambientes críticos (bases de datos, servidores web, sistemas de monitoreo).
   - Auditorías de infraestructura
   - Procedimiento de mantenimiento programado.
   - Validaciones previas a cambios mayores en almacenamiento.

   Permite detectar **errores de diseño historico** que suelen pasar desapercibidos hasta que ocurre una caída del
   sistema

   **Ejemplo de Ejecución**

   sudo ./partition-risk-check.sh /var/log

   **Curiosidad Técnica**

   - Utiliza el lsblk con opciones -nro para obtener salidas limpias y controladas.
   - Emplea arregos asociativos en Bash para contabilizar particiones por disco.
   - Usa sustitucion de procesos para evitar subshells y conservar el estado de variables.

   **Ejemplo de Salida**

   [WARNING] disk sdb

   Partition table	:mbr

   Tamaño del disco     :3.6T

   Mensaje		El disco es MBR y sobrepasa el limite de 2TB

   Recomendacion        Convertir la tabal a gpt

   [CRITICAL] partition sdb1

   FILESYSTEM		:NO PRESENTE

   MOUNTPOINT		:

   Mensaje		:La particion no tiene un filesystem creado.

   Recomendacion	:Crearle un filesystem a este archivo

   [WARNING] Diseño del sistema de archivos

   - / and /var comparten la misma particion sda2
   - Riesgo: El crecimiento del registro puede llenar el sistema de archivo raiz

   [SUMMARY]

   Total de discos analizados: 2

   Total de particiones analizadas: 5

   OK: 3
   WARNING: 2
   CRITICAL: 1

   ESTADO DEL SISTEMA: CRITICAL
   Exit code 2
