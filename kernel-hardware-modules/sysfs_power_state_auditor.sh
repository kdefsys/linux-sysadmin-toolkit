#!/bin/bash
### Nombre: sysfs_power_state_auditor.sh
### Autor: kdefsys
### Descripcion: En los centros de datos modernos y servidores empresariales de alta densidad, la optimización del consumo energético y la gestión térmica del hardware son críticas.
### Muchas veces, los discos de estado sólido (SSD) y discos mecánicos (HDD) en caliente operan bajo perfiles de energía por defecto ineficientes o carecen de políticas de
### administración de energía dinámicas (Advanced Power Management - APM o Link Power Management - ALPM), lo que incrementa el desgaste prematuro de los componentes o mantiene un
### consumo calórico innecesario en los racks.
### Este script actua como un auditor de politicas de energía para dispositivos de bloques. El script debe recibir como argumento el nombre de un dispositivo de bloque (por ejemplo:
### sda, sdb nvme0n1) y generar un informe técnico estructurado en fases utilizando la telemetría del sistema de archivos virtual /sys
### Uso: sudo ./sysfs_power_state_auditor.sh <nombre_dispositivo_bloque>

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con permisos de superusuario" >&2
	exit 1
fi

if [[ "$#" -ne 1 ]]; then
	echo "El script solo debe de tener un unico argumento que es el nombre del dispositivo" >&2
	exit 1
fi

NOMBRE="$1"
DISPOSITIVO="/dev/${NOMBRE}"

[[ ! -b "$DISPOSTIVIO" ]] && { echo "El dispositivo ingresado no existe en el sistema"; exit 1; }

echo "[+] AUDITANDO ESTADO ENERGÉTICO PARA: $DISPOSITIVO"
echo "---------------------------------------------------------------------------------------------"

### ------------------------------------------------------------------------------------------------
###			FASE 01: LOCALIZACION DEL ARBOL DE ENERGIA
### ------------------------------------------------------------------------------------------------

RUTA_SYS="/sys$(udevadm info -q path -n "$DISPOSITIVO")"
echo " -> Ruta base en sysfs: $RUTA_SYS"

if [[ ! -d "$RUTA_SYS" ]]; then
	echo "[-] Error: No se pudo resolver la ruta física en SysFS para $DISPOSITIVO." >&2
	exit 1
fi

### ------------------------------------------------------------------------------------------------
### 		FASE 02: INTROSPECCION DE PARAMETROS ENERGETICOS Y DE ESTADO
### ------------------------------------------------------------------------------------------------

echo "[+] FASE 2: Extrayendo telemetría de energía y colas desde RAM ... "
if [[ -f "${RUTA_SYS}/power/control" ]]; then
	ESTADO_PODER="$(cat "${RUTA_SYS}/power/control")"
else
	ESTADO_PODER="$(cat "${RUTA_SYS}/device/power/control" 2>/dev/null || echo "NO DISPONIBLE")"
fi

if [[ -f "${RUTA_SYS}/queue/scheduler" ]]; then
	SCHEDULER="$(cat "${RUTA_SYS}/queue/scheduler")"
else
	SCHEDULER="No disponible"
fi

if [[ -f "${RUTA_SYS}/power/runtime_active_time" ]]; then
	TIEMPO_ACTIVO="$(cat "${RUTA_SYS}/power/runtime_active_time")"
else
	TIEMPO_ACTIVO="N/A"
fi

echo " -> Modo de Control de Energia (Runtime PM): ${ESTADO_PODER}"
echo " -> Planificador de I/O Activo (Scheduler): ${SCHEDULER}"
echo " -> Tiempo acumulado en estado activo (ms): ${TIEMPO_ACTIVO}"

### ------------------------------------------------------------------------------------------------
###		FASE 03: REPORTE DE AUDITORIA Y RECOMENDACION OPERATIVO
### ------------------------------------------------------------------------------------------------

echo "-------------------------------------------------------------------------------------------"
echo "[+] Fase 03: Diagnostico y Recomendacion de Infraestrcutura"
if [[ "$ESTADO_PODER" == "auto" ]]; then
	echo "[AVERTENCIA] El dispositivo opera con suspensión dinamica (auto). Puede generar latencia en I/O de base de datos."
elif [[ "$ESTADO_PODER" == "on" ]]; then
	echo "[OK]: El dispositivo se encuentra en modo de rendimiento constante (on). Ideal para servidores de alta disponibilidad."
else
	echo "[INFO]: El subsistema no soporta control directo de Runtime PM en este nivel."
fi
echo "--------------------------------------------------------------------------------------------"
echo "[+] Auditoría energética finalizada con éxito."
