#!/bin/bash
### Nombre: auditoria_usuarios_privilegios
### Autor: kdefsys
### La gestion de usuarios es una de las áreas más críticas de la administración de sistemas. Un usuario con UID 0 que no sea root,
### una contraseña vacia o un shell inexsitente son indicadores de una mala configuración o de un sistema comprometido.
### Este script analiza archivos /etc/passwd y /etc/shadow para clasificar a los usuarios y detectar anomalías de seguridad.
### Uso: sudo ./auditoria_usuarios_privilegios

if [[ "$EUID" -ne 0 ]]; then
	echo -e "El script debe ejecutarse con privilegios de superusuario\nSaliendo del script..."
	exit 1
fi

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="usuarios_privilegios_${FECHA}.log"

echo -e "======================================REPORTE DE CONFIGURACION DE USUARIOS CON PRIVILEGIOS=====================================\n\n" > "$REPORTE"
function seguridad_de_cuenta {
	local -n Natural=$3
	local -n Estad=$4

	if [[ "$2" -ge 1000 && "$2" -le 60000 ]]; then
		Natural="HUMANA"
	else
		Natural="sistema"
	fi

	if [[ "$2" -eq 0 && "$1" != "root" ]]; then
		Estad="Crítico por no ser root"
	else
		if [[ -z "$5" ]]; then
			Estad="CRITICO por contrasenia vacía"
		elif [[ "$5" =~ "^(!|\*)" ]]; then
			Estad="BLOQUEADA"
		else
			Estad="OK"
		fi
	fi

}

function seguridad_de_configuracion {
	local -n Estad2=$3

	if [[ ! -e "$1" ]]; then
		Estad2="SOSPECHOSO (shell no existente)"
	elif [[ ! -d "$2" ]]; then
		Estad2="SOSPECHOSO (home no existente)"
	else
		Estad2="BIEN"
	fi
}

while IFS=":" read -r name uid shell direhome; do

	contrasenia=$(getent shadow "$name" | cut -d ":" -f 2)
	Naturaleza="ok"
	Estado="ok"
	Estado2="ok"
	seguridad_de_cuenta "$name" "$uid" Naturaleza Estado "$contrasenia"
	seguridad_de_configuracion "$shell" "$direhome" Estado2
	printf "%s::%s::%s::%s::%s::%s::%s\n" "$name" "$uid" "$shell" "$direhome" "$Naturaleza" "$Estado" "$Estado2" | tee -a "$REPORTE" &> /dev/null

done < <(gawk -F ":" 'BEGIN{OFS=":"} {print $1, $3, $7, $6}' /etc/passwd)

