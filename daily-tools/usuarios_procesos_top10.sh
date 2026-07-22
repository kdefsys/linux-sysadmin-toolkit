#!/bin/bash
##Nombre: usuarios_procesos_top10.sh
##Autor: kdefsys
##Descripción: Este script analiza el sistema para identificar los usuarios que tienen la mayor cantidad de procesos activos en este momento.
##El script debe generar un reporte con el top 10 de usuarios y guardar el resultado en un archivo de texto.
##Uso: ./usuarios_procesos_top10.sh

mapfile -t uids < <(cat "/etc/passwd" | gawk -F : '{print $3}')

for uid in "${uids[@]}"; do
	cantidad=$(ps -U "$uid" --no-headers 2>/dev/null | wc -l)
	echo "$uid:$cantidad"
done | sort -t ':' -k 2nr,2nr | head -n 10 | tee top10_usuarios_procesos.txt
