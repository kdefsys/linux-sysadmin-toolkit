#!/bin/bash
### Nombre: auditoria_usuarios_privilegios.sh
### Autor: kdefsys
### Descripcion: En la administración de sistemas Linux, la gestión de identidades y accesos es una de las áreas más críticas de la seguridad. Configuración deficiente o ataques
### maliciosos suelen dejar huellas en los archivos /etc/passwd y /etc/shadow. Muchas de esas anomalias son:
### 1. Usuarios con UID 0 que no son root: Un usuario no legítimo con UID 0 obtiene privilegios totales sobre el kernel sin pasar por los mecanismos habituales de delegación (sudo).
### 2. Cuentas con contraseñas vacías: Permiten el acceso inmediato sin ningún tipo de autenticación.
### 3. Inconsistencias en el entorno del usuario: Shells configurados que apuntan a binarios inexistentes o directorios home asignados que no existen en el sistema de archivos.
### Para prevenir esto, este script analiza a todos los usuarios registrados en el sistema, evalua su estado de seguridad y genera un reporte consolidado
### Uso: sudo ./auditoria_usuarios_privilegios.sh

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con privilegios sudo" >&2
	exit 1
fi

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="usuarios_privilegios_${FECHA}.log"
if [[ -f "$REPORTE" ]]; then rm -f "$REPORTE"; fi

function seguridad_cuenta {
	local name="$1"
	local uid="$2"
	local contraseña="$3"
	local -n naturaleza="$4"
	local -n estado_cuenta="$5"

	if (( uid >= 1000 && uid <= 60000 )); then
		naturaleza="HUMANA"
	else
		naturaleza="SISTEMA"
	fi

	if [[ "$uid" -eq 0 && "$name" != "root" ]]; then
		estado_cuenta="[CRITICO] El usuario no es root y tiene permisos de superusuario"
	elif [[ -z "$contraseña" ]]; then
		estado_cuenta="[CRITICO] La contraseña esta vacia"
	elif [[ "$contraseña" =~ ^(!|\*) ]]; then
		estado_cuenta="Contraseña bloqueada"
	else
		estado_cuenta="[OK]"
	fi
}

function seguridad_de_configuracion {
	local ruta_shell="$1"
	local ruta_home="$2"
	local -n estado_configuracion="$3"
	if [[ ! -e "$ruta_shell" ]]; then
		estado_configuracion="SOSPECHOSO (shell no existente)."
	elif [[ ! -d "$ruta_home" ]]; then
		estado_configuracion="SOSPECHOSO (home no existente)."
	else
		estado_configuracion="BIEN"
	fi
}

exec 3>>"$REPORTE"
echo "========================================================REPORTE DE CONFIGURACION DE USUARIOS CON PRIVILEGIOS==========================================" >&3

while IFS=":" read -r name _ UID _ _ home shell; do
	CONTRA="$(getent shadow "$name" | gawk -F ":" '{print $2}')"
	naturaleza=""
	cuenta=""
	configuracion=""
	seguridad_cuenta "$name" "$UID" "$CONTRA" naturaleza cuenta
	seguridad_de_configuracion "$shell" "$home" configuracion
	echo "$name::$UID::$shell::$home::$naturaleza::$cuenta::$configuracion" >&3
done < "/etc/passwd"
exec 3>&-
echo "auditoria_usuarios_privilegios.sh ha concluido correctamente. Ver el reporte en $REPORTE"
