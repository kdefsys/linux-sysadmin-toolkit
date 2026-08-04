#!/bin/bash
### Nombre: detectar_procesos_zombie.sh
### Autor: kdefsys
### Descripcion: En sistemas Bash/Linux, los procesos en estado Zombie (estado Z) son aquellos que han terminado su ejecución, pero cuyos procesos padre aún no han leído su
### código de salida mediante la llamada wait(). Aunque no consumen CPU ni memoria RAM activa, sí ocupan un registro en la tabla de procesos del sistema. Si una aplicación genera
### demasiados procesos zombie sin limpiarlos, puede agotar la cantidad de PIDs disponibles y degradar la operatividad del servidor.
### Uso: ./detectar_procesos_zombie.sh -d <directorio_del_log> -s <umbral_de_alerta>

function help {
	echo "El script debe de ejectuarse asi: ./detectar_procesos_zombie.sh -d <directorio_del_log> -s <umbral_de_alerta>"
	echo "   -d : Directorio donde se guardara el reporte. Si no se introduce se asume que es el directorio actual."
	echo "   -s : Cantidad maxima tolerable de zombies. Tiene que ser un numero entero"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
UMBRAL=""

while getopts :d:s:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$(realpath $OPTARG)"
		 if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		 fi
		 ;;
		s)
		 UMBRAL="$OPTARG"
		 if [[ ! "$UMBRAL" =~ ^[0-9]+$ ]]; then
			echo "El umbral ingresado no es un numero entero. Saliendo del script" >&2
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

if [[ -n "$UMBRAL" ]]; then
	FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
	REPORTE="${DIRECTORIO}/zombies_${HOSTNAME}_${FECHA}.log"
	exec 3>>"$REPORTE"
	echo "=========================================== REPORTE DE PROCESOS ZOMBIES =============================================" >&3
	echo "REPORTE GENERADO POR EL SCRIPT: detectar_procesos_zombie.sh" >&3
	echo "UMBRAL: $UMBRAL" >&3

	mapfile -t procesos_zombie < <(ps -eo pid,ppid,uid,stat,start,cmd --no-headers \
		| gawk 'BEGIN{OFS="|"} $4~"^Z"{ $6=""; for(i=6; i<=NF; i++) $6 = $6 (i==6 ? "" : " ") $i; print $1, $2, $3, $4, $5, $6}')

	CANTIDAD="${#procesos_zombie[@]}"
	if [[ "$CANTIDAD" -eq 1 && -z "${procesos_zombie[0]}" ]]; then CANTIDAD=0; fi
	if (( CANTIDAD == 0 )); then
		echo "El sistema esta libre de procesos zombies" | tee -a "$REPORTE"
	else
		echo "LA TABLA DE PROCESOS ZOMBIES ES ASI: " >&3
		echo -e "PID\t\tPPID\t\tUID\t\tSTAT\t\tSTART\t\tCMD" >&3
		printf "%s\n" "${procesos_zombie[@]}" | gawk -F "|" 'BEGIN{OFS="\t"}{print $1, $2, $3, $4, $5, $6}' >&3
		echo "CANTIDAD DE PROCESOS ZOMBIES: $CANTIDAD" >&3
		echo "==========================================================================================" >&3
		echo "RECOPILACION POR PROCESO PADRE" >&3
		echo "==========================================================================================" >&3
		gawk -F "|" -v archivo="$REPORTE" '{
			arreglo[$2]++;
		}END{
			for (indice in arreglo){
				PPADRE=indice
				VALOR=arreglo[indice]
				if(VALOR >=1 && VALOR <= 4) ESTADO="OBSERVACION"
				else if(VALOR >=5 && VALOR <=19) ESTADO="ADVERTENCIA"
				else ESTADO="INCIDENTE"
				printf "PPID: %s	CANTIDAD: %s	ESTADO: %s \n", PPADRE, VALOR, ESTADO >> archivo
			}

		}' < <(printf "%s\n" "${procesos_zombie[@]}")
		echo "============================== LEYENDA =====================================" >&3
		if (( CANTIDAD <= UMBRAL )); then
			echo "Todo esta bajo control. La cantidad de procesos zombies no excede al UMBRAL" >&3
		else
			echo "ALERTA DE RIESGO OPERATIVO. LA CANTIDAD DE PROCESOS ZOMBIES EXCEDE AL UMBRAL" >&3
		fi
	fi
else
	echo "No se introdujo ningun umbral de cantidad maxima tolerable de zombies. No se puede realziar el script"
	exit 1
fi

exec 3>&-
echo "detectar_procesos_zombie.sh ha concluido correctamente. Puede ver el reporte en $REPORTE"
