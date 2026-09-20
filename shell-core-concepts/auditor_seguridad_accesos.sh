#!/bin/bash
### Nombre: auditor_seguridad_accesos.sh
### Autor: kdefsys
### Descripcion: En servidores de producción expuestos a redes internas o a Internet, los atacantes o scripts automatizados intentan constantemente vulnerar el acceso mediante ataques
### de fuerza bruta por SSH. Al mismo tiempo, malas prácticas de administración pueden dejar cuentas locales con privilegios elevados injustificados o configuraciones inseguras.
### Uso: sudo ./auditor_seguridad_accessos.sh [-u <umbral_fallos>] [-l <archivo_log>] [-h]

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con permisos de superusuario" >&2
	exit 1
fi

function help {
	echo "El script debe ejecutarse asi: ./auditor_seguridad_accessos.sh -u <umbral_fallos> -l <archivo_log> [-h] "
	echo "   -u : Numero minimo de intentos fallidos de autenticacionnn para que una direccion IP sea catalogada como sospechosa (valor por defecto: 5)"
	echo "   -l : Ruta al archivo log de autenticacion a inspeccionar. Si no se especifica, debe buscar automaticamente el archivo estandar del sistema"
	echo "   por ejemplo, /var/log/auth.log en Debian/Ubuntu o /var/log/secure en RHEL/CentOS y validar que exista y tenga permiso de lectura."
	echo "   -h : Imprime esta guia"
}

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
UMBRAL=5
REPORTE="auditoria_seguridad_${FECHA}.log"
ARCHIVO_LOG=""

while getopts :u:l:h opt; do
	case "$opt" in
		u)
		 if [[ "$OPTARG" =~ ^[0-9]+$ ]] && (( OPTARG > 0 )); then
			UMBRAL="$OPTARG"
		 else
			echo "El valor de umbral ingresado no es un numero. Saliendo del script..." >&2
			exit 1
		 fi
		 ;;
		l)
		 if [[ -f "$OPTARG" ]]; then
		 	if ! [[ -r "$OPTARG" ]]; then
				echo "El archivo ingresado existe, pero no tiene permiso de lectura" >&2
				exit 1
			else
				ARCHIVO_LOG="$OPTARG"
			fi
		 else
			echo "El archivo log ingresado no existe. Saliendo del script..." >&2
			exit 1
		 fi
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

if [[ -z "$ARCHIVO_LOG" ]]; then
	if [[ -f "/var/log/auth.log" ]]; then
		ARCHIVO_LOG="/var/log/auth.log"
	elif [[ -f "/var/log/secure" ]]; then
		ARCHIVO_LOG="/var/log/secure"
	else
		echo "No se encontró ningún archivo de log de autenticación estándar (/var/log/auth.log o /var/log/secure)." >&2
		exit 1
	fi
fi

## ------------------------------------------------------------------------------------------------------------------
## 					AUDITORIA DE CUENTAS LOCALES
## ------------------------------------------------------------------------------------------------------------------

# Detectando si existe algun usuario en el sistema que tenga UID 0 pero que no sea root

>"$REPORTE"
exec 3>>"$REPORTE"

echo -e "\n==================================== AUDITORIA SEGURIDAD ACCESSOS =============================================\n" >&3
echo "SCRIPT: auditor_seguridad_accesos.sh" >&3
echo "UMBRAL: $UMBRAL" >&3
echo "LOG: $ARCHIVO_LOG" >&3
echo "FECHA: $FECHA" >&3
echo -e "\n===============================================================================================================\n" >&3
echo -e "Usuarios con ID 0 pero que no sean root" >&3

mapfile -t usuarios_peligrosos < <(gawk -F ':' '$3==0{	if($1 != "root") print $1}' /etc/passwd)
CANTIDAD_USUARIOS_PELIGROSOS="${#usuarios_peligrosos[@]}"
if (( CANTIDAD_USUARIOS_PELIGROSOS == 0 )); then
	echo "No existen usuarios que tengan UID 0 y que no sean root" >&3
else
	printf "%s\n" "${usuarios_peligrosos[@]}" >&3
fi

echo -e "\n===============================================================================================================\n" >&3
echo -e "Cuentas activas con shell interactiva" >&3

SHELLS=("/bin/bash" "/bin/sh")
mapfile -t cuentas_activas < <(gawk -F ":" -v a_sh="${SHELLS[*]}" 'BEGIN{OFS="-"} {
	encuentro=0
	split(a_sh, arreglo, " ")
	for ( indice in arreglo){
		if ($7 == arreglo[indice]) encuentro++
	}
	if (encuentro != 0 ) print $1, $7
}' /etc/passwd)

CANTIDAD_SHELLS="${#cuentas_activas[@]}"
if (( CANTIDAD_SHELLS == 0 )); then
	echo "No existen cuentas activas (con shell "$SHELLS[*]") " >&3
else
	printf "%s\n" "${cuentas_activas[@]}" >&3
fi

echo -e "\n==============================================================================================================\n" >&3
echo -e "Cuentas con contraseña vacias" >&3

mapfile -t cuentas_vacias < <(gawk -F ":" '{if ($2 == "") print $1}' /etc/shadow)
CANTIDAD_VACIAS="${#cuentas_vacias[@]}"
if (( CANTIDAD_VACIAS == 0 )); then
	echo "No existen contraseñas activas" >&3
else
	printf "%s\n" "${cuentas_vacias[@]}" >&3
fi

echo -e "\n==============================================================================================================\n" >&3
echo "Auditoria de ataques de fuerza bruta por SSH" >&3
echo -e "\nIntentos Fallidos de acceso por SSH (UMBRAL >= $UMBRAL)" >&3

mapfile -t ips_sospechosas < <(grep "Failed password" "$ARCHIVO_LOG" | gawk -v umbral="$UMBRAL" '{
	for (i=1 ; i <= NF; i++){
		if ($i == "from") {
			ip = $(i+1)
			conteo[ip]++
			break
		}
	}
} END{
	for (ip in conteo){
		if (conteo[ip] >= umbral){
			printf "%-6d intentos fallidos | IP de origen: %s\n", conteo[ip], ip
		}
	}
}' | sort -rn)

CANTIDAD_IPS="${#ips_sospechosas[@]}"
if (( CANTIDAD_IPS == 0 )); then
    echo "OK: No se registraron IPs que alcancen o superen el umbral de $UMBRAL fallos." >&3
else
    printf "%s\n" "${ips_sospechosas[@]}" >&3
fi

echo -e "\n=================================================================================================" >&3
echo "FIN DEL INFORME" >&3
echo "=================================================================================================" >&3

exec 3>&-

# Resumen conciso por consola
echo "Auditoria de seguridad finalizada."
echo "  - Superusuarios ocultos (UID 0): ${#usuarios_peligrosos[@]}"
echo "  - Cuentas sin contrasena       : ${#cuentas_vacias[@]}"
echo "  - IPs sospechosas detectadas   : $CANTIDAD_IPS"
echo "Reporte detallado generado en: $REPORTE"
