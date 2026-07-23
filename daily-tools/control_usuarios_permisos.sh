#!/bin/bash
### Nombre: control_usuarios_permisos.sh
### Autor: kdefsys
### Descripción: Este script audita el sistema en dos niveles: identificando los usuarios que utilizan la consola /bin/bash como shell por defecto y
### detectando archivos dentro de un directorio objetivo que carezcan de permisos de lectura para su grupo asignado. Además genera reportes individuales
### y un resumen final en consola.
### Uso: ./control_usuarios_permisos -u -d <directorio> -h [help]

OPERACION_DIRECTORIO="NO"
OPERACION_USUARIOS="NO"

function help {
	echo "Uso: $0 -u -d <directorio> [-h]"
        echo "  -d: Directorio objetivo a buscar los archivos que no tienen permiso de lectura para el grupo dueño"
	echo "  -u: Activa la operación de buscar usuarios con shell por defecto (/bin/bash)"
        echo "  -h: Muestra esta ayuda"
        exit 0
}

while getopts :ud:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			DIRECTORIO="$(pwd)"
		  fi
		  OPERACION_DIRECTORIO="SI"
		  ;;
		u)
		  OPERACION_USUARIOS="SI"
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

if [[ "$OPERACION_DIRECTORIO" == "SI" || "$OPERACION_USUARIOS" == "SI" ]]; then
	FECHA=$(date '+%Y-%m-%d %H-%M-%S')
	echo -e "\n==================================REPORTE GENERAL DEL SCRIPT ($FECHA)============================\n"
fi

if [[ "$OPERACION_DIRECTORIO" == "SI" ]]; then
	REPORTE_FILES="archivos_no_lectura.txt"
	exec 3>"$REPORTE_FILES"
	echo "==================Archivos que no tienen permiso de lectura en grupo ===========================" >&3
	mapfile -t archivos_no_lectura < <(find "$DIRECTORIO" -type f ! -perm -g=r 2>/dev/null)
	if [[ "${#archivos_no_lectura[@]}" -eq 0 ]]; then
		echo "No hay archivos que no tengan el permiso de lectura para su grupo dueño"
		exec 3>&-
		rm -f "$REPORTE_FILES"
	else
		printf "%s\n" "${archivos_no_lectura[@]}" >&3
		cat "$REPORTE_FILES"
		echo -e "\nCANTIDAD TOTAL: ${#archivos_no_lectura[@]}"
		exec 3>&-
	fi
fi

if [[ "$OPERACION_USUARIOS" == "SI" ]]; then
	REPORTE_USUARIOS="usuarios_bash.txt"
	exec 3>"$REPORTE_USUARIOS"
	echo "===================USUARIOS CON SHELL=/bin/bash===================" >&3
	mapfile -t usuarios_indicados < <(cat "/etc/passwd" | gawk -F : '$7~/^\/bin\/bash/{print $1}')
	if [[ "${#usuarios_indicados[@]}" -eq 0 ]]; then
		echo "No hay usuarios cuyo shell por defecto sea: /bin/bash"
		exec 3>&-
		rm -f "$REPORTE_USUARIOS"
	else
		printf "%s\n" "${usuarios_indicados[@]}" >&3
		cat "${REPORTE_USUARIOS}"
		echo -e "\nCANTIDAD TOTAL: ${#usuarios_indicados[@]}"
		exec 3>&-
	fi
fi
