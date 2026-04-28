#!/bin/bash
### Nombre: auditoria_procesos_largos.sh
### Autor: kdefsys
### Identifica los procesos activos que superen un tiempo de ejecución determinado, filtrando procesos
### del sistema y evaluando la severidad de la carga en el servidor
### Uso: ./auditoria_procesos_largos.sh <directorio_log> <tiempo_maximo> <limite_tolerancia>

if [[ "$#" -ne 3 ]]; then
	echo -e "El script no recibió 3 argumentos\nSaliendo del script"
	sleep 2
	exit 1
fi

if [[ ! -d "$1" ]]; then
	echo -e "El directorio ingresado como primer argumento no existe\nSaliendo del script..."
	sleep 2
	exit 1
fi

DIRECTORIO="$1"
TIEMPO=$(( $2 * 60 ))
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
LIMITE="$3"
ESTADO="OK"
REPORTE="${DIRECTORIO}/auditoria_procesos_largos_${HOSTNAME}_${FECHA}.log"
SCRIPT_NAME=$(basename "$0")

exec 3>>"${REPORTE}"
echo -e "===================================REPORTE DE PROCESOS LARGOS==================================\n" >&3
echo -e "FECHA: ${FECHA}\nHOST: ${HOSTNAME}\nPARAMETROS USADOS: "$1" "$2" "$3"\n\n" >&3

mapfile -t procesos < <(ps -eo pid,ppid,uid,etimes,start,pcpu,pmem,stat,cmd --no-headers | while read -r pid ppid uid etimes inicio cpu mem estado comando; do
    if [[ "$estado" =~ ^(S|R|D) ]]; then
        if [[ "$etimes" -gt "$TIEMPO" ]]; then
            # Filtro de kernel threads y evitar que el script se lea a sí mismo
            if [[ ! "$comando" =~ ^\[.*\]$ && "$comando" != *"${SCRIPT_NAME}"* ]]; then
                printf "PID: %s | PPID: %s | UID: %s | TIME: %ss | START: %s | CPU: %s%% | MEM: %s%% | STAT: %s | CMD: %s\n" \
                        "$pid" "$ppid" "$uid" "$etimes" "$inicio" "$cpu" "$mem" "$estado" "$comando"
            fi
        fi
    fi
done)

CANTIDAD=${#procesos[@]}

if [[ "${#procesos[@]}" -eq 0 ]]; then
	echo -e "No hay procesos con esas caracteristicas TODO OK\n" | tee -a "${REPORTE}"
	exit 1
else
	echo -e "LISTA DE PROCESOS FILSTADOS:\n\n" >&3
	printf "%s\n" "${procesos[@]}" >&3
	if [[ "$CANTIDAD" -ge 1 && "$CANTIDAD" -le "$LIMITE" ]]; then
		echo "CANTIDAD: ${CANTIDAD} ESTADO: OBSERVACION" >&3
	else echo "CANTIDAD: ${CANTIDAD} ESTADO: ALERTA OPERATIVA" >&3
	fi
fi

echo -e "Termino el proceso, los datos estan guardados en ${REPORTE}"
exec 3>&-
