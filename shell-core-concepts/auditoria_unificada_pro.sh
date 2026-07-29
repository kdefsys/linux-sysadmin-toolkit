#!/bin/bash
### Nombre: auditoria_unificada_pro.sh
### Autor: kdefsys
### Descripcion: Este script audita directorios del sistema en busca de archivos de registro que contengan patrones especificos (como errores o alertas).
### Adicionalmente, el script permite filtrar los hallazgos por antiguedad y tamaño, y ofrece un modo opcional para purgar de forma segura archivos temporales o de respaldo
### antiguos que coindicen con los criterios.
### Uso: ./auditoria_unificada_pro.sh -d <directorio> [-p <patron>] [-m <dias>] [-s <tamaño_MB>] [-e] [-h]

function help {
	echo "El script se debe de ejecutar asi: ./auditoria_unificada_pro.sh -d <directorio> [-p <patron>] [-m <dias>] [-s <tamaño_MB>] [-e] [-h]"
	echo "   -d : Ruta absoluta o relativa del directori a auditar. Si no se introduce la bandera se asume que es el directorio actual"
	echo "   -p : Expresion o palabra a buscar dentro del contenido de los archivos. Si no se especifica, debe usar por defecto el patron error"
	echo "   -m : Antiguedad maxima en dias (archivos modificados en los ultimos N dias). Debe validarse que sea un entero positivo"
	echo "   -s : Tamaño minimo del archivo en Megabytes. Debe validarse que sea un entero positivo"
	echo "   -e : Activa el modo de eliminacion segura."
	echo "   -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
PATRON="error"
DIAS=""
TAMANIO=""
ELIMINACION=0

while getopts :d:p:m:s:eh opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
		 	echo "El directorio ingrsado no existe. Saliendo del script." >&2
			exit 1
		 fi
		 ;;
		p)
		 PATRON="$OPTARG"
		 ;;
		m)
		 DIAS="$OPTARG"
		 if ! [[ "$DIAS" =~ ^[0-9]+$ ]]; then
			echo "El numero de dias ingresado no es entero. Saliendo del script." >&2
			exit 1
		 fi
		 ;;
		s)
		 TAMANIO="$OPTARG"
		 if ! [[ "$TAMANIO" =~ ^[0-9]+$ ]];then
			echo "El tamaño ingresado no es entero. Saliendo del script." >&2
			exit 1
		 fi
		 ;;
		e)
		 ELIMINACION=1
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion ingresada invalida" >&2
		 help
		 exit 1
		 ;;
	esac
done

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="reporte_unificado_${FECHA}.log"

if [[ -f "$REPORTE" ]]; then
	rm -f "$REPORTE"
fi

function recopilacion {
	local direc="$1"
	local variable=$2
	local patron="$3"

	case "$variable" in
		1)
		 find "$direc" -type f -size +"${TAMANIO}M" -exec grep -l "$patron" {} + 2>/dev/null
		 ;;
		2)
		 find "$direc" -type f -mtime -"$DIAS" -exec grep -l "$patron" {} + 2>/dev/null
		 ;;
		3)
		 find "$direc" -type f -mtime -"$DIAS" -size +"${TAMANIO}M" -exec grep -l "$patron" {} + 2>/dev/null
		 ;;
		4)
		 find "$direc" -type f -exec grep -l "$patron" {} + 2>/dev/null
		 ;;
		*)
		 ;;
 	esac
}


exec 3>>"$REPORTE"

echo "=============================================== REPORTE UNIFICADO ============================================================="  >&3
echo "DIRECTORIO: $DIRECTORIO" >&3
echo "FECHA: $FECHA" >&3
echo "PATRON: $PATRON" >&3

function proceso {
        local -n arreglo=$1
        local CANTIDAD="${#arreglo[@]}"
        if (( CANTIDAD == 0 )); then
                echo "No hay archivos que cumplan con esas caracteristicas" >&3
        else
                echo "Si se encontraron archivos con esas caracterisitcas. Procedemos a listarlos" >&3
		printf "%s\n" "${arreglo[@]}" >&3
		if (( ELIMINACION == 1 )); then
			echo "Se selecciono la bandera -e: Eliminacion segura de archivos .bak, .tmp y .old"
			echo "===========================================================================" >&3
			echo "Eliminacion por bandera segura -e " >&3
			echo "===========================================================================" >&3
			for file in "${arreglo[@]}"; do
				if ! [[ "$file" =~ .*/.*(\.bak|\.tmp|\.old)$ ]]; then continue; fi
				if rm -f "$file" 2>/dev/null; then
					echo "El archivo: $file fue eliminado con exito" >&3
				else
					echo "El archivo: $file no fue eliminado con exito" >&3
				fi
			done
		fi
        fi
	echo "=================================================================================================" >&3
}


if [[ -z "$DIAS" && -n "$TAMANIO" ]]; then

	echo "TAMANIO: $TAMANIO" >&3
	mapfile -t files < <(recopilacion "$DIRECTORIO" 1 "$PATRON")
	proceso files

elif [[ -n "$DIAS" && -z "$TAMANIO" ]]; then

	echo "DIAS: $DIAS" >&3
	mapfile -t files < <(recopilacion "$DIRECTORIO" 2 "$PATRON")
	proceso files

elif [[ -n "$DIAS" && -n "$TAMANIO" ]]; then

	echo "DIAS: $DIAS" >&3
	echo "TAMANIO: $TAMANIO" >&3
	mapfile -t files < <(recopilacion "$DIRECTORIO" 3 "$PATRON")
	proceso files

else

	mapfile -t files < <(recopilacion "$DIRECTORIO" 4 "$PATRON")
	proceso files

fi

echo "auditoria_unificada_pro concluida con exito. Ver reporte en $REPORTE"
exec 3>&-
