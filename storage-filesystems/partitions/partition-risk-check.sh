#!/bin/bash
# partition-risk-check.sh
### Script que detecta riesgos de particionado que pueden causar probblemas graves en servidores de producción
### Este script actuá como un pre-flight check antes de:
### Ampliar discos, tocar LVM, montar nuevos filesystems y realizar migraciones

function mensaje {
	echo "$1"
	echo "Saliendo del script..."
	sleep 1
}

## El script debe si o sí ejecutarse con privilegios de superusuario

if [[ "$EUID" -ne 0 ]]; then
	$(mensaje "No fue ejecutado con privilegio de supuerusuario")
	exit 1
fi

## Debe tener si o śi un parámetro de entrada

if [[ "$#" -ne 1 ]]; then
	$(mensaje "El script no tiene un parámetro de entrada")
	exit 1
fi

## Recolecctamos los parámetros de entrada y declaramos variables

DIR="$1"

if [[ ! -d "$DIR" ]]; then
	echo "El directorio no existe, desea crearlo? (Y/N): "
	read -n1 op
	case "$op" in
		Y|y)
		   mkdir log
		   echo "Creado con éxito"
		   ;;
		N|n)
		   $(mensaje "No se creó ningun directorio") ;;
		*)
		   $(mensaje "Opción incorrecta") ;;
	esac
fi

FECHA=$(date +'%Y%m%d_%H%M')
SALIDA="${DIR}/partition_disk_check_${FECHA}.log"

cantidad_discos=0
cantidad_particiones=0
cantidad_ok=0
cantidad_warning=0
cantidad_critico=0
mayor=0

declare -A discos

## Apuntamos cuantas particiones tiene un disco

while read padre; do
	if [[ -n "$padre" ]]; then
		((++discos["$padre"]))
	fi
done < <(lsblk -nro pkname)

exec 1> "$SALIDA"

echo "====================================================="
echo "PARTITION RISK CHECK REPORT"
echo "====================================================="
echo "Hostname: $(hostname)"
echo "Date: $FECHA"
echo "User: $USER"
echo
echo "-----------------------------------------------------"
echo "[RIESGO ESTRUCTURAL]"
echo "-----------------------------------------------------"
echo
echo

## Primero veamos la parte de structural risks

while read nombre tipo tama tipotable; do
	if [[ "$tipo" != "disk" ]]; then
		continue; fi
	((++cantidad_discos))
	estado="OK"
	recomendacion="Ninguna, todo está muy bien en este disco"
	if [[ -z "${discos[$nombre]}" ]]; then
		estado="WARNING"
		mensaje="El disco no tiene particiones"
		recomendacion="Añadir particiones para este disco"
		((++cantidad_warning))
		if (( mayor < 1 )); then mayor=1; fi
	elif [[ "${discos[$nombre]}" -eq 1 ]]; then
		estado="WARNING"
		mensaje="El disco solo tiene una partición"
		recomendacion="Añadir mas particiones, no solo una"
		((++cantidad_warning))
		if (( mayor < 1 )); then mayor=1; fi
	else
		mensaje="Tiene varias particiones y sus tablas de particiones estan OK"
	fi
	if [[ "$tipotable" == "mbr" || "$tipotable" == "MBR" ]]; then
		if [[ "$tama" == "2TB" || "$tama" == "2tb" ]]; then
			((++cantidad_critico))
			estado="CRITICAL"
			mensaje="El disco es MBR y sobrepasa el límite de 2TB"
			recomendacion="Convertir la tabla a gpt"
			if (( mayor < 2 )); then mayor=2; fi
		fi
	fi
	if [[ "$estado" == "OK" ]]; then
		((++cantidad_ok))
	fi
	echo -e "[$estado] disk $nombre"
	echo -e "\tPartition Table\t\t:${tipotable}"
	echo -e "\tTamaño del disco\t:${tama}"
	echo -e "\tMensaje\t\t:${mensaje}"
	echo -e "\tRecomendación\t\t:${recomendacion}"
	echo
	echo

done < <(lsblk -nro name,type,size,pttype)

## Ahora veamos la zona de las particiones, si tienen filesystems o no, si están montadas o no

echo "-----------------------------------------------------"
echo "RIESGO OPERACIONAL"
echo "-----------------------------------------------------"
echo
echo

