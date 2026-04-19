#!/bin/bash
# Limpieza_logs.sh
# Limpieza de logs duplicados y resumen de entradas frecuentes

# Revisamos un directorio de logs y listamos todos los archivos de .log

FECHA=$(date '+%Y-%m-%d %H:%M:%S')
DIRECTORIO="${1:-.}"

## Verificamos si el directorio existe"

if [[ ! -d "$DIRECTORIO" ]]; then
	echo "El directorio no existe"
	echo "Procedemos a salir del script"
	sleep 3
	exit 1
fi

mapfile -t LISTA_LOGS < <(find "$DIRECTORIO" -type f -name "*.log")
SALIDA="log_limpio.txt"

echo "=== Limpieza de logs ejecutada: $FECHA === " > "$SALIDA"

for archivo in "${LISTA_LOGS[@]}"; do
	if [[ -f "$archivo" ]]; then
		sort "$archivo" | uniq >> "$SALIDA"
	fi
done

echo -e "\n=== Top 10 entradas más frecuentes ===" >> "$SALIDA"
sort "$SALIDA" | grep -v "===" | uniq -c | sort -nr | head -n 10 >> "$SALIDA"

echo "Mostrando la salida en la terminal"
cat "$SALIDA"
