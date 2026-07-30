#!/bin/bash
### Nombre: auditoria_permisos_peligrosos.sh
### Autor: kdefsys
### Descripcion: En sistemas Linux, los archivos que tienen activos los bits SETUID o SETGID permiten a cualquier usuario ejecutarlos con los privilegios del dueño del archivo o del
### grupo, respectivamente. Si un atacante o usuario malintencionado coloca un archivo ejecutable con estos permisos en una ruta inusual (como carpetas temporales o de usuarios),
### podría aprovecharlo para escalar privilegios a root.
### Este script inspecciona una ruta del sistema y clasifica que binarios con permisos especiales estan en ubicaciones estandar (seguras) y cuales representan un riesgo potencial.
### Uso: sudo ./auditoria_permisos_peligrosos.sh -d <directorio> [-h]

function help {
	echo "El script debe de ejecutarse asi: sudo ./auditoria_permisos_peligrosos.sh -d <directorio> [-h]"
	echo "Es obligatorio que se ejecute con privilegio sudo"
	echo "   -d : Directorio objetivo. Si no se introduce la bandera, se asume el directorio actual."
	echo "   -h : Iprime esta guia"
}

if [[ "$EUID" -ne 0 ]]; then
	echo "El script no se ejecuto con privilegio sudo" >&2
	help
	exit 1
fi

DIRECTORIO="$(pwd)"

while getopts :d:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
		 	echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		 fi
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion ingresada invalida"
		 help
		 exit 1
		 ;;
	esac
done

DIRECTORIO="$(realpath "$DIRECTORIO")"

### ============================================================================================
### 		BUSQUEDA DE ARCHIVOS QUE TENGAN EL SETUID Y EL SETGID ACTIVADOS
### ============================================================================================

mapfile -t files < <(find "$DIRECTORIO" -type f \( -perm -4000 -or -perm -2000 \) -exec stat -c "%n|%U|%G|%a" {} \; | gawk -F "|" 'BEGIN{OFS="\t"}{print $1, $2, $3, $4}')
if [[ "${#files[@]}" -eq 0 ]]; then
	echo "No se encontraron archivos con permisos especiales en ese directorio"
	exit 0
fi

### =======================================================
### 		DIRECTORIOS ESTANDARES
### ======================================================

DIRECTORIOS_ESTANDARES=("/bin/" "/sbin/" "/usr/bin/" "/usr/sbin/" "/lib/" "/lib64/" "/usr/lib/" "/usr/lib64/")
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="auditoria_setuid_setgid_${FECHA}.log"
if [[ -f "$REPORTE" ]]; then rm -f "$REPORTE"; fi
exec 3>>"$REPORTE"

echo "================================================== AUDITORIA SETUID Y SETGID ==================================================" >&3
echo "DIRECTORIO: $DIRECTORIO" >&3
echo "FECHA: $FECHA" >&3
echo "LISTA DE ARCHIVOS ENCONTRADOS" >&3
echo -e "RUTA\t\tUSUARIO\t\tGRUPO\t\tPERMISOS" >&3
printf "%s\n" "${files[@]}" >&3

archivos_criticos=0

for file in "${files[@]}"; do
	SALIDA=0
	archivo="${file%%$'\t'*}"

	for directorio in "${DIRECTORIOS_ESTANDARES[@]}"; do
		if [[ "$archivo" == "${directorio}"* ]]; then
			echo "[OK] El archivo $archivo pertenece a los directorios estandares permitidos" >&3
			SALIDA=1
			break
		fi
	done
	if (( SALIDA == 0 )); then
		(( archivos_criticos++ ))
		echo "[CRITICO] El archivo $archivo tiene los permisos especiales activados y no pertenece a los directorios estandares permitidos" >&3
	fi
done

echo "Auditoria_permisos_peligrosos.sh ha concluido correctamente. El reporte puede verlo en $REPORTE"
echo "En total se encontraron $archivos_criticos archivos criticos"
exec 3>&-
