#!/bin/bash
### Leemos el contenido del archivo monitor.conf que tiene restricciones umbrales
### El script se encarga de verificar si el sistema excede o no esas restricciones
### Si es asi, entonces identificamos que procesos son los culpables de esto
### Y si no es asi, entonces mandamos una señal de todo OK

FECHA=$(date '+%Y-%m-%d %H:%M:%S')
SALIDA="alertas_recursos.log"

exec 3>>"$SALIDA"

if [[ "$#" -eq 0 ]]; then
	echo "No se ingreso ningun parametro"
	exit 1
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
	echo "El archivo no existe"
	exit 1
fi

MAX_CPU=$(gawk '{print $1}' "$FILE")
MAX_RAM=$(gawk '{print $2}' "$FILE")

CPU_GLOBAL=$(top -bn1 | grep -i "cpu(s)" | gawk '{print $2 + $4}' | cut -d "." -f 1)
RAM_GLOBAL=$(free | grep -i "MEm" | gawk '{print $3/$2 * 100.0}' | cut -d "." -f 1)

echo "==========REPORTE: '$FECHA'==========" >&3

if (( CPU_GLOBAL >= MAX_CPU )); then
	echo "[ALERTA CPU] Uso actual: $CPU_GLOBAL% (Limite: $MAX_CPU%)" >&3
fi
if (( RAM_GLOBAL >= MAX_RAM )); then
	echo "[ALERTA RAM] Uso actual: $RAM_GLOBAL% (Limite: $MAX_RAM%)" >&3
fi

if (( CPU_GLOBAL >= MAX_CPU || RAM_GLOBAL >= MAX_RAM)); then
	ps -eo user,pid,pcpu,pmem,stat,cmd --no-headers | sort -k 3nr,4nr | head -n 5 >&3
else
	echo "Todo Ok, no se excede ni en CPU ni en RAM" >&3
fi

exec 3>&-
