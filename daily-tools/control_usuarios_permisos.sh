#!/bin/bash
### Nombre: control_usuarios_permisos.sh
### Autor: kdefsys
### Descripcion: Realiza una auditoria mdoular del sistema en dos ambitos independientes o combinables: Identificar las cuentas de usuario
### configuradas con /bin/bash como shell por defecto y detectar archivos regulares dentro de un directorio objetivo que no tengan
### permiso de lectura para su grupo, generando reportes en archivo, mostrándonos por pantalla y contabilizando los hallazgos
### Uso: ./control_usuarios_permisos -u -d <directorio> -h [help]

function help {
	echo "Uso: $0 -u -d <directorio> [-h]"
        echo "  -d: Directorio objetivo a buscar los archivos que no tienen permiso de lectura para el grupo dueño"
	echo "  -u: Activa la operación de buscar usuarios con shell por defecto (/bin/bash)"
        echo "  -h: Muestra esta ayuda"
        exit 0
}

USUARIO="NO"
PERMISO="NO"

while getopts :ud:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		  fi
		  PERMISO="SI"
		  ;;
		u)
		  USUARIO="SI"
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

if [[ "$PERMISO" != "NO" || "$USUARIO" != "NO" ]]; then
	echo "EL SCRIPT CUMPLE TODAS LAS CONDICIONES PARA PODER EJECUTARSE"
	FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
	echo "FECHA: $FECHA"
fi

if [[ "$PERMISO" == "NO" && "$USUARIO" == "NO" ]]; then exit 0; fi

if [[ "$PERMISO" == "SI" ]]; then
	REPORTE="archivos_no_lectura_group.txt"
	mapfile -t archivos_nolectura < <(find "$DIRECTORIO" -type f -not -perm -g=r 2>/dev/null)
	CANTIDAD="${#archivos_nolectura[@]}"
	if (( CANTIDAD == 0 )); then
		echo "No hay archivos que no tengan permiso de lectura de grupo"
	else
		exec 3>>"$REPORTE"
		echo "=========== ARCHIVOS SIN PERMISO DE LECTURA PARA GRUPO ============" >&3
		echo "SCRIPT: control_usuarios_permisos.sh" >&3
		echo "HOSTNAME: $HOSTNAME" >&3
		echo "FECHA: $FECHA" >&3
		echo "===================================================================" >&3
		echo "Los archivos son: " >&3
		printf "%s\n" "${archivos_nolectura[@]}" >&3
		exec 3>&-
	fi
fi


if [[ "$USUARIO" == "SI" ]]; then
	REPORTE="usuarios_bash.txt"
	mapfile -t usuarios_bash < <(cat /etc/passwd | gawk -F ":" '$7~/^\/bin\/bash$/{print $1}')
	CANTIDAD="${#usuarios_bash[@]}"
	if (( CANTIDAD == 0 )); then
		echo "El sistema no tiene usuarios con shell /bin/bash"
	else
		exec 3>>"$REPORTE"
		echo "============ USUARIOS QUE TIENEN SHELL /bin/bash =================" >&3
		echo "SCRIPT: control_usuarios_permisos.sh" >&3
                echo "HOSTNAME: $HOSTNAME" >&3
                echo "FECHA: $FECHA" >&3
                echo "===================================================================" >&3
		echo "Los usuarios son" >&3
		printf "%s\n" "${usuarios_bash[@]}" >&3
		exec 3>&-
	fi
fi
