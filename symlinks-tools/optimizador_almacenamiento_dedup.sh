#!/bin/bash
### Nombre: optimizador_alamcenamiento_dedup.sh
### Autor: kdefsys
### Descripcion: En entornos con grandes volúmenes de datos (como servidores de respaldos o repositorios de activos), es habitual encontrar archivos completamente idénticos
### duplicados en diferentes rutas. Esto desperdicia almacenamiento físico y recursos del sistema de archivos.
### Este script de deduplicacion identifica archivos identicos entre dos directorios ( un directorio de referencia y uno de destino) y reemplaza las copias repetidas por enlaces duros
### hacia la version original, liberando espacio en disco de forma transparente
### Uso: ./optimizador_alamcenamiento_dedup.sh -r <directorio_de_referencia> -d <directorio_destino> -m <tamaño_minimo> -s -h [help]

function help {
	echo "El script se ejecuta asi: ./optimizador_alamcenamiento_dedup.sh -r <directorio_de_referencia> -d <directorio_destino> -m <tamaño_minimo> -s <modo_simulacro> -h"
	echo "   -r: Directorio de referencia (contiene los archivos originales), si se omite se toma el directorio actual"
	echo "   -d: Directorio destino donde se buscara y se reemplazaran los archivos duplicados. Si no existe se cancela la ejecucion"
	echo "   -m: Tamaño minimo, un umbral en bytes a partir del cual se consideraran los archivos para el analisis, por defecto es 0"
	echo "   -s: Modo simulacro, un flag tipo switch sin argumentos que, si esta presente, activa el modo prueba"
	echo "   -h: Imprime esta guia "
}

DIRECTORIO_ORIGEN="$(pwd)"
DIRECTORIO_ORIG_HAY="SI"
DIRECTORIO_DEST_HAY="NO"
LIMITE="0"
SIMULACION="NO"

while getopts :r:d:m:sh opt; do
	case "$opt" in
		r)
		 if [[ -d "$OPTARG" ]]; then DIRECTORIO_ORIGEN="$OPTARG"; fi
		 ;;
		d)
		 DIRECTORIO_DESTINO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO_DESTINO" ]]; then
		 	echo "No existe el directorio destino, se cancela la ejecucion"
		 	exit 1
		 fi
		 DIRECTORIO_DEST_HAY="SI"
		 ;;
		m)
		 LIMITE="$OPTARG"
		 ;;
		s)
		 SIMULACION="SI"
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion invalida de argumento"
		 help
		 exit 1
		 ;;
	esac
done

function filtrado_por_size {
	local -n arreglo=$1
	local -n arreglo_salida=$2
	for file in "${arreglo[@]}"; do
		local TAMAÑO="$(stat -c '%s' "$file")"
		arreglo_salida[$TAMAÑO]="${arreglo_salida[$TAMAÑO]}"%"$file"
	done
}

AHORRADO=0

if [[ "$DIRECTORIO_DEST_HAY" == "SI" ]]; then

	if [[ "$SIMULACION" == "SI" ]]; then
	        echo "======================================================SIMULACRO========================================"
	else
        	echo "===============================================EJECUCION REAL=========================================="
	fi
	mapfile -t files_origen < <(find "$DIRECTORIO_ORIGEN" -type f -size +"${LIMITE}c")
	mapfile -t files_destino < <(find "$DIRECTORIO_DESTINO" -type f -size +"${LIMITE}c")
	## Filtramos por tamaño, la clave es el tamaño en bytes y el valor es una cadena con los nombres
	## de todos los archivos que cumplen esa condicion de tamaño con un separador %

	declare -A files_por_size_origen

	filtrado_por_size files_origen files_por_size_origen

	for file_destino in "${files_destino[@]}"; do
		tamaño_destino=$(stat -c "%s" "$file_destino")
		if [[ -n "${files_por_size_origen[$tamaño_destino]}" ]]; then
			cadena_origen="${files_por_size_origen[$tamaño_destino]}"
			cadena_origen="${cadena_origen#%}"

			## Aplicamos un read con IFS y un here string
			IFS="%" read -r -a opciones_origen <<< "$cadena_origen"
			hash_destino="$(sha256sum "$file_destino" | gawk '{print $1}')"
			inodo_destino=$(stat -c "%i" "$file_destino")

			for file_origen in "${opciones_origen[@]}"; do
				inodo_origen=$(stat -c "%i" "$file_origen")
				hash_origen="$(sha256sum "$file_origen" | gawk '{print $1}')"
				if (( inodo_destino == inodo_origen )); then
					echo "El archivo destino: $file_destino ya es un enlace duro del archivo original: $file_origen"
					break
				else
					if [[ "$hash_destino" == "$hash_origen" ]]; then
						AHORRADO=$(( AHORRADO + tamaño_destino))
						if [[ "$SIMULACION" == "SI" ]]; then
							echo "Como es un simulacro no se modifica el sistema de archivos"
							echo "Pero sabemos que el archivo $file_destino es una copia del archivo $file_origen"
						else
							rm -fv "$file_destino"
							if ln "$file_origen" "$file_destino" 2>/dev/null; then
								echo "Se creo correctamente el enlace duro"
								echo "El enlace duro: $file_destino -> $file_origen"
							else
								echo "No se pudo crear correctamente el enlace duro $file_destino"
							fi
						fi
						break
					fi
				fi
			done
		fi
	done
fi

## ==========================================================
## 			REPORTE
## ==========================================================

if [[ "$SIMULACION" == "SI" ]]; then
	echo "Si lanzamos este script en ejecucion real se estaria ahorrando $AHORRADO bytes"
else
	echo "Se ahorro un total de $AHORRADO bytes eliminando esos duplicados y copias de archivos"
fi
