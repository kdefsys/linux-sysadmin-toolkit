#!/bin/bash
### Nombre: detector_permisos_inseguros.sh
### Autor: kdefsys
### Descripcion: En sistemas Linux multiusuario, existen dos riesgos comunes vinculados a la gestión de permisos:
### 1. Archivos World-Writable: Archivos regulares donde la categoría "otros" (others) tiene permisos de lectura y escritura. Cualquier usuario del sistema puede modificar
### su contenido, lo que representa un riesgo alto de manipulación o inyección de código.
### 2. Falta de Sticky Bit en Directorios Temporales: Directorios compartidos (como /tmp o /var/tmp) deben tener activo el Sticky Bit (+t). Sin este bit especial, cualquier
### usuario podría borrar o renombrar archivos creados por otros usuarios dentro de esas carpetas.
### Para automatizar la auditoría y solución de estos problemas, se requiere una herramienta modular basada en banderas (opciones de línea de comandos).
### Uso: sudo ./detector_permisos_inseguros.sh -d <directorio> -c -f <directorio> [-h]

if [[ "${EUID}" -ne 0 ]]; then
	echo "No hay prilegio de superusuario" >&2
	exit 1
fi

function help {
	echo "El script debe ejecutarse asi: sudo ./detector_permisos_inseguros.sh -d <directorio> -c -f <directorio> [-h]"
	echo " -d : Directorio a examinar. Si no se introduce la bandera, se asumira que es el directorio actual"
	echo " -c : Ejecuta la auditoria de directorios criticos predefinidos /tmp/ , /var/tmp"
	echo " -f : Ejecuta la correcion interactiva sobre el directorio especificado"
	echo " -h : Imprime esta guia"
}

DIRECTORIO_OBJETIVO="$(pwd)"
AUDITORIA=0
INTERACTIVIDAD=0
BUSQUEDA=0

while getopts :d:cf:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO_OBJETIVO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO_OBJETIVO" ]]; then
		 	echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		 fi
		 BUSQUEDA=1
		 ;;
		c)
		 AUDITORIA=1
		 ;;
		f)
		 DIRECTORIO_INTERACTIVO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO_INTERACTIVO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		 fi
		 INTERACTIVIDAD=1
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion ingresada no valida" >&2
		 help
		 exit 1
		 ;;
	esac
done

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="detector_${FECHA}.log"
DIRECTORIOS_ESPECIALES=("/tmp" "/var/tmp")

if [[ -f "$REPORTE" ]]; then
	rm -f "$REPORTE"
fi

exec 3>>"$REPORTE"

function busqueda_archivos_inseguros {
	local ruta_directorio="$1"
	mapfile -t files_inseguros < <(find "$ruta_directorio" -type f -perm -o=rw -exec stat -c "%n|%a|%U|%u|%G|%F" {} \; | gawk -F "|" 'BEGIN{OFS="\t"}{print $1, $2, $3, $4, $5, $6}')
	if [[ "${#files_inseguros[@]}" -eq 0 ]]; then
		echo "No hay archivos con permisos de lectura y escritura para otros usuarios." >&3
	else
		echo "=========================================================================" >&3
		echo "Lista de archivos con permisos de lectura y escritura para otros usuarios" >&3
		printf "%s\n" "${files_inseguros[@]}" >&3
		echo "=========================================================================" >&3
	fi
}

function auditoria_de_directorios_criticos {
	echo "=================================================================================" >&3
	echo "REPORTE DE STICKY BIT DE DIRECTORIOS ESPECIALES" >&3
	echo "=================================================================================" >&3

	for directorio in "${DIRECTORIOS_ESPECIALES[@]}"; do
		if [[ -k "$directorio" ]]; then
			echo "[OK] El directorio $directorio de la lista DIRECTORIOS ESPECIALES si tiene el STICKY BIT activado"
		else
			echo "[CRITICO] El directorio $directorio de la lista de DIRECTORIOS ESPECIALES no tiene el STICKY BIT activado"
		fi
	done
}

function correcion_interactiva {
	echo "================================================================================"
	echo "CORRECION INTERACTIVA"
	echo "================================================================================"

	local ruta_directorio="$1"
	if [[ -k "$ruta_directorio" ]]; then
		echo "El directorio $ruta_directorio tiene el sticky bit activado, esta seguro"
	else
		echo "El directorio $ruta_directorio no tiene el sticky bit activado"
		read -p "Desea activarlo? (S|N): " op
		case "$op" in
			s|S)
				if chmod +t "$ruta_directorio" 2>/dev/null; then
					echo "Ahora el directorio $ruta_directorio tiene activado el sticky bit"
				else
					echo "No se pudo activar el sticky bit del directorio $ruta_directorio"
				fi
				;;
			*)
			 ;;
		esac
	fi
}

if (( BUSQUEDA == 0 && AUDITORIA == 0 && INTERACTIVIDAD == 0 )); then
    BUSQUEDA=1
fi

if (( BUSQUEDA == 1 ));then
	busqueda_archivos_inseguros "$DIRECTORIO_OBJETIVO"
fi

if (( AUDITORIA == 1 )); then
	echo "Auditoria activada"
	auditoria_de_directorios_criticos
fi

if (( INTERACTIVIDAD == 1 )); then
	echo "Interaccion activada"
	correcion_interactiva "$DIRECTORIO_INTERACTIVO"
fi

exec 3>&-
echo "detector_permisos_inseguros.sh concluido correctamente. Vea el reporte en: $REPORTE"
