#!/bin/bash
# auditar_archivos_criticos.sh
### En servidores compartidos, es comun que archivos criticos de configuracion
### o logs crezcan, cambien permisos o sean modificados fuera de horario laboral
### Vamos a recibir un parametro asi que ejecutar asi:
### ./auditar_archivos_criticos.sh directorio

# Recibimos como parametro un directorio base

DIRECTORIO="${1:-.}"
FECHA=$(date +'%Y-%m-%d')
SALIDA="reporte_auditoria_$FECHA.log"

if [[ ! -d "$DIRECTORIO" ]]; then
	echo "El directorio introducido no existe"
	echo "Saliendo del script"
	exit 1
fi

mapfile -t archivos < <(find "$DIRECTORIO" -type f -not -path "*/tmp/*" \
	\( -name "*.conf" -or -name "*.cnf" -or -name "*.log" \) -mtime -1 \
	-exec stat -c "%n|%s|%y|%Y" {} \; | gawk -F "|" 'BEGIN{OFS="\t"}{ 
		print $1, $2, $3
	}')

exec 3>>"$SALIDA"

echo -e "RUTA\t\tTAMAÑO\t\tFECHA_MODIFICACION\n" >&3

for lineas in "${archivos[@]}"; do
	echo "$lineas" >&3
done

exec 3>&-
