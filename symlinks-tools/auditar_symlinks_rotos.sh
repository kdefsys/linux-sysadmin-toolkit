#!/bin/bash
# auditar_symlinks_rotos.sh
## Para ejecutar este script debes poner un directorio como parametro
## De esta forma: ./auditar_symlinks_rotos.sh directorio

DIRECTORIO="$1"
FECHA=$(date +'%Y-%m-%d\%H:%M:%S')
SALIDA="archivo$FECHA.log"

# Verificamos si el directorio existe o no

if [ ! -d "$DIRECTORIO" ]; then
	echo "El directorio ingresado no existe"
	echo "Salimos del script"
	exit
fi

# Buscamos todos los enlaces simbólicos rotos dentro de ese directorio

enlaces_rotos=$(find "$DIRECTORIO" -type l -not -exec test -e {} \; -print)

if [ -z "$enlaces_rotos" ]; then
	echo "No existen enlaces rotos"
	echo "Salimos del script"
	exit
fi

# Mostramos en pantalla la ruta del enlace y su destino esperado

for ruta in $enlaces_rotos; do
	echo "Ruta: $ruta Destino: $(readlink $ruta)" >> "$SALIDA"
done

# Mostramos el contenido de ese archivo

cat "$SALIDA"
