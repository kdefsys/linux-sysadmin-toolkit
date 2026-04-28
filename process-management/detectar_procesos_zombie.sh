#!/bin/bash
### Nombre: detectar_procesos_zombie.sh
### Autor: kdefsys
### Analiza la tabla de procesos del sistema, identifica aquellos en estado zomie (estado Z) y genera un reporte
### detallado basado en un umbral de alerta definido por el usuario
### Uso: ./detectar_procesos_zombie.sh <directorio_del_log> <umbral_de_alerta>

if [[ "$#" -ne 2 ]]; then
	echo -e "El script no recibió dos argumentos\nSaliendo del script..."
	sleep 2
	exit 1
fi

if [[ -d "$1" ]]; then
	DIRECTORIO="$1"
else
	echo -e "El directorio ingresado no existe\nSaliendo del script..."
	sleep 2
	exit 1
fi

UMBRAL="$2"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="${DIRECTORIO}/zombies_${HOSTNAME}_${FECHA}.log"

exec 3>>"$REPORTE"

echo -e "=================================REPORTE DE PROCESOS ZOMBIES===================================" >&3
echo -e "FECHA: ${FECHA}" >&3

mapfile -t procesos_zombies < <(ps -eo pid,ppid,uid,stat,start,cmd --no-headers | gawk 'BEGIN{OFS="|"} $4=="Z"{print $1, $2, $3, $4, $5, $6}')

CANTIDAD=${#procesos_zombies[@]}

echo -e "TOTAL DE PROCESOS ZOMBIES DETECTADOS: ${CANTIDAD}"

if [[ ${#procesos_zombies[@]} -eq 0 ]]; then
	echo "No hay procesos zombies" | tee -a "${REPORTE}"
	echo "Proceso Finalizado" | tee -a "${REPORTE}"
	exec 3>&-
	exit 1
fi

### Dividiendo por PPID


gawk -F "|"  -v archivo="$REPORTE" '{arreglo[$2]+=1}
END{
	print "DESGLOSE POR PPID CON SU RESPECTIVA CLASIFICACION DE ESTADO\n" >> archivo
	for (indice in arreglo){

		if (arreglo[indice] >= 1 && arreglo[indice] <= 4)
			estado="OBSERVACION"
		else if (arreglo[indice] >= 5 && arreglo[indice] <= 19)
			estado="ADVERTENCIA"
		else if (arreglo[indice] >= 20) estado = "INCIDENTE"

		printf ("PPID: %s\tCANTIDAD: %s\tESTADO: %s\n", indice, arreglo[indice], estado) >> archivo

	}
}' < <(printf "%s\n" "${procesos_zombies[@]}")

echo -e "LISTA COMPLETA DE PROCESOS ZOMBIES DETECTADOS:\n" >&3

printf "%s\n" "${procesos_zombies[@]}" >&3

if [[ "$UMBRAL" -ge "${CANTIDAD}" ]]; then
	echo -e "Todo esta OK, no se supero la cantidad limite ${UMBRAL}" >&3
else
	echo -e "RIESGO OPERATIVO, si se supero la cantidad limite ${UMBRAL}" >&3
fi

echo "Script finalizado, los datos fueron guardados en ${REPORTE}"

exec 3>&-
