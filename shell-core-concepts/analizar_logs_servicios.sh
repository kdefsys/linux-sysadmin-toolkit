#!/bin/bash
### Nombre: analizar_logs_servicios.sh
### Autor: kdefsys
### Script que busca la coincidencia de un patron en archivos
### log y log.*, el resultado lo guarda en un archivo.log con la ruta del
### archivo y el numero de coincidencias que tiene este.
### USO: ./analizar_logs_servicios.sh <directorio> <patron>

DIRECTORIO="${1:-.}"
PATRON="${2:-Error}"
FECHA=$(date '+%Y-%m-%d_%M-%H-%S')
SALIDA="reporte_coincidencias_${FECHA}.log"

if [[ ! -d "$DIRECTORIO" ]]; then
	echo "El directorio ingresado no existe"
	echo "Saliendo del script..."
	exit 1
fi


mapfile -t archivos < <(find "$DIRECTORIO" -type f -not -name "*.gz" \
	\( -name "*.log" -or -name "*.log.*" \)  -exec grep -Hic "$PATRON" {} + \
		| sort -t ":" -k 2nr,2nr)

exec 3>>"$SALIDA"

echo "---REPORTE DE AUDITORIA: $PATRON---" >&3
echo "Ejecutado el $(date)" >&3
echo "-----------------------------------" >&3

if [[ "${#archivos[@]}" -eq 0 ]]; then
	echo "No se encontraron coincidencias para '$PATRON'." >&3
else
	for linea in "${archivos[@]}"; do
		echo "$linea" >&3
	done
fi

exec 3>&-

echo "Proceso finalizado. Resultados guardados en: $SALIDA"
