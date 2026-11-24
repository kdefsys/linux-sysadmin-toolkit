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
	echo "Descripcion: Inspecciona un directorio objetivo para detectar enlaces simbolicos rotos (aquellos cuyo destino ya no existe)"
	echo "registra una auditoria con la ruta del enlace y su objetivo, pide confirmacion interactiva al usuario y permite eliminarlos"
	echo "  -d: Directorio objetivo a buscar los enlaces"
	echo "  -h: Muestra esta ayuda"
	exit 0
}

DIRECTORIO="$(pwd)"

while getopts :d:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script"
			exit 1
		  fi
		  ;;
		h)
		  help
		  exit 0
		  ;;
		*)
		  echo "Opcion ingresada no valida"
		  help
		  exit 1
		  ;;
	esac
done

## Seleccionamos los enlaces que estan rotos y los guardamos en un arreglo

mapfile -t enlaces_rotos < <(find "$DIRECTORIO" -type l ! -exec test -e {} \; -print)
CANTIDAD="${#enlaces_rotos[@]}"

if (( CANTIDAD == 0 )); then
	echo "No existen enlaces rotos en el directorio $DIRECTORIO"
	exit 0
fi

REPORTE="${DIRECTORIO}/enlaces_rotos.txt"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
exec 3>>"$REPORTE"

echo "================================================ LIMPIEZA DE ENLACES ROTOS ===========================================" >&3
echo "SCRIPT: ./limpieza_enlaces_rotos.sh" >&3
echo "HOSTNAME: $HOSTNAME" >&3
echo "FECHA: $FECHA" >&3
echo "======================================================================================================================" >&3
## Por cada enlace encontrado, preguntamos al usuario si queremos eliminar o no
for enlace in "${enlaces_rotos[@]}"; do
	ruta_destino="$(readlink -f "$enlace")"
	echo "ENLACE: $enlace   -    RUTA_DESTINO: $ruta_destino" >&3
	read -n 1 -p "Desea eliminar el enlace roto? (Y|n): " op
	echo -e "\n"
	case "$op" in
		y|Y)
		  echo "Opcion de eliminacion seleccionada. Pasamos a eliminar el enlace"
		  if rm -vf "$enlace" 2>/dev/null; then
		  	echo "Enlace $enlace eliminado correctamente"
			echo "(ELIMINADO CORRECTAMENTE)" >&3
		  else
			echo "El enlace no se puedo eliminar correctamente"
		  fi
		  ;;
		*)
		  echo "Continuamos con el proceso normal, no hay eliminacion"
		  ;;
	esac
done

exec 3>&-
echo "Script termino con exito. Vea el reporte en $REPORTE"
