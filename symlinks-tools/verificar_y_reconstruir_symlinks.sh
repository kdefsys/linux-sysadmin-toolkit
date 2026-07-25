#!/bin/bash
### Nombre: verificar_y_reconstruir_symlinks.sh
### Autor: kdefsys
### Descripción: En un entorno de producción, múltiples despliegues de software dependen de enlaces simbólicos estandarizados para apuntar a las versiones activas
### (por ejemplo, /opt/app/current apunte a la versión de producción /opt/app/release/v3.2). Tras un proceso de actualización o rollback defectuoso, varios enlaces quedaron
### apuntando a versiones obsoletas o rutas incorrectas.
### El script toma un archivo de configuracion estructurado en formato par clave:valor (del tipo enlace_a_verificar:nuevo_destino_esperado) y fuerce la reorientación de cada enlace
### únicamente cuando este apunte a una ruta distinta a la deseada
### Uso: ./verificar_y_reconstruir_symlinks.sh -f <archivo> -h [help]

function help {
	echo "Debe ejecutar el script asi: ./verificar_y_reconstruir_symlinks.sh -f <ruta_archivo> [-h]"
	echo "     -f: Ruta del archivo de configuracion objtivo"
	echo "     -h: Imprime esta guia"
}

##========================================================================================
##				MENU GETOPTS
##========================================================================================

OPERACION="NO"

while getopts :f:h opt; do
	case "$opt" in
		f)
		 RUTA_ARCHIVO="$OPTARG"
		 if [[ ! -f "$RUTA_ARCHIVO" ]]; then
			echo "El archivo ingresado no existe"
			echo "Saliendo del script..."
			exit 1
		 else
		 	OPERACION="SI"
		 fi
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Ingreso una opcion invalida. Saliendo del script..."
		 help
		 exit 1
		 ;;
	esac
done

if [[ "$OPERACION" == "SI" ]]; then

	DIRECTORIO_ARCHIVO="$(dirname "$RUTA_ARCHIVO")"
	REPORTE="${DIRECTORIO_ARCHIVO}/cambios_enlace.log"
	exec 3>>"$REPORTE"

	echo -e "Realizamos la operacion de reconstruccion de enlaces del archivo: ${RUTA_ARCHIVO}\n\n" >&3
	while IFS=":" read -r enlace ruta || [[ -n "$enlace" ]]; do
		if [[ -L "$enlace" ]]; then
			ruta_destino="$(readlink "$enlace")"
			if [[ "$ruta_destino" == "$ruta" ]]; then
				echo -e "\nEl enlace: $enlace ya apuntaba a esa direccion, no es necesario redireccionar\n" >&3
			else
				echo "El enlace: $enlace apunta a otra direccion, vamos a reconstruir"
				if ln -sf "$ruta" "$enlace" 2>/dev/null; then
					echo -e "\nEl enlace $enlace se reconstruyo correctamente, ahora apunta a $(readlink "$enlace")\n" >&3
				else
					echo -e "\nEl enlace $enlace no se pudo reconstruir correctamente\n" >&3
				fi
			fi
		else
			echo "El enlace $enlace no existe, pasamos al siguiente registro"
		fi
	done < <(cat "$RUTA_ARCHIVO")

	echo "================================VEAMOS EL RESULTADO DEL REPORTE: $REPORTE============================================"
	exec 3>&-
	cat "$REPORTE"
else
	echo "El script no se puede ejecutar, porque no ingreso el archivo de configuracion objetivo"
	help
	exit 1
fi

