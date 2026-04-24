#!/bin/bash
### Nombre: auditar_symlinks_rotos.sh
### Autor: kdefsys
### Identifica y registra todos los enlaces simbólicos rotos dentro de un directorio
### específico proporcionado por el usuario
### Uso: ./auditar_symlinks_rotos.sh <directorio>

if [[ "$#" -ne 1 ]]; then
	echo -e "El script no tiene ningun argumento\nSaliendo del script..."
	exit 1
fi

DIRECTORIO="$1"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')

if [[ -d "$DIRECTORIO" ]]; then

	SALIDA="auditoria_enlaces_rotos_${FECHA}.log"

	exec 3>>"$SALIDA"

	echo -e "=============================Enlaces rotos en ${DIRECTORIO}===============================" >&3

	mapfile -t enlaces_rotos < <(find "$DIRECTORIO" -type l -not -exec test -e {} \; -print)

	if [[ "${#enlaces_rotos[@]}" -eq 0 ]]; then
		echo "No hay enlaces rotos" >&3
	else
		for enlace in "${enlaces_rotos[@]}"; do
			archivo_destino=$(readlink "$enlace")
			printf "Ruta de enlace:%s\tArchivo Destino:%s\n" "${enlace}" "${archivo_destino}" >&3
		done
		read -p "Desea eliminar estos enlaces? (s/n): " opcion
		case "$opcion" in
			s|S)
				for enlace in "${enlaces_rotos[@]}"; do
					if rm -iv "$enlace"; then
						echo "Enlace: $enlace eliminado del sistema" >&3
					fi
				done ;;
			*)
				echo "No hay proceso de eliminación"
				;;
		esac
	fi

else
	echo -e "El directorio ingresado como primer argumento no existe\nSaliendo del script..."
	exit 1
fi

echo -e "El contenido completo del archivo log resultante es:"

cat "$SALIDA"

exec 3>&-
