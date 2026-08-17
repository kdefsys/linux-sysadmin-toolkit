#!/bin/bash
### Nombre: pci_network_monitor.sh
### Autor: kdefsys
### Descripcion: En una auditoría de seguridad física, el equipo de respuesta a incidentes sospecha que un atacante o empleado descontento está conectando tarjetas de red no
### autorizadas (adaptadores Ethernet PCIe dedicados, interfaces USB-to-Ethernet o tarjetas Wi-Fi M.2/PCIe) en los servidores para crear puertas traseras físicas (out-of-band
### management) o puentear la segmentación de red empresarial.
### Este script analiza una interfaz de red especifica pasada como parametro ( por ejemplo eth0, wlan0, enp3s0 y eth1 ) y valida si la tarjeta esta conectada mediante un bus PCI/PCIe
### o USB, extrayendo su telemetria directamente del hardware.
### Uso: sudo ./pci_network_monitor.sh <interfaz_de_red>

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con permiso sudo" >&2
	exit 1
fi

if [[ "$#" -ne 1 ]]; then
	echo "El script solo debe de ejecutarse con un solo parametro que es la interfaz de red." >&2
	exit 1
else
	if [[ ! -d "/sys/class/net/"$1"" ]]; then
		echo "La interfaz de red no tiene directorio en /sys/class/net." >&2
		exit 1
	fi
fi

RED="$1"
echo "[+] Auditando interfaz de red: "$RED""
echo "-----------------------------------------------------------------------------------------------------"

### --------------------------------------------------------------------------------------------------------
### 			FASE 01: IDENTIFICACION DEL BUS DE CONEXION (/sys)
### --------------------------------------------------------------------------------------------------------

enlace="$(readlink -f /sys/class/net/"$RED")"

if echo "$enlace" | grep -qi "pci" 2>/dev/null; then
	if echo "$enlace" | grep -qi "usb" 2>/dev/null; then
		BUS="USB Bus"
	else
		BUS="PCI Express"
	fi
elif echo "$enlace" | grep -qi "usb" 2>/dev/null; then
	BUS="USB Bus"
elif echo "$enlace" | grep -qi "virtual" 2>/dev/null; then
	BUS="Virtual"
fi

### --------------------------------------------------------------------------------------------------------
### 	FASE 02: INSPECCION Y EXTRAIDO DE ATRIBUTOS DE HARDWARE solo para PCIs o USB
### --------------------------------------------------------------------------------------------------------

if [[ "$BUS" =~ ^(PCI|USB).* ]]; then
	echo "-> Estado: Dispositivo fisico detectado."
	DIRECCION_MAC="$(cat "/sys/class/net/${RED}/address")"
	RUTA_DRIVER="$(readlink -f "/sys/class/net/${RED}/device/driver")"
	if [[ -n "$RUTA_DRIVER" ]]; then
		DRIVER="$(basename "$RUTA_DRIVER")"
	else
		DRIVER="$(udevadm info -q property -p "/sys/class/net/${RED}" | grep "ID_NET_DRIVER" | cut -d "=" -f 2)"
	fi
	ID_VENDOR="$(udevadm info -q property -p "/sys/class/net/${RED}" | grep "ID_VENDOR_ID" | cut -d "=" -f 2)"
	ID_DEVICE="$(udevadm info -q property -p "/sys/class/net/${RED}" | grep "ID_MODEL_ID" | cut -d "=" -f 2)"
	RUTA_DEV="/sys/class/net/${RED}/device"
	if [[ -z "$ID_VENDOR" && -f "${RUTA_DEV}/vendor" ]]; then
		ID_VENDOR="$(cat "${RUTA_DEV}/vendor")"
	fi
	if [[ -z "$ID_DEVICE" ]]; then
		if [[ -f "${RUTA_DEV}/device" ]]; then
			ID_DEVICE="$(cat "${RUTA_DEV}/device")"
		elif [[ -f "${RUTA_DEV}/idProduct" ]]; then
			ID_DEVICE="$(cat "${RUTA_DEV}/idProduct")"
		fi
	fi
	UBICACION_BUS="$(basename "$(readlink -f "${RUTA_DEV}")")"
	echo "-> Direccion MAC permanente: ${DIRECCION_MAC:-Desconocida}"
	echo "-> Bus de conexion: $BUS ($UBICACION_BUS)"
	echo "-> Driver del kernel en uso: ${DRIVER:-Desconocido}"
	echo "-> Vendor ID: ${ID_VENDOR:-Desconocido}"
	echo "-> Device/Product ID: ${ID_DEVICE:-Desconocido}"
fi



### ---------------------------------------------------------------------------------------------------------
### 					FASE 03: ALERTA DE AUDITORIA
### ---------------------------------------------------------------------------------------------------------

echo "------------------------------------------------------------------------------------------------------"
if [[ "$BUS" == *"USB"* ]]; then
	echo "[ALERTA DE SEGURIDAD]: Interfaz de red extraible/USB detectado."
elif [[ "$BUS" == "PCI"* ]]; then
	echo "[INFO]: Interfaz de red fija integrada/PCIe"
else
	echo "[INFO]: Interfaz virtual detectada."
fi
