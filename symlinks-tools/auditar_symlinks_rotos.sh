#!/bin/bash
### Nombre: auditar_symlinks_rotos.sh
### Autor: kdefsys
### Descripción: Los enlaces simbólicos pueden quedar "huérfanos" o "rotos" cuando el archivo o directorio de destino es movido o eliminado
### Este script escanea rutas, identifica estos enlaces dañados, genera un informe de registro (log) y permite limpiarlos de forma segura
### Uso: ./auditar_symlinks_rotos.sh -d <directorio_a_examinar>  -f <ruta_destino_log> -h [help]

##=================================================================
##		FUNCIÓN HELP
##=================================================================

function help {
	echo " GUIA"
	echo "  -d : directorio base a examinar"
	echo "  -f : ruta de destino del archivo .log"
	echo "  -h : esta ayuda"
}

##=================================================================================
##			MENU DE GETOPTS
##=================================================================================

OPERACION="NO"
RUTA_DESTINO="$(pwd)"

while getopts :d:f:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
			DIRECTORIO="$(pwd)"
		 fi
		 OPERACION="SI"
		 ;;
		f)
		 RUTA_DESTINO="$OPTARG"
		 if [[ ! -d "$RUTA_DESTINO" ]]; then
			RUTA_DESTINO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
		 fi
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opción de argumento inválida"
		 help
		 exit 1
		 ;;
	esac
done

if [[ "$OPERACION" == "SI" ]]; then
	FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
	REPORTE="${RUTA_DESTINO}/enlaces_rotos_${FECHA}.log"
	exec 3>>"$REPORTE"
	echo -e "============================ REPORTE DE ENLACES ROTOS EN EL DIRECTORIO $DIRECTORIO ==================================" >&3
	mapfile -t enlaces_rotos < <(find "$DIRECTORIO" -type l ! -exec test -e {} \; -print)
	CANTIDAD_ENLACES_ROTOS="${#enlaces_rotos[@]}"
	if [[ "$CANTIDAD_ENLACES_ROTOS" -eq 0 || -z "${enlaces_rotos[0]}" ]]; then
		echo "No se encontraron enlaces rotos en el directorio: $DIRECTORIO" >&3
	else
		echo "Si se encontraron enlaces rotos en el directorio: $DIRECTORIO" >&1
		echo "Lista de los enlaces rotos encontrados en $DIRECTORIO" >&3
		for enlace in "${enlaces_rotos[@]}"; do
			echo "ENLACE: $enlace	RUTA: $(readlink -f "$enlace")" >&3
		done
		read -p "Desea eliminarlos (s/n): " op
		if [[ "$op" == "s" || "$op" == "S" ]]; then
			echo "Procedemos a eliminar los enlaces rotos del directorio $DIRECTORIO"
			echo -e "Se activo el proceso de eliminarlos\nLista de eliminacion" >&3
			printf "%s\n" "${enlaces_rotos[@]}" | xargs rm -fv >&3
			echo "Proceso de eliminacion terminado..."
		else
			echo "Se cancelo la operacion de eliminar a los enlaces rotos del directorio $DIRECTORIO"
		fi
	fi
	echo "EL REPORTE FINAL FUE: "
	cat "$REPORTE"
	exec 3>&-
else
	echo "No se puede realizar ninguna operación porque no introdujo el directorio a examinar"
	help
	exit 1
fi
