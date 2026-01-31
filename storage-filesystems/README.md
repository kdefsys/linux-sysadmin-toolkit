# storage-filesystems/

Este módulo del **linux-sysadmin-toolkit** está dedicado a la **gestión de almacenamiento en sistemas Linux**,
cubriendo desde la identificación de dispositivos de bloque hasta la creación,
verificación y montaje de sistemas de archivos.
El objetivo de este bloque es **documentar y automatizar tareas críticas de almacenamiento**,
manteniendo una separación clara por capas técnicas para reducir errores y
facilitar el mantenimiento en entornos reales.

## Enfoque Técnico

El almacenamiento en linux se organiza en **capas**, y este directorio respeta
esa arquitectura

1. **Dispositivos de bloque** (block devices)
2. **Particiones**
3. **Sistemas de archivos**
4. **Montaje y verificación**
5. **Medios ISO y utilidades ópticas**

Cada subdirectorio representa una capa distinta, con scripts y notas enfocadas
en **casos reales de administración de sistemas**.

## Estructura del Directorio

storage-filesystems/
|____ partitions/
|     Herramientas y notas para la gestión de particiones
|     **Advertencia: scripts potencialmente destructivos si se usan sin cuidado
|
|____ filesystems/
|     Creación, verificación y montaje de sistemas de archivos
|
|____ block_devices/
|     Escripts de descubrimiento e inventario de dispositivos de bloque
|
|____ iso-tools/
|     Creación y grabación de imágenes ISO.
|
|____ README.md

## Uso en Entornos Empresariales
- Administración de servidores Linux
- Migraciones de discos
- Recuperación ante fallos
- Repraración de almacenamiento para aplicaciones
- Automatización de inventarios y auditorías

La separación por capas reduce errores críticos y facilita la revisión por otros
administradores

## **Advertencias Importantes**
- Algunos scripts modifican estructuras de disco
- Se recomienda ejecutar solo en entornos de prueba
- Revisar siempre el código antes de ejecutarlo como root
