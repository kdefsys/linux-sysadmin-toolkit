#!/bin/bash
# auditoria_procesos_largos.sh
### El script audita procesos largos de ejecución, genere un reporte claro, y
### permite a un sysadmin tomar decisiones informadas, sin matar procesos.
### Tiene 3 parámetros de entrada obligatorios

if [[ "$#" -ne 3 ]]; then
	echo "No hay 3 parámetros de entrada"
	echo "Saliendo del script"
	exit
fi

DIR="$1"

if [ ! -d "$DIR" ]; then
	echo "El Directorio especificado en el parametro de entrada no existe"
	echo "Saliendo del script"
	exit
fi

TIME=$(( $2 * 60))
LIMITE="$3"
FECHA=$(date +'%Y%m%d_%H%M')
SALIDA="${DIR}/auditoria_procesos_largos_$(hostname)_$FECHA.log"

PROCESOS_TOTALES=$(ps -eo pid,ppid,uid,etimes,start,pcpu,pmem,stat,cmd --no-headers)

PROCESOS_FILTRADOS=$(while read -r Pid Ppid Uid Etimes Start Pcpu Pmem Stat Cmd; do
	if [[ "$Stat" =~ ^S.* || "$Stat" =~ ^R.* || "$Stat" =~ ^D.* ]]; then
		if (( Etimes  > TIME )); then
			if [[ ! "$Cmd" =~ ^\[.*\]$ && "$Cmd" != "$0" ]]; then
				echo "$Pid $Ppid $Uid $Etimes $Start $pcpu $Pmem $Cmd"
			fi
		fi
	fi
done < <(echo "$PROCESOS_TOTALES"))

echo "---------------------------------------------"
CANTIDAD=$(echo "$PROCESOS_FILTRADOS" | wc -l)

if (( CANTIDAD == 0 )); then
	SEVERIDAD="OK"
elif (( CANTIDAD > 0 && CANTIDAD <= LIMITE )); then
	SEVERIDAD="OBSERVACIÓN"
else
	SEVERIDAD="ALERTA OPERATIVA"
fi

echo "==========PROCESOS CON EXCESO DE TIEMPO EJECUTÁNDOSE========" > "$SALIDA"
echo "Fecha: $FECHA" >> "$SALIDA"
echo "Host: $(hostname)" >> "$SALIDA"
echo "Parámetros usados: $1 $2 $3" >> "$SALIDA"
echo >> "$SALIDA"
echo -e "Procesos Detectados:" | tee -a "$SALIDA" &> /dev/null
echo "$PROCESOS_FILTRADOS" | tee -a "$SALIDA" &> /dev/null
echo >> "$SALIDA"
echo "Cantidad de procesos totales: $CANTIDAD" >> "$SALIDA"
echo "Nivel de severidad: $SEVERIDAD" >> "$SALIDA"


