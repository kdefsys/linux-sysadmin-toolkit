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
	echo "   -d : Directorio objetivo a analizar. Si no se introduce esta opcion entonces se asume que se va a buscar en el directorio actual"
	echo "   -p : Patron a buscar dentro de todos los logs. Si no se introduce se asume por defecto el patrón Error"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
PATRON="Error"

while getopts :d:p:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe" >&2
			echo "Saliendo del script" >&2
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
		 echo "Opcion Invalida"
		 help
		 exit 1
		 ;;
	esac
done

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="reporte_coincidencias_${FECHA}.log"

echo "====================================================REPORTE DE COINCIDENCIAS DEL PATRON====================================" > "$REPORTE"
echo "PATRON: $PATRON" >> "$REPORTE"
echo "FECHA: $FECHA" >> "$REPORTE"

mapfile -t files_logs < <(find "$DIRECTORIO" -type f \( ! -name "*.gz" -and \( -name "*.log" -or -name "*.log.*" \) \) -exec grep -Hic "$PATRON" {} + | sort -t ":" -k 2nr,2nr)
if [[ "${#files_logs[@]}" -eq 0 ]]; then
	echo -e "\n\nNo se encontraron archivos logs con ese patron" >> "$REPORTE"
else
	printf "%s\n" "${files_logs[@]}" >> "$REPORTE"
fi

echo "El proceso termino, el reporte esta guardado en: $REPORTE"
