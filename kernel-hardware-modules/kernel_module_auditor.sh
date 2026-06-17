#!/bin/bash
###Nombre: kernel_module_auditor.sh
###Autor: kdefsys
###Contexto: En entornos de servidores de alta seguridad o en auditorías de sistemas, mantener módulos del kernel cargados que no se están utilizando (o que pertenecen a hardware 
###obsoleto) es una mala práctica. Cada módulo en la RAM consume memoria y, peor aún, aumenta la "superficie de ataque" del sistema (más código en el kernel significa más potencial 
###de tener una vulnerabilidad explotable).
###Este script actúa como un auditor automatizado para una lista específica de modulos sospechosos o propensos a desuso.
###Uso: sudo ./kernel_module_auditor.sh modulo1 modulo2 modulo3 ...

if [[ "$EUID" -ne 0 ]]; then echo "El script debe de ejecutarse como superusuario"; exit 1; fi

REPORTE="estados_de_los_modulos.log"
exec 3>>"$REPORTE"

echo "[+] Iniciando auditoría de seguridad del kernel..." >&3
echo "--------------------------------------------------" >&3

for modulo in "$@"; do

	echo "[*] Evaluando módulo: $modulo" >&3
	#------------------------------------------------
	##Verificamos si el modulo está montado en la RAM
	#------------------------------------------------

	if lsmod | gawk '{print $1}' | grep -qxi "$modulo"; then
		echo "    -> Estado: ¡ALERTA! El módulo está cargado en la RAM." >&3
		## Extraemos de forma automatica su descripcion y su licencia del modulo
		DESCRIPCION=$(modinfo -F description "$modulo" 2>/dev/null)
		LICENCIA=$(modinfo -F license "$modulo" 2>/dev/null)
		echo "    -> Info: $DESCRIPCION (Licencia: ${LICENCIA})" >&3
		## Intentamos descargar el módulo de la memoria RAM de forma inteligente
		echo "    -> Intentando remover de forma segura..." >&3
		if modprobe -r "$modulo" 2>/dev/null; then
			echo "    [SUCCESS] Módulo $modulo removido con éxito." >&3
		else
			echo "    [ERROR] Módulo $modulo no fue removido con exito" >&3
		fi
	else
		echo "    -> Estado: No está cargado en la RAM. [OK]" >&3
	fi
done

echo "------------------------------------------------------" >&3
echo "[+] Auditoría finalizada." >&3
exec 3>&-
