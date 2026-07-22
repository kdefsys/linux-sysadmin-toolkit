#!/bin/bash
###Nombre: limpieza_enlaces_rotos.sh
###Autor: kdefsys
###Descripción: Este script scanea un directorio objetivo y busca enlaces simbólicos huérfanos o rotos (enlaces que apuntan a archivos o rutas que ya no existen).
###El script debe auditar estos enlaces, eliminarlos del sistema de forma segura y registrar la actividad en un archivo de registro (log).
###Uso: ./limpieza_enlaces_rotos.sh -d <directorio> -h [help]

##=============================================================
## FUNCIÓN DE AYUDA
##=============================================================

function help {
	echo "Uso: $0 -d <directorio> [-h]"
	echo "  -d: Directorio objetivo a buscar los enlaces"
	echo "  -h: Muestra esta ayuda"
	exit 0
}

OPERAR="NO"
FECHA="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORTE="enlaces_rotos_${FECHA}.log"

while getopts :d:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$OPTARG" ]]; then
		  	DIRECTORIO="$(pwd)"
		  fi
		  OPERAR="SI"
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

if [[ "$OPERAR" == "SI" ]]; then
	exec 3>>"$REPORTE"

	mapfile -t enlaces_rotos < <(find "$DIRECTORIO" -type l ! -exec test -e {} \; -print)

	if [[ "${#enlaces_rotos[@]}" -eq 0 ]]; then
		echo "No se encontraron enlaces simbólicos rotos en $DIRECTORIO"
		exec 3>&-
		rm -f "$REPORTE"
		exit 0
	fi

	for enlace in "${enlaces_rotos[@]}"; do
		destino=$(readlink "$enlace")
		echo "Enlace: ${enlace} - Destino: ${destino}" >&3
	done

	echo -e "\n============Auditoria: Enlaces Rotos en el Directorio ($DIRECTORIO)=======================\n"
        cat "${REPORTE}"
	echo -e "\n===========================================================================================\n"
	read -p "Desea eliminar los enlaces? (si/no)" op
	if [[ "$op" == "SI" || "$op" == "si" ]]; then
		for enlace in "${enlaces_rotos[@]}"; do
			rm -iv "$enlace"
		done
		echo "Enlaces eliminados exitosamente"
		rm -f "$REPORTE"
	else
		echo "Operación cancelada. El reporte se conserva en: $REPORTE"
	fi
	exec 3>&-
else
	echo "Error: Debes especificar un directorio con la opción -d."
        echo "Usa $0 -h para ver la ayuda."
	exit 1
fi


