#!/bin/bash
###Nombre: usb_security_guard.sh
###Autor: kdefsys
###Uso: sudo ./usb_security_guard.sh <nombre_del_dispositivo>

if [[ "$EUID" -ne 0 ]]; then echo "El script no tiene permiso de superusuario"; exit 1; fi

if [[ "$#" -ne 1 ]]; then echo "El script no tiene el unico argumento <nombre_del_dispositivo>"; exit 1; fi

DISPOSITIVO="$1"

if [[ ! -b "/dev/$DISPOSITIVO" ]]; then echo "El dispositivo de bloque no existe. Saliendo del script..."; exit 1; fi

echo "[+] ANALIZANDO DISPOSITIVO: $DISPOSITIVO"
echo "----------------------------------------------------------------------------"

RUTA_1=$(udevadm info -q path -n "/dev/$DISPOSITIVO")
RUTA_COMPLETA="/sys${RUTA_1}"
ARCHIVO_VIRTUAL=$(cat "$RUTA_COMPLETA/removable")

#---------------------------------------------------------------------------------------------------------------
# FASE 01: DETECTAR LA NATURALEZA DEL DISPOSITIVO (Fijo vs Removible)
#---------------------------------------------------------------------------------------------------------------

if (( ARCHIVO_VIRTUAL == 0 )); then

	echo "[*] Estado: DISPOSITIVO FIJO INTERNO [OK]"
	echo "[+] El dispositivo forma parte de la infraestructura segura de la empresa. No se requiere acción"
	echo "------------------------------------------------------------------------------------------------"

else

	echo "[!] ALERTA: DISPOSITIVO REMOVIBLE DETECTADO EN EL SISTEMA [ALTA PRIORIDAD]"
	echo "--------------------------------------------------------------------------"
	echo " -> Origne del almacenamiento: DISPOSITIVO EXTRAÍBLE / PENDRIVE"

	if [[ -n $(echo "$RUTA_COMPLETA" | grep -iE "USB" ) ]]; then

		echo " -> Bus detectado: Subsistema de transferencia USB"
		#.......................................................................................................
		# FASE 02: RASTREO DEL BUS PADRE (Introspección en el árbol USB)
		#.......................................................................................................
		echo " -> Interfaz del kernel en RAM: $RUTA_COMPLETA"
		PUERTO=$(echo "$RUTA_COMPLETA" | gawk -F "/" '{print $6}')
		echo " -> Puerto de conexión fśicia: Controlador Maestro $PUERTO"

	else
		echo " -> Bus no detectado"
	fi

	#-------------------------------------------------------------------------------------------------------
	# FASE 03: CREDENCIALES FORENSES DE HARDWARE
	#-------------------------------------------------------------------------------------------------------
	VENDEDOR_ID=$(udevadm info -a -n "/dev/$DISPOSITIVO" | grep -m1 "ATTRS{idVendor}" | gawk -F '"' '{print $2}')
	PRODUCTO_ID=$(udevadm info -a -n "/dev/$DISPOSITIVO" | grep -m1 "ATTRS{idProduct}" | gawk -F '"' '{print $2}')
	NUMERO_SERIAL=$(udevadm info -a -n "/dev/$DISPOSITIVO" | grep -m1 "ATTRS{serial}" | gawk -F '"' '{print $2}')

	# Si udevadm no los encuentra por alguna razón, los buscamos directamente en /sys subiendo niveles

	if [[ -z "$VENDEDOR_ID" ]]; then
	        # Subimos desde .../block/sdb hasta encontrar la carpeta del dispositivo (ej: 1-1)
        	# Caminamos de forma segura usando la ruta de los atributos de udev
	        VENDEDOR_ID=$(udevadm info -q property -n "/dev/$DISPOSITIVO" | grep "ID_VENDOR_ID" | cut -d= -f2)
        	PRODUCTO_ID=$(udevadm info -q property -n "/dev/$DISPOSITIVO" | grep "ID_MODEL_ID" | cut -d= -f2)
	        NUMERO_SERIAL=$(udevadm info -q property -n "/dev/$DISPOSITIVO" | grep "ID_SERIAL_SHORT" | cut -d= -f2)
	fi

	printf " -> Firma del Fabricante (Vendedor ID): %s\n" "${VENDEDOR_ID:-Desconocido}"
	printf " -> Identificador del Producto (Product ID): %s\n" "${PRODUCTO_ID:-Desconocido}"
	printf " -> Número de Serie de Fábrica: %s\n" "${NUMERO_SERIAL:-Desconocido}"
	echo "---------------------------------------------------------------------------"
	echo "[!] Reporte de auditoría USB generado. Listo para enviar al SIEM."
fi
