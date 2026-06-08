#!/bin/bash
### Autor: kdefsys
### Genera una firma o instantanea (snapshot) del estado de los archivos de un directorio
### clave (por ejemplo, /etc, /var/www o tus propios scripts de desarrollo) y, posteriormente,
### poder verificar si algun archivo ha sido modificado, creado o eliminado sin autorización
### USO: ./auditoria_integridad.sh -d <directorio> -g -v -f <archivo.db>

RUTA="/tmp"
SALIDA="${RUTA}/snapshot.db"
SALIDA2="${RUTA}/nuevo_snapshot.db"
MODIFICADOS="modificados.log"
CREADOS="creados.log"
ELIMINADOS="eliminados.log"

exec 3>>"$SALIDA"
exec 4>>"$SALIDA2"

while getopts :d:gvf:h opt; do
	case "$opt" in
		d)
		  DIRECTORIO="${OPTARG:-.}"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe"
			exit 1
		  fi
		  ;;

		g)
		  find "$DIRECTORIO" -type f -exec sha256sum {} + >&3
		  ;;

		v)
		  find "$DIRECTORIO" -type f -exec sha256sum {} + >&4
		  sort "$SALIDA" -o "$SALIDA"
		  sort "$SALIDA2" -o "$SALIDA2"
		  mapfile -t modi_o_cre < <(comm -23 "$SALIDA2" "$SALIDA" 2>/dev/null | gawk '{print $2}')
		  for files in "${modi_o_cre[@]}"; do
			cadena=$(cat "$SALIDA" | grep -i "$files")
			if [[ -n "$cadena" ]]; then
				echo "$files" >> "$MODIFICADOS"
			else
				echo "$files" >> "$CREADOS"
			fi
		  done
		  mapfile -t eliminados < <(comm -13 "$SALIDA2" "$SALIDA" 2>/dev/null | gawk '{print $2}')
		  for files in "${eliminados[@]}"; do
			cadena=$(cat "$SALIDA2" | grep -i "$files")
			if [[ -z "$cadena" ]]; then
				echo "$files" >> "$ELIMINADOS"
			fi
		  done
		  ;;

		f)
		  ruta="$OPTARG"
		  mv "$SALIDA" "$ruta"
		  SALIDA="$ruta"
		  SALIDA2="${ruta%/*}"
		  SALIDA2="$SALIDA2/nuevo_snapshot.db"
		  ;;

		default)
		  echo "Argumento no permitido"
		  exit 1 ;;
	esac
done

echo -e "=====REPORTE=====\n"
echo -e "\nArchivos Modificados\n"
[[ -f "$modificados.log" ]] && cat "modificados.log" || echo "Ninguno"
echo -e "\nArchivos Creados\n"
[[ -f "$CREADOS" ]] && cat "$CREADOS" || echo "Ninguno"
echo -e "\nArchivos Eliminados\n"
[[ -f "$ELIMINADOS" ]] && cat "$ELIMINADOS" || echo "Ninguno"
rm -f "$SALIDA2"

exec 3>&-
exec 4>&-
