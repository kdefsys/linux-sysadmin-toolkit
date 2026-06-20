#!/bin/bash
###Nombre: scsi_storage_auditor.sh
###Autor: kdefsys
###Contexto: En el centro de datos de la empresa, los servidores reciben constantemente nuevas rebanadas de almacenamiento (LUNs) desde una cabina de discos externa (SAN). 
###El equipo de Ciberseguridad y Operaciones ha detectado que los administradores a veces cometen errores al montar discos basándose en rutas volátiles como /dev/sdb, lo que causa 
###caídas del sistema tras los reinicios.
###Descripción: Actúa como una herramienta de auditoria forense y de infraestructura en caliente.
###Uso: sudo ./scsi_storage_auditor.sh <nombre_dispositivo_bloque>

if [[ "$EUID" -ne 0 ]]; then echo "El script no tiene permiso de superusuario"; exit 1; fi
if [[ "$#" -ne 1 ]]; then echo "El script no recibe un argumento obligatorio que es el nombre del disco"; exit 1; fi

NOMBRE="$1"
NOMBRE_DEV="/dev/${1}"

if [[ ! -b "$NOMBRE_DEV" ]]; then echo "El dispositivo no existe en el sistema"; exit 1; fi

echo "[+] INICIANDO AUDITORÍA DE INFRAESTRUCTURA PARA: $NOMBRE"
echo "----------------------------------------------------"
#===================================================================================================================
#FASE 01: EXTRACCIÓN DE LA JERARQUÍA SCSI (HCTL):
#===================================================================================================================

gawk -v nombre_dispositivo="${NOMBRE_DEV}" '{
	cadena=$1
	split(cadena,datos,":")
	printf "\n[FASE 1: DIRECCIONAMIENTO SCSI (HCTL)]\n"
	printf " -> Dirección Completa: %s\n", cadena
	printf "    DISPOSITIVO: %s\n", nombre_dispositivo
	printf "    HOST ADAPTER SCSI: %s]\n", datos[1]
	printf "    BUS SCSI: [%s]\n", datos[2]
	printf "    ID TARGET: [%s]\n", datos[3]
	printf "    LUN: [%s\n", datos[4]
	printf "\n\n"
}' < <(lsscsi | grep -iE "${NOMBRE_DEV}")

#===================================================================================================================
#FASE 02: INTROSPECCIÓN VIRTUAL EN /sys/devices:
#===================================================================================================================

RUTA_COMPLETA_EN_SYS=$(udevadm info -q path -n "${NOMBRE_DEV}")

printf "[FASE2: TELEMETRÍA DESDE /SYS (RAM)]\n"
printf " -> Ruta Sysfs: /sys%s\n" "${RUTA_COMPLETA_EN_SYS}"

if [[ -f "/sys/${RUTA_COMPLETA_EN_SYS}/device/model" ]]; then
	printf "    Modelo de Fábrica: %s\n" "$(cat /sys${RUTA_COMPLETA_EN_SYS}/device/model 2>/dev/null)"
else
	echo "     No contiene modelo"
fi

printf "    Capacidad en Sectores: %s\n" $(cat "/sys${RUTA_COMPLETA_EN_SYS}/size" 2>/dev/null)

if [[ "$(cat /sys${RUTA_COMPLETA_EN_SYS}/queue/rotational 2>/dev/null)" -eq 1 ]]; then
	printf "    Naturaleza Física: [MECANICO/HDD]\n"
elif [[ "$(cat /sys${RUTA_COMPLETA_EN_SYS}/queue/rotational 2>/dev/null)" -eq 0 ]]; then
	printf "    Naturaleza Física: [SSD/FLASH]\n"
else
	printf "    Naturaleza Física: [OTRO]\n"
fi

echo -e "\n\n"
#===================================================================================================================
#FASE 03: DESCUBRIMIENTO DE IDENTIDADES INDESTRUCTIBLES
#===================================================================================================================

printf "[FASE 3: ENLACES PERSISTENTES INMUNE A REINICIOS]\n"
printf " -> Rutas seguras detectadas en /dev/disk/by-id:\n"

ls -l /dev/disk/by-id | grep -iE "/${NOMBRE}" | gawk '{printf "    -/dev/disk/by-id/%s\n", $9}'

printf "\n-------------------------------------------------------\n"
printf "[+] Auditoría finalizada con éxito\n"
