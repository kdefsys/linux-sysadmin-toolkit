#!/bin/bash
# usuarios_procesos.sh
# Monitoriza los usuarios con más procesos activos (los 10 primeros)

# Primero veamos todos los usuarios que hay

LIST_USER=$(cat /etc/passwd | gawk 'BEGIN{FS=":"} {print $1}' | sort | uniq )

echo "$LIST_USER"

declare -A USUARIOS

for user in $LIST_USER; do
	CUENTA=$(ps aux | grep $user | sort -k 1,1 | uniq | wc -l)
	USUARIOS["$user"]=$CUENTA
done

for indice in "${!USUARIOS[@]}"; do
	echo "$indice%${USUARIOS[$indice]}"
done | sort -t "%" -k 2nr | head -n 10 | tee proc_user.txt > /dev/null

# Veamos ese archivo

sed -i 's/%/  /g' proc_user.txt > /dev/null

cat proc_user.txt

