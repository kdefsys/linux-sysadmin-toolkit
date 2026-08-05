#!/bin/bash
### Nombre: process_resource_governor.sh
### Autor: kdefsys
### Descripcion: En servidores de producción y entornos multiusuario, es común que ciertos procesos (como scripts mal optimizados, tareas fuera de control o ataques de denegación de
### servicio local) consuman un porcentaje desmedido de procesamiento durante tiempos prolongados. Esto degrada el rendimiento general del sistema y afecta a otros servicios críticos.
### El equipo de administración de sistemas e infraestructura requiere un demonio / servicio de patrullaje en tiempo real que supervise la actividad de la CPU y aplique políticas de
### degradación progresiva de forma automatizada: primero reduciendo la prioridad del proceso ofensivo y, si este continúa monopolizando el procesador en lecturas subsecuentes, terminando
### su ejecución de manera forzada.
### Este script en Bash funciona como un gobernador de recursos en segundo plano. Debe patrillar de forma asincrona la tabla de procesos, verificar que procesos exceden las cotas de
### consumo y tiempo fijadas por el usuario, degradar o terminar los procesos infractores segun su reincidencia y, registrar toda la actividad en un archivo de auditoria.
### Uso: sudo ./process_resource_governor.sh -u <umbral_cpu> -t <tiempo_maximo> [-d <directorio_reporte>] [-h]

function help {
	echo "El script se debe de ejectuar asi: sudo ./process_resource_governor.sh -u <umbral_cpu> -t <tiempo_maximo> [-d <directorio_reporte>] [-h]"
	echo "   -d : Ruta del directorio donde se creara o actualizara el archivo de reporte governor.log. Si no introduce se asume el directorio actual"
	echo "   -u : Umbral de CPU. Porcentaje limite de uso de procesador."
	echo "   -t : Tiempo maximo de ejecucion. Limite de tiempo activo (en segundos) antes de considerar un proceso como abusivo."
	echo "   -h : Imprime esta guia."
}

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con privilegios sudo" >&2
	exit 1
fi

DIRECTORIO="$(pwd)"
UMBRAL_CPU=""
TIEMPO_MAX=""

while getopts :d:u:t:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
		 	echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		 fi
		 ;;
		u)
		 UMBRAL_CPU="$OPTARG"
		 if ! [[ "$UMBRAL_CPU" =~ ^[0-9]+$ ]]; then
		 	echo "El valor de Umbral cpu no es un entero. Saliendo del script" >&2
			exit 1
		 fi
		 if ! (( UMBRAL_CPU >= 0 && UMBRAL_CPU <= 100 )); then
			echo "El valor de umbral cpu no es valido para un porcentaje." >&2
			exit 1
		 fi
		 ;;
		t)
		 TIEMPO_MAX="$OPTARG"
		 if ! [[ "$TIEMPO_MAX" =~ ^[0-9]+$ ]]; then
			echo "El valor del tiempo maximo no es entero. Saliendo del script." >&2
			exit 1
		 fi
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion invalida ingresada" >&2
		 help
		 exit 1
		 ;;
	esac
done

if [[ -n "$UMBRAL_CPU" && -n "$TIEMPO_MAX" ]]; then
	FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
	REPORTE="${DIRECTORIO}/governor.log"
	exec 3>>"$REPORTE"
fi

CANTIDAD_TOTAL=0

function cierre {
	echo "El reporte se cerro correctamente tras un SIGINT o un SIGTERM" >&3
	echo "CANTIDAD TOTAL DE PENALIZACIONES/VARIACIONES: $CANTIDAD_TOTAL" >&3
	exec 3>&-
	echo "process_resource_governor.sh ha concluido correctamente. Ver el reporte en $REPORTE"
	exit 0
}

trap cierre SIGINT SIGTERM

if [[ -n "$UMBRAL_CPU" && -n "$TIEMPO_MAX" ]]; then

	echo "================================================ REPORTE PROCESS RESOURCE GOVERNOR =======================================================" >&3
	echo "Reporte mediante el uso de un demonio del script process_resource_governor.sh" >&3
	echo "FECHA: $FECHA" >&3
	echo "UMBRAL DE CPU: $UMBRAL_CPU" >&3
	echo "TIEMPO MAXIMO: $TIEMPO_MAX" >&3
	echo "==========================================================================================================================================" >&3

	declare -A estado_proc

	while true; do
		# Purga de PIDs muertos para evitar falsos reincidentes por reciclaje de PID
		for p in "${!estado_proc[@]}"; do
			if ! kill -0 "$p" 2>/dev/null; then
				unset "estado_proc[$p]"
			fi
		done

		mapfile -t procesos < <(ps -eo pid,ppid,pcpu,pmem,etimes,cmd --no-headers \
			| gawk 'BEGIN{OFS="|"} {$6=""; for(i=6;i<=NF;i++) $6 = $6 (i==6 ? "" : " ") $i; print $1, $2, $3, $4, $5, $6}')
		while IFS="|" read -r pid ppid pcpu pmem etimes cmd; do

			if [[ "$pid" -eq "$$" || "$pid" -eq "$PPID" ]]; then continue; fi

			if (( $(echo "$pcpu > $UMBRAL_CPU" | bc -l) )) && (( etimes > TIEMPO_MAX )); then
				if [[ -z "${estado_proc[$pid]}" ]]; then
					estado_proc[$pid]="infractor"
					renice -n +19 -p "$pid" >/dev/null 2>&1
					echo "El proceso longevo con PID: $pid a las $(date '+%Y-%m-%d_%H-%M-%S') con comando: $cmd es infractor por superar umbral de cpu" >&3
					echo "Se le asigno una prioridad de +19" >&3
					(( CANTIDAD_TOTAL++ ))
				else
					echo "El proceso longevo con PID: $pid a pesar de bajarle la prioridad sigue consumiendo mucha CPU" >&3
					echo "Le mandamos señal SIGTERM para que termine." >&3
					kill -TERM "$pid" 2>/dev/null
					unset "estado_proc[$pid]"
					(( CANTIDAD_TOTAL++ ))
				fi
			fi
		done < <(printf "%s\n" "${procesos[@]}")
		sleep 4
	done
else
	echo "No se introdujeron las banderas obligatorias (-u y -t). Saliendo del script" >&2
	exit 1
fi
