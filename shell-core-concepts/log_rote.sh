#!/bin/bash
### Nombre: log_rote.sh
### Autor: kdefsys
### Tienes un servidor de aplicaciones que genera archivos de log constantemente (.log).
### Si estos archivos se quedan ahí, crecen indefinidamente. Tu misión es crear un script que rote
### los logs antiguos: que los identifique, los comprima para ahorrar espacio y mueva los comprimidos
### a una carpeta de histórico, dejando solo los más recientes en la carpeta principal.
### Uso: ./log_rote.sh <directorio_logs> <limite_dias>

if [[ "$#" -ne 2 ]]; then
	echo -e "El script no tiene dos argumentos\nSaliendo del script"
	exit 1
fi

DIRECTORIO="$1"
DIAS="$2"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="rotacion_ejecucion.log"

if [[ -d "$DIRECTORIO" ]]; then

	exec 3>>"$REPORTE"

	mapfile -t archivos_logs < <(find "$DIRECTORIO" -type f \( -name "*access*.log" -o -name "*error*.log" \) \
		-mtime +"$DIAS" -print)
	if [[ "${#archivos_logs[@]}" -eq 0 ]]; then
		echo -e "No existen archivos con esas caracteristicas\nSaliendo del script..." >&3
		exit 1
	else
		SALIDA="archive_[${FECHA}]"
		DIRECTORIO_NUEVO="${DIRECTORIO}/${SALIDA}"

		echo "Lista de archivos encontrados" 
		printf "%s\n" "${archivos_logs[@]}"
		read -p "Desea proceder con la rotacion de estos archivos?(s/n):" op

		case "$op" in
			s|S)
			  echo "Procedemos entonces"
			  ;;
			*)
			  echo -e "Se cancelo el proceso\nSaliendo del script"
			  exit 1
			  ;;
		esac

		mkdir "$DIRECTORIO_NUEVO"

		TAMANIO_ANTES=$(du -hcb "${DIRECTORIO}" | tail -n 1)

		echo "Creado correctamente el directorio '${DIRECTORIO_NUEVO}'" >&3
		echo "Ahora comprimimos los archivos" >&3
		printf "%s\0" "${archivos_logs[@]}" | xargs -0 gzip >&3

		mv "${DIRECTORIO}"/*.gz "${DIRECTORIO_NUEVO}"

		TAMANIO_AHORA=$(du -hcb "${DIRECTORIO}" | tail -n 1)

		echo "Movimos correctamente los archivos .gz a ese nuevo directorio" >&3

		vacio_o_no=$(ls -l "${DIRECTORIO}"/*access*.log "${DIRECTORIO}"/*error*.log 2>& /dev/null)

		if [[ -z "$vacio_o_no" ]]; then
			echo "Los logs seleccionados fueron eliminados correctamente al comprimirlos" >&3
		else
			echo "Los logs seleccionados no fueron eliminados correctamente al comprimirlos" >&3
			echo "Saliendo del script, revisar eso porfavor" >&3
			exit 1
		fi

		echo -e "\n\n===============================ESTADISTICAS==============================\n\n" >&3
		echo -e "ARCHIVOS COMPRIMIDOS: ${#archivos_logs[@]}\n\n" >&3
		echo -e "Peso antes de comprimir: ${TAMANIO_ANTES}\n\nPeso despues de comprimir: ${TAMANIO_AHORA}\n\n" >&3
		echo -e "Los archivos que fueron movidos fueron\n\n" >&3
		printf "%s\n" "${archivos_logs[@]}" >&3
	fi
else
	echo -e "El directorio ingresado como primer argumento no existe\nSaliendo del script..."
	exit 1
fi


