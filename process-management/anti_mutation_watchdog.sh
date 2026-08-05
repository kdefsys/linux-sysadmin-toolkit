#!/bin/bash
### Nombre: anti_mutation_watchdog.sh
### Autor: kdefsys
### Descripcion: Los ataques por malware moderno y ransomware en entornos Linux suelen emplear técnicas de evadir detección por firma o comportamiento basándose en dos vectores
### principales:
### 1. Ejecución anómala en memoria o rutas temporales: Inyección de código mediante el enmascaramiento de binarios, la ejecución desde rutas volátiles (/tmp, /dev/shm) o la
### eliminación del binario ejecutable en disco mientras el proceso sigue activo en memoria (deleted).
### 2. Ráfagas de mutación masiva: Modificación rápida e indiscriminada de archivos críticos (cifrado o corrupción de datos) en intervalos de pocos segundos.
### El equipo de respuesta a incidentes (Blue Team) requiere un script en Bash que funcione como un IDS (Sistema de Detección de Intrusiones) activo en segundo plano. Debe ser
### capaz de vigilar el sistema en tiempo real, identificar anomalías estructurales en los procesos, correlacionar ráfagas de modificación en carpetas críticas con los descriptores
### de archivo abiertos, congelar inmediatamente los procesos sospechosos y registrar evidencia forense estructurada en formato JSON.
### Este script es de monitoreo continuo que audita la estructura del pseudofilesystem /proc, valida la integridad ante sospechas de ransoware enviando señales de suspension
### SIGSTOP, y genera un log de incidentes forenses en formato JSON valido al finalizar su ejecucion.
### Uso: ./anti_mutation_watchdog.sh -d <directorio_a_vigilar> -u <limite_de_archivos_modificados> -f <ruta_archivo_configuracion_lista_blanca> [-h]

function help {
	echo "El script se debe de ejecutar: ./anti_mutation_watchdog.sh -d <directorio_a_vigilar> -u <limite_de_archivos_modificados> -f <ruta_archivo_configuracion_lista_blanca> [-h]"
	echo "   -d : Directorio critico a vigilar contra rafagas de mutacion."
	echo "   -u : Limite de archivos modificados (umbral de tolerancia) en la ventana de tiempo evaluada."
	echo "   -f : Ruta del archivo de configuracion (Lista Blanca de procesos/PIDs permitidos)."
	echo "   -h : Imprime esta guia"
}

LOG_JSON="ids_forensic_alerta.json"

while getopts :d:u:f:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		 fi
		 ;;
		u)
		 LIMITE="$OPTARG"
		 ;;
		f)
		 LISTA_BLANCA="$OPTARG"
		 if [[ ! -f "$LISTA_BLANCA" ]]; then
			echo "La ruta de la lista blanca no existe. Saliendo del script" >&2
			exit 1
		 fi
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion ingresada invalida"
		 help
		 exit 1
		 ;;
	esac
done

if [[ -z "$DIRECTORIO" || -z "$LIMITE" || -z "$LISTA_BLANCA" ]]; then
	echo "Error: Faltan argumentos obligatorios." >&2
	help
	exit 1
fi

function verificacion_lista_blanca {
	local pid=$1
	local comando=""

	if [[ -f "/proc/$pid/comm" ]]; then comando="$(cat /proc/$pid/comm)"; fi

	if grep -qxE "($pid|$comando)" "$LISTA_BLANCA"; then
		return 0
	fi
	return 1
}

function generar_json_reporte {

	local timestamp="$1"
	local pid="$2"
	local ppid="$3"
	local binario="$4"
	local tipo_alerta="$5"
	local archivos_afectados="$6"

	local archivos_json="[]"
	if [[ -n "${archivos_afectados// /}" ]]; then
		local formatted
		formatted=$(echo "$archivos_afectados" | xargs | sed 's/ /", "/g')
		archivos_json="[\"$formatted\"]"
	fi

	{
		echo "{"
		echo "  \"timestamp\": \"$timestamp\","
		echo "  \"pid\": $pid,"
		echo "  \"ppid\": $ppid,"
		echo "  \"real_binary\": \"$binario\","
		echo "  \"alert_type\": \"$tipo_alerta\","
		echo "  \"containment_status\": \"SUSPENDED\","
		echo "  \"affected_files\": $archivos_json"
		echo "},"
	} >> "$LOG_JSON"

}

function congelar_procesos {
	local pid=$1
	local ppid=$2

	echo "[-] [CONTENCION] Enviando SIGSTOP al PID agresor: $pid"
	kill -STOP "$pid" 2>/dev/null

	if [[ "$ppid" -gt 1 ]]; then
		echo "[-] [CONTENCION] Enviando SIGSTOP al PPID (Padre watchdog): $ppid"
		kill -STOP "$ppid" 2>/dev/null
	fi

}

# =============================================================================================================
# BUCLE PRINCIPAL DE AUDITORIA (MONITOREO EN TIEMPO REAL)
# =============================================================================================================

