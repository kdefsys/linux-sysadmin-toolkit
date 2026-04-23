#!/bin/bash
### Nombre: mensajeria.sh
### Autor: kdefsys
###Script que manda una mensajeria a otro usuario con su respectivo terminal
### Uso: ./mensajeria.sh

read -p "Introduzca el nombre del usuario a mandar la mensajeria: " nameUser

if ! getent passwd "$nameUser" > /dev/null; then
	echo "Usuario inexistente en el servidor"
	echo "Procedemos a salir del script"
	exit 1
fi

echo "Usuario encontrado con exito. Continuamos..."

## Hasta acá hemos demostrado si el usuario receptor del mensaje existe o no
## Ahora vamos a obtener su respectivo terminal

terminal=$(who | grep -i -m 1 "^$nameUser" | gawk '{print $2}')

if [[ -n "$terminal" ]]; then
	echo "Terminal encontrado ($terminal )correctamente"
	echo "Continuamos con el proceso..."
else
	echo "No se encontro terminal relacionado con el usuario"
	echo "Saliendo del script ... "
	exit 1
fi

read -p "Escribe el mensaje para $nameUser: " mensaje

echo "$mensaje" | write "$nameUser" "$terminal"

echo "Mensaje enviado correctamente"



