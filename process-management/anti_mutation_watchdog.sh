#!/bin/bash
###Nombre: anti_mutation_watchdog.sh
###Autor: kdefsys
###Funciona como un sistema de deteccion temprana (IDS a nivel de procesos).
###Uso: ./anti_mutation_watchdog.sh <directorio> <limite_tasa> <file_configuracion>

if [[ "$#" -ne 3 ]]; then
	echo -e "El script no recibe 3 argumentos\nSaliendo del script.."
	sleep 2
	exit 1
fi

DIR_CRITICO="$1"
LIMITE_MUTACION="$2"
LISTA_BLANCA_FILE="$3"
LOG_JSON="ids_forensic_alerta.json"

if [[ ! -d "$DIR_CRITICO" ]]; then
	echo "Error: El directorio crítico '$DIR_CRITICO' no existe"
	exit 1
fi

if [[ ! -f "$LISTA_BLANCA_FILE" ]]; then
	echo "Error: El archivo de lita blanca '$LISTA_BLANCA_FILE' no existe."
	exit 1
fi

# ====================================================================================
# FUNCIONES DE APOYO (FORENSE Y CONTROL)
# ====================================================================================

esta_en_lista_blanca() {
	local pid="$1"
	local comm_names=""

	if [[ -f "/proc/$pid/comm" ]]; then
		comm_names=$(cat "/proc/$pid/comm")
	fi

	if grep -qxE "($pid|$comm_names)" "$LISTA_BLANCA_FILE"; then
		return 0
	fi
	return 1
}

generar_json_reporte() {
	local timestamp="$1"
	local pid="$2"
	local ppid="$3"
	local binario="$4"
	local tipo_alerta="$5"
	local archivos_afectados="$6"

	local archivos_json=""
	if [[ -n "$archivos_afectados" ]]; then
		archivos_json=$(echo "$archivos_afectados" | sed 's/ /", "/g')
		archivos_json="[\"$archivos_json\"]"
	else
		archivos_json="[]"
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

congelar_procesos() {
	local pid="$1"
	local ppid="$2"

	echo "[-] [CONTENCIÓN] Enviando SIGSTOP al PID agresor: $pid"
	kill -STOP "$pid" 2>/dev/null

	if [[ "$ppid" -gt 1 ]]; then
		echo "[-] [CONTENCIÓN] Enviando SIGSTOP al PPID (Padre watchdog): $ppid"
		kill -STOP "$ppid" 2>/dev/null
	fi
}

# ==========================================================================================
# BUCLE PRINCIPAL DE AUDITORIA (MONITOREO EN TIEMPO REAL)
# ==========================================================================================

echo "=========================================================================="
echo "    INICIANDO GUARDÍAN ANTIRANSOMWARE Y MONITOR DE MUTACIÓN DE PROCESOS   "
echo "=========================================================================="
echo "[+] Vigilando zona crítica: $DIR_CRITICO"
echo "[+] Umbral de tolerancia: $LIMITE_MUTACION archivos en 5 segundos."
echo "--------------------------------------------------------------------------"

if [[ ! -s "$LOG_JSON" ]]; then
	echo "[" > "$LOG_JSON"
fi

cerrar_json_valido() {
    echo -e "\n[-] Deteniendo el guardián de procesos..."
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
	# --------------------------------------------------------------------------
	# REGLA 1: DETECCIÓN DE BINARIOS ENMASCARADOS / ELIMINADOS EN TODO EL SISTEMA
	# --------------------------------------------------------------------------
	for proc_dir in /proc/[0-9]*/; do

		PID=$(basename "$proc_dir")
		if [[ "$PID" -eq "$$" ]]; then continue; fi
		BINARIO_REAL=$(readlink -f "/proc/$PID/exe" 2>/dev/null)
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
			if ! esta_en_lista_blanca "$PID"; then
				TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
				echo "[!] ¡MUTACION DETECTADA! PID: $PID | MOTIVO: $ALERTA"
				congelar_procesos "$PID" "$PADRE_PID"
				generar_json_reporte "$TIMESTAMP" "$PID" "$PADRE_PID" "$BINARIO_REAL" "$ALERTA" ""
			fi
		fi
	done
	# --------------------------------------------------------------------------
	# REGLA 2: CORRELACIÓN DE EVENTOS (EFECTO RANSOMWARE EN LA RUTA CRÍTICA)
	# --------------------------------------------------------------------------
	# Buscamos archivos modificados en los últimos 5 segundos en el directorio crítico

	ARCHIVOS_MODIFICADOS=$(find "$DIR_CRITICO" -type f -mmin -0.083 2>/dev/null) # 0.083 minutos ~ 5s
	CANTIDAD_MODIFICADOS=$(echo -n "$ARCHIVOS_MODIFICADOS" | grep -c '^')

	if [[ "$CANTIDAD_MODIFICADOS" -gt "$LIMITE_MUTACION" ]]; then
		TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
		echo "[!] [ALERTA RANSOMWARE] Ráfaga de mutaciones: $CANTIDAD_MODIFICADOS archivos modificados."
		CULPABLE_PID=""
		CULPABLE_PPID=0
		CULPABLE_BIN=""

		for proc_dir in /proc/[0-9]*/; do
			PID_CHECK=$(basename "$proc_dir")
            		if [[ "$PID_CHECK" -eq "$$" ]]; then continue; fi
            		if esta_en_lista_blanca "$PID_CHECK"; then continue; fi

	        	for fd in /proc/"$PID_CHECK"/fd/*; do
                		[[ ! -e "$fd" ]] && continue
	                	FD_TARGET=$(readlink -f "$fd" 2>/dev/null)
				if [[ "$FD_TARGET" == "$DIR_CRITICO"* ]]; then
					CULPABLE_PID="$PID_CHECK"
					CULPABLE_PPID=$(gawk '{print $4}' "/proc/${PID_CHECK}/stat" 2>/dev/null)
					CULPABLE_BIN=$(readlink -f /proc/"$PID_CHECK"/exe 2>/dev/null)
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
			echo "[-] Ráfaga detectada pero el proceso cerró sus descriptores antes del análisis"
		fi
	fi
	sleep 1
done
