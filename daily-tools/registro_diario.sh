#!/bin/bash
### Nombre: registro_diario.sh
### Autor: kdefsys
### Descripcion: Este script automatiza el registro de una tarea completada junto con la marca de tiempo
### exacta del momento de ejecucion en un archivo de registro (log)
### Uso: ./registro_diario.sh

function help {
	echo "Uso del script: ./registro_diario.sh [-h]"
	echo -e "Descripcion: Este script automatiza el registro de una tarea completada junto con la marca de tiempo exacta"
	echo -e "del momento de ejecucion en un archivo de registro (log)\n"
	echo "   -h: Muestra esta guía"
}

while getopts :h opt; do
	case "$opt" in
		h)
		  help
		  ;;
		*)
		  echo "Opcion ingresada no valida"
		  help
		  exit 1
		  ;;
	esac
done

REGISTRO="actividad_diaria.log"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
exec 3>>"$REGISTRO"

printf "%s - Tarea Completada\n" "$FECHA" >&3

echo "El registro fue completado en el archivo $REGISTRO"
echo "============================================= RESUMEN ==========================================="
echo "El contenido del registro es:"
echo -e "=================================================================================================\n"

exec 3>&-
cat "$REGISTRO"
