#!/bin/bash
###Nombre: quarantine2
###Autor: kdefsys
###Uso: sudo ./quarantine2 -q <ruta_archivo_sospechoso> -r <ruta_directorio> -u <nombre_usuario>

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con permisos de superusuario"
	exit 1
fi

guia_ejecucion() {
	echo "El script debe de ser lanzado asi:"
	echo "sudo ./quarantine_and_lockdown.sh con opciones: "
	echo "-q <ruta_archivo>: Para poner en cuarentena a ese archivo sospechoso"
	echo "-u <nombre_usuario>: Bloquear el usuario comprometido"
	echo "-r <ruta_directorio>: Sospecha de persistencia o alteracion de permisos en directorios criticos"
	echo "-h: Se muestra la guia de ejecucion"
	echo -e "\n"
}

if [[ "$#" -eq 0 ]]; then
	echo "El script no tiene argumentos "
	guia_ejecucion
	exit 1
fi

##
# Variables globales del script
##

REPORTE="/var/log/lockdown-action.log"
JAULA="/opt/quarantine"

exec 3>>"$REPORTE"

CUARENTENA=0 ; BLOQUEO=0 ; PERSISTENCIA=0

##
# Menu de getopts
##

while getopts :q:r:u:h opt; do
	case "$opt" in
		q)
		  CUARENTENA=1
		  ARCHIVO=$OPTARG
		  ;;
		u)
		  BLOQUEO=1
		  USUARIO=$OPTARG
		  ;;
		r)
		  PERSISTENCIA=1
		  DIRECTORIO=$OPTARG
		  ;;
		h)
		  guia_ejecucion
		  exit 0
		*)
		  echo "Opción invalida"
		  exec 3>&-
		  exit 1
	esac
done

if (( CUARENTENA == 1 )); then
	echo "==========================================================================" >&3
	echo "===================== CUARENTENA DEL ARCHIVO $ARCHIVO ====================" >&3
	echo "==========================================================================" >&3
	echo "FECHA: $(date '+%Y-%m-%d %H-%M-%S')" >&3
	if [[ -f "$ARCHIVO" ]]; then
		echo "El archivo si está registrado en el sistema" >&3
		if [[ -u "$ARCHIVO" || -g "$ARCHIVO" ]]; then
			if chmod u-s,g-s "$ARCHIVO" 2>/dev/null; then
				echo "El archivo ha sido removido para evitar escalada de privilegios" >&3
			else
				echo "No se pudo remover los permisos especiales del archivo" >&3
			fi
		fi
		if [[ ! -d "$JAULA" ]]; then
			mkdir "$JAULA"
		fi
		NOMBRE_BASE=$(basename "$ARCHIVO")
		if mv "$ARCHIVO" "${JAULA}/${NOMBRE_BASE}" 2>/dev/null; then
			echo "El archivo ha sido movido a la jaula correctamente" >&3
			if chown root:root "${JAULA}/${NOMBRE_BASE}" 2>/dev/null; then
	                        echo "Se cambió correctamente los propietarios root:root" >&3
                	else
                        	echo "Hubo un error al cambiar los propietarios del archivo en la jaula" >&3
	                fi
        	        if chmod 000 "${JAULA}/${NOMBRE_BASE}" 2>/dev/null; then
                	        echo "Se cambió correctamente los permisos del archivo a 000" >&3
	                else
        	                echo "Hubo un error al cambiar los permisos a 000" >&3
 	               fi
		else
			echo "Hubo un error al mover el archivo a la jaula" >&3
		fi
	else
		echo "El archivo no existe en el sistema" >&3
	fi
fi

if (( BLOQUEO == 1 )); then
	echo "============================================================================" >&3
	echo "===================== BLOQUE DEL USUARIO $USUARIO ==========================" >&3
	echo "============================================================================" >&3
	echo "FECHA: $(date '+%Y-%m-%d %H-%M-%S')" >&3
	if getent passwd "$USUARIO" &>/dev/null; then
		echo "El usuario si existe en la base de datos del sistema" >&3
		if usermod -L "$USUARIO" 2>/dev/null; then
			echo "Se bloqueó correctamente la contraseña del usuario" >&3
		else
			echo "No se pudo bloquear la contraseña del usuario" >&3
		fi
		if usermod -s "/usr/sbin/nologin" "$USUARIO" 2>/dev/null; then
			echo "Cambiamos su shell a /usr/sbin/nologin para que no pueda iniciar sesion" >&3
		else
			echo "No se pudo cambiar el shell, el usuario todavia puede iniciar sesion" >&3
		fi
		if usermod -e now "$USUARIO" 2>/dev/null; then
			echo "La cuenta del usuario ha sido expirada correctamente" >&3
		else
			echo "No se pudo expirar la cuenta del usuario" >&3
		fi
	else
		echo "El usuario no existe en la base de datos del sistema" >&3
	fi
fi

if (( PERSISTENCIA == 1 )); then
	echo "==============================================================================" >&3
	echo "================== ANÁLISIS DEL DIRECTORIO: $DIRECTORIO ======================" >&3
	echo "==============================================================================" >&3
	echo "FECHA: $(date '+%Y-%m-%d %H-%M-%S')" >&3
	if [[ -d "$DIRECTORIO" ]]; then
		echo "El directorio si existe en el sistema" >&3
		if find "$DIRECTORIO" \( -type d -exec chmod 755 {} + \) -o \( -type f -exec chmod 644 {} + \) &>/dev/null; then
			echo "Los subdirectorios han sido cambiado sus permisos a 755 correctamente" >&3
			echo "Los archivos han sido cambiado sus permisos a 644 correctamente" >&3
		else
			echo "No se pudo cambiar los permisos" >&3
		fi
	else
		echo "El directorio a analizar no existe en el sistema" >&3
	fi
fi

exec 3>&-
