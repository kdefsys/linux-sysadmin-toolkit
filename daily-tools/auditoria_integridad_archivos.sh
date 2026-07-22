#!/bin/bash
###Nombre: auditoria_integridad_archivos.sh
###Autor: kdefsys
###Descripción: Este script gestiona la integridad de los archivos de un directorio clave mediante el uso de resúmenes criptográficos (hashes SHA-256)
###El script debe permitir crear un snapshot de referencia y, en ejecuciones posteriores, verificar si han ocurrido cambios (modificaciones, creaciones o eliminaciones)
###Uso: ./auditoria_integridad_archivos.sh -d <directorio> -g -v -f <ruta_archivo> -h(help)

DIRECTORIO_HAY="NO"
SNAPSHOT="NO"
VERIFICACION="NO"

##================================================================================================
## MENÚ DE AYUDA SI PONEMOS LA OPCION -h
##================================================================================================

function help {
	echo "Uso: $0 -d <directorio> [-g] [-v] [-f <ruta_directorio_salida>] [-h]"
	echo "  -d: Directorio a auditar"
	echo "  -g: Generar nuevo snapshot de referencia"
	echo "  -v: Verificar estado actual contra el snapshot"
	echo "  -f: Directorio destino para guardar snapshots y logs"
	echo "  -h: Muestra esta ayuda"
	exit 0
}

##================================================================================================
## MENÚ DE GETOPTS
##================================================================================================

while getopts :d:gvf:h opt; do
	case "$opt" in
	  d)
	   DIRECTORIO="$OPTARG"
	   if [[ ! -d "$DIRECTORIO" ]]; then
		echo "El directorio especificado no existe. Usando directorio actual."
		DIRECTORIO="$(pwd)"
	   fi
	   ;;
	  g)
	   SNAPSHOT="SI"
	   ;;
	  v)
	   VERIFICACION="SI"
	   ;;
	  f)
	   RUTA="$OPTARG"
	   if [[ ! -d  "$RUTA" ]]; then
		echo "La ruta de salida no existe. Guardando en directorio del script."
		RUTA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	   fi
	   ;;
	  h)
	   help
	   ;;
	  *)
	   echo "Opción inválida"
	   exit 1
	esac
done

if [[ "$SNAPSHOT" == "NO" && "$VERIFICACION" == "NO" ]]; then
    echo "Error: Debes especificar al menos la opción -g (generar) o -v (verificar)."
    echo "Usa $0 -h para ver las instrucciones."
    exit 1
fi

if [[ -z "$RUTA" ]]; then
	RUTA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [[ -z "$DIRECTORIO" ]]; then
        DIRECTORIO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
RUTA_FINAL="${RUTA}/snapshot_old.db"

##=================================================================================================
## PROCEDEMOS A HACER EL SNAPSHOT DE NUESTRO DIRECTORIO PASADO COMO ARGUMENTO
##=================================================================================================

if [[ "$SNAPSHOT" == "SI" ]]; then
	echo "Generando snapshot de referencia para: $DIRECTORIO..."
	> "$RUTA_FINAL"
	find "$DIRECTORIO" -type f -exec sha256sum {} + >> "$RUTA_FINAL"
	echo "Snapshot guardado en: $RUTA_FINAL"
fi

##==================================================================================================
## PROCEDENOS A HACER LA VERIFICACION CON EL SISTEMA ACTUAL DE ARCHIVOS
##==================================================================================================

if [[ "$VERIFICACION" == "SI" ]]; then
	if [[ ! -f "$RUTA_FINAL" ]]; then
        	echo "Error: No existe un snapshot previo ($RUTA_FINAL). Ejecuta con -g primero."
        	exit 1
    	fi

	RUTA_FINAL2="${RUTA}/snapshot_new.db"
	RUTA_MODIFICADOS="${RUTA}/modificados.log"
	RUTA_CREADOS="${RUTA}/creados.log"
	RUTA_ELIMINADOS="${RUTA}/eliminados.log"

	> "$RUTA_FINAL2"
	> "$RUTA_MODIFICADOS"
        > "$RUTA_CREADOS"
        > "$RUTA_ELIMINADOS"

	find "$DIRECTORIO" -type f -exec sha256sum {} + >> "$RUTA_FINAL2"
	sort "${RUTA_FINAL}" -o "${RUTA_FINAL}"
	sort "${RUTA_FINAL2}" -o "${RUTA_FINAL2}"

	mapfile -t modi_o_cre < <(comm -23 "${RUTA_FINAL2}" "${RUTA_FINAL}" | gawk '{ $1=""; print substr($0,2) }')
	for file in "${modi_o_cre[@]}"; do
        	if grep -Fq "$file" "${RUTA_FINAL}"; then
            		echo "Archivo: $file" >> "${RUTA_MODIFICADOS}"
        	else
            		echo "Archivo: $file" >> "${RUTA_CREADOS}"
        	fi
    	done

    	mapfile -t eliminados < <(comm -13 "${RUTA_FINAL2}" "${RUTA_FINAL}" | gawk '{ $1=""; print substr($0,2) }')
    	for file in "${eliminados[@]}"; do
        	if ! grep -Fq "$file" "${RUTA_FINAL2}"; then
            		echo "Archivo: $file" >> "${RUTA_ELIMINADOS}"
        	fi
    	done

	##================================================================================================
	## MOSTRANDO EN PANTALLA LOS RESULTADOS
	##================================================================================================

	echo -e "\n===== REPORTE DE AUDITORÍA =====\n"
    	echo -e "--- Archivos CREADOS ---"
    	[[ -s "$RUTA_CREADOS" ]] && cat "$RUTA_CREADOS" || echo "Ninguno"

    	echo -e "\n--- Archivos MODIFICADOS ---"
    	[[ -s "$RUTA_MODIFICADOS" ]] && cat "$RUTA_MODIFICADOS" || echo "Ninguno"

    	echo -e "\n--- Archivos ELIMINADOS ---"
    	[[ -s "$RUTA_ELIMINADOS" ]] && cat "$RUTA_ELIMINADOS" || echo "Ninguno"

    	rm -f "$RUTA_FINAL2"
fi
