#!/bin/bash
### Nombre: monitor_recursos_umbral.sh
### Autor: kdefsys
### Descripción: El script lee umbrales de consumo desde un archivo de configuración externo, evalua el uso global actual de CPU y memoria RAM en el sistema
### y en caso de superar los limites, registra una alerta, junto con los procesos que mas recursos estan consumiendo
### Uso: ./monitor_recursos_umbral.sh <file>

if [[ "$#" -ne 1 ]]; then
	echo "Argumentos invalidos"
	echo "Debe ejecutarse así: $0 <file>"
	exit 1
fi

RUTA_FILE_UMBRAL="$1"
REPORTE="alertas_recursos.log"
FECHA=$(date '+%Y-%m-%d %H-%M-%S')


if [[ ! -f "${RUTA_FILE_UMBRAL}" ]]; then
	echo "El archivo ingresado no existe"
	exit 1
fi

exec 3>>"$REPORTE"
MAX_CPU="$(gawk '{print $1}' $RUTA_FILE_UMBRAL)"
MAX_RAM="$(gawk '{print $2}' $RUTA_FILE_UMBRAL)"

##==============================================================================
## CALCULAMOS LA CPU
##==============================================================================

read -r _ user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 _ < /proc/stat
total1=$((user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1 + steal1))
idle1_total=$((idle1 + iowait1))

sleep 1

read -r _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 _ < /proc/stat
total2=$((user2 + nice2 +system2 + idle2 + iowait2 + irq2 + softirq2 + steal2))
idle2_total=$((idle2 + iowait2))

diff_total=$((total2 - total1))
diff_idle=$((idle2_total - idle1_total))

CPU_GLOBAL=$(( 100 * (diff_total - diff_idle)/ diff_total ))

##==============================================================================
## CÁLCULO DEL USO DE LA MEMORIA
##==============================================================================

RAM_TOTAL=$(grep MemTotal /proc/meminfo | gawk '{print $2}')
RAM_AVAIL=$(grep MemAvailable /proc/meminfo | gawk '{print $2}')

RAM_GLOBAL=$(( 100 * (RAM_TOTAL - RAM_AVAIL) / RAM_TOTAL ))

##==============================================================================
##				REPORTE
##==============================================================================

echo "================REPORTE: '$FECHA' ========================" >&3

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
