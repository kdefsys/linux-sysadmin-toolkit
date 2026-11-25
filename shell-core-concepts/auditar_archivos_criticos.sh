#!/bin/bash
### Nombre: auditar_archivos_criticos.sh
### Autor: kdefsys
### Descripción: En un entorno de servidores compartidos, los administradores de sistemas necesitan mantener bajo control los cambios no autorizados o inesperados. Es habitual que
### archivos de configuración o de registro (logs) crezcan de forma desmedida, cambien sus permisos o sean modificados fuera del horario laboral habitual.
### Este script realiza una auditoria periodica de archivos criticos dentro de una ruta especificada
### Se busca unicamente archivos regulares, que tengan extensiones tipicas de configuracion o logs ( .conf, .cnf o .log), que hayan sido modificados en las ultimas 24 horas
### y ademas excluye cualquier archivo que se encuentre dentro de carpetas temporales (rutas que contengan /tmp)
### Uso: ./auditar_archivos_criticos.sh -d <directorio> [-h]

function help {
	echo "Este script realiza una auditoria periodica de archivos criticos dentro de una ruta especificada"
	echo "DESCRIPCION: Se busca unicamente archivos regulares, que tengan extensiones tipicas de configuracion o logs ( .conf, .cnf o"
	echo " .log), que hayan sido modificados en las ultimas 24 horas"
	echo "y ademas excluye cualquier archivo que se encuentre dentro de carpetas temporales (rutas que contengan /tmp)"
	echo "Se debe ejecutar: ./auditar_archivos_criticos.sh -d <directorio> [-h]"
	echo "   -d : Directorio objetivo que se va a auditar, si no se introduce se asume que es el directorio actual"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"

while getopts :d:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio objetivo ingresado no existe. Saliendo del script" >&2
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

## =========================================================================================
## Buscamos los archivos .conf, .cnf o .log que han sido modificados en las ultimas 24 horas
## pero que no pertenecen a la ruta /tmp como intermedio osea (ejemplo: /tmp/)
## =========================================================================================

mapfile -t files < <(find "$DIRECTORIO" -type f -not -path "*/tmp*" -regextype posix-extended -regex "(.*\.conf$|.*\.cnf$|.*\.log$)" -mtime -1 \
	-exec stat -c '%s|%y|%n' {} \; 2>/dev/null \
	| gawk -F "|" 'BEGIN{OFS="\t"}{ruta="";for(i=3;i<=NF;++i) ruta=(i==3 ? "" : ruta " ") $i; print $1, $2, ruta}')

CANTIDAD="${#files[@]}"

if (( CANTIDAD == 0 )); then
	echo "No hay archivos que cumplen esa caracteristica dentro del directorio objetivo: $DIRECTORIO"
	exit 0
fi

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="reporte_auditoria_archivos_criticos_${FECHA}.log"

>"$REPORTE"
exec 3>>"$REPORTE"

echo "=================================================== REPORTE ARCHIVOS CRITICOS ======================================" >&3
echo "SCRIPT: auditar_archivos_criticos.sh" >&3
echo "FECHA: $FECHA" >&3
echo "HOSTNAME: $HOSTNAME" >&3
echo "Los archivos .conf, .cnf o .log modificados en las ultimas 24 horas, que no pertenecen a subrutas /tmp/ son: " >&3
echo -e "TAMAÑO\t\tFECHA ULTIMA MODIFICACION\t\tRUTA\n" >&3

printf "%s\n" "${files[@]}" >&3

exec 3>&-

echo "Script concluyó con exito. Ver el reporte en: $REPORTE"
