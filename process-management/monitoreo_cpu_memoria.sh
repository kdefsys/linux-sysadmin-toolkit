#!/bin/bash
### Nombre: monitoreo_cpu_memoria.sh
### Autor: kdefsys
### Descripcion: En entornos de producción, el consumo desmedido de recursos por parte de un solo proceso puede desestabilizar el servidor completo. Para prevenir caídas de servicio,
### el equipo de operaciones requiere una herramienta de auditoría automatizada que analice la tabla de procesos en tiempo real, identifique aquellos que sobrepasen umbrales de uso
### de CPU o Memoria RAM predefinidos, y los clasifique dinámicamente según la severidad del exceso.
### Este script recibe parametros de tolerancia de recursos (CPU y Memoria), audita los procesos activos en el sistema descartando la propia ejecucion de la auditoria, evala la
### severidad del consumo de cada proceso mediante el uso de calculo con decimales, suma el impacto total de los procesos excedidos y guarda los hallazgos ordenados en un reporte de
### salida.
### Uso: ./monitoreo_cpu_memoria.sh [-d <directorio_salida>] -m <umbral_memoria> -p <umbral_cpu> [-h]

function help {
	echo "El script se debe de ejecutar asi: ./monitoreo_cpu_memoria.sh [-d <directorio_salida>] -m <umbral_memoria> -p <umbral_cpu> [-h]"
	echo "   -d : Directorio donde se va guardar el reporte. Si no se introduce la bandera, se asumira que es el directorio actual de trabajo."
	echo "   -m : Umbral maximo de memoria RAM permitido (porcentaje)."
	echo "   -p : Umbral maximo de CPU permitido (porcentaje)."
	echo "   -h : Imprime esta guia."
}

DIRECTORIO="$(pwd)"
UMBRAL_CPU=""
UMBRAL_MEM=""

while getopts :d:m:p:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script." >&2
			exit 1
		 fi
		 ;;
		m)
		 UMBRAL_MEM="$OPTARG"
		 if ! [[ "$UMBRAL_MEM" =~ ^[0-9]+$ ]]; then
			echo "El valor de UMBRAL DE MEMORIA no es un numero entero. Saliendo del script." >&2
			exit 1
		 fi
		 if ! (( UMBRAL_MEM >= 0 && UMBRAL_MEM <= 100 )); then
			echo "El valor de UMBRAL DE MEMORIA RAM no es correcto para un porcentaje." >&2
			exit 1
		 fi
		 ;;
		p)
		 UMBRAL_CPU="$OPTARG"
		 if ! [[ "$UMBRAL_CPU" =~ ^[0-9]+$ ]]; then
			echo "El valor de UMBRAL DE CPU no es un numero entero. Saliendo del script." >&2
			exit 1
		 fi
		 if ! (( UMBRAL_CPU >= 0 && UMBRAL_CPU <= 100 )); then
		 	echo "El valor de UMBRAL DE CPU no es correcto para un porcentaje." >&2
			exit 1
		 fi
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion ingresada invalida" >&2
		 help
		 exit 1
		 ;;
	esac
done

function evaluacion {
	local consumo="$1"
	local umbral="$2"
	# Evaluamos mediante bc devolviendo 1 (true) o 0 (false)
	local es_ok=$(echo "$consumo <= $umbral" | bc -l)
	local es_obs=$(echo "$consumo <= ($umbral * 1.5)" | bc -l)

	if [[ "$es_ok" -eq 1 ]]; then
		echo "OK"
	elif [[ "$es_obs" -eq 1 ]]; then
		echo "OBSERVACION"
	else
		echo "CRITICO"
	fi
}

if [[ -n "$UMBRAL_CPU" && -n "$UMBRAL_MEM" ]]; then
	FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
	REPORTE="${DIRECTORIO}/cpu_mem_monitor_${HOSTNAME}_${FECHA}.log"
	SCRIPT="$(basename "$0")"
	exec 3>>"$REPORTE"

	echo "=========================================================== REPORTE DE UMBRAL DE CPU Y MEM ====================================================" >&3
	echo "ESTE REPORTE HA SIDO GENERADO POR EL SCRIPT: monitoreo_cpu_memoria.sh" >&3
	echo "HOSTNAME: $HOSTNAME" >&3
	echo "FECHA: $FECHA" >&3
	echo "UMBRAL DE CPU: $UMBRAL_CPU" >&3
	echo "UMBRAL DE MEMORIA RAM: $UMBRAL_MEM" >&3
	echo "===============================================================================================================================================" >&3

	mapfile -t procesos < <(ps -eo pid,ppid,pcpu,pmem,etimes,cmd --no-headers \
		| gawk -v script="$SCRIPT" 'BEGIN{OFS="|"} $0!~script{$6=""; for(i=6;i<=NF;++i) $6 = $6 (i==6 ? "" : " ") $i; print $1, $2, $3, $4, $5, $6}' \
		| while IFS="|" read -r pid ppid pcpu pmem etimes cmd; do
			estado_cpu=$(evaluacion "$pcpu" "$UMBRAL_CPU")
			estado_mem=$(evaluacion "$pmem" "$UMBRAL_MEM")
			if [[ "$estado_cpu" != "OK" || "$estado_mem" != "OK" ]]; then
				echo "$pid|$ppid|$pcpu|$pmem|$etimes|$cmd|$estado_cpu|$estado_mem"
			fi
		done)

	CANTIDAD="${#procesos[@]}"
	if [[ "$CANTIDAD" -eq 1 && -z "${procesos[0]}" ]]; then
		CANTIDAD=0
	fi
	if (( CANTIDAD == 0 )); then
		echo "No se encontraron procesos que superen dichos umbrales" >&3
	else
		CONSUMO_TOTAL_CPU=0
		CONSUMO_TOTAL_MEM=0

		CONSUMO_TOTAL_CPU=$(printf "%s\n" "${procesos[@]}" | gawk -F "|" '{s+=$3} END{print s}')
		CONSUMO_TOTAL_MEM=$(printf "%s\n" "${procesos[@]}" | gawk -F "|" '{s+=$4} END{print s}')

		echo "LOS PROCESOS ENCONTRADOS SON: ">&3
		echo -e "PID\t\tPPID\t\tPCPU\t\tPMEM\t\tETIMES\t\tCMD\t\tESTADO_CPU\t\tESTADO_MEM\n" >&3
		printf "%s\n" "${procesos[@]}" | LC_ALL=C sort -t "|" -k 3,3nr -k 4,4nr | gawk -F "|" 'BEGIN{OFS="\t"}{print $1, $2, $3, $4, $5, $6, $7, $8}' >&3

		echo "=================================================================== LEYENDA ===============================================================" >&3
		echo "TOTAL DE CPU CONSUMIDA: $CONSUMO_TOTAL_CPU" >&3
		echo "TOTAL DE MEMORIA CONSUMIDA: $CONSUMO_TOTAL_MEM" >&3
		echo "===========================================================================================================================================" >&3
	fi

	exec 3>&-
	echo "monitoreo_cpu_memoria.sh concluido correctamente. Puede ver el reporte en: $REPORTE"
else
	echo "No se introdujeron las banderas obligatorias (-m y -p). Saliendo del script."
fi
