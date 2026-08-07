#!/bin/bash
### Nombre: kernel_module_auditor.sh
### Autor: kdefsys
### Descripcion: En entornos de producción con altos requerimientos de seguridad (máquinas hardened o servidores críticos), mantener módulos del kernel cargados en memoria que no
### están en uso activo representa un riesgo innecesario. Cada módulo en la RAM no solo consume recursos del sistema, sino que expande la superficie de ataque al exponer más código
### en espacio de kernel susceptible de contener vulnerabilidades explotables.
### Este es un script de auditoria automatizada que analice una lista de modulos sospechosos o en desuso pasados como argumento por la linea de comandos.
### Uso: sudo ./kernel_module_auditor.sh modulo1 modulo2 modulo3 ...

function help {
	echo "El script se debe de ejecutar asi: sudo ./kernel_module_auditor.sh modulo1 modulo2 modulo3 ..."
	echo "Con un argumento como minimo."
}

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe tener privilegios sudo para poder ejecutarlo. Saliendo del script." >&2
	exit 1
fi

if [[ "$#" -eq 0 ]]; then
	echo "No se paso ningun argumento al script. Saliendo del script." >&2
	help
	exit 1
fi

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="estados_de_los_modulos_${FECHA}.log"
exec 3>>"$REPORTE"

echo "======================================================================== MOVIMIENTO DE MODULOS =============================================================" >&3
echo "Manipulacion de Modulos del kernel. Reporte generado por el script: kernel_module_auditor.sh" >&3
echo "Analisis de los siguientes modulos: ">&3
modulos=("$@")

echo "Los modulos ingresados como parametros son: ${modulos[*]}" >&3
echo "============================================================================================================================================================" >&3

for modulo in "${modulos[@]}"; do
	echo "Se va a pasar para comprobar si $modulo esta cargado actualmente en la memoria RAM." >&3
	if lsmod | gawk '{print $1}' | grep -ixq "$modulo" 2>/dev/null; then
		echo "[ALERTA] El modulo $modulo si esta cargado actualmente en la RAM." >&3

		DESCRIPCION=$(modinfo -F description "$modulo" 2>/dev/null)
		LICENCIA=$(modinfo -F license "$modulo" 2>/dev/null)

		echo "Tiene como descripcion: $DESCRIPCION" >&3
		echo "Tiene como licensia a: $LICENCIA" >&3
		echo "Vamos a proceder a descargar de la memoria RAM" >&3
		if modprobe -r "$modulo" 2>/dev/null; then
			echo "[OK] El descargo funciono correctamente" >&3
		else
			echo "[ERROR] El descargo fallo" >&3
		fi
	else
		echo "[OK] El modulo $modulo no esta cargado actualmente en la memoria RAM" >&3
		echo "El estado es seguro/OK" >&3
	fi
done

exec 3>&-
echo "kernel_module_auditor.sh terminada con exito. Ver el reporte en $REPORTE"
