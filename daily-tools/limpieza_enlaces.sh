#!/bin/bash
### Nombre: limpieza_enlaces.sh
### Encuentra enlaces simbolicos rotos dentro de un directorio crítico
### Los elimina automáticamente
### Genera un log de los enlaces eliminados
### Uso: ./limpieza_enlaces.sh <directorio>

DIRECTORIO="$1"
LOG_FILE="enlaces_rotos.log"

find "$DIRECTORIO" -type l ! -exec test -e {} \; -print | tee -a "$LOG_FILE" | xargs -r rm -v >>  "$LOG_FILE" 2>&1

# Imprimamos el archivo

cat $LOG_FILE

# Eliminando el archivo

rm -fv $LOG_FILE
