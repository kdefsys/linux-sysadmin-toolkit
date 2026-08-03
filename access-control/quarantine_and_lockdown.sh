#!/bin/bash
### Nombre: quarantine_and_lockdown.sh
### Autor: kdefsys
### Descripcion: En el centro de operaciones de seguridad (SOC) de una organización, se ha detectado una intrusión activa en uno de los servidores críticos. El equipo de respuesta
### ante incidentes necesita una herramienta automatizada en Bash que permita realizar acciones inmediatas de contención y remediación cuando se identifica un vector de compromiso.
### Para contener el impacto y mitigar la persistencia del atacante de manera rápida y trazable, el administrador de sistemas debe implementar un script de contención llamado
### quarantine_and_lockdown.sh que ejecute tres módulos clave de respuesta rápida:
### 1. Cuarentena de Artefactos Sospechosos: Aislar archivos maliciosos neutralizando sus capacidades de ejecución o escalada de privilegios.
### 2. Bloqueo Inmediato de Cuentas Comprometiendo el Sistema: Revocar inmediatamente el acceso a un usuario sospechoso en múltiples niveles.
### 3. Hardening y Remediación de Directorios: Restaurar permisos seguros por defecto en directorios donde un atacante pudo haber alterado permisos para establecer persistencia.
### Uso: sudo ./quarantine_and_lockdown.sh -q <ruta_archivo> -u <nombre_usuario> -d <directorio> [-h]

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con privilegios sudo" >&2
	exit 1
fi

function help {
	echo "El script debe de ejecutarse asi: sudo ./quarantine_and_lockdown.sh -q <ruta_archivo> -u <nombre_usuario> -d <directorio> [-h]"
	echo "   -q : Para poner en cuarentena a ese archivo sospechoso"
	echo "   -u : Bloquear al usuario comprometido"
	echo "   -d : Sospecha de persistencia o alteracion de permisos en directorio criticos"
	echo "   -h : Imprime esta guia"
}

CUARENTENA=0
BLOQUEO=0
PERSISTENCIA=0

while getopts :q:u:d:h opt; do
	case "$opt" in
		q)
		 ARCHIVO="$(realpath $OPTARG)"
		 if [[ ! -f "$ARCHIVO" ]]; then
			echo "El archivo no existe en el sistema" >&2
			exit 1
		 fi
		 CUARENTENA=1
		 ;;
		u)
		 USUARIO="$OPTARG"
		 if ! getent passwd "$USUARIO" &>/dev/null; then
		 	echo "El usuario no existe en el sistema" >&2
			exit 1
		 fi
		 BLOQUEO=1
		 ;;
		d)
		 DIRECTORIO="$(realpath $OPTARG)"
		 if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio no existe en el sistema" >&2
			exit 1
		 fi
		 PERSISTENCIA=1
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion ingresada invalida" >&2
		 help
		 exit 1
		 ;;
	esac
done

