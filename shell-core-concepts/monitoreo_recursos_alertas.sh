#!/bin/bash
### Nombre: nonitoreo_recursos_alertas.sh
### Autor: kdefsys
### Descripcion: En un entorno de producción, es fundamental detectar a tiempo si el servidor se está quedando sin recursos antes de que un servicio colapse. El equipo de
### operaciones necesita un script interactivo o automatizable que revise de manera periódica el estado de la CPU, la memoria RAM y el espacio en disco.
### Si alguno de estos recursos supera un umbral de advertencia configurado por el usuario, el script debe generar una alerta visual y documentar el incidente registrando información
### detallada del sistema para ayudar al diagnóstico posterior.
### Uso: ./monitoreo_recursos_alertas.sh [-d <umbral_disco>] [-m <umbral_memoria>] [-c <umbral_cpu>] [-h]

function help {
	echo "El script se debe de ejecutar asi: ./monitoreo_recursos_alertas.sh [-d <umbral_disco>] [-m <umbral_memoria>] [-c <umbral_cpu>] [-h]"
	echo "   -d : Umbral de disco. Si no se ingresa, por defecto es 80 "
	echo "   -m : Umbral de memoria. SI no se ingresa valor, por defecto es 85"
	echo "   -c : Umbral de cpu. Si no se ingresa valor, por defecto es 90"
	echo "   -h : Imprime esta guia"
}

UMBRAL_DISCO=80
UMBRAL_MEMOR=85
UMBRAL_CPU=90

while getopts :d:m:c:h opt; do
	case "$opt" in
		d)
		 UMBRAL_DISCO=$OPTARG
		 if ! [[ "$UMBRAL_DISCO" =~ ^[0-9]+$ ]]; then
			echo "El numero ingresado como UMBRAL DISCO no es un entero. Saliendo del script" >&2
			exit 1
		 fi
		 ;;
		m)
		 UMBRAL_MEMOR=$OPTARG
		 if ! [[ "$UMBRAL_MEMOR" =~ ^[0-9]+$ ]]; then
			echo "El numero ingresado como UMBRAL DE MEMORIA no es un entero. Saliendo del script" >&2
			exit 1
		 fi
		 ;;
		c)
		 UMBRAL_CPU=$OPTARG
		 if ! [[ "$UMBRAL_CPU" =~ ^[0-9]+$ ]]; then
			echo "El numero ingresado como UMBRAL DE CPU no es un entero. Saliendo del script" >&2
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

function espacio_disco {
	df -h "/" | gawk 'NR==2{print $5}' | tr -d '%'
}

function memoria_ram {
	local memoria_total="$(cat /proc/meminfo | grep "MemTotal" | gawk '{print $2}')"
	local memoria_usada="$(cat /proc/meminfo | grep "MemAvailable" | gawk '{print $2}')"

	local porcentaje_memoria_usada=$(( 100 * (memoria_total - memoria_usada) / memoria_total ))
	echo "$porcentaje_memoria_usada"
}

function uso_cpu {
	read -r _ user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 _ < "/proc/stat"
	local total_cpu1=$(( user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1 + steal1 ))
	local idle_total1=$(( idle1 + iowait1 ))

	sleep 1

	read -r _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 _ < "/proc/stat"
        local total_cpu2=$(( user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2 ))
        local idle_total2=$(( idle2 + iowait2 ))

	local diff_total=$(( total_cpu2 - total_cpu1 ))
	local diff_idle=$(( idle_total2 - idle_total1))

	local CPU_GLOBAL=$(( 100 * (diff_total - diff_idle) / diff_total ))

	echo "$CPU_GLOBAL"
}
ESPACIO_DISCO="$(espacio_disco)"
MEMORIA_USADA=$(memoria_ram)
CPU_USADA=$(uso_cpu)

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')

if [[ "$ESPACIO_DISCO" -le "$UMBRAL_DISCO" && "$MEMORIA_USADA" -le "$UMBRAL_MEMOR" && "$CPU_USADA" -le "$UMBRAL_CPU" ]]; then
	echo "[OK] EL SISTEMA SE ENCUENTRA EN ESTADO SALUDABLE"
	echo "Disco: ${ESPACIO_DISCO}% | RAM: ${MEMORIA_USADA}% | CPU: ${CPU_USADA}%"
else
	REPORTE="alerta_recursos_${FECHA}.log"
	if [[ -f "$REPORTE" ]]; then
        	rm -f "$REPORTE"
	fi
	exec 3>>"$REPORTE"
	if [[ "$ESPACIO_DISCO" -gt "$UMBRAL_DISCO" ]]; then
        	echo "[ALERT] EL ESPACIO EN DISCO HA EXCEDIDO EL UMBRAL" >&3
        	echo "Lo sobrepaso con: $(( ESPACIO_DISCO - UMBRAL_DISCO ))" >&3
	fi

	if [[ "$MEMORIA_USADA" -gt "$UMBRAL_MEMOR" ]]; then
        	echo "[ALERT] LA MEMORIA RAM HA EXCEDIDO EL UMBRAL" >&3
	        echo "Lo sobrepaso con $(( MEMORIA_USADA - UMBRAL_MEMOR ))" >&3
        	echo "====================================================" >&3
	        echo "Los procesos que hicieron que se exciera fueron" >&3
        	ps -eo pid,pmem,user,cmd --sort=-%mem --no-headers | head -n 5 >&3
	fi

	if [[ "$CPU_USADA" -gt "$UMBRAL_CPU" ]]; then
        	echo "[ALERT] EL USO DE CPU HA EXCEDIDO EL UMBRAL" >&3
	        echo "Lo sobrepaso con $(( CPU_USADA - UMBRAL_CPU ))" >&3
        	echo "====================================================" >&3
	        echo "Los procesos que hicieron que se exciera fueron" >&3
	        ps -eo pid,pcpu,user,cmd --sort=-%cpu --no-headers | head -n 5 >&3
	fi
	exec 3>&-
	echo "monitoreo_recursos_alertas.sh ejecutado con exito. El reporte esta guardado en $REPORTE"
fi

