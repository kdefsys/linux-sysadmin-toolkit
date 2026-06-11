#!/bin/bash
###Nombre: auditoria_unificada_pro.sh
###Autor: kdefsys
###Centraliza la busqueda, el calculo de espacio y la pre-seleccion de archivos criticos o basura
###utilizando estrictamente getopts para procesar argumentos
###Uso: ./auditoria_unificada_pro.sh -d <directorio> -p <patron> -m <dias> -s <tamanio> -e

directorio_hay=""
PATRON="error"
dias_hay=""
tamanio_hay=""
interaccion=""
FECHA=$(date +"%Y:%m:%d_%H:%M:%S")
SALIDA="reporte_unificado_${FECHA}.log"

while getopts :d:p:m:s:e opt; do
	case "$opt" in
		d)
		  DIRECTORIO="${OPTARG}"
		  if [[ -d "$DIRECTORIO" ]]; then
			directorio_hay="si"
		  fi
		  ;;
		p)
		  PATRON="${OPTARG}"
		  ;;
		m)
		  dias_hay="si"
		  DIAS="${OPTARG}"
		  ;;
		s)
		  tamanio_hay="si"
		  TAMANIO="$OPTARG"
		  ;;
		e)
		  interaccion="si"
		  ;;
		*)
		  echo -e "Argumento no valido\n"
		  exit 1
	esac
done

function recopilacion {

	local directorio=$1
	local variable=$2
	local patron=$3

	if [[ "$variable" -eq 1 ]]; then
		find "$directorio" -type f -mtime -"$DIAS" -exec grep -Hic "$patron" {} + | gawk -F ':' '$2!=0{print $1}'
	elif [[ "$variable" -eq 2 ]]; then
		find "$directorio" -type f -size +"${TAMANIO}M" -exec grep -Hic "$patron" {} + | gawk -F ":" '$2!=0{print $1}'
	else
		find "$directorio" -type f -size +"${TAMANIO}M" -mtime -"$DIAS" -exec grep -Hic "$patron" {} + | gawk -F ":" '$2!=0{print $1}'
	fi

}

if [[ -n "$directorio_hay" ]]; then
	exec 3>>"$SALIDA"

	if [[ -n "$DIAS" ]]; then
		if [[ -n "$TAMANIO" ]]; then
			mapfile -t archivos_log < <(recopilacion "$DIRECTORIO" 3 "$PATRON")
		else
			mapfile -t archivos_log < <(recopilacion "$DIRECTORIO" 1 "$PATRON")
		fi
	else
		if [[ -n "$TAMANIO" ]]; then
			mapfile -t archivos_log < <(recopilacion "$DIRECTORIO" 2 "$PATRON")
		else
			mapfile -t archivos_log < <(find "$DIRECTORIO" -type f -exec grep -Hic "$PATRON" {} + | gawk -F ":" '$2!=0{print $1}')
		fi
	fi

	echo -e "\n\n=========REPORTE===========\n\n" >&3
	echo -e "Para el directorio ${DIRECTORIO} hemos tenido los siguientes archivos cuyo contenido se encuentra el patron: ${PATRON}\n\n" >&3
	if [[ "${#archivos_log[@]}" -ne 0 ]]; then
		printf "%s\n" "${archivos_log[@]}" >&3
		if [[ -n "$interaccion" ]]; then
			echo -e "\n\nModo de eliminacion segura activado\n" >&3
			echo -e "Procedemos a eliminar los archivos con terminaciones: .bak, .tmp, .old\n\n" >&3
			for archivo in "${archivos_log[@]}"; do
				if [[ "$archivo" =~ \.(bak|tmp|old)$ ]]; then
					rm -fv "$archivo" >&3
				fi
			done

		else
			echo -e "\nFinal del reporte" >&3
		fi
	else
		echo "No hay ningun archivo con esas caracteristicas" >&3
	fi
else
	echo "No introdujo ningun directorio y era argumento obligatorio"
	echo "SALIENDO DEL SCRIPT..."
	exec 3>&-
	exit 1
fi

exec 3>&-
