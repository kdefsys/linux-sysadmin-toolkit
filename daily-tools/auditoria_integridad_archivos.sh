#!/bin/bash
###Nombre: auditoria_integridad_archivos.sh
###Autor: kdefsys
###Descripción: Este script gestiona la integridad de los archivos de un directorio clave mediante el uso de resúmenes criptográficos (hashes SHA-256)
###El script debe permitir crear un snapshot de referencia y, en ejecuciones posteriores, verificar si han ocurrido cambios (modificaciones, creaciones o eliminaciones)
###Uso: ./auditoria_integridad_archivos.sh -d <directorio> -g -v -f <ruta_archivo> -h(help)

##================================================================================================
## MENÚ DE AYUDA SI PONEMOS LA OPCION -h y FUNCIONES
##================================================================================================

function help {
	echo "Uso: $0 -d <directorio> [-g] [-v] [-f <ruta_directorio_salida>] [-h]"
	echo "DESCRIPCION: Permite vigilar la integridad de los archivos dentro de un directorio objetivo"
	echo "mediante resumenes criptograficos de contenido, pudiendo generar una base de referencia (snapshot)"
	echo "y en ejecuciones posteriores, detectar y reportar que archivos fueron creados, modificados o eliminados"
	echo -e "\n"
	echo "  -d: Directorio a auditar"
	echo "  -g: Generar nuevo snapshot de referencia"
	echo "  -v: Verificar estado actual contra el snapshot"
	echo "  -f: Directorio destino para guardar snapshots y logs"
	echo "  -h: Muestra esta ayuda"
	exit 0
}

function generar_snapshot {
	local origen="$1"
	local destino="$2"
	local file="$3"

	if [[ -f "$file" ]]; then rm -f "$file"; fi

	find "$origen" -type f -exec sha256sum {} + 2>/dev/null 1>>"$file"
}

function verificacion {
	local ruta_snapshot="$1"
	local destino="$(dirname "$ruta_snapshot")"
	local origen="$2"

	>"${destino}/creados.log"
	>"${destino}/modificados.log"
	>"${destino}/eliminados.log"

	mapfile -t archivos_nuevos < <(find "$origen" -type f -exec sha256sum {} + 2>/dev/null)
	CANTIDAD="${#archivos_nuevos[@]}"
	if (( CANTIDAD == 0 )); then
		cat "$ruta_snapshot" | gawk '{$2=""; for(i=2;i<=NF;i++) $2 = $2 ( i==2 ? "" : " ") $i; print $2}' >> "${destino}/eliminados.log"
	else
		for string in "${archivos_nuevos[@]}"; do
			file_nuevo="$(echo "$string" | gawk '{$2=""; for(i=2;i<=NF;i++) $2 = $2 ( i==2 ? "" : " ") $i; print $2}')"
			cripto_nuevo="$(echo "$string" | gawk '{print $1}')"
			#verificamos si fue creado o modificado
			presente="$(gawk '{$2=""; for(i=2;i<=NF;i++) $2 = $2 ( i==2 ? "" : " ") $i; print $2}' "${ruta_snapshot}" \
				| grep -Fx -- "${file_nuevo}")"
			if [[ -z "$presente" ]]; then
				echo "$file_nuevo" >> "${destino}/creados.log"
			else
				cripto_antiguo="$(gawk -v archivo="${file_nuevo}" '{
					$2=""; for(i=2;i<=NF;i++) $2 = $2 ( i==2 ? "" : " ") $i;
					if ( $2 == archivo ){ print $1; exit }
				}' "${ruta_snapshot}")"
				if [[ "$cripto_antiguo" != "$cripto_nuevo" ]]; then
					echo "$file_nuevo" >> "${destino}/modificados.log"
				fi
			fi
		done
		#vericiamos si fue eliminado
		while read -r cripto_antiguo file_antiguo; do
			eliminado="$(printf "%s\n" "${archivos_nuevos[@]}" \
				| gawk '{$2=""; for(i=2;i<=NF;i++) $2 = $2 ( i==2 ? "" : " ") $i; print $2}' | grep -Fx -- "${file_antiguo}")"
			if [[ -z "$eliminado" ]]; then
				echo "$file_antiguo" >> "${destino}/eliminados.log"
			fi
		done < <(cat "$ruta_snapshot" | gawk '{$2=""; for(i=2;i<=NF;i++) $2 = $2 (i==2 ? "" : " ") $i; print $1, $2}')
	fi
}

##================================================================================================
## MENÚ DE GETOPTS
##================================================================================================

DIRECTORIO="$(pwd)"
DIRECTORIO_DESTINO="$(pwd)"
SNAPSHOT="NO"
VERIFICACION="NO"
FILE_SNAPSHOT="snapshot.db"

while getopts :d:gvf:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado como objetivo no existe. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		g)
		  SNAPSHOT="SI"
		  ;;
		v)
		  VERIFICACION="SI"
		  ;;
		f)
		  DIRECTORIO_DESTINO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO_DESTINO" ]]; then
			echo "El directorio ingresado como destino no existe. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		h)
		  help
		  exit 0
		  ;;
		*)
		  echo "Opcion ingresada no valida" >&2
		  help
		  exit 1
		  ;;
	esac
done

if [[ "$SNAPSHOT" == "SI" ]]; then
	if generar_snapshot "$DIRECTORIO" "$DIRECTORIO_DESTINO" "${DIRECTORIO_DESTINO}/${FILE_SNAPSHOT}" 2>/dev/null; then
		echo "Snapshot generado exitosamente. Puede verlo en ${DIRECTORIO_DESTINO}/${FILE_SNAPSHOT}"
	else
		echo "No se pudo generar el snapshot"
		exit 1
	fi
fi

if [[ "$VERIFICACION" == "SI" ]]; then
	if [[ ! -f "${DIRECTORIO_DESTINO}/${FILE_SNAPSHOT}" ]]; then
		echo "No existe ningun archivo snapshot en el directorio $DIRECTORIO_DESTINO" >&2
		echo "NO se puede hacer ninguna verificacion. Debe crear primero el snapshot" >&2
		exit 1
	else
		echo "PROCESO DE VERIFICACION..."
		if verificacion "${DIRECTORIO_DESTINO}/${FILE_SNAPSHOT}" "$DIRECTORIO" 2>/dev/null; then
			echo "El proceso de verificacion termino con exito"
		else
			echo "No se pudo completar el proceso de verificacion" >&2
			exit 1
		fi
	fi
fi

## ==================================================================================================
## 						REPORTE
## ==================================================================================================

if [[ "$VERIFICACION" == "NO" ]]; then
	exit 0
fi

echo -e "Archivos Creados:\n"
if [[ $(wc -l < "${DIRECTORIO_DESTINO}/creados.log") -eq 0 ]]; then
	echo "NINGUNO"
else
	cat "${DIRECTORIO_DESTINO}/creados.log"
fi

echo -e "\n\n"

echo -e "Archivos Modificados:\n"
if [[ $(wc -l < "${DIRECTORIO_DESTINO}/modificados.log") -eq 0 ]]; then
	echo "NINGUNO"
else
	cat "${DIRECTORIO_DESTINO}/modificados.log"
fi
echo -e "\n\n"

echo -e "Archivos Eliminados:\n"
if [[ $(wc -l < "${DIRECTORIO_DESTINO}/eliminados.log") -eq 0 ]]; then
	echo "NINGUNO"
else
	cat "${DIRECTORIO_DESTINO}/eliminados.log"
fi
echo -e "\n\n"
