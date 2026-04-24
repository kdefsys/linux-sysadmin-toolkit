#!/bin/bash
### Nombre: revinculacion_inteligente.sh
### Autor: kdefsys
### No solo limpia enlaces rotos, sino que intenta repararlos buscando archivos huerfanos con
### nombres similares en el sistema, comportandose como una herramienta de autorrecuperación
### Uso: ./revinculacion_inteligente.sh <directorio>

if [[ "$#" -ne 1 ]]; then
	echo -e "El script no contiene 1 argumento\nSaliendo del script..."
	exit 1
fi

DIRECTORIO="$1"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')

function menus {
	local -n Lista=$1
	local SALIDA="$2"
	echo "======================================FLUJO DE OPERACIONES================================" &> "$SALIDA"
	for enlace in "${Lista[@]}"; do
		echo "Tenemos el enlace roto: $enlace"
		read -p "Que hacemos? REPARAR(R), ELIMINAR(E), IGNORAR(I): " opcion
		case "$opcion" in
			R|r)
				local archivo_destino=$(readlink "$enlace")
				local archivo2="${archivo_destino##*/}"
				local archivo_nuevo=$(find "/" -type f -name "*${archivo2}" 2>/dev/null | head -n 1)
				if [[ -z "$archivo_nuevo" ]]; then
					echo "No se puede reparar porque el archivo dejo de existir"
				else
					echo "El archivo al parecer o bien fue movido a otro directorio o se creo en otro"
					if ln -sf "${archivo_nuevo}" "$enlace"; then
						echo "$enlace           REPARADO" | tee -a "$SALIDA"
						echo "RUTA ANTIGUA: ${archivo_destino}   RUTA NUEVA: ${archivo_nuevo}" | tee -a "$SALIDA"
					fi
				fi ;;
			E|e)
				if rm -v "$enlace"; then
					echo "$enlace      ELIMINADO" | tee -a "$SALIDA"
				fi
				;;
			*)
				echo "$enlace      IGNORADO" | tee -a "$SALIDA" ;;
		esac
	done
}

if [[ -d "$DIRECTORIO" ]]; then
	mapfile -t enlaces_rotos < <(find "$DIRECTORIO" -type l -not -exec test -e {} \; -print)
	if [[ "${#enlaces_rotos[@]}" -eq 0 ]]; then
		echo -e "No hay enlaces rotos\nSaliendo del script..."
		exit 1
	fi
	SALIDA="auditoria_enlaces_${FECHA}.log"
	cantidad_enlaces_rotos="${#enlaces_rotos[@]}"
	echo -e "LISTA DE ENLACES ROTOS CON LOS ARCHIVOS A LOS QUE APUNTA:\n\n" | tee -a "$SALIDA"
	for enlace in "${enlaces_rotos[@]}"; do
		archivo_destino=$(readlink "$enlace")
		printf "%s     %s\n" "$enlace" "$archivo_destino" | tee -a "$SALIDA"
	done
	menus enlaces_rotos $SALIDA
else
	echo "El directorio ingresado como argumento no existe"
	echo "Saliendo del script..."
	sleep 2
	exit 1
fi

