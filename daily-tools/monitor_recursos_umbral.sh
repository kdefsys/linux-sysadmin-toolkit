#!/bin/bash
### Nombre: monitor_recursos_umbral.sh
### Autor: kdefsys
### Descripción: El script lee umbrales de consumo desde un archivo de configuración externo, evalua el uso global actual de CPU y memoria RAM en el sistema
### y en caso de superar los limites, registra una alerta, junto con los procesos que mas recursos estan consumiendo
### Uso: ./monitor_recursos_umbral.sh -f <file>

## =========================================================
##		FUNCION HELP
## =========================================================

function help {
	echo "El script se ejecuta asi: ./monitor_recursos_umbral.sh -f <file>"
	echo "DESCRIPCION: Lee umbrales de consumo de CPU y memoria RAM desde un archivo de configuracion, mide el uso global actual"
	echo "de ambos recursos en el sistema, evalua si se superan los limites configurados y registra en un archivo de bitacora las"
	echo "alertas correspondientes junto con los principales procesos consumidores cuando corresponde"
	echo "   -f <file> : Introducir el archivo donde se encuentra el umbral"
	echo "   -h : Imprime esta guia"
}

file=""

while getopts :f:h opt; do
	case "$opt" in
		f)
		  file="$(realpath "$OPTARG")"
		  if [[ ! -f "$file" ]]; then
			echo "El archivo ingresado no existe. Saliendo del script" >&2
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

if [[ -z "$file" ]]; then echo "No se paso ningun archivo"; exit 1; fi

MAX_CPU="$(gawk '{print $1}' "$file")"
MAX_RAM="$(gawk '{print $2}' "$file")"

## ==============================================================================================================
## ======================================== MEDICION GLOBAL DE LA CPU ===========================================
## ==============================================================================================================

read -r  _ user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 _ < /proc/stat
total1=$((user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1 + steal1))
idle1_total=$((idle1 + iowait1))

sleep 1

read -r  _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 _ < /proc/stat
total2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2))
idle2_total=$((idle2 + iowait2))

diff_total=$((total2 - total1))
idle_total=$((idle2_total - idle1_total))

CPU_GLOBAL=$(( 100 * (diff_total - idle_total) / diff_total ))

## =============================================================================================================
## ========================================= MEDICION GLOBAL DE LA RAM =========================================
## =============================================================================================================

RAM_TOTAL=$(grep MemTotal /proc/meminfo | gawk '{print $2}')
RAM_AVAIL=$(grep MemAvailable /proc/meminfo | gawk '{print $2}')

RAM_GLOBAL=$(( 100 * (RAM_TOTAL - RAM_AVAIL) / RAM_TOTAL ))

## =============================================================================================================
## =============================================== REPORTE =====================================================
## =============================================================================================================

REPORTE="alertas_recursos.log"
FECHA=$(date '+%Y-%m-%d %H-%M-%S')
exec 3>>"$REPORTE"

if (( CPU_GLOBAL >= MAX_CPU )); then
	echo "[ALERTA CPU] Uso actual: $CPU_GLOBAL% (Limite: $MAX_CPU%)" >&3
fi

if (( RAM_GLOBAL >= MAX_RAM )); then
	echo "[ALERTA RAM] Uso actual: $RAM_GLOBAL% (Limite: $MAX_RAM%)" >&3
fi

if (( CPU_GLOBAL >= MAX_CPU || RAM_GLOBAL >= MAX_RAM )); then
	ps -eo user,pid,pcpu,pmem,stat,cmd --no-headers | sort -k3,3nr -k4,4nr | head -n 5 >&3
else
	echo "Todo OK, no se excede ni en CPU ni en RAM" >&3
fi

exec 3>&-
