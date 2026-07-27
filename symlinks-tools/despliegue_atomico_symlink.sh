#!/bin/bash
### Nombre: despliegue_atomico_symlink.sh
### Autor: kdefsys
### Descripcion: En entornos de producción (como servidores web o despliegues de aplicaciones), actualizar una aplicación copiando o sobrescribiendo archivos directamente en el
### directorio activo puede provocar fallos temporales, lecturas incompletas por parte de los usuarios o tiempos de parada (downtime).
### Para evitar esto, las metodologías modernas de SysAdmin y DevOps emplean despliegues atómicos: se prepara la nueva versión en un directorio independiente y, en un único paso
### instantáneo (atómico), se conmuta un enlace simbólico principal que apunta a la versión activa. Si la nueva versión presenta fallos críticos, el sistema debe ser capaz de
### revertir el cambio (rollback) de forma igualmente instantánea hacia la versión estable anterior.
### Uso: ./despliegue_atomico_symlink.sh -p <Ruta_base> -n <name_nueva_version> [-b] -k <limite_versiones_anteriores> [-h]

function help {
	echo "El script se debe de ejecutar asi: ./despliegue_atomico_symlink.sh -p <ruta> -n <nombre> [-b] -k <limite> [-h]"
	echo "   -p : Ruta base que contiene las carpetas de versiones (release/) y el enlace activo (current). Si no se especifica toma el directorio actual"
	echo "   -n : Nombre o etiqueta de la nueva version a activar (ejemplo: v1.2.0 o release_2026-07-26)"
	echo "   -b : Flag tipo switch (sin argumento) que indica que se debe deshacer el ultimo cambio y apuntar a la version inmediatamente anterior."
	echo "   -k : Numero maximo de versiones antiguas que se deben conservar en el servidor (por defecto 3)"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
ESTRUCTURA_HAY="NO"
OPERACION="NO"
ROLLBACK="NO"
LIMITE=3
ELIMINAR="NO"
HISTORIAL="${DIRECTORIO}/releases/archivo_historial.txt"

while getopts :p:n:bk:h opt; do
	case "$opt" in
		p)
		 if [[ -d "$OPTARG" ]]; then DIRECTORIO="$OPTARG"; fi
		 ;;
		n)
		 NOMBRE="$OPTARG"
		 OPERACION="SI"
		 ;;
		b)
		 ROLLBACK="SI"
		 ;;
		k)
		 LIMITE="$OPTARG"
		 ELIMINAR="SI"
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion Invalida"
		 help
		 exit 1
		 ;;
	esac
done

ESTRUCTURA="${DIRECTORIO}/releases"

if [[ ! -d "$ESTRUCTURA" ]]; then
	echo "No existe la estructura: $ESTRUCTURA"
	echo "No se puede continuar. Saliendo del script..."
	exit 1
fi
if ! find "$ESTRUCTURA" -type l | grep -Fq "current" 2>/dev/null; then
	echo "No existe el enlace current"
	echo "No se puede continuar. Saliendo del script..."
	exit 1
else
	ENLACE="${DIRECTORIO}/releases/current"
	ENLACE_TMP="${ENLACE}_TMP"
fi

ESTRUCTURA_HAY="SI"


if [[ "$OPERACION" == "SI" && "$ESTRUCTURA_HAY" == "SI" ]]; then
	NOMBRE_COMPLETO="${DIRECTORIO}/releases/$NOMBRE"
        if [[ ! -e "$NOMBRE_COMPLETO" ]]; then
		echo "No existe la carpeta $NOMBRE"
                echo "No se puede continuar. Saliendo del script..."
                exit 1
	fi
	HISTORIAL="${DIRECTORIO}/releases/archivo_historial.txt"
	DESTINO_ANTERIOR="$(readlink "$ENLACE")"
	if ln -snf "$NOMBRE_COMPLETO" "$ENLACE_TMP" && mv -Tf "$ENLACE_TMP" "$ENLACE"; then

		if [[ ! -f "$HISTORIAL" ]]; then touch "$HISTORIAL"; fi

		if [[ -n "$DESTINO_ANTERIOR" && "$DESTINO_ANTERIOR" != "$NOMBRE_COMPLETO" ]]; then
			echo "[EXITO] El enlace $ENLACE apunta a la nueva version $NOMBRE_COMPLETO"
			echo "$DESTINO_ANTERIOR" >> "$HISTORIAL"
		fi

		DESTINO_ACTUAL="$(readlink "$ENLACE")"

		if [[ "$ELIMINAR" == "SI" ]]; then
			echo "Como la bandera de eliminar fue introducida vamos a examinar la cantidad de versiones"

			## TODAS LAS VERSIONES EXCEPTO LA ACTUAL QUE APUNTA NUESTRO ENLACE
			mapfile -t directorio_versiones < <(find "$DIRECTORIO/releases/" -maxdepth 1 -mindepth 1 -type d ! -path "$DESTINO_ACTUAL" -exec stat -c "%Y %n" {} \;)
			CANTIDAD=${#directorio_versiones[@]}
			if [[ "$CANTIDAD" -gt "$LIMITE" ]]; then
				echo "La cantidad de versiones excedio al limite"
				echo "Procedemos a eliminar las mas antiguas hasta volver al limite permitido"
				CANTIDAD_A_ELIMINAR=$(( CANTIDAD - LIMITE ))
				printf "%s\n" "${directorio_versiones[@]}" | sort -n | head -n "$CANTIDAD_A_ELIMINAR" | gawk '{print $2}' | xargs rm -rfv
				echo "[EXITO] Fueron eliminados con exito, regresamos a la normalidad dentro del limite establecido de versiones"
			fi
		fi
	else
		echo "[ERROR] El enlace $ENLACE no pudo apuntar correctamente a la nueva version $NOMBRE_COMPLETO"
	fi
fi

if [[ "$ROLLBACK" == "SI" ]]; then
	if [[ -n "$HISTORIAL" && -f "$HISTORIAL" ]]; then
		LINEAS=$(wc -l < "$HISTORIAL")
		CONTEO=1
		HUBO_ROOLBACK="NO"
		while (( CONTEO <= LINEAS )); do
			VERSION_ANTERIOR="$(tail -n "$CONTEO" "$HISTORIAL" | head -n 1)"
			if [[ ! -e "$VERSION_ANTERIOR" ]]; then
				(( ++CONTEO ))
				continue
			fi
			VERSION_QUE_VA_PARA_ANTERIOR="$(readlink -f "$ENLACE")"
			if ln -snf "$VERSION_ANTERIOR" "$ENLACE_TMP" && mv -Tf "$ENLACE_TMP" "$ENLACE" 2>/dev/null; then
				echo "[EXITO] El enlace $ENLACE volvio a apuntar a la version anterior que apuntaba $VERSION_ANTERIOR"
				echo "$VERSION_QUE_VA_PARA_ANTERIOR" >> "$HISTORIAL"
				HUBO_ROOLBACK="SI"
				break
			else
				echo "[ERROR] El enlace $ENLACE no pudo volver a apuntar a la version anterior que apuntaba anteriormente"
			fi
		done
		if [[ "$HUBO_ROOLBACK" == "NO" ]]; then
			echo "Todo el historial tiene rutas que ya no existen"
			echo "No pudo ser posible realizar el Rollback"
			echo "Pasamos a eliminar el historial"
			rm -fv "$HISTORIAL"
		fi
	else
		echo "No existe ningun archivo de historial"
	fi
fi

