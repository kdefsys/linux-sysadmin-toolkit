#!/bin/bash
# auditoría_permisos_peligrosos
### Script que escanea todo el sistema (o un directorio configurable) en busca
### de archivos con los bits SETUID o SETGID activos


## Validacion de ejecucion

if [[ $EUID -ne 0 ]]; then 
  echo "Este script debe ejecutarse como root"
  exit 1
fi

## Parametros y variables

DIR="$1"
FECHA=$(date +'%Y-%m-%d_%H-%M-%S')
SALIDA="auditoria_setuid_setgid_$FECHA.log"

## Rutas estándar donde se esperan binarios privilegiados

RUTAS_ESTANDAR=(
  "/bin"
  "/sbin"
  "/usr/bin"
  "/usr/sbin"
  "/lib"
  "/lib64"
  "/usr/lib"
  "/usr/lib64" )

## Recolección
echo "Auditoría de archivos con SETUID/SETGID" > "$SALIDA"
echo "Fecha: $FECHA" >> "$SALIDA"
echo "Directorio analizado: $DIR" >> "$SALIDA"
echo "-------------------------------------" >> "$SALIDA"

find "$DIR" -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null |
while read file; do
  # Datos del archivo
  INFO=$(stat -c '%n|%U|%G|%a|%u' "$file")

  # Clasifiación
  ESTANDAR="NO"
  for ruta in "${RUTAS_ESTANDAR[@]}"; do
      if [[ "$file" =~ ^"${ruta}" ]]; then
	   ESTANDAR="SI"
	   break
      fi
   done
   if [[ "$ESTANDAR" == "SI" ]]; then
      echo "[OK] $INFO" >> "$SALIDA"
   else
      echo "[CRITICO] $INFO" >> "$SALIDA"
   fi
done

echo "------------------------------------------" >> "$SALIDA"
echo "Auditoría finalizada" >> "$SALIDA"

cat "$SALIDA"
