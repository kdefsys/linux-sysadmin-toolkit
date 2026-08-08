#!/bin/bash
### Nombre: kernel_boot_persister.sh
### Autor: kdefsys
### Descripcion: Los cambios realizados dinámicamente en el kernel de Linux (como cargar o descargar módulos en caliente) son volátiles y se pierden tras reiniciar el sistema.
### En entornos de servidores es fundamental garantizar la persistencia de la configuración: por un lado, auto-cargar módulos críticos requeridos por el sistema al iniciar; por el
### otro, bloquear permanente (blacklist) controladores vulnerables, innecesarios o que representen un riesgo de seguridad. Además, para evitar configuraciones ciegas o incoherentes,
### se requiere verificar primero si existe hardware físico en el equipo vinculado al módulo que se desea gestionar antes de escribir cualquier regla permanente.
### Uso: sudo ./kernel_boot_persister.sh [--blacklist | --enable] <modulo>

function help {
	echo "El script se debe de ejecutar asi: sudo ./kernel_boot_persister.sh [--blacklist | --enable] <modulo>"
	echo "   --blacklist : Bloquear el modulo."
	echo "   --enable : Autocargado del modulo en el arranque."
}

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con privilegios sudo." >&2
	echo "Saliendo del script" >&2
	exit 1
fi

if [[ "$#" -ne 2 ]]; then
	echo "El script no tiene los argumentos necesarios para empezar la ejecucion." >&2
	help
	echo "Saliendo del script" >&2
	exit 1
fi

ACCION="$1"
MODULO="$2"

DIR_BLACKLIST="/etc/modprobe.d"
DIR_LOAD="/etc/modules-load.d"

echo "[+] Iniciando Gestor de Persistencia del kernel..."
echo "--------------------------------------------------"

### =======================================================================================================================
### 				FASE 01: DIAGNOSTICO E INSPECCION DE HARDWARE
### =======================================================================================================================
echo "[+] Escaneando presencia de hardware fisico..."
HW_DETECTADO=0

case "$MODULO" in
	*usb*|*vide*|joydev|ath9k|rtw*)
		if lsusb 2>/dev/null | grep -qiE "video|camera|wireless|wlan|media|input"; then
			HW_DETECTADO=1
		fi
		;;
	*e1000e*|*r8169*|*nvme*|*tg3*)
		if lspci 2>/dev/null | grep -qiE "ethernet|network|audio|vga|non-volatile"; then
			HW_DETECTADO=1
		fi
		;;
	*)
		ALIAS_HW=$(modinfo -F alias "$MODULO" 2>/dev/null)
		if [[ -n "$ALIAS_HW" ]]; then
			HW_DETECTADO=1
		fi
		;;
esac

if [[ "$HW_DETECTADO" -eq 1 ]]; then
	echo "		-> [INFO] Se detectaron indicios de hardware compatible en los buses del sistema."
else
	echo "		-> [ADVERTENCIA] No se detecto hardware fisico activo directamente vinculado a $MODULO."
fi

### =======================================================================================================================
### 					FASE 02: APLICACION DE PERSISTENCIA
### =======================================================================================================================
echo "[+] Aplicando directivas de persistencia en el almacenamiento..."

case "$ACCION" in
	--blacklist)
		ARCHIVO_CONF="${DIR_BLACKLIST}/blacklist-${MODULO}.conf"
		echo "blacklist $MODULO" | tee "$ARCHIVO_CONF" >/dev/null
		if [[ -f "$ARCHIVO_CONF" ]]; then
			echo "	[SUCCESS] Modulo $MODULO bloqueado permanentemente en boot."
			echo "	[CONF] Archivo generado en: $ARCHIVO_CONF"
			echo "[*] Sincronizando estado de la memoria RAM..."
			if modprobe -r "$MODULO" 2>/dev/null; then
				echo "	[SUCCESS] Modulo $MODULO descargado de la RAM en caliente."
			else
				echo "	[INFO] El modulo no estaba activo en la RAM o esta siendo retenido por el sitema."
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
		echo "[-] Parametro no reconocido: $ACCION" >&2
		help
		exit 1
		;;
esac

echo "------------------------------------------------------------------------"
echo "[+] Operacion de persistencia finalizada con exito."
