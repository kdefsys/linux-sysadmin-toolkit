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
	echo "DESCRIPCION: Detecta archivos regulares voluminosos modificados recientemente dentro de un directorio, calcula el espacio"
	echo "total que ocupan, ordena los hallazgos de mayor a menor tamaño. Indentifica el archivo mas pesado y guarda en un reporte"
	echo "   -d : Directorio raiz a inspeccionar, si no se ingresa se asumira que es el directorio actual"
	echo "   -s : Tamaño minimo de archivos"
	echo "   -m : Antiguedad maxima de dias"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
TAMANIO=""
ANTIGUEDAD=""

while getopts :d:s:m:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		s)
		  TAMANIO="$OPTARG"
		  if ! [[ "$TAMANIO" =~ ^[0-9]+$ ]]; then
			echo "El valor ingresado como tamaño, no es un numero. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		m)
		  ANTIGUEDAD="$OPTARG"
		  if ! [[ "$ANTIGUEDAD" =~ ^[0-9]+$ ]]; then
			echo "El valor ingresado como tamaño, no es un numero. Saliendo del script" >&2
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

if [[ -z "$ANTIGUEDAD" || -z "$TAMANIO" ]]; then
	echo "No hay parametros necesarios, para que se realize el script" >&2
	exit 1
fi

mapfile -t files < <(find "$DIRECTORIO" -type f -mtime -"$ANTIGUEDAD" -size +"$TAMANIO"M -exec stat -c '%s|%b|%y|%u|%n' {} \;)

CANTIDAD="${#files[@]}"

if (( CANTIDAD == 0 )); then
	echo "El directorio $DIRECTORIO no contiene archivos con esas caracteristicas"
	exit 0
fi

ESPACIO_TOTAL="$(printf "%s\n" "${files[@]}" | cut -d "|" -f 5 | tr '\n' '\0' | xargs -0 du -hc | tail -n 1 | gawk '{print $1}')"
FILE_MAYOR_TAMANIO="$(printf "%s\n" "${files[@]}" | cut -d "|" -f 1,5 | sort -t "|" -k1,1nr | head -n 1 | gawk -F "|" '{print $2}')"

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="auditoria_disco_avanzada_${FECHA}.log"
>"$REPORTE"
exec 3>>"$REPORTE"

echo "=================================== AUDITORIA DE DISCO AVANZADA ================================" >&3
echo "SCRIPT: auditoria_avanzada.sh" >&3
echo "DIRECTORIO OBJETIVO: $DIRECTORIO " >&3
echo "LIMITE DE TAMAÑO: $TAMANIO" >&3
echo "ANTIGUEDAD: $ANTIGUEDAD" >&3
echo "HOSTNAME: $HOSTNAME" >&3
echo "USUARIO: $USER" >&3
echo "FECHA: $FECHA" >&3
echo "================================================================================================" >&3
echo "Los archivos encontrados que cumplen esa caracteristicas son:" >&3

printf "%s\n" "${files[@]}" | sort -t "|" -k1,1nr >&3

echo -e "\nLa cantidad de archivos totales encontrados fueron: $CANTIDAD \n" >&3
echo "El espacio total ocupado es: $ESPACIO_TOTAL" >&3
echo "EL archivo con mayor tamaño es: ${FILE_MAYOR_TAMANIO}" >&3

echo "================================================================================================" >&3

exec 3>&-
echo "El script finalizo con exito. Ver el reporte en $REPORTE"