if (( CUARENTENA == 1 )); then
	if [[ -g "$ARCHIVO" ]]; then
		ESPECIALES=1
		echo "El archivo: $ARCHIVO tiene permiso especial SETGID activado"
		echo "Procedemos a removerlo"
		if chmod g-s "$ARCHIVO" 2>/dev/null; then
			echo "[OK] Se lo removimos correctamente"
		else
			echo "[ERROR] No se le pudo remover" >&2
		fi
	fi
	if [[ -u "$ARCHIVO" ]]; then
		ESPECIALES=1
		echo "El archivo: $ARCHIVO tiene permiso especial SETUID activado"
		echo "Procedemos a removerlo"
		if chmod u-s "$ARCHIVO" 2>/dev/null; then
			echo "[OK] Se lo removimos correctamente"
		else
			echo "[ERROR] No se le pudo remover" >&2
		fi
	fi
	ERROR=0
	JAULA="/opt/quarantine/jaula"
	if [[ ! -d "$JAULA" ]]; then mkdir -p "$JAULA"; fi
	if mv "$ARCHIVO" "$JAULA"; then
		echo "[OK] El archivo $ARCHIVO fue movido correctamente a la ruta $JAULA"
		ARCHIVO_NORMAL="$(basename $ARCHIVO)"
	        RUTA_ACTUAL="${JAULA}/${ARCHIVO_NORMAL}"
        	if chown root:root "$RUTA_ACTUAL" 2>/dev/null; then
                        echo "[OK] El archivo $RUTA_ACTUAL es ahora propiedad de root:root"
			if chmod 000 "$RUTA_ACTUAL" 2>/dev/null; then
				echo "[OK] El archivo $RUTA_ACTUAL tiene permisos 000"
			else
				echo "[ERROR] No se pudo cambiar los permisos de $RUTA_ACTUAL" >&2
				ERROR=1
			fi
		else
			echo "[ERROR] El archivo $RUTA_ACTUAL no cambio de propietarios" >&2
			ERROR=1
                fi
	else
		echo "[ERROR] No se pudo mover el archivo $ARCHIVO a la ruta $JAULA" >&2
		ERROR=1
	fi
	if (( ERROR == 0 ));then
		echo "[OK] El proceso de poner al archivo $ARCHIVO en cuarentena, fue concluido con exito"
	else
		echo "[ERROR] Hubo errores al poner al archivo $ARCHIVO en cuarentena"
	fi
fi

if (( BLOQUEO == 1 )); then
	echo "Vamos a bloquear al usuario $USUARIO"
	ERROR=0
	if usermod -L "$USUARIO" 2>/dev/null; then
		echo "[OK] La contraseña del usuario $USUARIO ha sido bloqueada correctamente, para que no pueda iniciar sesion."
		if usermod -s "/usr/sbin/nologin" "$USUARIO" 2>/dev/null; then
			echo "[OK] El shell del usuario $USUARIO fue cambiado a /usr/sbin/nologin corectamente, para que no pueda ejecutar archivos."
			if usermod -e now "$USUARIO" 2>/dev/null; then
				echo "[OK] La cuenta del usuario $USUARIO fue expirada correctamente."
			else
				echo "[ERROR] La cuenta del usuario $USUARIO no fue expirada correctamente." >&2
				ERROR=1
			fi
		else
			echo "[ERROR] No se pudo cambiar el shell del usuario $USUARIO" >&2
			ERROR=1
		fi
	else
		echo "[ERROR] La contraseña del usuario $USUARIO no se pudo bloquear correctamente" >&2
		ERROR=1
	fi
	if (( ERROR == 0 ));then
                echo "[OK] El proceso de bloquear al usuario $USUARIO fue concluido con exito"
        else
                echo "[ERROR] Hubo errores al bloquear al usuario $USUARIO" >&2
        fi
fi

if (( PERSISTENCIA == 1 )); then
	ERROR=0
	echo "Aplicamos de forma recursiva una politica de permisos estandar de hardening sobre el arbol de archivos del directorio $DIRECTORIO"
	if find "$DIRECTORIO" -type d -exec chmod 755 {} + 2>/dev/null; then
		echo "[OK] Se aplico correctamente los permisos 755 a los subdirectorios del directorio $DIRECTORIO"
		if find "$DIRECTORIO" -type f -exec chmod 644 {} + 2>/dev/null; then
			echo "[OK] Se aplico correctamente los permisos 644 a los archivos del directorio $DIRECTORIO"
		else
			echo "[ERROR] No se pudo aplicar correctamente los permisos 644 a los archivos" >&2
			ERROR=1
		fi
	else
		echo "[ERROR] No se pudo aplicar correctamente los permisos a los subdirectorios del directorio $DIRECTORIO" >&2
		ERROR=1
	fi
	if (( ERROR == 0 )); then
		echo "[OK] El proceso de handening del directorio $DIRECTORIO fue concluido con exito"
	else
		echo "[ERROR] Hubo errores en el proceso de handening" >&2
	fi
fi

echo "quarantine_and_lockdown.sh Concluido con exito"

