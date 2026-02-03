#!/bin/bash
# device_audit.sh
### Este Script genera un reporte técnico de dispositivos de bloque, mostrando:
### Nombre del dispositivo, Tipo (block/char), Major y minor number, Driver del kernel, Tipo de dispositivo
### Información SCSI (host,bus,ID,LUN)
### Punto de montaje (si existe)

## Ejecutarlo si o si como superusuario

if [[ "$EUID" -ne 0 ]]; then
	echo "No fue ejecutado como superusuario"
	echo "Saliendo del script"
	exit 1
fi

## Declaramos variables

FECHA=$(date +'%Y%m%d_%H%M')
SALIDA="device_audit_report.txt"

exec 1> "$SALIDA"

echo "======== INFORME DE AUDITORIA DE DISPOSTIVIO DE BLOQUE ========"
echo "Hostname: $(hostname)"
echo "Date: $FECHA"
echo "User: $USER"
echo "==============================================================="
echo
echo

while IFS="|" read nombre tipo numbers fstipo montaje trans; do
	if [[ "$tipo" == "loop" || "$tipo" == "ram" ]]; then continue; fi
	echo "Device: $nombre"
	if [[ -b "/dev/$nombre" ]]; then
		dtype="block"
	elif [[ -c "/dev/$nombre" ]]; then
		dtype="char"
	else
		dtype="DESCONOCIDO"
	fi
	echo "Type: $dtype"
	Major="${numbers%:*}"
	Minor="${numbers#*:}"
	echo "Major: ${Major}"
	echo "Minor: ${Minor}"
	driver=$(cat /proc/devices | grep "^[[:space:]]*${Major}[[:space:]]")
	echo "Driver: ${driver##*[[:space:]]}"
	echo "Transport: ${trans}"
	Host=""
	Bus=""
	ID=""
	Lun=""
	while IFS=":" read host bus id lun; do
		Host="${host#*[}"
		Bus="$bus"
		ID="$id"
		Lun="${lun%]*}"
	done < <(lsscsi | tr ' ' ':' | grep "${nombre}")
	if [[ -n "$Host" ]]; then
        	echo -e "SCSI:\n  Host: ${Host}\n  Bus: ${Bus}\n  ID=${ID}\n  Lun=${Lun}"
	else
		echo "Es una particion asi que no tiene SCSI"
	fi
	if [[ -z "$montaje" ]]; then
		echo "Montado: NO ESTÁ MONTADO"
	else
		echo "Montado: $montaje"
	fi
	echo "Filesystem: $fstipo"
	echo "-------------------------------------------------"
	echo
	echo
done < <(lsblk -nro name,type,maj:min,fstype,mountpoint,tran | tr ' ' '|')

echo "FIN DEL REPORTE"
