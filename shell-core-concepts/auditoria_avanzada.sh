#!/bin/bash
### auditoria_avanzada.sh
### Este script actua como una herramienta de administracion
### de sistemas para localizar archivos de gran tamaño que han sido
### modificados recientemente, facilitando la prevencion de saturacion
### en los discos del servidor

if [[ ! "$#" -eq 3 ]]; then
	echo -e "El script necesita si o si 3 argumentos\nSaliendo del script..."
	exit 1
fi

FECHA=$(date '+%Y-%m-%d_%H-%M')
DIRECTORIO="$1"
TAMANIO="$2"
DIAS="$3"

if [[ -d "$DIRECTORIO" ]]; then
	mapfile -t archivos < <(find "$DIRECTORIO" -type f -size +"${TAMANIO}"M -mtime -"${DIAS}" -print)
else
	echo -e "El directorio ingresado como primer argumento, no existe\nSaliendo del script..."
	exit 1
fi

if [[ "${#archivos[@]}" -eq 0 ]]; then
	echo -e "No se encontraron archivos con esas caracteristicas\nSaliendo del script..."
	sleep 2
	exit 1
else
	TOTAL="${#archivos[@]}"
	SALIDA="auditoria_disco_${FECHA}.log"
	SALIDA2="Borrador.log"
	exec 3>>"$SALIDA"
	echo "==========AUDITORIA AVANZADA DE DISCO==========" >&3
	echo -e "RUTA\tTAMANIO\tTAMANIO_BLOQUE\tULTIMA_MODIFICACION\tUID_PROPIETARIO\n" >&3

	for archivo in "${archivos[@]}"; do
		gawk -F "|" 'BEGIN{OFS="\t"}{
			print $1, $2, $3, $4, $5
		}' < <(stat -c "%n|%s|%b|%y|%u" "${archivo}") >> "$SALIDA2"
	done

	sort -t $'\t' -k 2nr,2nr "$SALIDA2" >&3
	ARCHIVO_MAYOR_TAMANIO=$(cat "$SALIDA2" | head -n 1 | gawk '{print $1}')


	echo -e "\n\nTOTAL DE ARCHIVOS ENCONTRADOS: '$TOTAL'" >&3
	echo -e "\n\nEspacio total en disco: " >&3
	echo "${archivos[@]}" | xargs du -hcb >&3
	echo -e "\n\nArchivo con mayor tamaño:\t${ARCHIVO_MAYOR_TAMANIO}" >&3 
	rm "$SALIDA2"
fi

exec 3>&-
