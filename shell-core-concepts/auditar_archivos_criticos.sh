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
	echo "Se busca unicamente archivos regulares, que tengan extensiones tipicas de configuracion o logs ( .conf, .cnf o .log), que hayan sido modificados en las ultimas 24 horas"
	echo "y ademas excluye cualquier archivo que se encuentre dentro de carpetas temporales (rutas que contengan /tmp)"
	echo "Se debe ejecutar: ./auditar_archivos_criticos.sh -d <directorio> [-h]"
	echo "   -d : Directorio objetivo que se va a auditar, si no se introduce se asume que es el directorio actual"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
while getopts :d:h opt; do
	case "$opt" in
		d)
		 if [[ -d "$OPTARG" ]]; then
			DIRECTORIO="$OPTARG";
		 else
			echo "El directorio $OPTARG no existe, saliendo del script ..." >&2
			exit 1
		 fi
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion invalida"
		 help
		 exit 1
		 ;;
	esac
done

mapfile -t files < <(find "$DIRECTORIO" -type f ! -path "*/tmp/*" -regextype posix-extended -regex "(.*\.conf$|.*\.cnf$|.*\.log$)" -mtime -1 -exec stat -c "%s|%y|%n" {} \; \
	| gawk -F "|" 'BEGIN{OFS="\t"} {print $1, $2, $3}')

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="reporte_auditoria_archivos_criticos_${FECHA}.log"
exec 3>>"$REPORTE"

echo -e "TAMAÑO\t\tFECHA_MODIFICACION\t\tRUTA\n" >&3
printf "%s\n" "${files[@]}" >&3

echo "Auditoria completada con exito. Reporte generado en: $REPORTE"
exec 3>&-