while read nombre tipo tama tipofs montaje; do
	if [[ "$tipo" != "part" ]]; then
		continue; fi
	((++cantidad_particiones))
	estado="OK"
	mensaje="La particion tiene su filesystem creada y esta montada"
	recomendacion="Ninguna, todo esta OK"
	if [[ -n "$tipofs" ]]; then
		filesystem="$tipofs"
		if [[ -z "$montaje" ]]; then
			((++cantidad_warning))
			montado="NO MONTADO"
			estado="WARNING"
			mensaje="La partición tiene un filesystem creado pero no está montado"
			recomendacion="Montar el sistema de archivo de esa particion"
			if (( mayor < 1 )); then mayor=1; fi
		else
			montado="$montaje"
		fi
	else
		((++cantidad_critico))
		filesystem="NO PRESENTE"
		estado="CRITICO"
		mensaje="La partición no tiene un filesystem creado."
		recomendacion="Crearle un filesystem a este archivo"
		if (( mayor < 2 )); then mayor=2; fi
	fi
	if [[ "$estado" == "OK" ]]; then
		((++cantidad_ok))
	fi
	echo -e "[$estado] Partiton: $nombre"
	echo -e "\t- Filesystem\t:${filesystem}"
	echo -e "\t- Mountpoint\t:${montado}"
	echo -e "\t- Mensaje\t:${mensaje}"
	echo -e "\t- Recomendacion\t:${recomendacion}"
	echo
	echo

done < <(lsblk -nro name,type,size,fstype,mountpoint)

case "$mayor" in
	0)
	  estado_sistema="OK" ;;
	1)
	  estado_sistema="WARNING" ;;
	2)
	  estado_sistema="CRITICAL" ;;
esac

## Ahora la parte de analisis del sistema de archivo

echo "----------------------------------------------------------"
echo "[DISEÑO DEL SISTEMA DE ARCHIVOS CRÍTICOS]"
echo "----------------------------------------------------------"
echo
echo

root_dev=""
var_dev=""
boot_dev=""

## Recolectamos dispositivos por mountpoint

while read nombre montaje; do
	case "$montaje" in
		"/")
		   root_dev="$nombre" ;;
		"/var")
		   var_dev="$nombre" ;;
		"/boot")
		   boot_dev="$nombre" ;;
	esac
done < <(lsblk -nro name,mountpoint)

layout_ok=1

## / y /var en la misma particion

if [[ -n "$root_dev" && -n "$var_dev" && "$root_dev" == "$var_dev" ]]; then
	echo "[WARNING] Diseño del sistema de archivos"
	echo " - / and /var comparten la misma particion $(root_dev)"
	echo " - Riesgo: El crecimiento del registro puede llenar el sistema de archivo raiz"
	echo
	((++cantidad_warning))
	layout_ok=0
	if (( mayor < 1 )); then mayor=1; fi
fi

## /boot no separado

if [[ -z "$boot_dev" ]]; then
	echo "[WARNING] /boot"
	echo " - Problema: No está en una partición separada"
	echo " - Impacto: Riesgo de actualización del kernel"
	echo
	((++cantidad_warning))
	layout_ok=0
	if (( mayor < 1 )); then mayor=1; fi
fi

## layout sano

if (( layout_ok == 1 )); then
	echo "[OK] Diseño de sistema de archivos"
	echo " -/, /var and /boot debidamente separados"
	echo
	(( ++cantidad_ok))
fi

## Ahora ponemos los resultados totales

echo "--------------------------------------------------"
echo "[SUMMARY]"
echo "--------------------------------------------------"
echo
echo "Total de discos analizados ${cantidad_discos}"
echo "Total de particiones analizadas ${cantidad_particiones}"
echo
echo "OK: ${cantidad_ok}"
echo "WARNING: ${cantidad_warning}"
echo "CRITICAL: ${cantidad_critico}"
echo
echo "--------------------------------------------------"
echo "RESULTADO FINAL"
echo "--------------------------------------------------"
echo
echo "ESTADO DEL SISTEMA : $estado_sistema"
echo "Exit code: $mayor"
echo
echo "--------------------------------------------------"
echo "FIN DEL REPORTE"
echo "--------------------------------------------------"

