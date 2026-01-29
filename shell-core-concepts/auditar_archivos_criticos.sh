#!/bin/bash
# auditar_archivos_criticos.sh
### En servidores compartidos, es comun que archivos criticos de configuracion
### o logs crezcan, cambien permisos o sean modificados fuera de horario laboral
### Vamos a recibir un parametro asi que ejecutar asi:
### ./auditar_archivos_criticos.sh directorio

# Recibimos como parametro un directorio base

FECHA=$(date +'%Y-%m-%d')
SALIDA="reporte_auditoria_$FECHA.log"

var=$(find "$1" -type f -not -path "*/tmp/*" \
   \( -name "*.conf" -or -name "*.cnf" -or -name "*.log" \) \
   -exec stat -c '%n|%s|%y|%Y' {} \; |
  gawk -F '|' -v now="$(date +%s)" 'now - $4 <= 86400 {
	printf "Ruta: %s | tamaño: %s bytes | Modificado: %s\n", $1, $2, $3
    }')

echo "$var" >> "$SALIDA"
