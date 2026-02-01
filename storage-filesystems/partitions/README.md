# partitions/

## **Contenido**

- [auditoria_disk_partitions.sh](#auditoria_disk_partitionssh)

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
