#!/bin/bash
### Nombre: auditoria_procesos_largos.sh
### Autor: kdefsys
### Descripcion: En la administración de servidores Linux, los procesos que permanecen activos en ejecución o en espera durante demasiado tiempo pueden representar fugas de recursos,
### tareas colgadas o consumidores excesivos de CPU/Memoria. Sin embargo, no todos los procesos duraderos son un problema: el kernel del sistema mantiene hilos internos (kernel threads)
### y servicios esenciales que operan de forma continua. Por ello, es necesario auditar el sistema filtrando esos hilos del kernel y monitorear únicamente los procesos de usuario/aplicación
### que superen un tiempo límite configurado.
### Este script inspecciona la tabla de procesos activos, identifica aquellos procesos que llevan ejecutandose mas de un tiempo determinado (convertido a minutos), aplica filtros para
### descartar procesos del kernel y el propio script de auditoria, y genera un reporte detallado clasificando el nivel de severidad del servidor.
### Uso: ./auditoria_procesos_largos.sh -d <directorio_log> -m <tiempo_maximo> -c <limite_tolerancia> [-h]

function help {
	echo "El script debe de ejecutarse asi: ./auditoria_procesos_largos.sh -d <directorio_log> -m <tiempo_maximo> -s <limite_tolerancia> [-h]"
	echo "   -d : Directorio donde se guardara el archivo de reporte. Si no se introduce se asume que es el directorio actual de trabajo"
	echo "   -m : Tiempo maximo permitido en minutos."
	echo "   -c : Limite de tolerancia (cantidad maxima de procesos largos tolerables antes de pasar a un estado de alerta critica"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
TIEMPO=""
LIMITE=""

while getopts :d:m:c:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script..." >&2
			exit 1
		 fi
		 ;;
		m)
		 TIEMPO="$OPTARG"
		 if ! [[ "$TIEMPO" =~ ^[0-9]+$ ]]; then
			echo "El tiempo introducido no es un entero" >&2
			exit 1
		 fi
		 ;;
		c)
		 LIMITE="$OPTARG"
		 if ! [[ "$LIMITE" =~ ^[0-9]+$ ]]; then
			echo "El limite introducido no es un entero" >&2
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

if [[ -n "$TIEMPO" && -n "$LIMITE" ]]; then
	FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
	REPORTE="${DIRECTORIO}/reporteprocesoslargos_${HOSTNAME}_${FECHA}.log"
	exec 3>>"$REPORTE"
	echo "=========================================================== REPORTE DE PROCESOS LARGOS ====================================================" >&3
	echo "ESTE REPORTE ES EL RESULTADO DEL SCRIPT: auditoria_procesos_largos.sh">&3
	echo "HOST: ${HOSTNAME}" >&3
	echo "TIEMPO LIMITE: $(( TIEMPO * 60 ))" >&3
	echo "LIMITE DE CANTIDAD: $LIMITE" >&3
	echo "===========================================================================================================================================" >&3
	TIEMPO=$(( TIEMPO * 60 ))
	SCRIPT="$(basename "$0")"

	mapfile -t procesos_largos < <(ps -eo pid,ppid,uid,etimes,start,pcpu,pmem,stat,cmd --no-headers \
		| gawk -v t="$TIEMPO" -v script="$SCRIPT" 'BEGIN{OFS="|"} $8~/^(S|R|D)/ && $4>t && $9!~/^\[.*\]/ && $0!~script{ $9=""; for(i=9; i<=NF; i++) $9 = $9 (i==9 ? "" : " ") $i; print $1, $2, $3, $4, $5, $6, $7, $8, $9}')

	CANTIDAD="${#procesos_largos[@]}"
	if [[ "$CANTIDAD" -eq 1 && -z "${procesos_largos[0]}" ]]; then
		CANTIDAD=0
	fi
	if (( CANTIDAD == 0 )); then
		echo "No se encontraron procesos largos con esas caracteristicas" >&3
	else
		echo "Se encontraron $CANTIDAD procesos largos con esas caracteristicas" >&3
		echo "Estos son: " >&3
		echo -e "PID\t\tPPID\t\tUID\t\tTIME\t\tSTART\t\tPCPU\t\tPMEM\t\tSTAT\t\tCMD\n" >&3
		printf "%s\n" "${procesos_largos[@]}" | gawk -F "|" 'BEGIN{OFS="\t"}{print $1, $2, $3, $4, $5, $6, $7, $8, $9}' >&3
	fi
	echo "========================================================== LEYENDA =================================================================" >&3
	echo "====================================================================================================================================" >&3

	if (( CANTIDAD == 0 )); then
		echo "ESTADO GENERAL DEL SISTEMA: OK" >&3
	elif (( CANTIDAD <= LIMITE ));then
		echo "ESTADO GENERAL DEL SISTEMA: OBSERVACION" >&3
	else
		echo "ESTADO GENERAL DEL SISTEMA: ALERTA OPERATIVA" >&3
	fi

	exec 3>&-
	echo "auditoria_procesos_largos.sh concluyo con exito. Ver el reporte en: $REPORTE"
else
	echo "No se puede ejecutar el script porque no tiene los dos argumentos obligatorios que son el tiempo y el limite." >&2
fi
