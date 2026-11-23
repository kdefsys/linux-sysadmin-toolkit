#!/bin/bash
##Nombre: usuarios_procesos_top10.sh
##Autor: kdefsys
##Descripción: Este script analiza el sistema para identificar los usuarios que tienen la mayor cantidad de procesos activos en este momento.
##El script debe generar un reporte con el top 10 de usuarios y guardar el resultado en un archivo de texto.
##Uso: ./usuarios_procesos_top10.sh [-h]

function help {
	echo "El script se debe de ejecutar asi: ./usuarios_procesos_top10.sh [-h]"
	echo "Descripcion: Evalua la actividad de procesos en el sistema para determinar cuales usuarios tienen mayor cantidad de procesos"
	echo "activos en el momento de la ejecucion, generando un reporte con los 10 primeros, guardandolos en una pantalla"
	echo "   -h : Imprime esta guia"
}

while getopts :h opt; do
	case "$opt" in
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

REPORTE="top10_usuarios_procesos.txt"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')

mapfile -t usuarios_uid < <(ps -eo uid --no-headers | sort | uniq -c | gawk '{printf "%s:%s\n",$2,$1}' | sort -t ":" -k2,2nr)

CANTIDAD="${#usuarios_uid[@]}"

if (( CANTIDAD == 0 )); then echo "No ningun usuario ejecutando procesos (RARO)"; exit 0; fi

exec 3>>"$REPORTE"

echo "=============================== TOP 10 USUARIOS CON MAS PROCESOS ==================================" >&3
echo "SCRIPT: ./usuarios_procesos_top10.sh" >&3
echo "HOSTNAME: $HOSTNAME" >&3
echo "FECHA: $FECHA" >&3
echo "TOP 10 USUARIOS: " >&3
echo "===================================================================================================" >&3
printf "%s\n" "${usuarios_uid[@]}" | head -n 10 >&3

exec 3>&-

echo "Script finalizo con exito. Vea el reporte en $REPORTE"
