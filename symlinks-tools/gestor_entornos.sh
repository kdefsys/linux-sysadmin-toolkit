#!/bin/bash
### Nombre: gestor_entornos.sh
### Autor: kdefsys
### Descripción: En arquitecturas de software modernas, es muy común tener múltiples archivos o directorios de configuración correspondientes a distintos entornos
### (por ejemplo: config.prod, config.dev, config.qa).Para evitar modificar el código fuente de las aplicaciones, los sistemas de despliegue emplean un enlace simbólico maestro
### (como config.active o current_env) que apunta directamente al entorno deseado en cada momento.
### Este script es capaz de conmutar de forma segura la configuración activa mediante el uso de argumentos en linea de comandos.
### Uso: ./gestor_entornos.sh -s <directorio_fuente> -t <enlace simbolico objetivo> -e <entorno_objetivo> -h [help]

function help {
	echo "Se debe de ejecutar asi: ./gestor_entornos.sh -s <directorio_fuente> -t <enlace simbolico objetivo> -e <entorno_objetvio> -h [help]"
	echo "   -s: Directorio fuente"
	echo "   -t: Enlace simbolico objetivo"
	echo "   -e: Entorno objetivo"
	echo "   -h: Imprime esta guia "
}

### =======================================================
###			MENU DE GETOPTS
### =======================================================

DIRECTORIO_HAY="NO"
ENLACE_HAY="NO"
ENTORNO_HAY="NO"

while getopts :s:t:e:h opt; do
	case "$opt" in
		s)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
		 	echo "ERROR: El directorio fuente '$DIRECTORIO' no existe."
			exit 1
		 fi
		 DIRECTORIO_HAY="SI"
		 ;;
		t)
		 ENLACE="$OPTARG"
		 ENLACE_HAY="SI"
		 ;;
		e)
		 ENTORNO="$OPTARG"
		 ENTORNO_HAY="SI"
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion Invalida, no existe este argumento"
		 help
		 exit 1
		 ;;
	esac
done

if [[ "$DIRECTORIO_HAY" == "SI" && "$ENLACE_HAY" == "SI" && "$ENTORNO_HAY" == "SI" ]]; then
	RUTA_DESTINO="${DIRECTORIO}/$ENTORNO"
	if [[ ! -e "$RUTA_DESTINO" ]]; then
		echo "Error: El entorno '$ENTORNO' no existe dentro de '$DIRECTORIO'."
		exit 1
	fi
	REPORTE="reporte_gestor_entorno.log"
	exec 3>>"$REPORTE"
	echo "=======================================REPORTE DE CREACION Y MODIFICACION DE ENLACES==============================" >&3
	echo "Autor: $USER" >&3
	echo "FECHA: $(date '+%Y-%m-%d %H-%M-%S')" >&3
	echo "Enlace: $ENLACE 	-	RUTA: $RUTA_DESTINO" >&3

	if [[ -L "$ENLACE" ]]; then
		echo "La ruta: $ENLACE es un enlace simbolico" >&3 
		echo "Procedemos a cambiar su destino para que apunte al entorno" >&3
		if ln -sf "${RUTA_DESTINO}" "$ENLACE" 2>/dev/null; then
			echo "El cambio fue realizado con exito" >&3
			echo "Ahora el enlace: $ENLACE apunta a la ruta $RUTA_DESTINO" >&3
		else
			echo "El cambio del enlace: $ENLACE a la ruta $RUTA_DESTINO no se pudo realizar correctamente" >&3
		fi
	elif [[ -f "$ENLACE" || -d "$ENLACE" ]]; then
		echo "El ruta: $ENLACE no es un enlace simbolico" >&3
	else
		echo "La ruta $ENLACE no existe" >&3
		echo "Hay que convertirlo en enlace simbolico" >&3
		if ln -s "$RUTA_DESTINO" "$ENLACE" 2>/dev/null; then
			echo "Se creó correctamente el enlace" >&3
			echo "$ENLACE apunta a la ruta $RUTA_DESTINO" >&3
		else
			echo "No se pudo crear correctamente el enlace $ENLACE" >&3
		fi
	fi
	exec 3>&-
else
	echo "No estan presentes los 3 argumentos obligatorios"
	help
	exit 1
fi
