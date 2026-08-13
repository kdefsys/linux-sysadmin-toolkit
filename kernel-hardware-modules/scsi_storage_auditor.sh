#!/bin/bash
#### Nombre: scsi_storage_auditor.sh
### Autor: kdefsys
### Descripcion: En el centro de datos de la empresa, los servidores Linux están conectados a una red SAN (Storage Area Network) desde la cual reciben constantemente LUNs
### (Logical Unit Numbers) de almacenamiento presentados desde cabinas externas.
### El equipo de Auditoría y Ciberoperaciones ha detectado que varios administradores cometen el error de montar o configurar el almacenamiento basándose en nombres de dispositivos
### tradicionales y volátiles (como /dev/sdb o /dev/sdc). Esto ha provocado incidentes graves de caídas de servicio (outages) tras los reinicios de los servidores, debido a que el
### orden de inicialización de los discos en el bus SCSI no es determinista y los nombres de bloque pueden cambiar dinámicamente.
### Este script actua como una herramienta de inspeccion en caliente y audita forense para alamcenaniento SCSI/SAN. El script analiza un dispositivo de bloque especifico ingresado
### como argumento y genera un reporte tecnico dividido en 3 fases de diagnostico.
###Uso: sudo ./scsi_storage_auditor.sh <nombre_dispositivo_bloque>

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con privilegios sudo" >&2
	exit 1
fi

if [[ "$#" -ne 1 ]]; then
	echo "El script debe de tener un solo argumento que es el nombre del dispositivo de bloque" >&2
	exit 1
fi

DISPOSITIVO="/dev/${1}"

[[ ! -b "$DISPOSITIVO" ]] && { echo "El argumento no pertenece a un dispositivo de bloque. Saliendo del script" >&2; exit 1; }

### ---------------------------------------------------------------------------------------------------------
### 				FASE 01: DIRECCIONAMIENTO JERARQUICO SCSI (HCTL)
### ---------------------------------------------------------------------------------------------------------

gawk -v dispositivo="$DISPOSITIVO" '{
	split($1,arreglo,":")
	print "========================================== FASE 01: DIRECCIONAMIENTO JERARQUICO SCSI =========================================="
	printf "DIRECCION HCTL DEL DISPOSITIVO: %s\n", dispositivo
	printf "Host Adapter: %s]\n", arreglo[1]
	printf "Bus/Channel: [%s]\n", arreglo[2]
	printf "Target ID: [%s]\n", arreglo[3]
	printf "LUN [%s\n", arreglo[4]
}' < <(lsscsi 2>/dev/null | grep  "${DISPOSITIVO}")

### ---------------------------------------------------------------------------------------------------------------
### 			FASE 02: TELEMETRIA DESDE EL SISTEMA DE ARCHIVOS VIRTUAL (/sys)
### ---------------------------------------------------------------------------------------------------------------

echo "====================================================== TELEMETRIA VIRTUAL CON /sys ==============================================="
echo "DISPOSITIVO: $DISPOSITIVO"
echo "=================================================================================================================================="

RUTA_SYS="/sys$(udevadm info -q path -n "$DISPOSITIVO")"
echo "RUTA EN sys: ${RUTA_SYS}"

if [[ -f "${RUTA_SYS}/device/model" ]]; then
	MODELO="$(cat "${RUTA_SYS}"/device/model)"
	echo "MODELO: $MODELO"
else
	echo "No tiene Modelo asignado"
fi

printf "CAPACIDAD EN SECTORES: %s\n" "$(cat "${RUTA_SYS}"/size 2>/dev/null)"

if [[ "$(cat "${RUTA_SYS}"/queue/rotational 2>/dev/null)" -eq 1 ]]; then
	echo "NATURALEZA FISICA: [MECANICO/HDD]"
elif [[ "$(cat "${RUTA_SYS}"/queue/rotational 2>/dev/null)" -eq 0 ]]; then
	echo "NATURALEZA FISICA: [SSD/FLASH]"
else
	echo "NATURALEZA FISICA: OTRA"
fi

### ---------------------------------------------------------------------------------------------------------------------
### 		FASE 03: DESCUBRIMIENTO DE IDENTIFICADORES PERSISTENTES (Inmunes a Reinicios)
### ---------------------------------------------------------------------------------------------------------------------

echo "FASE 3: ENLACES PERSISTENTES INMUNE A REINICIOS"
echo "-> Rutas detectadas en /dev/disk/by-id:"

ls -l /dev/disk/by-id | grep -iE "$1" | gawk '{print "	 -> /dev/disk/by-id/" $9}'

echo "-----------------------------------------------"
echo "[+] scsi_storage_auditor.sh finalizada con exito."
