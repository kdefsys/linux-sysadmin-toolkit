#!/bin/bash
# lsblk_report.sh
## Audita el estado de los dispositivos de bloque del sistema, generando un
## reporte estructurado que muestre:
## jerarquía de discos (arbol), tamaños, tipo de dispositivo, puntos de montaje
## y estado general del almacenamiento

## Verificamos si se ejecuta con permisos adecuados

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe ejecutarse con permiso adecuado"
	echo "Saliendo del script"
	exit 1
fi

if [[ "$#" -ne 1 ]]; then
	echo "El script no tiene exactamente un parámetro de entrada"
	echo "Que serviría como uso de directorio a guardar el archivo .log"
	echo "Salimos del script"
	exit 1
fi

## Variables Globales

DIR="$1"
FECHA=$(date +'%Y%m%d-%H%M')
SALIDA="${DIR}/dispositivos_bloque_$FECHA.log"

if [ ! -d "$DIR" ]; then
	echo "El directorio ingresado como parámetro de entrada no existe"
	echo "Saliendo del script"
	exit 1
fi

echo "========Lista de los dispositivos de bloque del sistema========" > "$SALIDA"
echo -e "\nFECHA: $FECHA" >> "$SALIDA"
echo -e "\nHOSTNAME: $(hostname)" >> "$SALIDA"
echo -e "\nUSER: $USER" >> "$SALIDA"
echo -e "\n\nLista completa" >> "$SALIDA"

## Verificamos si el comando lsblk existe

lsblk > /dev/null

if [[ "$?" -ne 0 ]]; then
	echo "El comando lsblk no existe"
	echo "Desea instalarlo al sistema? (Y/N)"
	read -n1 op
	case "$op" in
		Y|y)
		   apt update
		   apt install util-linux
		   echo "Ya está instalado"
		   ;;
		N|n)
		   echo "Entonces salimos del script"
		   exit 1
		   ;;
		*) echo "Opcion incorrecta" ; echo "Saliendo del script" 
		   exit 1;;
	esac
fi

## Recolectamos informacion obtenida del comando lsblk

INFO=$(lsblk -no NAME,TYPE,SIZE,FSTYPE,MOUNTPOINT,PKNAME | sed -n '1!G; h; $p' |
     gawk '{
	estado1="OK"
	if( $2 == "part") {
	   discos_padre[$6]++
	   if( $5 == "" )estado1="riesgo potencial"
	}
	else if( $2 == "disk" ){
	   for (i in discos_padre) if(i == $1) estado1="OK"
	   if(estado1 != "OK") estado1="No-incializado"
	}
	else if( $2 == "loop") estado1="uso-temporal"
	else estado1="Otro"
       print $1, $2, $3, $4, $5, $6, estado1
   }')

echo "$INFO" | sed -n '1!G; h; $p'>> "$SALIDA"

## Empezamos las filtraciones correspondientes
## Recolectamos el numero de discos detectados, el numero de particiones y
## cuantos estan montados vs no montados

nueva_salida=$(gawk -v discos=0 -v parti=0 -v montados=0 -v no_montados=0 '
 {
  if( $2 == "disk") discos++
  if( $2 == "part") parti++
  if( $5 == "" ) no_montados++
  if( $5 != "") montados++
 }
 END{
   printf "\nNumero de discos: %s\nNumero de particiones: %s\nNumero de montados: %s\nNumero de no montados: %s", discos, parti , montados, no_montados
 }' < <(echo "$INFO"))

echo "$nueva_salida" >> "$SALIDA"