echo "========================================================================================================="
echo "		INICIANDO GUARDIAN ANTIRANSOMWARE Y MONITOR DE MUTACION DE PROCESOS"
echo "========================================================================================================="
echo "[+] Vigilando zona critica: $DIRECTORIO"
echo "[+] Umbral de tolerancia: $LIMITE archivos en 5 segundos"
echo "========================================================================================================="

if [[ ! -s "$LOG_JSON" ]]; then
	echo "[" > "$LOG_JSON"
fi

cerrar_json_valido() {
	echo -e "\n[-] Deteniendo el guardian de procesos..."
	if [[ -f "$LOG_JSON" ]]; then
		sed -i '$ s/,$//' "$LOG_JSON"
		echo "]" >> "$LOG_JSON"
		echo "[+] Log forense estructurado correctamente en: $LOG_JSON"
	fi
	exit 0
}

trap cerrar_json_valido SIGINT SIGTERM

while true; do
	FECHA_INICIO=$(date '+%Y-%m-%d %H:%M:%S')
	# ---------------------------------------------------------------------------------------------
	# REGLA 1: DETECCION DE BINARIOS ENMASCARADOS / ELIMINADOS EN TODO EL SISTEMA
	# ---------------------------------------------------------------------------------------------
	for proc_dir in /proc/[0-9]*/; do
		PID=$(basename "$proc_dir")
		if [[ "$PID" -eq "$$" ]]; then continue; fi
		BINARIO_REAL="$(readlink -f /proc/$PID/exe 2>/dev/null)"
		[[ -z "$BINARIO_REAL" ]] && continue
		PADRE_PID=$(gawk '{print $4}' "/proc/$PID/stat" 2>/dev/null)
		[[ -z "$PADRE_PID" ]] && PADRE_PID=0

		ALERTA=""
		if [[ "$BINARIO_REAL" == *" (deleted)"* ]]; then
			ALERTA="PROCESO ANOMALO (ALERTA ROJA: BINARIO ELIMINADO)"
		elif [[ "$BINARIO_REAL" =~ ^/tmp/ || "$BINARIO_REAL" =~ ^/dev/shm/ ]]; then
			ALERTA="PROCESO ANOMALO (ALERTA: EJECUCION EN RUTA TEMPORAL)"
		fi

		if [[ -n "$ALERTA" ]]; then
			if ! verificacion_lista_blanca "$PID"; then
				TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
				echo "[!] ¡MUTACION DETECTADA! PID: $PID | MOTIVO: $ALERTA"
				congelar_procesos "$PID" "$PADRE_PID"
				generar_json_reporte "$TIMESTAMP" "$PID" "$PADRE_PID" "$BINARIO_REAL" "$ALERTA" ""
			fi
		fi
	done
	# -----------------------------------------------------------------------------------------------
	# REGLA 2: CORRELACION DE EVENTOS (EFECTO RANSOWARE EN LA RUTA CRITICA)
	# -----------------------------------------------------------------------------------------------
	# Buscamos archivos modificados en los ultimos 5 segundos en el directorio critico

	ARCHIVOS_MODIFICADOS=$(find "$DIRECTORIO" -type f -mmin -0.083 2>/dev/null)
	CANTIDAD_MODIFICADOS=$(echo -n "$ARCHIVOS_MODIFICADOS" | grep -c '^')

	if [[ "$CANTIDAD_MODIFICADOS" -gt "$LIMITE" ]]; then
		TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
		echo "[!] [ALERTA RANSOMWARE] Ráfaga de mutaciones: $CANTIDAD_MODIFICADOS archivos modificados."
		CULPABLE_PID=""
		CULPABLE_PPID=0
		CULPABLE_BIN=""

		for proc_dir in /proc/[0-9]*/; do
			PID_CHECK=$(basename "$proc_dir")
			if [[ "$PID_CHECK" -eq "$$" ]]; then continue; fi
			if verificacion_lista_blanca "$PID_CHECK"; then continue; fi
			for fd in /proc/"$PID_CHECK"/fd/*; do
				[[ ! -e "$fd" ]] && continue
				FD_TARGET=$(readlink -f "$fd" 2>/dev/null)
				if [[ "$FD_TARGET" == "$DIRECTORIO"* ]]; then
					CULPABLE_PID="$PID_CHECK"
					CULPABLE_PPID=$(gawk '{print $4}' "/proc/$PID_CHECK/stat" 2>/dev/null)
					CULPABLE_BIN="$(readlink -f /proc/$PID_CHECK/exe 2>/dev/null)"
					break 2
				fi
			done
		done

		if [[ -n "$CULPABLE_PID" ]]; then
			echo "[!] Culpable Identificado -> PID $CULPABLE_PID | Binario: $CULPABLE_BIN"
			congelar_procesos "$CULPABLE_PID" "$CULPABLE_PPID"
			LISTA_FILES=$(echo "$ARCHIVOS_MODIFICADOS" | tr '\n' ' ')
			generar_json_reporte "$TIMESTAMP" "$CULPABLE_PID" "$CULPABLE_PPID" "$CULPABLE_BIN" "RANSOMWARE_MUTATION_BURST" "$LISTA_FILES"
		else
			echo "[-] Rafaga detectada pero el proceso cerro sus descriptores antes del analisis"
		fi
	fi
	sleep 1
done
