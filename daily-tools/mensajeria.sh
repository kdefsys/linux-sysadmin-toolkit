#!/bin/bash
### Nombre: mensajeria.sh
### Autor: kdefsys
### Descripción: Este script permite enviar un mensaje de texto en tiempo real a otro usuario registrado en el sistema
### identificando automáticamente la terminal (TTY/PTS) en la que se encuentra conectado.
### Uso: ./mensajeria.sh -u <usuario> [-h]

## ======================================================
## 		FUNCION HELP
## ======================================================

function help {
	echo "El script se ejecuta asi: ./mensajeria.sh -u <usuario> [-h]"
	echo "Descripcion: Permite enviar un mensaje interactivo en tiempo real a una cuenta de usuario del sistema que se"
	echo "encuentra con una sesion activa, detectando automaticamente su terminal asignada y notificando el resultado del envio"
	echo "   -u <usuario> : Usuario para interactuar"
	echo "   -h : Imprime esta guia"
}

while getopts :u:h opt; do
	case "$opt" in
		u)
		  USUARIO="$OPTARG"
		  if ! getent passwd "$USUARIO" &>/dev/null; then
			echo "El usuario no existe en el sistema. Saliendo del script..." >&2
			exit 1
		  fi
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

if [[ -z "$USUARIO" ]]; then echo "No se ingreso ningun usuario"; exit 1; fi

if who | grep -q "^$USUARIO " 2>/dev/null; then
	TERMINAL="$(who | grep -i -m1 "^$USUARIO " | gawk '{print $2}')"
	if [[ -n "$TERMINAL" ]]; then
		read -p "Ingrese el mensaje a enviar: " mensaje
		if echo "$mensaje" | write "$USUARIO" "$TERMINAL" 2>/dev/null; then
			echo "Mensaje enviado con exito a $USUARIO a su terminal $TERMINAL"
		else
			echo "El mensaje no se pudo enviar a $USUARIO" >&2
		fi
	else
		echo "El usuario $USUARIO no esta conectado a ningun terminal" >&2
	fi
else
	echo "No tiene terminal asignado" >&2
fi
