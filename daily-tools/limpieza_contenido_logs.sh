#!/bin/bash
###Nombre: limpieza_contenido_logs.sh
###Autor: kdefsys
###Descripción: Este script escanea un directorio en busca de archivos de registro (con extensión .log), procesa su contenido para eliminar las líneas duplicadas
###consecutivas o repetidas y genera un reporte consolidando que incluya un análisis del top10 de entradas más frecuentes
###Uso: ./limpieza_contenido_logs.sh -d <directorio> -h [help]

OPERACION="NO"

function help {
	echo "Uso: $0 -d <directorio> [-h]"
        echo "  -d: Directorio objetivo a buscar los archivos .log"
        echo "  -h: Muestra esta ayuda"
        exit 0
}


while getopts :d:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then DIRECTORIO="$(pwd)"; fi
		  OPERACION="SI"
		  ;;
		h)
		  help
		  ;;
		*)
		  echo "Opción Inválida"
		  exit 1
		  ;;
	esac
done

if [[ "$OPERACION" == "SI" ]]; then
	REPORTE="log_limpio.txt"
	FECHA=$(date '+%Y-%m-%d %H:%M:%S')

	exec 3>"$REPORTE"

	echo "============Limpieza de logs ejecutada: $FECHA=========" >&3
	mapfile -t archivos_logs < <(find "$DIRECTORIO" -type f -name "*.log")

	if [[ "${#archivos_logs[@]}" -eq 0 ]]; then
		echo "No hay ningun archivo .log dentro del directorio objetivo: $DIRECTORIO"
		exec 3>&-
		rm -f "$REPORTE"
		exit 0
	fi

	##Ponemos todo el contenido de todos los archivos en un solo archivo
	for archivo in "${archivos_logs[@]}"; do
		[[ -f "$archivo" ]] && cat "$archivo" >&3
	done
	exec 3>&-
	echo -e "\n====== Top 10 entradas más frecuentes ========" >> "$REPORTE"
	grep -v "====" "$REPORTE" | sort | uniq -c | sort -k 1nr,1nr | head -n 10 >> "$REPORTE"

	cat "$REPORTE"
else
	echo "No se introdujo la opcion -d"
	echo "Ejecutar así: $0 -d <directorio>"
	exit 1
fi
