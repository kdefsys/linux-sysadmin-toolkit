#!/bin/bash
### Nombre: revinculacion_inteligente.sh
### Autor: kdefsys
### Descripcion: La reestructuración de directorios o migración de archivos suele romper enlaces simbolicos existentes.
### En lugar de limitarse a borrar los enlaces dañados, este script es una herramienta de "autorrecuperacion" que intente
### localizar archivos huerfanos con el mismo nombre dentro del sistema para reparar la vinculacion automaticamente, tambien
### ofrece la opcion de borrarlos o simplemente ignorarlos.
### Uso: ./revinculacion_inteligente.sh -d <directorio_objetivo> -f <ruta_destino> -h [help]

function help {
	echo "El script debe ejecutarse asi: ./revinculacion_inteligente.sh -d <directorio_objetivo> -f <ruta_destino> -h"
	echo "   -d: El directorio objetivo donde vamos a buscar los enlaces simbólicos rotos"
	echo "   -f: La ruta destino donde vamos a guardar nuestro log de auditoria"
	echo "   -h: Imprime esta ayuda"
}

###=========================================================
###		MENU DE GETOPTS
###=========================================================

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
		 echo "Opcion invalida en los argumentos"
		 exit 1
		 ;;
	esac
done

function menu {
	local -n arreglo_enlaces=$1

	for enlace in "${arreglo_enlaces[@]}"; do
		read -p "Enlace: $enlace . Que desea hacer? REPARAR (R), ELIMINAR (E) o IGNORAR (I): " op
		case "$op" in
			R|r)
			 local destino_enlace="$(readlink "$enlace")"
			 local nombre_archivo="${destino_enlace##*/}"
			 destino_nuevo="$(find / -name "$nombre_archivo" 2>/dev/null | head -n 1)"
			 if [[ -z "$destino_nuevo" ]]; then
			 	echo "No se encontro coincidencias con el archivo anterior, no es posible redireccionar el enlace"
				continue
			 fi
			 if ln -sf "${destino_nuevo}" "$enlace" 2>/dev/null; then
			 	echo "El enlace $enlace fue reparado y ahora apunta a esta nueva direccion $destino_nuevo" >&3
			 else
				echo "El enlace $enlace no pudo ser reparado correctamente"
			 fi
			 ;;
			E|e)
			 echo "Procedemos a eliminar el enlace roto"
			 if rm -f "$enlace" 2>/dev/null; then
			 	echo "El enlace $enlace fue eliminado correctamente del sistema" >&3
			 else
				echo "El enlace $enlace no pudo ser eliminado correctamente"
			 fi
			 ;;
			I|i)
			 echo "Ignoramos el enlace $enlace"
			 echo "El enlace: $enlace fue ignorado" >&3
			 ;;
			*)
			 echo "Opción inválida, no se puede procesar ninguna operacion"
			 ;;
		esac
	done
}

if [[ "$OPERACION" == "SI" ]]; then
	mapfile -t enlaces_rotos < <(find "$DIRECTORIO" -type l ! -exec test -e {} \; -print)
	if [[ "${#enlaces_rotos[@]}" -eq 0 || -z "${enlaces_rotos[0]}" ]]; then
		echo "No existen enlaces rotos en el directorio $DIRECTORIO"
	else
		FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
		REPORTE="${RUTA_DESTINO}/auditoria_enlaces_${FECHA}.log"
		exec 3>>"$REPORTE"
		echo "============================AUDITORIA_ENLACES_ROTOS===============================" >&3
		for enlace in "${enlaces_rotos[@]}"; do
			echo "ENLACE: $enlace  - RUTA: $(readlink "$enlace")" >&3
		done
		echo -e "\n\n==============================PROCEDEMOS A LISTAR LA APLICACION============================" >&3
		menu enlaces_rotos
		echo "==================================================================================" >&3
		exec 3>&-
	fi
else
	echo "No se pudo ejecutar el script, porque no introdujo su directorio objetivo"
	help
	exit 1
fi
