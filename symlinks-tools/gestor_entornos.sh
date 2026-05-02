#!/bin/bash
### Nombre: gestor_entornos.sh
### Autor: kdefsys
### Utiliza enlaces simbolicos para cambiar instantaneamente la configuracion activa de una aplicacion
### (por ejemplo, un sitio web o una base de datos) entre diferentes entornos, utilizando getopts para manejar
### los parametros
### Uso: ./gestor_entornos.sh -s <directorio_source> -t <target> -e <entorno>

DIRECTORIO=""
ENTORNO=""
ESTADO=""
REPORTE="reporte_gestor_entorno.log"

while getopts :s:t:e: opt; do
	case "$opt" in
		s)
		  if [[ -d "$OPTARG" ]]; then
			DIRECTORIO="$OPTARG"
		  fi
		  ;;
		t)
		  ESTADO="Activado"
		  ENLACE="$OPTARG"
		  ;;
		e)
		  if [[ -e "${DIRECTORIO}/${OPTARG}" ]]; then
			ENTORNO="$OPTARG"
		  fi
		  ;;
		*)
		  echo -e "Argumento no valido\nSaliendo del script..."
		  exit 1
	esac
done

exec 3>>"${REPORTE}"

if [[ -z "$ESTADO" ]]; then
	echo -e "No hay opcion de accion -t\nSaliendo del Script..."
	exec 3>&-
	exit 1
fi


if [[ -z "$DIRECTORIO" || -z "$ENTORNO" ]]; then
	echo -e "Los argumentos de directorio o de entorno esta vacio\nSaliendo del script..."
	exec 3>&-
	exit 1
fi

if [[ -L "$ENLACE" ]]; then
	if ln -sf "${DIRECTORIO}/${ENTORNO}" "${ENLACE}" 2> /dev/null; then
		echo "La modificacion del enlace simbolico con exito"
		echo -e "EL CAMBIO FUE UN EXITO\nUSUARIO:${USER}\tHORA:$(date '+%Y-%m-%d_%H-%M-%S')\nENTORNO: ${DIRECTORIO}/${ENTORNO} CON EL ENLACE: ${ENLACE}\n" >&3
	else
		echo "Hubo un error en la modificacion del enlace simbolico"
	fi
elif [[ -d "$ENLACE" || -f "$ENLACE" ]]; then
	echo "No es un enlace simbolico, asi que no procedemos a eliminar nada"
	exec 3>&-
	exit 1
else
	echo "No existe el enlace, pero vamos a crearlo"
	if ln -s "${DIRECTORIO}/${ENTORNO}" "${ENLACE}" 2>/dev/null; then
		echo "Creado el nuevo enlace simbolico con exito"
		echo -e "EL PROCESO FUE UN EXITO\nUSUARIO:${USER}\nHORA:$(date '+%Y-%m-%d_%H-%M-%S')\nENTORNO: ${DIRECTORIO}/${ENTORNO} CON EL ENLACE: ${ENLACE}\n" >&3
	else
		echo "Hubo un error en la creacion del enlace simbolico"
	fi
fi

echo "Proceso Finalizado, Reporte en ${REPORTE}"
exec 3>&-
