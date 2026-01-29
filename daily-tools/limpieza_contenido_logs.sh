#!/bin/bash
# Limpieza_logs.sh
# Limpieza de logs duplicados y resumen de entradas frecuentes

# Revisamos un directorio de logs y listamos todos los archivos de .log

DIRECTORIO="$1"
LISTA_LOGS=$(find $DIRECTORIO -type f -name "*.log")
SALIDA="log_limpio.txt"

echo "=== Limpieza de logs ejecutada: $FECHA === " > "$OUTPUT"

for archivo in $LISTA_LOGS; do
	sort "$archivo" | uniq >> "$SALIDA"
done

echo -e "\n=== Top 10 entradas más frecuentes ==="
sort "$SALIDA" | uniq -c | sort -nr | head -n 10
