#!/bin/bash
### Nombre: auditor_de_integridad.sh
### Autor: kdefsys
### Descripcion: En la seguridad de sistemas Linux, los archivos que poseen permisos especiales (como SUID, SGID o el Sticky Bit) representan un vector de
### riesgo muy elevado. Si un atacante o un usuario malintencionado logra comprometer el sistema, una de las técnicas más comunes de persistencia o escalada de
### privilegios consiste en:
### 1. Otorgar permisos SUID/SGID a un binario o script ordinario para ejecutar órdenes como root.
### 2. Modificar los permisos de un archivo ejecutable existente que ya poseía permisos especiales.
### Para prevenir y detectar estas intrusiones, los administradores de sistemas suelen generar líneas base (baselines) de archivos confiables.
### Al comparar el estado actual del sistema de archivos contra esta base de datos preexistente, es posible identificar inmediatamente cualquier anomalía, alteración o
### aparición de binarios sospechosos.
### Uso: sudo ./auditor_de_integridad.sh -g -d <directorio_examinar> [-h]

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con privilegios sudo" >&2
	exit 1
fi

function help {
	echo "El script debe de ejectuarse de esta forma: sudo ./auditor_de_integridad.sh -g -d <directorio_examinar> [-h]"
	echo "   -d : Directorio a eximnar."
	echo "   -g : Bandera que hace el escaneo y genera una base de datos en permitidos.db"
	echo "   -h : Imprime esta guia"
}
DIRECTORIO=""
ESCANEO=0
BASE_DATOS="permitidos.db"

while getopts :d:gh opt; do
	case "$opt" in
		d)
		 DIRECTORIO="$OPTARG"
		 if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script" >&2
			exit 1
		 fi
		 ;;
		g)
		 ESCANEO=1
		 ;;
		h)
		 help
		 exit 0
		 ;;
		*)
		 echo "Opcion ingresada invalida"
		 help
		 exit 1
		 ;;
	esac
done

function escaneo {
	local directorio="$1"
	find "$directorio" -type f -perm /7000 -exec stat -c "%n|%a" {} + 2>/dev/null
}

if (( ESCANEO == 1 )); then
	echo "Se activo la opcion de generacion/actualizacion de la base de datos"
	if [[ -f "${BASE_DATOS}" ]]; then
		echo "El archivo permitidos.db existe"
		read -n1 -p "Desea Reemplazarlo? (s|n): " op
		echo ""
		case "$op" in
			s|S)
				echo "Procedemos a reemplazar el contenido"
				if escaneo "/" > "$BASE_DATOS"; then
					echo "[OK] El archivo permitidos.db fue reemplazado correctamente"
				else
					echo "[ERROR] El archivo permitidos.db no pudo ser reemplazado correctamente" >&2
				fi
				;;
			*)
				;;
		esac
	else
		echo "El archivo permitidos.db no existe. Procedemos a crearlo"
		if escaneo "/" > "$BASE_DATOS"; then
			echo "[OK] El archivo permitidos.db fue creado exitosamente"
		else
			echo "[ERROR] El archivo permitidos.db no fue creado exitosamente" >&2
		fi
	fi
	echo "Termino la opcion de generacion/actualizacion correctamente"
fi

if [[ -n "$DIRECTORIO" ]]; then
	if [[ ! -f "$BASE_DATOS" ]]; then
		echo "[ERROR] La base de datos $BASE_DATOS no existe. Ejecuta primero la opcion -g." >&2
		exit 1
	fi
	FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
	REPORTE="integridad_permisos_${FECHA}.log"
	exec 3>>"$REPORTE"

	echo "Examinando el directorio $DIRECTORIO..."
	echo "=====================================================================================" >&3
	echo "Vamos a examinar todos los archivos con permisos especiales del directorio $DIRECTORIO" >&3
	echo "=====================================================================================" >&3

	mapfile -t files < <(escaneo "$DIRECTORIO")
	for linea in "${files[@]}"; do
		archivo_directorio="${linea%|*}"
		permisos_directorio="${linea##*|}"
		echo "Vamos a examinar el archivo $archivo_directorio" >&3
		registro_base=$(grep -F "${archivo_directorio}|" "${BASE_DATOS}" 2>/dev/null)

		if [[ -n "$registro_base" ]]; then
			permisos_base="${registro_base##*|}"
			if [[ "$permisos_directorio" == "$permisos_base" ]]; then
                		echo "[INTEGRO] LA RUTA EXISTE Y SUS PERMISOS OCTALES NO HAN CAMBIADO" >&3
            		else
                		echo "[PELIGRO-PERMISOS MODIFICADOS] LA RUTA EXISTE PERO SUS PERMISOS OCTALES HAN CAMBIADO" >&3
            		fi
		else
			echo "[ALERTA - BINARIO NUEVO O DESCONOCIDO] EL ARCHIVO NO FIGURA EN LA BASE DE DATOS" >&3
		fi
	done

	exec 3>&-
	echo "Escaneo del directorio $DIRECTORIO terminado. Ver el reporte en $REPORTE"
fi
