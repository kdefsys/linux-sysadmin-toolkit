#!/bin/bash
### Nombre: auditor_seguridad_accesos.sh
### Autor: kdefsys
### Descripcion: En servidores de producción expuestos a redes internas o a Internet, los atacantes o scripts automatizados intentan constantemente vulnerar el acceso mediante ataques
### de fuerza bruta por SSH. Al mismo tiempo, malas prácticas de administración pueden dejar cuentas locales con privilegios elevados injustificados o configuraciones inseguras.
### Uso: sudo ./auditor_seguridad_accessos.sh [-u <umbral_fallos>] [-l] [-h]

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con permiso de superusuario. Saliendo del script" >&2
	exit 1
fi

function help {
	echo "El script debe ejecutarse asi: ./auditor_seguridad_accessos.sh -u <umbral_fallos> -l <archivo_log> [-h] "
	echo "Descripcion: Audita cuentas locales y registros de autenticacio SSH frente a un umbral configurable, genera un reporte"
	echo "detallado y muestra un resumen conciso por consola"
	echo -e "\n"
	echo "   -u : Numero minimo de intentos fallidos de autenticacion para que una direccion IP sea catalogada como sospechosa (valor por defecto: 5)"
	echo "   -l : Operacion para ver logs del sistema"
	echo "   -h : Imprime esta guia"
}

UMBRAL=5
OPERACION="NO"

while getopts :u:lh opt; do
	case "$opt" in
		u)
		  UMBRAL="$OPTARG"
		  if ! [[ "$UMBRAL" =~ ^[0-9]+$ ]]; then
			echo "El valor ingresado como valor para numero de intentos fallidos, no es un numero" >&2
			exit 1
		  fi
		  ;;
		l)
		  OPERACION="SI"
		  ;;
		h)
		  help
		  exit 0
		  ;;
		*)
		  echo "Opcion ingresada no valida. Saliendo del script" >&2
		  help
		  exit 1
		  ;;
	esac
done

if [[ "$OPERACION" == "NO" ]]; then
	echo "No se introdujo la bandera para realizar la operacion" >&2
	exit 1
else
	FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
	REPORTE="auditoria_seguridad_${FECHA}.log"
	>"$REPORTE"
	exec 3>>"$REPORTE"

	echo "======================================= AUDITORIA DE SEGURIDAD DE ACCESO Y DE IPs ===================================" >&3
	echo "SCRIPT: auditor_seguridad_accesos.sh" >&3
	echo "HOSTNAME: $HOSTNAME" >&3
	echo "USUARIO: $USER" >&3
	echo "UMBRAL: $UMBRAL" >&3
	echo "FECHA: $FECHA" >&3
	echo "=====================================================================================================================" >&3
	echo "AUDITORIA DE CUENTAS LOCALES" >&3
	echo "USUARIOS CON CUENTAS QUE NO SON ROOT PERO TIENEN ID=0" >&3

	## =============================================================
	## 		AUDITORIA DE CUENTAS LOCALES
	## =============================================================
	## Detectando cuentas locales distintas de root que posean idenfitificador de usuario 0.

	mapfile -t cuentas < <(gawk -F ":" -v normal="root" '{
			if ( $1 != normal && $3 == 0 ) printf "%s\n", $1
		}' "/etc/passwd")
	if [[ "${#cuentas[@]}" -eq 0 ]]; then
		echo "NINGUNA CUENTA" >&3
	else
		printf "%s\n" "${cuentas[@]}" >&3
	fi
	echo "====================================================================================================================" >&3
	echo "AUDITORIA DE CUENTAS DE SHELL INTERACTIVA (/bin/bash o /bin/sh)" >&3
	echo "USUARIOS CON CUENTAS QUE TIENEN CUALQUIERA DE ESAS DOS SHELLS" >&3

	## Identificamos cuentas de shell interactiva (/bin/bash o /bin/sh)

	mapfile -t shell_interactiva < <(gawk -F ":" '{
			if ( $7 == "/bin/bash" || $7 == "/bin/sh" ) printf "%s|%s\n", $1, $7
		}' "/etc/passwd")
	if [[ "${#shell_interactiva[@]}" -eq 0 ]]; then
		echo "NINGUNA CUENTA" >&3
	else
		printf "%s\n" "${shell_interactiva[@]}" >&3
	fi
	echo "===================================================================================================================" >&3
	echo "AUDITORIA DE CUENTAS CON CONTRASEÑAS VACIAS" >&3

	## Identificamos cuentas que tengan la contraseña vacia en la base de sombras del sistema

	mapfile -t contrasenias_vacias < <(gawk -F ":" '{if ($2 == "") print $1}' /etc/passwd)

	if [[ "${#contrasenias_vacias[@]}" -eq 0 ]]; then
		echo "NINGUNA CUENTA" >&3
	else
		printf "%s\n" "${contrasenias_vacias[@]}" >&3
	fi
	echo "==================================== AUDITORIA DE INTENTOS FALLIDOS POR SSH =======================================" >&3
	## ================================================================
	## 		AUDITORIA DE INTENTOS FALLIDOS POR SSH
	## ================================================================
	mapfile -t ip_sospechosos < <(journalctl -u ssh -u sshd --no-pager --output=cat 2>/dev/null \
		| grep -F "Failed password" \
		| gawk -v umbral="$UMBRAL" '{
			for(i=1;i<=NF;++i){
				if ($i == "from"){
					ip=$(i+1)
					conteo[ip]++
					break
				}
			}
		}
		END{
			for (ip in conteo){
				if (conteo[ip] >= umbral){
					printf "%-6d intentos fallidos | IP de origen: %s\n", conteo[ip], ip
				}
			}
		}' | sort -rn )
	if [[ "${#id_sospechosos[@]}" -eq 0 ]]; then
		echo "No hay IPs sospechosos" >&3
	else
		echo "Si hay IPs sospechosos:" >&3
		printf "%s\n" "${ip_sospechosos[@]}" >&3
	fi

	exec 3>&-
	echo "Script finalizado con exito. Puede ver el reporte en: $REPORTE"
	echo "RESUMEN"
	echo "CANTIDAD DE USUARIOS CON PRIVILEGIOS: ${#cuentas[@]}"
	echo "CANTIDAD DE USUARIOS CON SHELL INTERACTIVA: ${#shell_interactiva[@]}"
	echo "CANTIDAD DE USUARIOS CON CONTRASENIAS VACIAS: ${#contrasenias_vacias[@]}"
	echo "CANTIDAD DE IPs SOSPECHOSAS: ${#ip_sospechosos[@]}"
fi
