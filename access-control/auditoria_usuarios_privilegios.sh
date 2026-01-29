#!/bin/bash
# auditoria_usuarios_privilegios.sh
## Este Script audita la consistencia de usuarios y privilegios del sistema

if [[ $EUID -ne 0 ]]; then
  echo "Este script debe de ejecutarse con privlegios de superusuario"
  echo "Saliendo del script"
  exit
fi

FECHA=$(date +'%Y-%m-%d_%H-%M-%S')
SALIDA="usuarios_privilegios_$FECHA.log"

echo "===Usuarios Humanos===" > "$SALIDA"

while read usuario uid shell home; do
  contra=$(gawk -F: -v u="$usuario" '$1==u {print $2}' /etc/shadow)
  if (( uid >= 1000 && uid <= 60000 )); then
     naturaleza="HUMANA"
  else
     naturaleza="sistema"
  fi
  if [ "$uid" -eq 0 ] && [ "$usuario" !=  "root" ]; then
     estado1="CRITICO POR ESCALA DE PRIVILEGIO"
  elif [[ "$contra" == "" ]]; then
     estado1="CRITICO POR CONTRASEÑA VACIA"
  elif [[ "$contra" == "!"* || "$contra" == "*"* ]]; then
     estado1="Bloqueada"
  else
     estado1="OK"
  fi
  if [ ! -e "$shell" ]; then
	estado2="SOSPECHOSO(NO EXISTE SU SHELL)"
  elif [ ! -d "$home" ]; then
	estado2="SOSPECHOSO(NO EXISTE SU HOME)"
  else estado2="BIEN HECHO"
  fi
  echo "$usuario::$uid::$shell::$home::$naturaleza::$estado1::$estado2" >> "$SALIDA"
done < <(gawk 'BEGIN{FS=":"} {print $1, $3, $7, $6}' /etc/passwd)


