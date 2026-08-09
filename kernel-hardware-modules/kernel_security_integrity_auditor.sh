#!/bin/bash
### Nombre: kernel_security_integrity_auditor.sh
### Autor: kdefsys
### Descripcion: En entornos corporativos con altos estándares de ciberseguridad, la carga de módulos del kernel no autorizados o sin firma digital representa un riesgo crítico de
### ejecución de rootkits o drivers no probados.
### Este script de auditoria analiza de forma integral el estado de los modulos cargados en la memoria RAM, verifica si cumplen con las politicas de firma digital (Tainted Kernel),
### detecta configuraciones huerfanas en /etc/modprobe.d/ y toma acciones correctivas automaticas.
### Uso: sudo ./kernel_security_integrity_auditor.sh [--strict]

function help {
	echo "El script se debe de ejecutar asi: sudo ./kernel_security_integrity_auditor.sh [--strict]"
	echo "    --strict: Activa el modo estricto de mitigacion (intenta descargar automaticamente cualquier modulo que rompa las politicas)."
	echo "Si no se pasa ningun parametro, el script debe ejecutar solo un modo de auditoria (lectura/reporte)."
}

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con privilegios sudo." >&2
	help
	exit 1
fi

if [[ "$#" -eq 0 ]]; then
	ESTRICTO=0
elif [[ "$#" -eq 1 ]]; then
	ARGUMENTO="$1"
	if [[ "$ARGUMENTO" == "--strict" ]]; then
		ESTRICTO=1
	else
		echo "Introdujo un argumento no valido. Saliendo del script." >&2
		help
		exit 1
	fi
else
	echo "El script tiene mas de 1 argumento, lo cual no es valido. Saliendo del script" >&2
	help
	exit 1
fi

### ========================================================================================================
###         FASE 01: AUDITORIA DE SEGURIDAD Y MODULOS "TAINTED" (CONTAMINADOS)
### ========================================================================================================

echo "Vamos a examinar si hay algun modulo en el kernel que este contaminando la RAM."

TAINTED="$(cat /proc/sys/kernel/tainted)"

if [[ "$TAINTED" -eq 0 ]]; then
	echo "[OK] El kernel esta limpio (sin flags de contaminacion)."
else
	echo "[WARN] El kernel esta CONTAMINADO (tainted flag: $TAINTED)."
	echo "Vamos a ver cual de los modulos esta alterando la RAM."
	mapfile -t modulos < <(lsmod | gawk 'NR>1 {print $1}')

	for modulo in "${modulos[@]}"; do
		CONTAMINADO=0
		LICENCIA="$(modinfo -F license "$modulo" 2>/dev/null)"
		if [[ -z "$LICENCIA" || "$LICENCIA" != *"GPL"* ]]; then
			echo "[SECURITY_RISK] Modulo Propietario / No GPL ($LICENCIA) : $modulo"
			CONTAMINADO=1
		fi
		if ! modinfo "$modulo" 2>/dev/null | grep -qi "signer" ; then
			echo "[SECURITY_RISK] Modulo no firmado: $modulo"
			CONTAMINADO=1
		fi
		if [[ -f "/sys/module/$modulo/taint" ]]; then
			TAINT_INDIVIDUAL="$(cat "/sys/module/$modulo/taint")"
			if [[ -n "$TAINT_INDIVIDUAL" ]]; then
				echo "[TAINTED] El modulo $modulo tiene banderas de contaminacion: $TAINT_INDIVIDUAL."
				CONTAMINADO=1
			fi
		fi
		if [[ "$ESTRICTO" -eq 1 && "$CONTAMINADO" -eq 1 ]]; then
			echo "Descargaremos el modulo $modulo de la RAM por estar contaminandola."
			if modprobe -r "$modulo" 2>/dev/null; then
				echo "[OK] Se descargo correctamente el modulo $modulo"
			else
				echo "[ERROR] No se pudo descargar de la RAM el modulo $modulo, por lo tanto sigue contaminando"
			fi
		fi
	done
fi

### ==========================================================================================================
###     FASE 02: VERIFICACION DE REGLAS Y PERSISTENCIA (/etc/modprobe.d/ y /etc/modules-load.d/)
### ==========================================================================================================

unset modulos

mapfile -t modulos < <(lsmod | gawk 'NR>1 {print $1}')

### Conflictos de carga: Aquellos modulos cargados en RAM que actualmente figuran en una regla de blacklist dentro de /etc/modprobe.d

for modulo in "${modulos[@]}"; do
	if grep -rqE "^\s*blacklist\s+${modulo}\b" /etc/modprobe.d/*.conf 2>/dev/null; then
		echo "[WARN] El modulo $modulo esta ejecutandose en la RAM y a la vez esta en el blacklist de modprobe.d"
		if [[ "$ESTRICTO" -eq 1 ]]; then
			echo "Como se activo el modo --strict, vamos a descargarlo inmediatamente."
			if modprobe -r "$modulo" 2>/dev/null; then
				echo "Modulo: $modulo descargado correctamente de la RAM."
			else
				echo "No se pudo descargar el modulo $modulo correctamente. Saliendo del script" >&2
				exit 1
			fi
		fi
	fi
done

### Buscar archivos huerfanos

echo "[+] Buscando archivos de configuracion huerfanos..."
DIRECTORIOS=("/etc/modules-load.d" "/etc/modprobe.d")

for DIR in "${DIRECTORIOS[@]}"; do
	if [[ -d "$DIR" ]]; then
		for ARCHIVO in "$DIR"/*.conf; do
			[[ -f "$ARCHIVO" ]] || continue
			grep -vE '^\s*#|^\s*$' "$ARCHIVO" | while read -r LINEA; do
				MODULO=$(echo "$LINEA" | gawk '{
					if($1 == "blacklist" || $1 == "options" || $1 == "install" || $1 == "remove") print $2;
					else if ($1=="alias") print $3;
					else print $1;
				}')
				[[ -z "$MODULO" ]] && continue
				if ! modinfo "$MODULO" &>/dev/null; then
					echo "[WARN] Archivo Huerfano/Invalido detectado:"
					echo "         -> Archivo: $ARCHIVO"
					echo "         -> Modulo no encontrado: $MODULO"
					echo "-------------------------------------------"
				fi
			done
		done
	fi
done
