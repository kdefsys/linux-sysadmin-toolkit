#!/bin/bash
### Nombre: log_rote.sh
### Autor: kdefsys
### Descripcion: Los servidores web y de aplicaciones generan archivos de traza (.log) a un ritmo acelerado. Si no se realiza un mantenimiento adecuado, estos archivos consumen la
### capacidad del almacenamiento principal, degradando el rendimiento general del sistema. Para optimizar el espacio sin perder información histórica para auditorías, el equipo de
### operaciones requiere un script automatizado que realice la rotación, compresión y archivado en histórico de los registros antiguos, manteniendo limpio el directorio activo.
### Uso: ./log_rote.sh -d <directorio> -m <dias> [-h]

function help {
	echo "El script se debe ejecutar asi: ./log_rote.sh -d <directorio> -m <dias> [-h]"
	echo "DESCRIPCION: Identifica archivos de log de acceso o de error que superen cierta antiguedad en dias, solicita confirmacion"
	echo "al operador, comprime los archivos seleccionados, los mueve a un directorio historico y registra metricas de espacio antes"
	echo "y despues del proceso"
	echo "   -d : La ruta del directorio objetivo donde residen los logs activos. Si no se introduce esta bandera, se asume el directorio actual"
	echo "   -m : La antiguedad minima en dias para rotas los archivos"
	echo "   -h : Imprime esta guia"
}

function impresion_archivo {
	local file="$1"
	local can_arreglo="$2"
	local espacio_antes="$3"
	local espacio_despues="$4"

	echo "======================================== ROTACION DE LOGS ==============================" >>"$file"
	echo "DIRECTORIO HISTORICO: $DIRECTORIO_HISTORICO" >> "$file"
	echo "CANTIDAD ANTES DE LA ROTACION: $espacio_antes" >> "$file"
	echo "CANTIDAD DE LOGS_ROTADOS: $can_arreglo" >> "$file"
	echo "CANTIDAD DESPUES DE LA ROTACION: $espacio_despues" >> "$file"
	echo "========================================================================================" >>"$file"

}

DIRECTORIO="$(pwd)"
DIAS=""

while getopts :d:m:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		m)
		  DIAS="$OPTARG"
		  if ! [[ "$DIAS" =~ ^[0-9]+$ ]]; then
			echo "El valor ingresado como antiguedad minima en dias no es un valor numerico. Saliendo del script" >&2
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

if [[ -z "$DIAS" ]]; then
	echo "Argumentos insuficientes. Saliendo del script" >&2
	help
	exit 1
fi

## ======================================================================================
## Busca archivos .log con patrones que incluyan access o error antes de .log
## ======================================================================================

mapfile -t files < <(find "$DIRECTORIO" -type f -regextype posix-extended -regex ".*(access|error).*\.log$"   -mtime +"$DIAS" )

CANTIDAD="${#files[@]}"
if (( CANTIDAD == 0 )); then
	echo "No se encontraron archivos con esas caracteristicas en el directorio $DIRECTORIO"
	exit 0
fi

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="rotacion_ejecucion.log"

echo "Los archivos encontrados son:"
printf "%s\n" "${files[@]}"

>"$REPORTE"
echo "======================================= LOG ROTE ========================================" >> "$REPORTE"
echo "SCRIPT: log_rote.sh" >> "$REPORTE"
echo "HOSTNAME: $HOSTNAME" >> "$REPORTE"
echo "DIRECTORIO OBJETIVO: $DIRECTORIO" >> "$REPORTE"
echo "USUARIO: $USER" >> "$REPORTE"
echo "DIAS MINIMOS: $DIAS" >> "$REPORTE"
echo "FECHA: $FECHA" >> "$REPORTE"
echo "=========================================================================================" >> "$REPORTE"
echo "Los archivos encontrados son: " >> "$REPORTE"
printf "%s\n" "${files[@]}" >> "$REPORTE"
echo "=========================================================================================" >> "$REPORTE"

read -n1 -p "OPERAMOS LA ROTACION? (Y|N): " op

echo -e "\n"

case "$op" in
	y|Y)
	  FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
	  DIRECTORIO_HISTORICO="${DIRECTORIO}/archive_${FECHA}"
	  if mkdir -p "${DIRECTORIO_HISTORICO}" 2>/dev/null; then
		echo "Se creo correctamente el directorio historico $DIRECTORIO_HISTORICO"
		ESPACIO_DIRECTORIO_OBJETIVO="$(du -hc "${DIRECTORIO}" | tail -n 1 | gawk '{print $1}')"
		echo "El espacio antes de la ejecucion es: ${ESPACIO_DIRECTORIO_OBJETIVO}"
		if printf "%s\0" "${files[@]}" | xargs -0 gzip  2>/dev/null; then
			echo "La operacion de comprimir los archivos se completo con exito"
			## Verificacion si hay archivos residuales
			for file in "${files[@]}"; do
				if [[ -e "$file" ]]; then
					echo "Si hay archivo residual. Saliendo del script" >&2
					exit 1
				fi
			done
			for file in "${files[@]}"; do
				ruta="${file}.gz"
				mv -n "${ruta}" "${DIRECTORIO_HISTORICO}" 2>/dev/null
			done
			ESPACIO_DIRECTORIO_OBJETIVO_2="$(du -hc "$DIRECTORIO" | tail -n 1 | gawk '{print $1}')"
			impresion_archivo "$REPORTE" "$CANTIDAD" "$ESPACIO_DIRECTORIO_OBJETIVO" "$ESPACIO_DIRECTORIO_OBJETIVO_2"
		else
			echo "No se pudo comprimir correctamente" >&2
			exit 1
		fi
	  else
		echo "Fallo la creacion del directorio historico. Saliendo del script" >&2
		exit 1
	  fi
	  ;;
	*)
	  echo "Cancelamos la operacion"
	  ;;
esac

echo "El script finalizo correctamente. Ver el reporte en $REPORTE"
