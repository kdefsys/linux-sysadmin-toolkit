#!/bin/bash
### Nombre: registro_diario.sh
### Autor: kdefsys
### Registra la fecha y actividad diaria en un log
### Uso: ./registro_diario.sh

LOG_FILE="actividad_diaria.log"
FECHA=$(date '+%Y/%m/%d %H:%M:%S')

echo "$FECHA - Tarea completada" >> "$LOG_FILE"
echo "Registro agregado a $LOG_FILE"

# Imprimimos el contenido actualizado de actividad_diaria.log

cat actividad_diaria.log



