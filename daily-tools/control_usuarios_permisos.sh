#!/bin/bash
# control_usuarios_permisos.sh
# Script de control de usuarios con shell bash y permisos en carpeta compartida

# Listamos todos los usuarios del sistema cuyo shell sea /bin/bash
# Introducimos un parámetro: directorio compartido

SALIDA="usuarios_bash.txt"
FECHA=$(date +'%Y/%m/%d %H:%M:%S')
SALIDA2="archivos_no_lectura.txt"

if [ -f "$SALIDA" ]; then
	cat < /dev/null > "$SALIDA"
fi

if [ -f "$SALIDA2" ]; then
	cat < /dev/null > "$SALIDA2"
fi

while IFS=" " read usuario bash; do
	if [[ "$bash" == "/bin/bash" ]]; then
		echo "$usuario" >> "$SALIDA"
	fi
done < <(gawk 'BEGIN{FS=":"} {print $1,$7}' /etc/passwd)

echo "Usuarios cuyo shell es /bin/bash"
cat "$SALIDA"

DIRECTORIO="$1"

if [ -d "$DIRECTORIO" ]; then
	find "$DIRECTORIO" -type f -not -perm -g=r | tee "$SALIDA2"
else
	echo "Ese directorio no existe"
fi

echo -e "===== $FECHA ========\n"
echo -e "Total de usuarios bash: $(wc -l $SALIDA)\n"
echo -e "Total de archivos no legibles por el grupo: $(wc -l $SALIDA2)\n"
