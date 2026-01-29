#!/bin/bash
# verificar_y_reconstruir_symlinks.sh
### En una empresa, ciertas aplicaciones dependen de enlaces simbolicos estandar
### por ejemplo: /opt/app/current -> /opt/app/release/v3.2
### Despues de una actualización fallida, algunos enlaces simbólicos apuntan
### a versiones antiguas o inexistentes.
### En este script pasamos como parametro un archivo con el siguiente formato:
### /opt/app/current:/opt/app/release/v3.2
### /var/www/html:/srv/web/release/latest

### El primero es el enlace y el segundo es el nuevo destino al cual debe de
### apuntar
### El script se ejecuta asi: ./verificar_y_reconstruir_symlinks.sh file

# Leemos el archivo en el parametro

FILE="$1"
SALIDA="cambios_enlace.log"

if [ ! -f "$FILE" ]; then
	echo "El archivo $FILE no existe"
	echo "Procedemos a salir del script"
	sleep 2
	exit
fi

while IFS=":" read enlace nuevo_destino; do
	if [ ! -L "$enlace" ]; then
	  echo "El enlace no existe, seguimos"
	  continue;
	else
	  echo "El enlace si existe, seguimos ..."
	fi
	actual=$(readlink "$enlace")
	echo "Enlace: $enlace -> $actual"
	if [[ "$actual" != "$nuevo_destino" ]]; then
	  echo "El destino actual es diferente al destino nuevo"
	  echo "Hay que cambiar el enlace, lo eliminamos y lo volvemos a crear"
	  rm -v "$enlace"
	  ln -s "$nuevo_destino" "$enlace"
	  echo "Ahora es:"
	  echo "$enlace -> $(readlink $enlace)"
	  echo "Enlace: $enlace ; DESTINO ANTERIOR: $actual ; DESTINO NUEVO: $nuevo_destino" >> "$SALIDA"
	fi
done < <(cat "$FILE")

# Mostramos esos cambios

cat "$SALIDA"
