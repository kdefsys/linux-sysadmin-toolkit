#!/bin/bash
### Nombre: access_guard.sh
### Autor: kdefsys
### Descripcion: La empresa TechSecure Labs está reorganizando sus servidores de desarrollo y producción. Han detectado que varios desarrolladores tienen permisos excesivos sobre
### archivos confidenciales y que usuarios antiguos aún conservan acceso a carpetas críticas.
### Este script es una herramienta de administración y auditoría llamada access_guard.sh que automatiza el aprovisionamiento de accesos, audita permisos inseguros y aplica políticas
### de control de acceso estrictas (Least Privilege).
### Uso: sudo ./access_guard.sh -a <usuario> -g <grupo> -d <directorio> //Modulo de Aprovisiamiento
### Uso: sudo ./access_guard.sh -c <directorio> -u <usuario_auditor> //Modulo de Control Fino con ACLs
### Uso: sudo ./access_guard.sh -s <directorio> // Modulo de Auditoria de Permisos Peligrosos
### Uso: sudo ./access_guard.sh -r <usuario> // Modulo de Revocacion y Blindaje

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse si o si con privilegios de superusuario" >&2
	exit 1
fi

function help {
	echo "El script se puede ejecutar asi: "
	echo "==============================================================================================================================="
	echo "							Modulo de Aprovisionamiento						     "
	echo "==============================================================================================================================="
	echo "   -a : Usuario a crear y que le voy a signar el grupo especificado"
	echo "   -g : Grupo especificado"
	echo "   -d : Directorio con propietario root y como grupo al especificado, al cual le cambiaremos los permisos y activaremos el SGID"
	echo "==============================================================================================================================="
	echo "							Modulo de ACLs								     "
	echo "==============================================================================================================================="
	echo "   -c : Directorio a cambiar permisos"
	echo "   -u : Usuario que se concedera permisos a traves de el control de acceso Posix(ACLs)"
	echo "==============================================================================================================================="
	echo "						Modulo de Auditoria Permisos Peligrosos						     "
	echo "==============================================================================================================================="
	echo "   -s : Directorio a escanear vulnerabilidades"
	echo "==============================================================================================================================="
	echo "						Modulo de Revocacion y Blindaje							     "
	echo "==============================================================================================================================="
	echo "   -r : Usuario a revocar"
	echo "==============================================================================================================================="
	echo "   -h : Imprime esta guia"
}

APROVISIONAMIENTO=0
ACLs=0
AUDITORIA=0
BLINDAJE=0

while getopts :a:g:d:c:u:s:r:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO_APROVISIONAMIENTO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO_APROVISIONAMIENTO" ]]; then
		 	echo "[ERROR] El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		 fi
		 (( APROVISIONAMIENTO++ ))
		 ;;
		a)
		 USUARIO_APROVISIONAMIENTO="$OPTARG"
		 (( APROVISIONAMIENTO++ ))
		 ;;
		g)
		 GRUPO="$OPTARG"
		 (( APROVISIONAMIENTO++ ))
		 ;;
		c)
		 DIRECTORIO_PERMISOS="$OPTARG"
		 if [[ ! -d "$DIRECTORIO_PERMISOS" ]]; then
                        echo "[ERROR] El directorio ingresado no existe. Saliendo del script" >&2
                        exit 1
                 fi
		 (( ACLs++ ))
		 ;;
		u)
		 USUARIO_PERMISOS="$OPTARG"
		 (( ACLs++ ))
		 ;;
		s)
		 DIRECTORIO_PELIGROSO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO_PELIGROSO" ]]; then
                        echo "[ERROR] El directorio ingresado no existe. Saliendo del script" >&2
                        exit 1
                 fi
		 AUDITORIA=1
		 ;;
		r)
		 USUARIO_BLINDAJE="$OPTARG"
		 BLINDAJE=1
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion Ingresada Invalida" >&2
		 help
		 exit 1
		 ;;
	esac
done

if (( APROVISIONAMIENTO == 3 ));then
	echo "Se activo el Modulo de Aprovisionamiento"

	if ! getent group "$GRUPO" &>/dev/null; then
		echo "El grupo $GRUPO no existe procedemos a crearlo"
		if groupadd "$GRUPO" 2>/dev/null; then
			echo "[OK] El grupo $GRUPO fue creado correctamente"
		else
			echo "[ERROR] El grupo $GRUPO no fue creado correctamente" >&2
			echo "Saliendo del script" >&2
			exit 1
		fi
	else
		echo "[OK] El grupo ya existe"
	fi

	if ! getent passwd "$USUARIO_APROVISIONAMIENTO" &>/dev/null; then
		echo "El usuario $USUARIO_APROVISIONAMIENTO no existe en el sistema, vamos a crearlo"
		if useradd -m "$USUARIO_APROVISIONAMIENTO" 2>/dev/null; then
			echo "[OK] El usuario $USUARIO_APROVISIONAMIENTO fue creado correctamente"
			if usermod -aG "$GRUPO" "$USUARIO_APROVISIONAMIENTO" 2>/dev/null; then
				echo "Se agrego correctamente el usuario $USUARIO_APROVISIONAMIENTO al grupo $GRUPO"
			else
				echo "No se pudo añadir" >&2
				exit 1
			fi
		else
			echo "[ERROR] El usuario $USUARIO_APROVISIONAMIENTO no se pudo crear correctamente" >&2
			echo "Saliendo del script" >&2
			exit 1
		fi
	else
		echo "[OK] El usuario ya existia"
		if usermod -aG "$GRUPO" "$USUARIO_APROVISIONAMIENTO" 2>/dev/null; then
			echo "Se agrego correctamente el usuario $USUARIO_APROVISIONAMIENTO al grupo $GRUPO"
		else
			echo "No se pudo añadir" >&2
			exit 1
		fi
	fi

	if chown root:"$GRUPO" "$DIRECTORIO_APROVISIONAMIENTO" 2>/dev/null; then
		echo "El propietario es root y el grupo es $GRUPO"
		if chmod 770 "$DIRECTORIO_APROVISIONAMIENTO" 2>/dev/null; then
			echo "[OK] Permisos modificados: Propietario y grupo pueden leer, escribir y acceder, el resto no"
			echo "Ahora por bonus de seguridad, le aplicamos el bit SGID"
			if chmod g+s "$DIRECTORIO_APROVISIONAMIENTO" 2>/dev/null; then
				echo "[OK] Se introdujo correctamente el bit SGID"
			else
				echo "[ERROR] No se pudo introducir el bit SGID" >&2
			fi
		else
			echo "[ERROR] Los permisos no fueron modificados correctamente" >&2
			exit 1
		fi
	else
		echo "El propietario no es root y el grupo no es el especificado. Saliendo del script" >&2
		exit 1
	fi
