#!/bin/bash
### Nombre: auditoria_avanzada.sh
### Autor: kdefsys
### Descripcion: En los entornos de producción con alta carga de trabajo, es frecuente que procesos o aplicaciones generen inesperadamente archivos masivos en poco tiempo (por
### ejemplo, dumps de memoria descontrolados, trazas de depuración de nivel elevado o respaldos no programados). Estos eventos pueden agotar el almacenamiento disponible en cuestión
### de horas, provocando la caída de servicios críticos. Este script identifica rapidamente archivos grandes creados o modificados recientemente, analizando su impacto en espacio,
### identificando a sus propietarios y detectando de forma automatizada cual es el archivo con mayor peso en el sistema.
### Uso: ./auditoria_avanzada.sh -d <directorio> -s <tamaño_minimo> -m <antiguedad_maxima_dias> [-h]

function help {
	echo "El script se ejecuta asi: ./auditoria_avanzada.sh -d <directorio> -s <tamaño_minimo> -m <antiguedad_maxima_dias> [-h]"
	echo "   -d : Directorio raiz a inspeccionar, si no se ingresa se asumira que es el directorio actual"
	echo "   -s : Tamaño minimo de archivos"
	echo "   -m : Antiguedad maxima de dias"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
TAMANIO=""
DIAS=""

while getopts :d:s:m:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
		 	echo "El directorio ingresado no existe. Saliendo del script..." >&2
			exit 1
		 fi
		 ;;
		s)
		 TAMANIO="$OPTARG"
		 ;;
		m)
		 DIAS="$OPTARG"
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion ingresada invalida"
		 help
		 exit 1
		 ;;
	esac
done

if [[ -n "$TAMANIO" && -n "$DIAS" ]]; then

	FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
	REPORTE="auditoria_disco_avanzada_${FECHA}.log"

	mapfile -t files < <(find "$DIRECTORIO" -type f -size +"$TAMANIO"M -mtime -"$DIAS" -exec stat -c "%s|%b|%y|%u|%n" {} \;)

	CANTIDAD="${#files[@]}"
	if (( CANTIDAD == 0 )); then
		echo "No hay archivos que cumplan esas condiciones"
		exit 0
	fi

	ESPACIO_TOTAL=$(printf "%s\n" "${files[@]}" | cut -d "|" -f 5 | tr '\n' '\0' | xargs -0 du -hc | tail -n 1 | gawk '{print $1}')

	echo "==============================================REPORTE DE AUDITORIA AVANZADA===================================================" > "$REPORTE"
	echo "DIRECTORIO: $DIRECTORIO" >> "$REPORTE"
	echo "FECHA: $FECHA" >> "$REPORTE"
	echo "TAMAÑO MINIMO: ${TAMANIO} MB" >> "$REPORTE"
	echo "DIAS LIMITES DE ULTIMA MODIFICACION: $DIAS" >>"$REPORTE"
	echo "ARCHIVOS ENCONTRADOS: "
	printf "%s\n" "${files[@]}" | sort -t "|" -k 1nr,1nr | tee -a "$REPORTE"
	ARCHIVO_MAYOR="$(printf "%s\n" "${files[@]}" | sort -t "|" -k 1nr,1nr | head -n 1 | gawk -F "|" '{print $5}')"
	echo "CANTIDAD TOTAL DE ARCHIVOS: $CANTIDAD" >> "$REPORTE"
	echo "ESPACIO TOTAL OCUPADO: $ESPACIO_TOTAL" >> "$REPORTE"
	echo "El archivo de mayor tamaño es: $ARCHIVO_MAYOR" >> "$REPORTE"

	echo "Auditoria_avanzada.sh concluida correctamente. Ver el reporte en: $REPORTE"
else
	echo "No se introdujo los argumentos necesarios"
	exit 1
fi
