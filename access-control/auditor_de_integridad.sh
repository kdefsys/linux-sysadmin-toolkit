#!/bin/bash
### Nombre: auditor_de_integridad.sh
### Autor: kdefsys
### El script compara los archivos con permisos especiales de un directorio contra una lista de "permitidos" y detecta cualquier anomalía
### Uso: sudo ./auditor_de_integridad.sh -g -s <directorio>

if [[ "$EUID" -ne 0 ]]; then
	echo -e "El usuario debe de tener permisos de superusuario\nSaliendo del Script..."
	exit 1
fi

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="integridad_permisos_${FECHA}.log"
PERMITIDOS="permitidos.db"

while getopts :s:g opts; do
	case "$opts" in
		g)
			if [[ -f "$PERMITIDOS" ]]; then
				read -p "El archivo ya existe - Desea Reemplazar (y|N): " -n1 op
				case "$op" in
					y|Y)
						if find "/" -type f -perm /7000 -exec stat -c "%n|%a" {} + 2> /dev/null > "${PERMITIDOS}"; then
							echo "Archivo ${PERMITIDOS} modificado con exito"
						fi
						;;
					*)
						;;
				esac
			else
				echo "Procediendo a crear el archivo ${PERMITIDOS}"
				if find "/" -type f -perm /7000 -exec stat -c "%n|%a" {} + 2> /dev/null > "${PERMITIDOS}"; then
					echo "Archivo creado con exito"
				fi
			fi
			;;
		s)
			DIRECTORIO="$OPTARG"
			if [[ ! -d "$DIRECTORIO" ]]; then
				echo -e "El directorio ${DIRECTORIO} no existe\nSaliendo del script..."
				exit 1
			else
				mapfile -t archivos < <(find "$DIRECTORIO" -type f -perm /7000 -exec stat -c "%n|%a" {} + 2> /dev/null)
				for archivo in "${archivos[@]}"; do
					ruta_nueva="${archivo%|*}"
					permiso_nueva="${archivo#*|}"
					permiso_antiguo=$(grep -F "${ruta_nueva}|" "$PERMITIDOS" | cut -d "|" -f 2)
					if [[ -n "$permiso_antiguo" ]]; then
						if (( permiso_antiguo == permiso_nueva )); then
							ESTADO="[INTEGRO]"
						elif (( permiso_antiguo != permiso_nueva )); then
							ESTADO="[PELIGRO: PERMISOS MODIFICADOS]"
						fi
					else
						ESTADO="[ALERTA: BINARIO NUEVO O DESCONOCIDO]"
					fi
					printf "%s|%s\n" "$ruta_nueva" "$ESTADO" >> "${REPORTE}"
				done
			fi
			;;
	esac
done

echo "REPORTE FINALIZADO; GUARDADO EN ${REPORTE}"
