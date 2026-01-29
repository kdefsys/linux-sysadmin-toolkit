#!/bin/bash
# analizar_logs_servicios.sh
### Los servidores generan decenas de logs por servicio
### Cuando algo falla, nadie abre archivos uno por uno
### Vamos a recibir dos parametro asi:
### ./analizar_logs_servicios.sh directorio(de logs)
### y un patron(ej: error, failed, denied)

# Rescatamos los patrones

DIR="$1"
PATRON="$2"
FECHA=$(date +'%F')
SALIDA="errores_$(hostname)_$FECHA.log"

find "$DIR" -type f \( ! -name "*.gz" -and \( -name "*.log" -or -name "*.log.*" \) \) |
   xargs grep -ic "$2" | sort -k 2nr >> "$SALIDA"

# Mostramos el archivo

cat "$SALIDA"
