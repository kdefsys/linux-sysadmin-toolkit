#!/bin/bash
# auditoria_avanzada.sh
### Script de auditoría de disco que permite a un sysadmin identificar archivos
### problemáticos en servidores linux que crecen silenciosamente y causan
### saturacion de disco
### Entrada tendra 3 parametros: directorio, tamaño en MB y numero de dias

DIR="$1"
TAM="$2"
DIA="$3"
SALIDA="auditoria_disco_$(date +'%Y%m%d_%H%M').log"

ARCHIVOS=$(find "$DIR" -type f -size +"${TAM}"M -mtime -"$DIA")

if [ -z "$ARCHIVOS" ]; then
  echo "NO existe archivo con esas características"
  echo "Saliendo del script..."
  sleep 2
  exit 0
fi

echo "=== Lista de archivos candidatos con sus características ===" > "$SALIDA"

# Por cada archivo obtenemos: Ruta, tamaño real, tamaño bloque, ultima
# modificacion y el UID del usuario dueño

echo "$ARCHIVOS" | xargs stat -c "%n|%s|%B|%y|%u" | sort -t '|' -k 2nr,2nr |
  gawk 'BEGIN{FS="|" ; print "FILE\t   SIZE    BLOQUE\tTIME\t\t\tUID"}{ print $1,  $2, $3, $4, $5}'|
  tee -a "$SALIDA" > /dev/null

# Cantidad de archivos candidatos

CANTIDAD=$(echo "$ARCHIVOS" | wc -l)

echo "Cantidad total de archivos detectados: $CANTIDAD" | tee -a "$SALIDA" > /dev/null

# Calculamos el espacio total ocupado por los archivos

TOTAL=$(echo "$ARCHIVOS" | xargs du -cbh | tail -n 1 | cut -f 1,1)

echo "Espacio total consumido $TOTAL"  | tee -a "$SALIDA" > /dev/null

# Archivo más grande

MAYOR=$(echo "$ARCHIVOS" | xargs stat -c "%n|%s" | sort -t '|' -k 2nr,2nr | 
   head -n 1 | gawk 'BEGIN{FS="|"} {print $1}')

echo "EL archivo de mayor tamaño es: $MAYOR" | tee -a "$SALIDA" > /dev/null

# Mostramos el archivo
cat "$SALIDA"
