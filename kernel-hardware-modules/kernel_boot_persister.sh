#!/bin/bash
###Nombre: kernel_boot_persister.sh
###Autor: kdefsys
###Contexto: Los cambios realizados con modprobe son volátiles y se pierden tras un reinicio. En entornos de servidores es crucial automatizar
###la persistencia de configuraciones del kernel (habilitar modulos criticos o banear controladores vulnerables/inncesearios) asegurando la coherencia
###con el hardware fisico instalado.
###Uso: sudo ./kernel_boot_persister.sh [--blackist | --enable] <modulo>

if [[ "$EUID" -ne 0 ]]; then echo "El script debe de ejecutarse como superusuario"; exit 1; fi

if [[ $# -ne 2 ]]; then
	echo "[-] Error de sintaxis."
	echo "Uso correcto: sudo $0 [--blacklist | --enable] <modulo>"
	exit 1
fi

ACCION="$1"
MODULO="$2"

DIR_BLACKLIST="/etc/modprobe.d"
DIR_LOAD="/etc/modules-load.d"

echo "[+] Iniciando Gestor de Persistencia del Kernel..."
echo "--------------------------------------------------"

#=====================================================================
# FASE 1: DIAGNÓSTICO DE HARDWARE ASOCIADO
#=====================================================================
echo "[*] Escanenado presencia de hardware físico..."

HW_DETECTADO=0

case "$MODULO" in
	*usb*|*video*|joydev|ath9k|rtw*)
		# Buscamos en el subsistema USB
		if lsusb 2/dev/null | grep -qiE "video|camera|wireless|wlan|media|input"; then
			HW_DETECTADO=1
		fi
		;;
	*e1000e*|*r8169*|*nvme*|*tg3*)
		# Buscamos en el bus PCI/PCIe
		if lspci 2>/dev/null | grep -qiE "ethernet|network|audio|vga|non-volatile"; then
			HW_DETECTADO=1
		fi
		;;
	*)
		ALIAS_HW=$(modinfo -F alias "$MODULO" 2>/dev/null)
		if [[ -not -z "$ALIAS_HW" ]]; then
			HW_DETECTADO=1
		fi
		;;
esac

if [[ "$HW_DETECTADO" -eq 1 ]]; then
	echo "		-> [INFO] Se detectaron indicios de hardware compatible en los buses del sistema."
else
	echo "		-> [ADVERTENCIA] No se detectó hardware físico activo directamente vinculado a $MODULO"
fi

#=====================================================================
# FASE 2: APLICACIÓN DE PERSISTENCIA
#=====================================================================
echo "[*] Aplicando directivas de persistencia en el almacenamiento..."

case "$ACCION" in
	--blacklist)
		ARCHIVO_CONF="${DIR_BLACKLIST}/blacklist-${MODULO}.conf"
		# Inyeccion segura en el directorio de modprobe
		echo "blacklist $MODULO" | tee "$ARCHIVO_CONF" >/dev/null
		if [[ -f "$ARCHIVO_CONF" ]]; then
			echo "	[SUCCESS] Módulo '$MODULO' bloqueado permanentemente en boot."
			echo "	[CONF] Archivo generado en: $ARCHIVO_CONF"
			echo "[*] Sincronizando estado en la memoria RAM..."
			if modprobe -r "$MODULO" 2>/dev/null; then
				echo "	[SUCCESS] Módulo '$MODULO' descargado de la RAM en caliente."
			else
				echo "	[INFO] El módulo no estaba activo en la RAM o está siendo retenido por el sistema."
			fi
		else
			echo "	[ERROR] No se pudo escribir la directiva de blacklist."
		fi
		;;
	--enable)
		ARCHIVO_CONF="${DIR_LOAD}/${MODULO}.conf"
		echo "$MODULO" | tee "$ARCHIVO_CONF" >/dev/null
		if [[ -f "$ARCHIVO_CONF" ]]; then
			echo "	  [SUCCESS] Módulo '$MODULO' configurado para auto-carga en el arranque."
			echo "    [CONF] Archivo generado en: $ARCHIVO_CONF"
			echo "[*] Sincronizando estado en la memoria RAM..."
			if modprobe "$MODULO" 2>/dev/null; then
				echo "    [SUCCESS] Módulo '$MODULO' inyectado en la RAM en caliente."
			else
				echo "    [ERROR] No se pudo cargar el módulo en la RAM. Verifique con 'modinfo'."
			fi
		else
			echo "    [ERROR] No se pudo escribir la directiva de carga automática."
		fi
		;;
	*)
		echo "[-] Parámetro no reconocido: $ACCION"
		echo "Use únicamente --blacklist o --enable"
        	exit 1
		;;
esac

echo "--------------------------------------------------"
echo "[+] Operación de persistencia finalizada con éxito."

