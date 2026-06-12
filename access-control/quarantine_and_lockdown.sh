#!/bin/bash
###Nombre: quarantine_and_lockdown.sh
###Autor: kdefsys
###Escript avanzado y aplicativo en Bash que actúe como un motor de mitigación interactivo,
###permitiendo enviar archivos a una jaula de cuarentena segura, revocar accesos a usuarios de forma
###temporal, y aplicar plantillas de permisos estrictas sobre directorios críticos de forma masiva.
###Uso: ./quarantine_and_lockdown.sh -q <archivo> -u <usuario> -r <directorio>

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con privilegios de superusuario"
	exit 1
fi

SALIDA="/var/log/lockdown-action.log"
FECHA=$(date +"%Y-%m-%d_%H:%M:%S")
JAULA="/opt/quarantine"

mkdir -p "$JAULA"
exec 3>>"$SALIDA"

while getopts :q:u:r: opt; do
	case "$opt" in
	    q)
		FILE="$OPTARG"
		echo -e "REPORTE DEL ARCHIVO ${FILE} A LA HORA: ${FECHA}\n\n"
		if [[ -f "$FILE" ]]; then
	       		if [[ -u "$FILE" || -g "$FILE" ]]; then
        	        	if chmod u-s,g-s "$FILE" 2>&3; then
                	        	echo "El archivo ${FILE} tiene permisos especiales activos. Removidos con éxito." >&3
	                	else
        	                	echo "ERROR: Falló la remoción de permisos especiales en ${FILE}" >&3
	                	        echo -e "\n" >&3
        	                	continue
	        		fi
        	        else
                		echo "El archivo no cuenta con permisos SUID/SGID. Procediendo directamente al aislamiento." >&3
	                fi
	                nombre_basico="${FILE##*/}"
        	        if mv "${FILE}" "${JAULA}/${nombre_basico}" 2>&3; then
                		if chmod 000 "${JAULA}/${nombre_basico}" 2>&3 && chown root:root "${JAULA}/${nombre_basico}" 2>&3; then
                        		echo "Mitigación exitosa: Movido a ${JAULA}/, permisos fijados en 000 y propietario root:root" >&3
	                	else
					echo "ERROR: Falló la reconfiguración de seguridad (000 / root:root) en la jaula" >&3
				fi
	                else
				echo "ERROR: No se pudo mover el archivo hacia la jaula de cuarentena" >&3
 	                fi
            	else
                	echo "El archivo ${FILE} no existe" >&3
            	fi
           	echo -e "\n\n" >&3
		;;
	    u)
		USUARIO="$OPTARG"
		echo -e "REPORTE DEL USUARIO ${USUARIO} A LA HORA: ${FECHA}\n\n"
		if getent passwd "$USUARIO" 2> /dev/null; then
			echo "Si existe el usuario, procedemos a bloquear su contraseña" >&3
			usermod -L "$USUARIO" 2>&3
			echo "Cambiamos su shell por /usr/sbin/nologin" >&3
			usermod -s "/usr/sbin/nologin" "$USUARIO" 2>&3
			echo "Expiramos su cuenta de inmediato" >&3
			usermod -e now "$USUARIO" 2>&3
		else
			echo "El usuario ${USUARIO} no existe en el sistema" >&3
		fi
		;;

	    r)
		DIRECTORIO="$OPTARG"
		echo -e "REPORTE DEL DIRECTORIO: $DIRECTORIO A LA HORA: ${FECHA}\n\n"
		if [[ -d "$DIRECTORIO" ]]; then
			echo "El directorio: $DIRECTORIO existe, entonces procedemos a cambiar los permisos: " >&3
			if find "$DIRECTORIO" \( -type d -exec chmod 755 {} + \) -o \( -type f -exec chmod 644 {} + \) 2>&3; then
				echo "Los cambios de permisos masivos fueron todo un exito" >&3
			else
				echo "Algo fallo en los cambios" >&3
			fi
		else
			echo "El directorio: $DIRECTORIO no existe" >&3
		fi
		;;

	    *)
		exit 1
	esac
done

exec 3>&-


