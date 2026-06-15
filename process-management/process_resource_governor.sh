#!/bin/bash
###Nombre: process_resource_governor.sh
###Autor: kdefsys
###Este script actua como un demonio o servicio de control de recursos en tiempo real. Debe patrullar el sistema de
###manera asíncrona y degradar o aislar de forma automatizada los procesos abusivos basándose en parámetros estrictos.
###Uso: sudo ./process_resource_governor.sh <umbral> <tiempo_maximo> <ruta_log>

if [[ "$EUID" -ne 0 ]]; then echo "El script debe ser ejecutado con permiso de superusuario"; fi

if [[ "$#" -ne 3 ]]; then
	echo "El script no tiene 3 argumentos de entrada. Saliendo del script..."
	sleep 3
	exit 1
fi

UMBRAL="$1" #Esta en porcentaje
TIME_MAX="$2" #Esta en segundos
REPORTE="${3}/governor.log"
VARIACIONES=0

exec 3>>"$REPORTE"

cerramos_el_reporte() {
	if [[ -f "$REPORTE" ]]; then
		echo "Finalizamos el reporte porque se presionó CTRL+C" >&3
		echo "En total se hizo: $VARIACIONES penalizaciones" >&3
	else
		echo "El reporte nunca fue creado" >&3
	fi
	exec 3>&-
	exit 0
}

trap cerramos_el_reporte SIGINT #Ctrl+C
declare -A estados_procesos

while true; do
	while IFS="|" read -r pid ppid pcpu pmem etimes cmd; do
		if [[ "$pid" -eq "$$" || "$pid" -eq $PPID ]]; then continue; fi
		if (( $(echo "$pcpu > $UMBRAL" | bc -l) && $(echo "$etimes > $TIME_MAX" | bc -l) )); then
			if [[ "${estados_procesos[$pid]}" != "renice" ]]; then
				echo "[!] [ALERTA] PID $pid superó umbrales (CPU: $pcpu%, Tiempo: ${etimes}s). Aplicando renice +19..." >&3
				renice +19 -p "$pid" >/dev/null 2>&1
				estados_procesos["$pid"]="renice"
				echo "$(date +'%Y-%m-%d %H:%M:%S') [DEGRADADO] PID: $pid - COMANDO: $cmd - CPU: $pcpu - NICE APLICADO" >&3
				(( VARIACIONES++ ))
			else
				echo "[!] [CRÍTICO] PID $pid sigue evadiendo control con Nice 19. Enviando SIGTERM..." >&3
				kill -TERM "$pid" 2>/dev/null
				echo "$(date +'%Y-%m-%d %H:%M:%S') [TERMINADO] PID: $pid - COMANDO: $cmd - CPU: $pcpu - ZOMBIE" >&3
				(( VARIACIONES++ ))
			fi
		fi
	done < <(ps -eo pid,ppid,pcpu,pmem,etimes,cmd --no-headers | gawk '{
		cmd_full=""; for (i=6; i<=NF; ++i) cmd_full=(cmd_full ? cmd_full" " : "")$i
		print $1"|"$2"|"$3"|"$4"|"$5"|"cmd_full}')
	sleep 4
done
