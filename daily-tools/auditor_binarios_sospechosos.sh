#!/bin/bash
### Nombre: auditor_binarios_sospechosos.sh
### Autor: kdefsys
### Descripcion: El script examina un directorio objetivo por defecto (/usr/bin o el que el operador indique) en busca de archivos ejecutables que tengan configurados bits
### especiales de privilegios (SUID o SGID), o permisos globales de escritura (world-writable), generando un informe clasificado y un archivo de alerta si detecta anomalías.
### Uso: sudo ./auditor_binarios_sospechosos.sh -d <directorio_objetivo> [-h]

function help {
	echo "El script debe de ejecutarse asi: sudo ./auditor_binarios_sospechosos.sh -d <directorio_objetivo> [-h]"
	echo "   -d : Directorio objetivo a analizar"
	echo "   -h : Imprime esta guia"
}

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="auditoria_privilegios_${FECHA}.log"

function salida_rapida {
	echo "El script fue interrumpido" >&2
	if [[ -f "$REPORTE" ]]; then
		echo "Cerrando el descriptor de archivo asignado al reporte" >&2
		exec 3>&-
	fi
	exit 1
}
trap salida_rapida SIGINT SIGTERM

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con permiso de superusuario" >&2
	echo "Saliendo del script" >&2
	exit 1
fi

APLICACION="NO"

while getopts :d:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
			DIRECTORIO="/usr/bin"
		 fi
		 APLICACION="SI"
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

if [[ "$APLICACION" == "NO" ]]; then
	echo "No se puede ejecutar el script porque no se introdujo la opcion -d" >&2
	help
	exit 1
fi

##---------------------------------------------------------------------------------------------------
## COMENZAMOS A BUSCAR ARCHIVOS CON PERMISOS ESPECIALES Y A ARCHIVOS CON PERMISOS WORLD-WRITABLES
##---------------------------------------------------------------------------------------------------

mapfile -t files_especiales < <(find "$DIRECTORIO" -type f \( -perm -4000 -o -perm -2000 \))
mapfile -t files_ww < <(find "$DIRECTORIO" -type f -perm -o=w -print)

if [[ "${#files_especiales[@]}" -eq 0 && "${#files_ww[@]}" -eq 0 ]]; then
	echo "No se encontraron archivos especiales"
	echo "El directorio esta limpio"
else
	exec 3>>"$REPORTE"

	if [[ "${#files_ww[@]}" -gt 0 ]]; then
		echo "[ALERT] RIESGO CRITICO DE ESCALADA DE PRIVILEGIOS: Se detectaron binarios modificables por cualquier usuario." >&2
	fi

	echo -e "\n============================================= REPORTE DE BINARIOS SOSPECHOSOS ======================================================\n" >&3
	echo "SCRIPT: $(dirname "${BASH_SOURCE[0]}")" >&3
	echo "DIRECTORIO OBJETIVO: $DIRECTORIO" >&3
	echo "FECHA: $FECHA" >&3
	echo "------------------------------------------------------------------------------------------------------------------------------------------" >&3
	echo "LISTADO DETALLADO DE BINARIOS CON SUID/SGID: " >&3
	printf "%s\n" "${files_especiales[@]}" | xargs stat -c "%a - %U:%G - %n" >&3
	echo "--------------------------------------------------------------------------------------------------------------------------------------------" >&3
	echo "LISTADO DETALLADO DE BINARIOS CON ESCRITURA PARA OTROS" >&3
	printf "%s\n" "${files_ww[@]}" >&3
	echo "--------------------------------------------------------------------------------------------------------------------------------------------" >&3
	echo "TOTAL DE ARCHIVOS BINARIOS CON PERMISOS ESPECIALES: ${#files_especiales[@]}" >&3
	echo "TOTAL DE ARCHIVOS BINARIOS WORLD WRITABLE: ${#files_ww[@]}" >&3
	exec 3>&-
fi

echo "auditor_binarios_sospechosos.sh finalizado, puede ver el reporte en $REPORTE"
echo "Fin del script"
