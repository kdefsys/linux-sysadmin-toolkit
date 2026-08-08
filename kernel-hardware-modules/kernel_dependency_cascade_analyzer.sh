#!/bin/bash
### Nombre: kernel_dependency_cascade_analyzer.sh
### Autor: kdefsys
### Descripcion: En la gestión de incidentes de seguridad o en tareas de optimización de sistemas, remover un módulo del kernel crítico o sospechoso suele fallar porque otros módulos
### dependen de él para funcionar. Intentar remover directamente un módulo "raíz" provocará errores de recurso ocupado o dependencias retenidas.
### Uso: sudo ./kernel_dependency_cascade_analyzer.sh <modulo>

if [[ "$EUID" -ne 0 ]]; then
	echo "El script se debe de ejecutar con privilegios sudo." >&2
	echo "Saliendo del script" >&2
	exit 1
fi

function help {
	echo "El script debe ejecutarse asi: sudo ./kernel_dependency_cascade_analyzer.sh <modulo>"
}

if [[ "$#" -ne 1 ]]; then
	echo "El script no tiene un unico argumento." >&2
	help
	echo "Saliendo del script" >&2
	exit 1
fi

MODULO="$1"

echo "[+] Iniciando Analizador Dinámico de Módulos del kernel..."
echo "----------------------------------------------------------"
echo "[*] Analizando el módulo objetivo: $MODULO"
echo -e "\n"
echo "[+] FASE 1: Inspección de Metadatos y Dependencias en RAM"
echo "----------------------------------------------------------"

### =======================================================================
### FASE 01: INSPECCION DE METADATOS Y DEPENDENCIAS EN RAM
### =======================================================================

if lsmod 2>/dev/null | gawk '{print $1}' | grep -qix "$MODULO"; then
	echo "	-> Estado en RAM:   [CARGADO]"
	RUTA_DISCO="$(modinfo -n "$MODULO")"
	echo "	-> Ruta en Disco:   $RUTA_DISCO"
	echo "  -> Lincencia:	    $(modinfo -F license "$MODULO")"
	echo "  -> Autor:	    $(modinfo -F author "$MODULO")"

	mapfile -t dependientes < <(lsmod 2>/dev/null | gawk '{print $1, $4}' | gawk -v mod="$MODULO" '{ if(mod == $1){ split($2,arreglo,","); for(indice in arreglo){printf "%s\n", arreglo[indice]} }}')
	TOTAL="${#dependientes[@]}"
	echo "   -> Dependientes:   ${dependientes[*]}"

	echo "[+] FASE 2: Ejecutando Descarga en Cascada"
	echo "------------------------------------------"
	if [[ "${#dependientes[@]}" -ne 0 ]]; then
		echo "[TREE] Secuencia calculada de remocion:"
		CANTIDAD=1
		for dep in "${dependientes[@]}"; do
			printf "	%s.  %s\n" "$CANTIDAD" "$dep"
			(( CANTIDAD++ ))
		done
		printf "	%s. %s\n (Objetivo)" "$CANTIDAD" "$MODULO"
		CANTIDAD=0
		SALIDA=0
		for dep in "${dependientes[@]}"; do
			(( CANTIDAD++))
			echo "[*] Intentando remover dependiente ($CANTIDAD/$TOTAL): $dep ..."
			if modprobe -r "$dep" 2>/dev/null; then
				echo "[SUCCESS] Modulo $dep removido de la RAM."
			else
				echo "[ERROR] No se pudo remover $dep. El dispositivo esta en uso."
				(( SALIDA++ ))
				break
			fi
		done
		if (( SALIDA == 1 )); then
			echo "[WARN] Proceso abortado..."
			echo "[-] Operacion finalizada con errores."
			exit 1
		fi
	else
		echo "[INFORME] No hay ninguna dependencia"
		echo "--------------------------------------------------------------------------------------------------"
	fi
	echo "[*] Intentando remover módulo objetivo: $MODULO ..."
	if modprobe -r "$MODULO" 2>/dev/null; then
		echo "[SUCCESS] El modulo objetivo $MODULO fue removido de la RAM."
		echo "[+] Operacion finalizada con exito."
	else
		echo "[ERROR] El modulo objetivo $MODULO no se pudo remover de la RAM."
		echo "[-] Operacion finalizada con errores."
		exit 1
	fi
else
	echo "	-> Estado en RAM:     [NO CARGADO]"
	echo "[+] FASE 3: Diagnostico en Disco y Prerrequisitos"
	echo "-------------------------------------------------"
	cadena="$(modinfo "$MODULO" | head -n 1)"
	if [[ -n "$cadena" ]]; then
		echo "	-> Existe en kernel: SI"
		echo "	-> Ruta en disco: $(modinfo -n "$MODULO")"
		prerrequisitos="$(modinfo -F depends "$MODULO")"
		if [[ -n "$prerrequisitos" ]]; then
			echo "	-> Prerrequisitos: $prerrequisitos"
		else
			echo "	-> Prerrequisitos: No tiene"
		fi
		echo "	-> Estado actual: El módulo está listo para cargarse si el hardware lo requiere."
	else
		echo "	-> Existe en kernel: NO"
		echo "	-> Estado actual: No existe el modulo en el kernel"
	fi
	echo "---------------------------------------------------------------"
	echo "[+] Analisis finalizado con exito."
fi
