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
	echo "   -d : Directorio objetivo donde se realizara la inspeccion. Si no se introduce esta bandera se tomara el directorio actual"
	echo "   -m : Antiguedad minima en dias que deben tener los archivos para ser considerados obsoletos"
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
COTA_INFERIOR=""

while getopts :d:m:h opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
		 	echo "El directorio ingresado: $DIRECTORIO no existe. Saliendo del script..." >&2
			exit 1
		 fi
		 ;;
		m)
		 COTA_INFERIOR="$OPTARG"
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

if [[ -z "$COTA_INFERIOR" ]]; then
	echo "No se introdujo la antiguedad minima en dias. Saliendo del script..." >&2
	help
	exit 1
fi

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="limpieza_${FECHA}.log"
if [[ -f "$REPORTE" ]]; then rm -f "$REPORTE"; fi

exec 3>>"$REPORTE"

echo "============================================LIMPIEZA================================================" >&3
echo "DIRECTORIO: $DIRECTORIO" >&3
echo "FECHA: $FECHA" >&3
echo "UMBRAL DE DIAS MINIMOS: $COTA_INFERIOR" >&3

mapfile -t files < <(find "$DIRECTORIO" -type f -regextype posix-extended -regex "(\.bak$|\.tmp$|\.old$|.*/backup_[^/]*$)" -mtime +"$COTA_INFERIOR" -size +1M)

echo "CANTIDAD_DE_ARCHIVOS_ENCONTRADOS: ${#files[@]}" >&3

if [[ "${#files[@]}" -eq 0 ]]; then
	echo -e "\n\nNo hay ningun archivo que cumpla esas caracteristicas" >&3
else
	ESPACIO_TOTAL=$(printf "%s\0" "${files[@]}" | xargs -0 du -hc | tail -n 1 | gawk '{print $1}')

	echo "ESPACIO TOTAL EN DISCO OCUPADO: $ESPACIO_TOTAL" >&3
	echo "LISTADO DE LOS ARCHIVOS: " >&3
	printf "%s\n" "${files[@]}" >&3
fi

echo "Limpieza_selectiva_archivos.sh fue lanzada con exito, ver el reporte en: $REPORTE"
echo "Veamos el contenido"
echo "================================================================================="
cat "$REPORTE"
echo "================================================================================="

sleep 2

if [[ "${#files[@]}" -eq 0 ]]; then
	exec 3>&-
	exit 0
fi

read -p "Desea eliminar los archivos mostrados? (s|n): " op

case "$op" in
	s|S|Si|SI|si|sI)
		echo -e "\n\nARCHIVOS ELIMINADOS: \n" >&3
		for file in "${files[@]}";do
			rm -fv "$file" | tee -a "$REPORTE"
		done
		echo "Los archivos fueron eliminados del sistema correctamente"
		;;
	*)
	  echo "No se puede eliminar los archivos del sistema"
	  ;;
esac
exec 3>&-
