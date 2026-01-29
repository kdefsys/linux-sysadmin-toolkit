#!/bin/bash
# limpieza_symlinks_huerfanos.sh
### En servidores antiguos, se acumulan enlaces simbolicos que ya no apuntan a
### nada, especialmente en carpetas de uso compartido.
### La manera de ejecutar es: ./limpieza_symlinks_huerfanos.sh directorio

# Recibimos un directorio objetivo

DIRECTORIO="$1"
SALIDA="enlaces.log"

# Detectamos enlaces simbolicos cuyo destino no exista.

enlaces_rotos=$(find "$DIRECTORIO" -type l ! -exec test -e {} \; -print)

echo "$enlaces_rotos"

# Listado previo con enlace y destino inexistente
# y preguntamos si desea eliminar o ignorar

for ruta in $enlaces_rotos; do
	echo "Ruta $ruta   Destino inexistente: $(readlink $ruta)"
	while (true); do
		echo "Desea eliminar o ignorar? (E/I): "
		read -n1 opcion
		case $opcion in
			E|e)
			  rm -v "$ruta"
			  echo "Elimino el enlace: $ruta" >> "$SALIDA"
			  break
			  ;;
			I|i)
			  echo "Ignoró el enlace: $ruta ; es decir sigue vivo" >> "$SALIDA"
			  break ;;
			*) echo "Opcion no valida " ;;
		esac
	done
done

# Notamos el contenido del archivo

cat "$SALIDA"
