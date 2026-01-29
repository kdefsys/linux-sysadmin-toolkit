#!/bin/bash
# limpieza_selectiva_archivos.sh
### En servidores de aplicaciones:
### .Se generan backups
### .Drumps
### .Archivos temporales
### Que nadie limpia hasta que el disco colapsa
### Parametros (2): directorio y un numero de días

# Rescatamos los parámetros

DIR="$1"
DAY="$2"
LOG="limpieza_$(date +%Y%m%d_%H%M).log"

# Validaciones básicas
if [[ -z "$DIR" || -z "$DIAS" ]]; then
  echo "Uso: $0 <directorio> <dias>"
  exit 1
fi

if [[ ! -d "$DIR" ]]; then
  echo "El directorio no existe"
  exit 1
fi

echo "=== Limpieza iniciada: $(date) ===" | tee "$LOG"
echo "Directorio: $DIRECTORIO" | tee -a "$LOG"
echo "Archivos mayores a $DIAS dias y > 1MB" | tee -a "$LOG"
echo

# Buscamos archivos candidatos
ARCHIVOS=$(find "$DIR" -type f \
  \( -name "*.bak" -or -name "*.tmp" -or -name "*.old" -or -anem "backup_*" \) \
  -mtime +"$DAY" -size +1M )

# Si no hay archivos, salimos
if [[ -z "$ARCHIVOS" ]]; then
  echo "No se encontraron archivos para limpiar"
  exit 0
fi

# Cantidad de archivos
CANTIDAD=$(echo "$ARCHIVOS" | wc -l)

# Cantidad total usando du + tuberías
ESPACIO_TOTAL=$(echo "$ARCHIVOS" | xargs du -cb | tail -n 1 | 
   gawk '{print $1}')

echo "Archivos candidatos: $CANTIDAD" | tee -a "$LOG"
echo "Espacio total ocupado: $ESPACIO_TOTAL bytes" | tee -a "$LOG"
echo
echo "Listado de archivos:" | tee -a "$LOG"
echo "$ARCHIVOS" | tee -a "$LOG"

echo
read -p "¿Desea eliminar estos archivos? (s/n): " RESPUESTA

if [[ "$RESPUESTA" != "s" ]]; then
  echo "Operacion cancelada por el usuario" | tee -a "$LOG"
  exit 0
fi

# Eliminacion

echo
echo "Eliminando archivos..." | tee -a "$LOG"
echo "$ARCHIVOS" | xargs rm -v | tee -a "$LOG"

echo "=== Limpieza finalizada: $(date) ===" | tee -a "$LOG"
