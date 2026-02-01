#!/bin/bash
# blkid_inventory.sh
## Inventariar sistemas de archivos persistentes, identificando de forma única
## y confiable cada partición mediante: UUID, TYPE, LABEL

## Verificamos si el comando existe

command -v blkid > /dev/null || {
	echo "blkid no está disponible"
	exit 1
}

## El script debe ejecutarse con permiso de superusuario

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con privilegio de superusuario"
	echo "Saliendo del script"
	exit 1
fi

## El script si o si debe de tener un parámetro de entrada que es el directorio
## a donde va el archivo de inventoría .log

if [[ "$#" -ne 1 ]]; then
	echo "El script no tiene un solo parámetro de entrada"
	echo "Saliendo del script"
	exit 1
fi

## Recolentando los parámetros de entrada y declarando variables

DIR="$1"
FECHA=$(date +'%Y%m%d_%H%M')

if [[ ! -d "$DIR" ]]; then
	echo "El directorio no existe"
	echo "Desea crearlo? (Y|N):"
	read -n1 op

	case "$op" in
		Y|y)
		    mkdir "$DIR"
		    echo "Directorio creado con éxito"
		    ;;
		N|n)
		    echo "Entonces procedemos a salir del script"
		    exit 1 ;;
	esac
fi

SALIDA="${DIR}/blkid_inventory_${FECHA}.log"

DISPOSITIVOS=$(blkid -o export | gawk '
  BEGIN{FS="="  ; RS=""}
  {
	label="-"
	uuid="-"
	type="-"
	devname="-"
	for (i=1 ; i<=NF; ++i) {
		switch ($i) {
			case "DEVNAME":
				devname=$(++i)
				break
			case "UUID":
				uuid=$(++i)
				break
			case "TYPE":
				type=$(++i)
				break
			case "LABEL":
				label=$(++i)
				break
			default:
				++i
				break
		}
	}
	printf "%-12s %-38s %-8s %-10s\n", devname, uuid, type, label
  }')

CANTIDAD=$(echo "$DISPOSITIVOS" | wc -l)

exec 1>& "$SALIDA"

echo "========INVENTARIO DE SISTEMAS DE ARCHIVOS========"
echo "FECHA: $FECHA"
echo "HOST: $(hostname)"
echo "Usuario: $USER"

echo "Total de Dispositivos $CANTIDAD"
echo ; echo
printf "%-12s %-38s %-8s %-10s\n" "DevName" "UUID" "TYPE" "LABEL"
echo "$DISPOSITIVOS"
echo ; echo
echo "==================================================="

