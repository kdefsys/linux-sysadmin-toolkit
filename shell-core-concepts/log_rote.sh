#!/bin/bash
### Nombre: log_rote.sh
### Autor: kdefsys
### Descripcion: Los servidores web y de aplicaciones generan archivos de traza (.log) a un ritmo acelerado. Si no se realiza un mantenimiento adecuado, estos archivos consumen la
### capacidad del almacenamiento principal, degradando el rendimiento general del sistema. Para optimizar el espacio sin perder información histórica para auditorías, el equipo de
### operaciones requiere un script automatizado que realice la rotación, compresión y archivado en histórico de los registros antiguos, manteniendo limpio el directorio activo.
### Uso: ./log_rote.sh -d <directorio> -m <dias> [-h]

function help {
	echo "El script se debe ejecutar asi: ./log_rote.sh -d <directorio> -m <dias> [-h]"
	echo "   -d : La ruta del directorio objetivo donde residen los logs activos. Si no se introduce esta bandera, se asume el directorio actual"
	echo "   -m : La antiguedad minima en dias para rotas los archivos"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
DIAS=""

while getopts :d:m:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then echo "El directorio ingresado no existe. Saliendo del script" >&2; exit 1; fi
		 ;;
		m)
		 DIAS="$OPTARG"
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion ingresada invalida" >&2
		 help
		 exit 1
		 ;;
	esac
done

if [[ -z "$DIAS" ]]; then
	echo "No se introdujo el argumento obligatorio (-m <dias>)" >&2
	help
	exit 1
fi

if ! [[ "$DIAS" =~ ^[0-9]+$ ]]; then
	echo "Error: El argumento -m debe ser un número entero positivo." >&2
	exit 1
fi

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="rotacion_ejecucion.log"

echo "===================================REPORTE DE ROTACION DE LOGS A COMPRIMIDOS=============================================================" > "$REPORTE"
echo "DIRECTORIO $DIRECTORIO" >> "$REPORTE"
echo "FECHA: $FECHA" >> "$REPORTE"
echo "LISTA DE ARCHIVOS ENCONTRADOS QUE SEAN *access*.log o *error*.log" >> "$REPORTE"

mapfile -t files < <(find "$DIRECTORIO" -regextype posix-extended -regex ".*/.*(access|error).*\.log$" -mtime +"$DIAS")
CANTIDAD="${#files[@]}"

if (( CANTIDAD == 0 )); then
	echo "No hay archivos dentro del directorio $DIRECTORIO que cumplan estas caracteristicas" >> "$REPORTE"
	exit 0
fi
printf "%s\n" "${files[@]}" >> "$REPORTE"
echo -e "\nLa lista encontrada fue: \n"
printf "%s\n" "${files[@]}"

read -p "Desea pasar a la operacion (s|n): " op
case "$op" in
	s|S)
		DIRECTORIO_SALIDA="${DIRECTORIO}/archive_${FECHA}"
	        if [[ ! -d "$DIRECTORIO_SALIDA" ]]; then
			mkdir -p "$DIRECTORIO_SALIDA"
			echo "Se creo correctamente la carpeta historica $DIRECTORIO_SALIDA" >> "$REPORTE"
		fi
		ESPACIO_ANTES="$(du -hc "$DIRECTORIO" | tail -n 1 | gawk '{print $1}')"

		printf "%s\0" "${files[@]}" | xargs -0 gzip 2>/dev/null

		archivos_pendientes=0
		for file in "${files[@]}"; do
			if [[ -f "$file" ]]; then
				((archivos_pendientes++))
			fi
		done
		if (( archivos_pendientes > 0 )); then
			echo "Error: Al menos $archivos_pendientes archivos no se eliminaron al comprimirse." >&2
	    		exit 1
		fi

		echo "CANTIDAD DE ARCHIVOS COMPRIMIDOS: $CANTIDAD" >> "$REPORTE"
		echo "Compresion terminada"

		for file in "${files[@]}"; do
			if [[ -f "${file}.gz" ]]; then
				mv "${file}.gz" "$DIRECTORIO_SALIDA/" 2>/dev/null
			fi
		done
		ESPACIO_AHORA="$(du -hc "$DIRECTORIO" | tail -n 1 | gawk '{print $1}')"

		echo "Compresion terminada. Los archivos comprimidos fueron enviados al directorio: $DIRECTORIO_SALIDA correctamente" >> "$REPORTE"
		echo -e "\n\n======================================================================\n" >> "$REPORTE"
		echo "Espacio ocupado antes de la compresion: $ESPACIO_ANTES" >> "$REPORTE"
		echo "Espacio ocupado despues de la compresion: $ESPACIO_AHORA" >> "$REPORTE"

		;;
	*)
		echo "Se cancelo la operacion"
		;;
esac
