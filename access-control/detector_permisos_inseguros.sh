#!/bin/bash
# detector_permisos_inseguros
## Script que analiza un directorio dado y detecta archivos o directorios
## con permisos inseguros

FECHA=$(date +'%Y-%m-%d_%H-%M-%S')
SALIDA="detector_$FECHA.log"

ESPECIALES=("/tmp" "/var/tmp" "/shared")

while getopts :d:f:c opt; do
     case "$opt" in
	d)
	  DIR="$OPTARG"
	  if [ ! -d "$DIR" ]; then
		echo "El directorio no existe"
		echo "Saliendo del script"
		exit
	  fi
	  echo "=====Búsqueda de archivos inseguros=====" >> "$SALIDA"
	  echo "En el directorio $DIR que sean world-writable" >> "$SALIDA"
	  find "$DIR" -type f \( -perm -o=r -and -perm -o=w \) |
	     xargs stat -c "%n|%A|%U|%u|%g|%F" | tee -a "$SALIDA" &> /dev/null
	  ;;
	c)
	  echo "=====Directorios especiales CON/SIN Sticky bit=====" >>"$SALIDA"
	  for directorio in "${ESPECIALES[@]}"; do
		if [ -k "$directorio" ]; then
		  echo "[OK] $directorio tiene sticky bit" >> "$SALIDA"
		else
		  echo "[CRITICO] $directorio no tiene sticky bit" >> "$SALIDA"
		fi
	  done
	  ;;
	f)
	  DIR="$OPTARG"
	  if [ ! -d "$DIR" ]; then
		echo "El directorio no existe"
		echo "Saliendo del script"
		exit
	  fi
	  if [ -k "$DIR" ]; then
		echo "El directorio: $directorio ya tiene el sticky bit activado"
	  else
		echo "¿Aplicar sticky bit a $DIR? [y/N]"
		read -n1 opcion
		case "$opcion" in
			y|Y)
			   sudo chmod +t "$DIR"
			   echo "Aplicado con Exito"
			   ;;
			*)
			   echo "No se aplico correctamente"
			   ;;
		esac
		echo "Saliendo del script"
		exit
  	  fi
	  ;;
	*)
	  echo "Opcion incorrecta"
	  echo "Saliendo del script"
	  exit
	esac
done

cat "$SALIDA"
