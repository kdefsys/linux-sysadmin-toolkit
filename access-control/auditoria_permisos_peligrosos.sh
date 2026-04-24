#!/bin/bash
### Nombre: Auditoria_permisos_peligrosos.sh
### Autor: kdefsys
### En sistemas UNIX/Linux, los archivos con los bits SETUID(4000) o SETGID(2000) permiten que un usuario
### ejecute un archivo con los privilegios del propietario o del grupo del archivo respectivamente
### Si un atacante deja un binario malicioso con estos bits en una carpeta inusual (como /tmp o /home)
### podria escalar privilegios facilmente
### Uso: ./auditoria_permisos_privilegios <directorio>

if [[ "$EUID" -ne 0 ]]; then
	echo -e "Este script debe ejecutarse como root\nSaliendo del script..."
	exit 1
fi

if [[ "$#" -ne 1 ]]; then
	echo -e "El script no tiene el argumento\nSaliendo del script..."
	exit 1
fi

DIRECTORIO="$1"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
SALIDA="auditoria_setuid_setgid_${FECHA}.log"
RUTAS_ESTANDAR=("/bin" "/sbin" "/usr/bin" "/usr/sbin" "/lib" "/lib64" "/usr/lib" "/usr/lib64")

if [[ -d "$DIRECTORIO" ]]; then
	echo -e "==========================AUDITORIA DE SETUID Y SETGID=======================\n" > "$SALIDA"
	echo -e "FECHA: ${FECHA}" >> "$SALIDA"
	echo -e "DIRECTORIO QUE FUE EXAMINADO: ${DIRECTORIO}" >> "$SALIDA"

	mapfile -t archivos_peligrosos < <(find "$DIRECTORIO" -type f \( -perm -4000 -or -perm -2000 \) -exec stat -c "%n|%U|%G|%a" {} + 2> /dev/null)
	gawk -F "|" -v ruta="$SALIDA" -v rutas="${RUTAS_ESTANDAR[*]}" '{
		ESTADO="NOSE"
		split(rutas, array_rutas," ")
		for (indice in array_rutas){
			if($1 ~ "^" array_rutas[indice]) ESTADO="OK"
		}
		if(ESTADO == "NOSE") ESTADO="CRITICO"
		printf "RUTA: %s\tPROPIETARIO: %s\tGRUPO: %s\tPERMISOS: %s\tESTADO: %s\n\n" "$1" "$2" "$3" "$4" ESTADO >> ruta
	}' < <(printf "%s\n" "${archivos_peligrosos[@]}")

else
	echo "El directorio ingresado no existe\nSaliendo del script" >> "$SALIDA"
fi
echo -e "\nAuditoría completada con éxito."
echo -e "Se han analizado ${#archivos_peligrosos[@]} archivos sospechosos."
echo -e "El reporte detallado está en: $SALIDA"
