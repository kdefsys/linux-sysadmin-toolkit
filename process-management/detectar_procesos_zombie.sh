#!/bin/bash
# detectar_procesos_zombie.sh
## Entrada 2 parámetros: directorio de salida de log y un umbral minimo

## Recolectamos los parámetros
## Verificamos que sean 2 parámetros de entrada

if [[ "$#" -ne 2 ]]; then
   echo "El script debe aceptar si o si 2 parámetros de entrada"
   echo "Saliendo del script"
   exit
fi

DIR="$1"
UMBRAL="$2"
FECHA=$(date +'%Y%m%d_%H%M')
SALIDA="${DIR}/zombies_$(hostname)_$FECHA.log"

## Verificamos si el directorio de entrada existe o no

if [ ! -d "$DIR" ]; then
   echo "El directorio no existe"
   echo "Saliendo del script"
   exit
fi

## Inspeccionamos la tabla de procesos del sistema y detectamos procesos cuyo
## estado sea Z
## Evitar falsos positivos (no confundir con procesos dormidos o detenidos)

echo "========Procesos Zombies========" | tee "$SALIDA" &> /dev/null
echo "Fecha y hora de publicación: $FECHA" | tee -a "$SALIDA" &> /dev/null

zombies=$(ps -eo pid,ppid,uid,cmd,start,stat |
	gawk -v es="Z" '$6 == es {print $1, $2, $3, $4, $5}')

if [ ! -z "$zombies" ]; then
	CANTIDAD=$(echo "$zombies" | wc -l)
	PADRES=$(echo "$zombies" | gawk '{print $2}' | sort -n | uniq -c)

	echo "Total de zombis detectados: $CANTIDAD" | tee -a "$SALIDA" &> /dev/null
	echo -e "\nAgrupación por procesos padre" | tee -a "$SALIDA" &> /dev/null

	while read cantidad_zombie padre; do
		if (( cantidad_zombie >=1 && cantidad_zombie <=4 )); then
			estado="OBSERVACIÓN"
		elif (( cantidad_zombie >=5 && cantidad_zombie <= 19 )); then
			estado="ADVERTENCIA"
		else
			estado="INCIDENTE"
		fi
		echo "PPID: $padre | Cantidad hijos zombie: $cantidad_zombie ($estado)" >> "$SALIDA"
	done < <(echo "$PADRES")

	echo -e "Lista completa de procesos zombis con sus datos: \n" | tee -a "$SALIDA" &> /dev/null

	echo "$zombies" >> "$SALIDA"

	if (( CANTIDAD > UMBRAL )); then
		echo "Se superó el umbral de $UMBRAL: riesgo operativo" >> "$SALIDA"
	else
		echo "No se superó el umbral de $UMBRAL, asi que todo OK" >> "$SALIDA"
	fi
else
	echo "No existen usuarios zombies " >> "$SALIDA"
fi
