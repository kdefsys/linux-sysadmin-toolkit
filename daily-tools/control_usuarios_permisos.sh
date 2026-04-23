#!/bin/bash
### Nombre: control_usuarios_permisos.sh
### Autor: kdefsys
### Script de control de usuarios con shell bash y permisos en carpeta compartida
### Listamos todos los usuarios del sistema cuyo shell sea /bin/bash
### Introducimos un parámetro: directorio compartido
### Uso: ./control_usuarios_permisos.sh 

SALIDA="usuarios_bash.txt"
SALIDA2="archivos_no_lectura.txt"
FECHA=$(date +'%Y-%m-%d %H:%M:%S')
DIRECTORIO="${1:-.}"

if [ ! -d "$DIRECTORIO" ]; then
	echo "Error: El directorio '$DIRECTORIO' no existe."
	exit 1
fi

> "$SALIDA"
> "$SALIDA2"

gawk 'BEGIN{FS=":"} $7=="/bin/bash"{print $1}' /etc/passwd > "$SALIDA"

echo "---Usuarios cuyo shell es /bin/bash---"
cat "$SALIDA"
echo "--------------------------------------"

find "$DIRECTORIO" -typ f -not -perm -g=r -print 2>/dev/null | tee "$SALIDA2"

TOTAL_USUARIOS=$(wc -l < "$SALIDA")
TOTAL_ARCHIVOS=$(wc -l < "$SALIDA2")

echo -e "\n===REPORTE: $FECHA ========"
printf "Total de usuarios bash %d\n" "$TOTAL_USUARIOS"
printf "Archivos no legibles por el grupo: %d\n" "$TOTAL_ARCHIVOS"
echo "========================================="

