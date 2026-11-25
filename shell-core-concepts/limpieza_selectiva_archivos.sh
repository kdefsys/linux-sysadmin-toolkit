#!/bin/bash
### Nombre: limpieza_selectiva_archivos.sh
### Autor: kdefsys
### Descripcion: En la infraestructura de producción de la empresa, los servidores de base de datos, copias de seguridad y sistemas de archivos temporales acumulan constantemente
### archivos antiguos o en desuso (.bak, .tmp, .old, dumps de backup, etc.). Si estos archivos no se gestionan, terminan por saturar el disco duro, provocando caídas críticas en
### los servicios. Este script es una herramienta automatizada pero con confirmacion manual por parte del operador que permita auditar espacio, listar los archivos candidatos a borrado
### y eliminarlos tras una aprobacion explicita.
### Uso: ./limpieza_selectiva_archivos.sh -d <directorio_objetivo> -m <dias> [-h]

function help {
	echo "El script se debe de ejecutar asi: ./limpieza_selectiva_archivos.sh -d <directorio_objetivo> -m <dias> [-h]"
	echo "DESCRIPCION: Inspecciona archivos antiguos que sean .bak, .tmp, .old o archivos cuyo nombre empiezen con backup_"
	echo "y de mayor tamaño dentro de un directorio, calcula el espacio total que ocupan,"
	echo "registra un reporte previo y solicita una confirmacion explicita del operador antes de proceder con su eliminacion"
	echo "   -d : Directorio objetivo donde se realizara la inspeccion. Si no se introduce esta bandera se tomara el directorio actual"
	echo "   -m : Antiguedad minima en dias que deben tener los archivos para ser considerados obsoletos"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
DIAS=0

while getopts :d:m:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		  fi
		  ;;
		m)
		  DIAS="$OPTARG"
		  if ! [[ "$DIAS" =~ ^[0-9]+$ ]]; then
			echo "El valor ingresado como dias, no es un numero entero. Saliendo del script" >&2
			exit 1
		  fi
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

## ==========================================================================
## Busqueda de archivos .bak, .tmp, .old o archivos que comiencen con backup_
## ==========================================================================

mapfile -t files < <(find "$DIRECTORIO" -type f -regextype posix-extended -regex "(.*\.bak$|.*\.tmp$|.*\.old$|.*/backup_.*$)" \
		-mtime +"$DIAS" -size +1M)

CANTIDAD="${#files[@]}"

if (( CANTIDAD == 0 )); then
	echo "No se encontraron archivos con esas caracteristicas"
	exit 0
fi

TAMANIO="$(printf "%s\0" "${files[@]}" | xargs -0 du -hc | tail -n 1 | gawk '{print $1}')"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="limpieza_${FECHA}"
>"$REPORTE"
exec 3>>"$REPORTE"

echo "==================================== LIMPIEZA SELECTIVA ================================" >&3
echo "SCRIPT: limpieza_selectiva_archivos.sh" >&3
echo "DIRECTORIO OBJETIVO: $DIRECTORIO" >&3
echo "LIMITE DE DIAS: $DIAS" >&3
echo "TAMAÑO: +1M" >&3
echo "========================================================================================" >&3
echo "Los archivos encontrados son: " >&3
printf "%s\n" "${files[@]}" >&3
echo "Tamaño total: $TAMANIO" >&3
echo "========================================================================================" >&3

echo "Los archivos encontrados con esas caracteristicas son:"
printf "%s\n" "${files[@]}"
read -n 1 -p "Quiere eliminar los archivos? (Y|N): " op
case "$op" in
	y|Y)
	  echo "Eliminamremos los archivos"
	  if rm -v "${files[@]}" 2>/dev/null; then
		echo "Eliminacion con exito"
		echo "Los archivos fueron eliminados por el usuario que ejecuto el script" >&3
	  else
		echo "Los archivos no pudieron ser eliminados"
		echo "Hubo un error a la hora de eliminar" >&3
	  fi
	  ;;
	*)
	  echo "No eliminaremos nada"
	  ;;
esac
echo "========================================================================================" >&3

exec 3>&-
echo "El script finalizo con exito. Ver el reporte en: $REPORTE"
