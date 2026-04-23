#!/bin/bash
### Nombre: limpieza_selectiva_archivos.sh
### Autor: kdefsys
### Permite a un administrador realizar limpiezas 
### controladas en directorios criticos (backup, temporales, dumps)
### para evitar el colapso del almacenamiento, incluyendo una etapa
### de confirmacion humana para mayor seguridad
### Uso: ./limpieza_selectiva.sh <directorio> <dias>

if [[ ! "$#" -eq 2 ]]; then
	echo -e "El script no recibe dos argumentos\nSaliendo del script..."
	exit 1
fi

DIRECTORIO="$1"
DIAS="$2"

if [[ ! -d "$DIRECTORIO" ]]; then
	echo -e "El directorio ingresado no existe\nSaliendo del script..."
	exit 1
else
	mapfile -t archivos < <(find "$DIRECTORIO" -type f --regextype posix-extended -regex '(\.bak$|\.tmp$|\.old$|.*/.*/backup_[^/]*$)' \
		-mtime +"$DIAS" -size +1M)

	if [[ "${#archivos[@]}" -eq 0 ]]; then
		echo -e "No hay archivos que cumplen esas caracteristicas\nSaliendo del script..."
		exit 1
	fi

	limpieza="limpieza_$(date '+%Y-%m-%d_%H-%M').log"
	exec 3>>"$limpieza"
	echo -e "==========================REPORTE==============================\n" >&3
	echo -e "FECHA DE INICIO: $(date)\nDIRECTORIO: ${DIRECTORIO}\n\n" >&3
	echo -e "CANTIDAD DE ARCHIVOS: ${#archivos[@]}\n\nCALCULO DEL ESPACIO TOTAL EN DISCO: \n" >&3
	echo "${archivos[@]}" | xargs du -hcb >&3
	echo -e "ARCHIVOS CANDIDATOS:\n " >&3
	printf "%s\n" "${archivos[@]}" >&3

	### Imprimiendo en pantalla
	cat "$limpieza"

	## Menu
	read -p "DESEA ELIMINAR LOS ARCHIVOS MOSTRADOS? (s\n): " op

	if [[ "$op" = "s" || "$op" == "S" ]]; then
		echo -e "ARCHIVOS ELIMINADOS:\n\n" >&3
		for archivo in "${archivos[@]}"; do
			rm -fv "$archivo" | tee -a /dev/fd/3
		done
	else
		echo "El usuario cancelo el proceso de eliminacion correctamente"
		echo "Saliendo del script..."
		exit 1
	fi
fi

echo "La tarea finalizo el $(date '+%Y-%m-%d_%H-%M-%S')"
exec 3>&-
