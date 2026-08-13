#!/bin/bash
###Nombre: usb_security_guard.sh
###Autor: kdefsys
###Descripcion: En la infraestructura de la empresa, la fuga de información sensible (Data Loss Prevention - DLP) y la inyección de vectores de ataque físicos mediante memorias USB
###(como BadUSB o ejecuciones no autorizadas) representan un riesgo de alta prioridad.
###El equipo de SOC (Security Operations Center) y Ciberseguridad necesita un mecanismo de auditoría en caliente para inspeccionar cualquier dispositivo de bloques que se conecte a
###los equipos de la red. Se requiere distinguir inmediatamente si un disco es parte de la infraestructura interna fija del sistema o si se trata de un medio extraíble que deba ser
###rastreado, extrayendo sus credenciales únicas de hardware para su posterior integración con el sistema SIEM (Security Information and Event Management).
###Este script actua como un sensor de auditoria y telemetria de hardware extraible. El scrtipt recibe como argumento el nombre de un dispositivo de bloque (ejemplo sdb, sdc) y
###determina su naturaleza, origen de bus y firma forense de fabricante.
###Uso: sudo ./usb_security_guard.sh <nombre_del_dispositivo>

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con permisos sudo" >&2
	exit 1
fi

if [[ "$#" -ne 1 ]]; then
	echo "El script debe recibir solo 1 parametro que es el nombre del dispositivo" >&2
	exit 1
fi

NOMBRE="$1"
DISPOSITIVO="/dev/${NOMBRE}"

[[ ! -b "$DISPOSITIVO" ]] && { echo "El dispositivo ingresado no existe en el sistema." >&2; exit 1; }

### ----------------------------------------------------------------------------------------------------------------
### 		FASE 01: IDENTIFIACION DE LA NATURALEZA DEL DISPOSITIVO (FIJO vs EXTRAIBLE)
### ----------------------------------------------------------------------------------------------------------------
echo "[+] Identificando la naturaleza del dispositivo (Fijo vs Extraible)."

RUTA_SYS="/sys$(udevadm info -q path -n "$DISPOSITIVO")"
if [[ -f "${RUTA_SYS}/removable" ]]; then
	REMOVIBLE="$(cat "${RUTA_SYS}"/removable)"
	if (( REMOVIBLE == 0 )); then
		echo "[OK] Es un dispositivo fijo interno, pertenece a la infraestructura y no requiere acciones de contencion."
		echo "---------------------------------------------------------------------------------------------------------"
	else
		echo "[ALERTA] Es un dispositivo extraible o memoria pendrive."
		echo "--------------------------------------------------------"
		### -------------------------------------------------------------------------------------------------
		### 			FASE 02: RASTREIO DEL BUS PADRE Y JERARQUIA FISICA
		### -------------------------------------------------------------------------------------------------
		if [[ -n $(echo "${RUTA_SYS}" | grep -iE "USB") ]]; then
			echo " -> Bus detectado: Subsistema de transferencia USB."
			echo " -> Interfaz del kerenl en RAM: $RUTA_SYS"
			PUERTO=$(echo "${RUTA_SYS}" | gawk -F "/" '{print $6}')
			echo " -> Puerto de conexion fisica: Controlador Maestro $PUERTO"
		else
			echo " -> Bus no detectado"
		fi
		### -------------------------------------------------------------------------------------------------
		### 			FASE 03: CREDENCIALES FORENSES DE HARDWARE
		### -------------------------------------------------------------------------------------------------
		VENDEDOR_ID=$(udevadm info -a -n "$DISPOSITIVO" | grep -m1 "ATTRS{idVendor}" | gawk -F '"' '{print $2}')
		PRODUCTO_ID=$(udevadm info -a -n "$DISPOSITIVO" | grep -m1 "ATTRS{idProduct}" | gawk -F '"' '{print $2}')
		NUMERO_SERIAL=$(udevadm info -a -n "$DISPOSITIVO" | grep -m1 "ATTRS{serial}" | gawk -F '"' '{print $2}')
		# si udevadm no los encuentra por alguna razon, los buscamos directamente en /sys subiendo niveles

		if [[ -z "$VENDEDOR_ID" ]]; then
			VENDEDOR_ID=$(udevadm info -q property -n "$DISPOSITIVO" | grep "ID_VENDOR_ID" | cut -d "=" -f 2)
			PRODUCTO_ID=$(udevadm info -q property -n "$DISPOSITIVO" | grep "ID_MODEL_ID" | cut -d "=" -f 2)
			NUMERO_SERIAL=$(udevadm info -q property -n "$DISPOSITIVO" | grep "ID_SERIAL_SHORT" | cut -d "=" -f 2)
		fi
		printf " -> Firma del Fabricante (Vendedor ID): %s\n" "${VENDEDOR_ID:-Desconocido}"
		printf " -> Identificador del Producto (Product ID): %s\n" "${PRODUCTO_ID:-Desconocido}"
		printf " -> Número de Serie de Fábrica: %s\n" "${NUMERO_SERIAL:-Desconocido}"
		echo "---------------------------------------------------------------------------"
		echo "[!] Reporte de auditoría USB generado. Listo para enviar al SIEM."
	fi
else
	echo "[-] El archivo removable no existe para el dispositivo."
	exit 1
fi
