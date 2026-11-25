#!/bin/bash
### Nombre: gestion_backups_rotacion.sh
### Autor: kdefsys
### Descripción: El script recibe un directorio origen y empaqueta su contenido en un archivo comprimido en una carpeta destino.
### Para evitar llenar el disco con respaldos antiguos, el script debe aplicar una politica de retencion automatica (rotacion).
### Uso: ./gestion_backups_rotacion.sh  -d <directorio_origen> -f <directorio_destino> -l <limite> [-h]

### ==========================================================================
###			GUIA MEDIANTE [-h]
### ==========================================================================

function help {
	echo "El script se ejecuta asi: ./gestion_backups_rotacion.sh -d <directorio_origen> -f <directorio_destino> -l <limite> [-h]"
	echo "DESCRIPCION: Comprime y respalda el contenido de un directorio origen en un directorio destino con marca de tiempo y"
	echo "aplica una politica de retencion automatica eliminando los respaldos mas antiguos cuando se supere el limite maximo"
	echo "    -d <directorio_origen> : Directorio objetivo"
	echo "    -f <directorio_destino> : Directorio destino"
	echo "    -l <limite> : limite de backup"
	echo "    -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
DIRECTORIO_DESTINO="$(pwd)"
LIMITE=0
POLITICA="NO"

while getopts :d:f:l:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		f)
		  DIRECTORIO_DESTINO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO_DESTINO" ]]; then
			echo "El directorio ingresado como destino no existe. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		l)
		  LIMITE="$OPTARG"
		  if ! [[ "$LIMITE" =~ ^[0-9]+$ ]]; then
			echo "El valor ingresado como limite no es un numero" >&2
			exit 1
		  fi
		  POLITICA="SI"
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

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
RESPALDO="${DIRECTORIO_DESTINO}/backup_${FECHA}.tar.gz"

if tar -czvf "$RESPALDO" -C "$DIRECTORIO" .  2>/dev/null; then
	echo "El directorio objetivo fue comprimido y empaquetado correctamente"
	echo "La ruta del respaldo es: $RESPALDO"
	echo "Cuyo tamaño es: $(stat -c '%s' "$RESPALDO")"
else
	echo "EL directorio objetivo no pudo ser comprimido y empaquetado correctamente" >&2
fi

## ================================================================================================
## 				ROTACION Y LIMPIEZA
## ================================================================================================

if [[ "$POLITICA" == "NO" ]]; then
	echo "No limpiamos porque el limite es 0"
	exit 0
else
	mapfile -t files_comprimidos < <(find "$DIRECTORIO_DESTINO" -type f \( -name "*.tar.gz" -o -name "*.tgz" \))
	CANTIDAD="${#files_comprimidos[@]}"
	echo "En el directorio $DIRECTORIO_DESTINO hay $CANTIDAD de archivos comprimidos"
	if (( CANTIDAD > LIMITE )); then
		echo "[WARN] La cantidad supera el limite. Vamos a rotar y eliminar"
		SOBRA=$(( CANTIDAD - LIMITE ))
		if printf "%s\0" "${files_comprimidos[@]}" | xargs -0 stat -c "%Y|%n" \
			| gawk -F "|" '{ruta="";for(i=2;i<=NF;i++) ruta=(i==2?"": ruta " ") $i; printf "%s|%s\n" $1, ruta}' | sort -t "|" -k1,1n \
			| head -n "$SOBRA" | gawk -F "|" '{printf "%s\0", $2}' | xargs -0 rm -fv 2>/dev/null; then
			echo "Se eliminaron correctamente los archivos sobrantes"
		else
			echo "No se eliminaron correctamente los archivos sobrantes" >&2
			exit 1
		fi
	else
		echo "[OK] La cantidad esta dentro del rango limite"
	fi
fi
