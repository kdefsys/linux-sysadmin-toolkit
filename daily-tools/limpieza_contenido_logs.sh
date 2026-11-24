#!/bin/bash
###Nombre: limpieza_contenido_logs.sh
###Autor: kdefsys
###Descripción: Este script escanea un directorio en busca de archivos de registro (con extensión .log), procesa su contenido para eliminar las líneas duplicadas
###consecutivas o repetidas y genera un reporte consolidando que incluya un análisis del top10 de entradas más frecuentes
###Uso: ./limpieza_contenido_logs.sh -d <directorio> -h [help]

## =======================================
## 		FUNCION HELP
## =======================================

function help {
	echo "El script debe de ejecutarse asi: ./limpieza_contenido_logs.sh -d <directorio> [-h]"
	echo "Descripcion: Recorre el directorio objetivo en busca de archivos de registro con extension .log,"
	echo "consolida su contenido en un archivo de reporte y añade al final un analisis de las 10 lineas o entradas mas "
	echo "frecuentes, mostrando el resultado completo en pantalla"
	echo "   -d <directorio>: Directorio objetivo"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"

while getopts :d:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		h)
		  help
		  exit 0
		  ;;
		*)
		  echo "Opcion ingresada no valida" >&2
		  help
		  exit 1
		  ;;
	esac
done

mapfile -t archivos_log < <(find "$DIRECTORIO" -type f -name "*.log")
CANTIDAD="${#archivos_log[@]}"
if (( CANTIDAD == 0 )); then
	echo "No existen archivos .log dentro del directorio objetivo $DIRECTORIO"
	exit 0
fi

REPORTE="log_limpio.txt"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')

echo "==================================== LIMPIEZA CONTENIDO DE LOGS =====================================" > "$REPORTE"
echo "=SCRIPT: limpieza_contenido_logs.sh" >> "$REPORTE"
echo "=HOSTNAME: $HOSTNAME" >> "$REPORTE"
echo "=FECHA: $FECHA" >> "$REPORTE"
echo "=====================================================================================================" >> "$REPORTE"

printf "%s\0" "${archivos_log[@]}" | xargs -0 cat >> "$REPORTE"

echo "=====================================================================================================" >> "$REPORTE"
echo "== Las 10 entradas mas frecuentes son: " >> "$REPORTE"

cat "$REPORTE" | grep -v "^=" | sort | uniq -c | sort -k1,1nr | head -n 10 >> "$REPORTE"

echo "El script finalizo con exito. Ver el reporte en: $REPORTE"
