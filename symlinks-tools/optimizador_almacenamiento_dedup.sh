#!/bin/bash
###Autor: kdefsys
###Script de deduplicacion de almacenamiento local basado en enlaces duros.
###Recorre dos directorios, identifica de forma masiva los archivos que son exactamente
###iguales(mismo tamaño y mismo hash criptográfico), y reemplazar los archivos duplicados
###en el destino por enlaces duros hacia el archivo de referencia original
###Uso: ./optimizador_almacenamiento_dedup.sh -r <dir_referencia> -d <dir_destino> -m <tamaño_min> -s

TAMANIO="0"
SIMULACRO=0
TOTAL_AHORRADO_BYTES=0

while getopts :r:d:m:s opt; do
	case "$opt" in
	  r)
	   DIRECTORIO_RE="${OPTARG:-.}"
	   ;;

	  d)
	   DIRECTORIO_DE="${OPTARG}"
	   if [[ ! -d "${DIRECTORIO_DE}" ]]; then
		echo "El directorio destino no existe" ; exit 1
	   fi
	   ;;
	  m)
	   TAMANIO="${OPTARG:-0}"
	   ;;
	  s)
	   SIMULACRO=1
	   ;;
	  *)
	   echo "Argumento invalido"
	   exit 1
	esac
done

mapfile -t archivos_re < <(find "$DIRECTORIO_RE" -type f -size +"${TAMANIO}c")
declare -A mapa_referencia

for file in "${archivos_re[@]}"; do

	tamanio=$(stat -c "%s" "$file")
	indice="${tamanio}"
	mapa_referencia["$indice"]="${mapa_referencia[$indice]}%${file}"

done

mapfile -t archivos_de < <(find "$DIRECTORIO_DE" -type f -size +"${TAMANIO}c")

for file_de in "${archivos_de[@]}"; do

	tamanio_de=$(stat -c "%s" "$file_de")
	if [[ -n "${mapa_referencia[${tamanio_de}]}" ]]; then

		cadena_re="${mapa_referencia[$tamanio_de]}"
		cadena_re="${cadena_re#%}"
		IFS='%' read -r -a opciones_re <<< "$cadena_re"
		hash_de=$(sha256sum "$file_de" | gawk '{print $1}')

		for file_re in "${opciones_re[@]}"; do

			inodo_de=$(stat -c "%i" "$file_de")
			inodo_re=$(stat -c "%i" "$file_re")
			if [[ "$inodo_de" == "$inodo_re" ]]; then
				continue
			fi
			hash_re=$(sha256sum "$file_re" | gawk '{print $1}')
			if [[ "$hash_re" == "$hash_de" ]]; then
				echo "Duplicado detectado"
				echo "Destino: $file_de"
				echo "Referencia: $file_re"
				TOTAL_AHORRADO_BYTES=$((TOTAL_AHORRADO_BYTES + tamanio_de))
				if (( SIMULACRO == 1 )); then
					echo "Estado: [SIMULACRO] El archivo no ha sido modificado."
				else
					echo "Estado: Reemplazando por enlace duro"
					rm "$file_de" ; ln "$file_re" "$file_de"
				fi
				echo "-------------------------------------------------------"
				break
			fi
		done
	fi
done

TOTAL_AHORRADO_MB=$(echo "scale=2; $TOTAL_AHORRADO_BYTES / 1024 / 1024 " | bc)

echo -e "\n========= RESUMEN DE OPTIMIZACION ==============\n"
if (( SIMULACRO == 1 )); then
	echo "Modo: SIMULACRO (Dry-Run)"
	echo "Espacio total estimado a ahorrar: $TOTAL_AHORRADO_MB MB"
else
	echo "Modo: EJECUCIÓN REAL"
	echo "Espacio total real liberado: $TOTAL_AHORRADO_MB MB"
fi
echo "======================================================="
