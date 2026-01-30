#!/bin/bash
# monitoreo_cpu_memoria.sh
### Audita periódicamente el consumo de CPU y memoria, detecta procesos que
### excendan ciertos umbrales y genere un reporte detallado, incluyendo 
### sugerencias de alerta según la severidad
### El script si o si recibe 3 parámetros de entrada

if [[ "$#" -ne 3 ]]; then
	echo "El script no tiene 3 parámetros de entrada"
	echo "Saliendo del script"
	exit 1
fi

function verificacion {
	if echo "$1 < 0 || $1 > 100" | bc -l | grep -q 1; then
		echo "Dato incorrecto en el umbral de $2, excede los límites."
		return 1
	fi
	return 0
}

## Parámetros de entrada y variables

DIR="$1"
U_CPU="$2"
U_MEM="$3"
FECHA=$(date +'%Y%m%d-%H%M')
SALIDA="${DIR}/cpu_mem_monitor_$(hostname)_$FECHA.log"

if [[ ! -d "$DIR" ]]; then
	echo "El directorio no existe"
	echo "Saliendo del script"
	exit 1
fi

e_s_cpu=$(verificacion $U_CPU "CPU")
e_s_mem=$(verificacion $U_MEM "MEM")

if (( e_s_cpu == 1 || e_s_mem == 1)); then
	echo "Saliendo del script"
	exit 1
fi

## Revisamos todos los procesos del sistema (propios de usuario o root)

PROCESOS_TOTALES=$(ps -eo pid,uid,pcpu,pmem,etimes,cmd --no-headers)

## Comenzamos a filtrar los procesos que excedan CPU o memoria definida en los
## umbrales

function limite {
	multi=$(echo "$2 * 1.5" | bc -l)
	if echo "$1 <= $2 " | bc -l | grep -q 1; then
		estado="OK"
	elif echo "$1 > $2 && $1 < $multi" | bc -l | grep -q 1; then
		estado="Observacion"
	else
		estado="Critico"
	fi
	echo "$estado"
}

PROCESOS_FILTRADOS=$(echo "$PROCESOS_TOTALES" | sort -k 3nr,3nr  -k 4nr,4nr |
	while read Pid Uid Pcpu Pmem Etimes Cmd; do
		if [[ "$Cmd" == "$0" ]]; then
			continue
		fi
		estado1=$(limite $Pcpu $U_CPU)
		estado2=$(limite $Pmem $U_MEM)
		if [[ "$estado1" == "OK" && "$estado2" == "OK" ]]; then
			continue
		else
		   echo "$Pid $Uid $Pcpu $Pmem $Etimes $Cmd $estado1 $estado2"
		fi
	done
)

echo "========LISTADO DE PROCESOS QUE SUPERAN LOS UMBRALES========" > "$SALIDA"
echo "Fecha: $FECHA" >> "$SALIDA"
echo "Host: $(hostname)" >> "$SALIDA"
echo "Parametros de entrada: $1  $2 $3" >> "$SALIDA"
echo "-------------------------------------" >> "$SALIDA"
echo "$PROCESOS_FILTRADOS" | tee -a "$SALIDA" >> /dev/null
echo >> "$SALIDA"

total_cpu_mem=$(gawk -v suma=0 -v suma2=0 '{suma += $3 ; suma2 += $4} END{print suma, suma2}' < <(echo "$PROCESOS_FILTRADOS"))

echo "El total de consumo de CPU Y de MEM respecitvamente fue: $total_cpu_mem" >> "$SALIDA"