elif (( APROVISIONAMIENTO > 0 )); then
    echo "[ERROR] Para el modulo de aprovisionamiento debes incluir -a, -g y -d juntos" >&2
fi

if (( ACLs == 2 )); then
	echo "[+] Ejecutando Modulo de Control Fino con ACLs..."
	if ! getent passwd "$USUARIO_PERMISOS" &>/dev/null; then
		echo "[ERROR] El usuario $USUARIO_PERMISOS no existe en el sistema" >&2
		exit 1
	fi
	if setfacl -R -m u:"$USUARIO_PERMISOS":r-x "$DIRECTORIO_PERMISOS" 2>/dev/null; then
		echo "[OK] ACLs de lectura y ejecucion (r-x) aplicadas recursivamente a $USUARIO_PERMISOS"
	else
		echo "[ERROR] Fallo al aplicar ACLs recursivas" >&2
	fi
	if setfacl -d -m u:"$USUARIO_PERMISOS":r-x "$DIRECTORIO_PERMISOS" 2>/dev/null; then
		echo "[OK] ACLs por defecto (Default ACL) configuradas para futuros archivos"
	else
		echo "[ERROR] Fallo al configurar Default ACLs" >&2
    	fi
elif (( ACLs > 0 )); then
	echo "[ERROR] Para el modulo de ACLs debes incluir -c y -u juntos" >&2
fi

if (( AUDITORIA == 1 )); then
	echo "Se activo el Modulo de Auditoria de Permisos Peligrosos para el directorio $DIRECTORIO_PELIGROSO"
	mapfile -t files_permisos_especiales < <(find "$DIRECTORIO_PELIGROSO" -type f \( -perm -4000 -or -perm -2000 \))
	mapfile -t permisos_escrituras < <(find "$DIRECTORIO_PELIGROSO" -perm -o=w)
	mapfile -t files_huerfanos < <(find "$DIRECTORIO_PELIGROSO" -type f \( -nouser -or -nogroup \))

	FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
	REPORTE="auditoria_peligrosa_script_access_guard_${FECHA}.log"
	exec 3>>"$REPORTE"
	echo "============================= AUDITORIA PELIGROSA ===================================" >&3
	echo "REPORTE HECHO POR EL SCRIPT: access_guard.sh" >&3
	echo "DIRECTORIO: $DIRECTORIO_PELIGROSO" >&3
	echo "FECHA: $FECHA" >&3
	echo "======================================================================================" >&3
	echo "			Archivos con permisos especiales: SUID Y SGID" >&3
	echo "======================================================================================" >&3
	printf "%s\n" "${files_permisos_especiales[@]}" >&3
	echo "======================================================================================" >&3
	echo "		  Archivos y Directorios con permiso de escritura para otros">&3
	echo "======================================================================================" >&3
	printf "%s\n" "${permisos_escrituras[@]}" >&3
	echo "======================================================================================" >&3
	echo "		  		Archivos Huerfanos" >&3
	echo "======================================================================================" >&3
	printf "%s\n" "${files_huerfanos[@]}" >&3
	echo "======================================================================================" >&3

	exec 3>&-
	echo "Reporte generado en: $REPORTE"
fi

if (( BLINDAJE == 1 )); then
	echo "[+] Ejecutando Modulo de Revocacion y Blindaje para $USUARIO_BLINDAJE..."
	if ! getent passwd "$USUARIO_BLINDAJE" &>/dev/null; then
        	echo "[ERROR] El usuario $USUARIO_BLINDAJE no existe en el sistema" >&2
		exit 1
    	fi
	## Revocamos ACLs explicitos en todo el sistema
	echo "Removiendo ACLs explicitas asignadas al usuario..."
	find / -xdev \( -type f -o -type d \) -exec setfacl -x u:"$USUARIO_BLINDAJE" {} + 2>/dev/null
	echo "[OK] ACLs explicitas removidas de los sistemas de archivos locales"

	## Eliminamos todos los grupos secundarios
	if usermod -G "" "$USUARIO_BLINDAJE" 2>/dev/null; then
		echo "[OK] Usuario removido de todos los grupos secundarios"
	else
		echo "[ERROR] No se pudo remover al usuario de los grupos secundarios" >&2
	fi

	if usermod -s "/usr/sbin/nologin" "$USUARIO_BLINDAJE" 2>/dev/null; then
		echo "El shell del $USUARIO_BLINDAJE fue cambiado correctamente a /usr/sbin/nologin"
	else
		echo "No se pudo cambiar el shell del usuario" >&2
	fi
fi
