#!/bin/bash
### Nombre: analizar_patron_logs_servicios.sh
### Autor: kdefsys
### Descripción: En la gestión de servidores y aplicaciones, analizar los archivos de registro (logs) es fundamental para detectar fallos, intentos de acceso no autorizados o
### advertencias del sistema. Sin embargo, los logs suelen estar divididos en múltiples archivos (archivos activos .log y archivos rotados como .log.1, .log.2, etc.)
### Para facilitar esta tarea a los equipos de soporte, este script en Bash busca cuántas veces aparece un texto/patrón específico dentro de todos los archivos de log de un
### directorio, organizando los resultados de mayor a menor según la cantidad de coincidencias encontradas.
### Uso: ./analizar_patron_logs_servicios.sh -d <directorio> -p < patron> [-h]

function help {
	echo "El script se debe de ejecutar asi: ./analizar_patron_logs_servicios.sh -d <directorio> -p <patron> [-h]"
	echo "DESCRIPCION: Contabiliza cuantas veces aparece un patron de texto dado en los archivos de log no comprimidos de un directorio"
	echo "y ordena los hallazgos de mayor a menor coincidencia en un archivo de reporte"
	echo "   -d : Directorio objetivo a analizar. Si no se introduce esta opcion entonces se asume que se va a buscar en el directorio actual"
	echo "   -p : Patron a buscar dentro de todos los logs. Si no se introduce se asume por defecto el patrón Error"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
PATRON=""

while getopts :d:p:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		p)
		  PATRON="$OPTARG"
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

if [[ -z "$PATRON" ]]; then
	echo "No se introdujo patron, por lo tanto salimos del script"
	exit 0
fi

## =======================================================================================
## Buscamos archivos que terminen en .log o .log.<algo> pero excluimos los comprimidos .gz
## =======================================================================================

mapfile -t files < <(find "$DIRECTORIO" -type f \( -regextype posix-extended \( ! -regex ".*\.gz$" \) \) \
	-and \( -regextype posix-extended -regex "(.*\.log$|.*\.log\..*$)" \))

CANTIDAD="${#files[@]}"

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="reporte_coincidencias_${FECHA}.log"
exec 3>>"$REPORTE"
echo "======================================= REPORTE COINCIDENCIAS ===============================" >&3
echo "SCRIPT: analizar_patron_logs_servicios.sh" >&3
echo "PATRON: $PATRON" >&3
echo "DIRECTORIO OBJETIVO: $DIRECTORIO" >&3
echo "HOSTNAME: $HOSTNAME" >&3
echo "USUARIO: $USER" >&3
echo "=============================================================================================" >&3

if (( CANTIDAD == 0 )); then
	echo "El directorio no tiene archivos .log o .log.<algo> que contengan ese patron" >&3;
else
	grep -Hci "$PATRON" "${files[@]}" | sort -t ":" -k 2,2nr >&3
fi

exec 3>&-
echo "El script finalizo con exito. Ver el reporte en: $REPORTE"
