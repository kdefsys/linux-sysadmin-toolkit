#!/bin/bash
### Nombre: monitoreo_cpu_memoria.sh
### Autor: kdefsys
### Audtia los procesos del sistema, detecta aquellos que exceden umbrales de consumo definidos por el usuario
### y genera un reporte con una clasificacion de severidad dinamica.

if [[ "$#" -ne 3 ]]; then
	echo -e "El script no recibe 3 argumentos\nSaliendo del script"
	sleep 2
	exit 1
fi

if [[ ! -d "$1" ]]; then
	echo -e "El directorio ingresado como primer argumento no existe\nSaliendo del script..."
	sleep 2
	exit 1
fi

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="${1}/cpu_mem_monitor_${HOSTNAME}_${FECHA}.log"
SUMA_CPU=0
SUMA_MEM=0
NAME_SCRIPT=$(basename "$0")

if [[ "$2" -ge 0 && "$2" -le 100 && "$3" -ge 0 && "$3" -le 100 ]]; then
	UMBRAL_CPU="$2"
	UMBRAL_MEM="$3"
else
	echo -e "No es aceptable esos numeros\nSaliendo del script..."
	sleep 2
	exit 1
fi

function detectando {
	local valor="$1"
	local umbral="$2"
	local advertencia=$(echo "$umbral * 1.5" | bc -l)
	if (( $(echo "$valor <= $umbral" | bc -l) )); then
		echo "OK"
	elif (( $(echo "$valor <= $advertencia" | bc -l) )); then
		echo "OBSERVACION"
	else
		echo "CRITICO"
	fi
}

mapfile -t procesos < <(ps -eo pid,ppid,pcpu,pmem,etimes,cmd --no-headers | while read -r pid ppid pcpu pmem etime cmd; do
		if [[ "$cmd" == *"${NAME_SCRIPT}"* ]]; then
			continue
		fi
		ESTADO_CPU=$(detectando "$pcpu" "$UMBRAL_CPU")
		ESTADO_MEM=$(detectando "$pmem" "$UMBRAL_MEM")
		if [[ "$ESTADO_CPU" != "OK" || "$ESTADO_MEM" != "OK" ]]; then
			printf "PID: %s | PPID: %s | CPU: %s | MEM: %s | TIME_TRANS: %s | COMANDO: %s | ESTADO_CPU: %s | ESTADO_MEM: %s\n" \
				"$pid" "$ppid" "$pcpu" "$pmem" "$etime" "$cmd" "$ESTADO_CPU" "$ESTADO_MEM"
		fi
	done)

TOTALES=$(printf "%s\n" "${procesos[@]}" | gawk -F "|" '
	{
		split($3, cpu, " "); split($4, mem, " ");
		s_cpu += cpu[2] ; s_mem += mem[2]
	}
	END{print s_cpu " " s_mem}')

read SUMA_CPU SUMA_MEM <<< "$TOTALES"

exec 3>>"${REPORTE}"

echo -e "==============================MONITOREO DE PROCESOS CON PCPU Y PMEM EXCEDIDOS AL UMBRAL=================================" >&3
echo -e "LISTA DE PROCESOS:\n\n" >&3
if [[ "${#procesos[@]}" -gt 0 ]]; then
	printf "%s\n" "${procesos[@]}" | sort -t "|" -k 3nr,3nr -k 4nr,4nr | tee -a "${REPORTE}" &> /dev/null
else
	echo "No se encontraron procesos que excedan esos umbrales" >&3
fi
printf "PCPU TOTAL %s\nPMEM TOTAL: %s\n" "${SUMA_CPU}" "${SUMA_MEM}" >&3

exec 3>&-

echo "Proceso Finalizado, Reporte en ${REPORTE}"
