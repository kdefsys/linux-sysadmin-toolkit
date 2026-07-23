#!/bin/bash
### Nombre: mensajeria.sh
### Autor: kdefsys
### Descripción: Este script permite enviar un mensaje de texto en tiempo real a otro usuario registrado en el sistema
### identificando automáticamente la terminal (TTY/PTS) en la que se encuentra conectado.
### Uso: ./mensajeria.sh <usuario>

if [[ "$#" -ne 1 ]]; then
	echo "Los argumentos no son válidos"
	echo "El script debe ser ejecutado así: $0 <usuario>"
	exit 1
fi

USUARIO="$1"

if getent passwd "$USUARIO" 2>/dev/null; then
	if ! who | grep -q "^$USUARIO " 2>/dev/null; then
		echo "El usuario no está conectado"
		echo "Finalizamos el proceso"
		exit 1
	else
		echo "El usuario si está conectado"
		read -p "Ingrese el mensaje que le quiere enviar: " mensaje
		TERMINAL=$(who | grep -i -m1 "^$USUARIO" | gawk '{print $2}')
		if echo "$mensaje" | write "$USUARIO" "$TERMINAL"; then
			echo "El mensaje fue enviado con éxito"
		else
			echo "El mensaje no se pudo enviar con éxito"
		fi
	fi

else
	echo "El usuario no existe en la base de datos del sistema"
	echo "Saliendo del script..."
	exit 1
fi

