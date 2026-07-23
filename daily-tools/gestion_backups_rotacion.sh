#!/bin/bash
### Nombre: gestion_backups_rotacion.sh
### Autor: kdefsys
### Descripción: El script recibe un directorio origen y empaqueta su contenido en un archivo comprimido en una carpeta destino.
### Para evitar llenar el disco con respaldos antiguos, el script debe aplicar una politica de retencion automatica (rotacion).
### Uso: ./gestion_backups_rotacion.sh  <directorio_origen> <directorio_destino> <limite>

if [[ "$#" -ne 3 ]]; then
	echo "El script debe tener 3 argumentos obligatorios"
	echo "Debe ejecutarse así: $0 <directorio_origne> <directorio_destino> <limite>"
	exit 1
fi

DIRECTORIO_ORIGEN="$1"
[[ ! -d "$DIRECTORIO_ORIGEN" ]] && { echo "El directorio origen no existe, saliendo del script..."; exit 1; }

DIRECTORIO_DESTINO="$2"
[[ ! -d "$DIRECTORIO_DESTINO" ]] && mkdir "$DIRECTORIO_DESTINO"

LIMITE="$3"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')

##================================================================
##		CREACIÓN DEL BACKUP
##================================================================

ARCHIVO_CREADO="${DIRECTORIO_DESTINO}/backup_${FECHA}.tar.gz"
if tar -cvzf "$ARCHIVO_CREADO" -C "${DIRECTORIO_ORIGEN}" . 2>/dev/null; then
	echo "Se creó correctamente el backup"
	echo "Archivo creado: $ARCHIVO_CREADO con tamaño: $(stat -c '%s' $ARCHIVO_CREADO)"
else
	echo "No se creó correctamente el backup"
fi

##================================================================
##		ROTACIÓN Y LIMPIEZA
##================================================================

mapfile -t files_backups < <(find "$DIRECTORIO_DESTINO" -type f -name "*.tar.gz")

CANTIDAD="${#files_backups[@]}"
echo "La cantidad total de backups en el directorio $DIRECTORIO_DESTINO es $CANTIDAD"

if [[ "$CANTIDAD" -gt "$LIMITE" ]]; then
	echo "La cantidad de backups en el directorio $DIRECTORIO_DESTINO excede el limite, entonces procedemos a limpiar"
	CANTIDAD_A_ELIMINAR=$(( CANTIDAD - LIMITE ))
	stat -c "%W|%n" "${files_backups[@]}" | sort -k 1n,1n | head -n "$CANTIDAD_A_ELIMINAR" | gawk -F "|" '{print $2}' | xargs rm -fv
else
	echo "La cantidad de backups en el directorio $DIRECTORIO_DESTINO no excede el limite, entonces no se procede a hacer la limpieza"
fi
