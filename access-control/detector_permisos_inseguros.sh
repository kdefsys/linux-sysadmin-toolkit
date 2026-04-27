#!/bin/bash
### Nombre: detector_permisos_inseguros.sh
### Autor: kdefsys
### En sistemas multiusuario, existen archivos "World-Writable" (que cualquiera puede escribir) que representan un riesgo de seguridad.
### Asimismo, existen directorios temporales o compartidos que deben tener activo el Sticky Bit (permiso +t) para evitar que un usuario borre los archivos de otro.
### Este script utiliza opciones (flags) para realizar auditorias de permisos, verificar directorios criticos y aplicar medidas correctivas de forma interactiva.
### Uso ./detector_permisos_inseguros.sh -d <directorio> -c -f <directorio> (o sus conjugados)

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="detector_${FECHA}.log"

ESPECIALES=("/tmp" "/var/tmp")

function busqueda_archivos_inseguros {
	local directorio="$1"
	local reporte="$2"
	mapfile -t archivos < <(find "$directorio" -type f \( -perm -o=r -and -perm -o=w \) -exec stat -c "%n|%a|%U|%u|%G|%F" {} + 2> /dev/null) 
	gawk -F "|" -v archivo="$reporte" '{
		printf "RUTA: %s | PERMISOS: %s | USER: %s | UID: %s | GROUP: %s | TIPO: %s\n", $1, $2, $3, $4, $5, $6 >> archivo
	}' < <(printf "%s\n" "${archivos[@]}")
}

function auditoria_directorios_criticos {
	local -n Lista=$1
	local archivo="$2"
	for directorios in "${Lista[@]}"; do
		local estado="OK"
		if [[ ! -k "$directorios" ]]; then
			estado="CRITICO"
		fi
		printf "%s\t%s\n" "$directorios" "$estado" | tee -a "$archivo" &> /dev/null
	done
}

function correccion_interactiva {
	local directorio="$1"
	local archivo="$2"
	if [[ ! -k "$directorio" ]]; then
		read -p "El directorio ${directorio} no tiene el sticky bit activado, desea activarlo? [y/N]: " -n1 op
		case "$op" in
			y|y)
				if sudo chmod +t "$directorio"; then
					echo "El cambio fue hecho con exito, ${directorio} ahora tiene el sticky bit activado"
				fi
				;;
			*)
				echo "Cancelando operacion"
				;;
		esac
	else
		echo "El directorio ${directorio} si tiene el sctiky bit activado"
	fi
}

while getopts :d:cf: opt; do
	case "$opt" in
		d)
			DIRECTORIO="$OPTARG"
			if [[ -d "$DIRECTORIO" ]]; then
				busqueda_archivos_inseguros "$DIRECTORIO" "$REPORTE"
			else
				echo "El directorio ingresado no existe"
			fi
			;;
		c)
			auditoria_directorios_criticos ESPECIALES "$REPORTE"
			;;
		f)
			DIRECTORIO="$OPTARG"
			if [[ -d "$DIRECTORIO" ]]; then
				correccion_interactiva "$DIRECTORIO" "$REPORTE"
			else
				echo "El directorio ingresado no existe"
			fi
			;;
		*)
			echo -e "Opcion no valida\nSaliendo del script"
			exit 1 ;;
	esac

done

echo "Proceso finalizado, datos guardados en ${REPORTE}"
