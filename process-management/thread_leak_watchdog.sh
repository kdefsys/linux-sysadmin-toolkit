#!/bin/bash
### Nombre: thread_leak_watchdog.sh
### Autor: kdefsys
### Descripcion: En entornos de servidores que ejecutan aplicaciones concurrentes de alto rendimiento (servidores web, microservicios en contenedores, bases de datos o scripts mal
### optimizados), pueden surgir errores de programación conocidos como fugas de hilos (thread leaks).
### Cuando una aplicación comienza a generar hilos de ejecución de manera descontrolada sin liberarlos, la cantidad de tareas activas por proceso (NLWP o Number of Light Weight Processes)
### se dispara. Aunque el consumo total de CPU o memoria RAM parezca moderado al principio, agotar el límite de hilos permitidos por usuario o por el sistema operativo (kernel.threads-max
### o max user processes) puede provocar la caída total del servidor al impedir la creación de nuevos procesos (incluso bloqueando el acceso por SSH).
### El equipo de infraestructura requiere un script en Bash que funcione como un monitor especializado en la concurrencia de hilos para detectar y reportar procesos anómalos antes de
### que colapsen el sistema.
### Desarrollar un script en Bash de monitoreo continuo que inspeccione la tabla de procesos del sistema enfocándose en la cantidad de hilos activos por proceso, valide contra un
### umbral de tolerancia configurable, descarte hilos del kernel y procesos protegidos mediante una lista blanca, y registre un reporte de auditoría detallado con clasificaciones de
### severidad.
### Uso: sudo ./thread_leak_watchdog.sh -t <umbral_maximo_hilos> -d <directorio_salida> -f <ruta_lista_blanca> [-h]

function help {
	echo "El script debe de ejecutarse asi: sudo ./thread_leak_watchdog.sh -t <umbral_maximo_hilos> -d <directorio_salida> -f <ruta_lista_blanca> [-h]"
	echo "   -t : Umbral maximo de hilos permitidos por proceso (numero entero)."
	echo "   -d : Directorio de salida donde se guardara el archivo de reporte de auditoria. Si no se indica, se asume el directorio actual"
	echo "   -f : Ruta del archivo de lista blanca de procesos o PIDs exentos de la auditoria"
	echo "   -h : Imprime esta guia"
}

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con permisos sudo" >&2
	exit 1
fi

DIRECTORIO="$(pwd)"
UMBRAL=""
LISTA_BLANCA=""

while getopts :t:d:f:h opt; do
	case "$opt" in
		t)
		  UMBRAL="$OPTARG"
		  if ! [[ "$UMBRAL" =~ ^[0-9]+$ ]]; then
			echo "El valor ingresado como umbral maximo de hilos no es un numero entero. Saliendo del script..." >&2
			exit 1
		  fi
		  ;;
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		f)
		  LISTA_BLANCA="$OPTARG"
		  if [[ ! -f "$LISTA_BLANCA" ]]; then
			echo "No existe el archivo de lista blanca. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		h)
		  help
		  exit 0
		  ;;
		*)
		  echo "Opcion ingresada no valida" >&2
		  help
		  exit 1
		  ;;
	esac
done

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="${DIRECTORIO}/reporte_thread_${FECHA}.log"

function cierre_limpio {
	echo "Se activo la funcion de cierre limpio"
	echo "Porque bien se reconocio algunas de estas dos señales: SIGTERM o SIGINT"
	if [[ -f "$REPORTE" ]]; then
		exec 3>&-
		echo "Descriptor de archivo cerrado. Ver reporte en $REPORTE"
	fi
	exit 0
}

trap cierre_limpio SIGINT SIGTERM

function verificar_lista_blanca {
	local pid="$1"
	if [[ -n "$LISTA_BLANCA" ]]; then
		if grep -qw "$pid" "$LISTA_BLANCA" 2>/dev/null; then
			return 0
		fi
	fi
	return 1
}

if [[ -n "$UMBRAL" && -n "$LISTA_BLANCA" ]]; then
	> "$REPORTE"
	exec 3>>"$REPORTE"

	echo "======================================================== REPORTE DE HILOS ==========================================================" >&3
	echo "SCRIPT: thread_leak_watchdog.sh" >&3
	echo "FECHA: $FECHA" >&3
	echo "UMBRAL MAXIMO: $UMBRAL" >&3
	echo "LISTA BLANCA: $LISTA_BLANCA" >&3
	echo "====================================================================================================================================" >&3

	SCRIPT="$(basename $0)"

	while true; do
		mapfile -t procesos < <(ps -eo pid,ppid,uid,stat,nlwp,cmd --no-headers \
			| gawk -v s="$SCRIPT" 'BEGIN{OFS="|"} $6!~/^\[.*\]/ && $0!~s{$6="" for(i=6;i<=NF;++i) $6 = $6 (i==6 ? "" : " ") $i; print $1, $2, $3, $4, $5, $6}' \
			| while IFS="|" read -r pid ppid uid stat nlwp cmd; do
				if [[ "$pid" == "$$" || "$pid" == "$PPID" ]]; then continue; fi
				if ! verificar_lista_blanca "$pid" 2>/dev/null; then
					if [[ "$nlwp" -le "$UMBRAL" ]]; then
						ESTADO="OK"
					elif (( nlwp > UMBRAL && nlwp <= UMBRAL*2 )); then
						ESTADO="OBSERVACION"
					else
						ESTADO="CRITICO"
					fi
					echo "$pid|$ppid|$uid|$stat|$nlwp|$cmd|$ESTADO"
				fi
			done)
		echo "================================================= LISTA DE PROCESOS =============================================" >&3
		CANTIDAD="${#procesos[@]}"
		if [[ "$CANTIDAD" -eq 1 && -z "${procesos[@]}" ]]; then CANTIDAD=0; fi
		if (( CANTIDAD == 0 )); then
			echo "No se encontraron procesos con esas caracteristicas" >&3
		else
			echo -e "PID\t\tPPID\t\tUID\t\tSTAT\t\tNLWP\t\tCMD\n" >&3
			printf "%s\n" "${procesos[@]}" >&3
		fi
		sleep 2
	done
else
	echo "No se ingresaron las banderas necesarias" >&2
	exit 1
fi
