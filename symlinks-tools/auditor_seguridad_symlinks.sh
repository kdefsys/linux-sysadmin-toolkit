#!/bin/bash
### Nombre: auditor_seguridad_symlinks.sh
### Autor: kdefsys
### Descripcion: En entornos multiusuario o servidores expuestos, los enlaces simbólicos y duros pueden ser aprovechados por atacantes para realizar ataques de tipo Symlink Race
### Condition (Symlink Poisoning) o evasión de restricciones. Este script actúa como una herramienta de auditoría de seguridad y hardening del sistema de archivos.
### Uso: ./auditor_seguridad_symlinks.sh -d <directorio_objetivo> -r <ruta_archivo> [-q] [-h]

function help {
	echo "El script debe de ejecutarse asi: ./auditor_seguridad_symlinks.sh -d <directorio_objetivo> -r <ruta_archivo> [--quarantine] [-h]"
	echo "	 -d : Directorio objetivo a inspeccionar"
	echo "	 -r : Ruta del archivo que contiene los enlaces simbolicos"
	echo "   --quarantine : Modo estricto que elimina automaticamente symlinks de Riesgo Alto (apuntando a /etc o /root)"
	echo "	 -h : Imprime esta guia"
}

DIRECTORIO="$(pwd)"
RUTA="$(pwd)"
ESTRICTO="NO"

while getopts :d:r:qh opt; do
	case "$opt" in
		d)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado no existe. Saliendo del script..." >&2
			exit 1
		  fi
		  ;;
		r)
		  RUTA="$OPTARG"
		  if [[ ! -d "$RUTA" ]]; then
			echo "La ruta para el reporte especificada no existe. Saliendo del script..." >&2
			exit 1
		  fi
		  ;;
		q)
		  ESTRICTO="SI"
		  ;;
		h)
		  help
		  exit 0
		  ;;
		*)
		  echo "Operacion ingresada no valida"
		  help
		  exit 1
		  ;;
	esac
done

FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="${RUTA}/reporte_${FECHA}.log"
>"$REPORTE"

exec 3>>"$REPORTE"

## -------------------------------------------------------------------------------------------------------------------
##			RASTREO DE ENLACES SIMBOLICOS PELIGROSOS (Symlink Poisoning)
## -------------------------------------------------------------------------------------------------------------------

echo "=================================== RASTREO DE ENLACES SIMBOLICOS PELIGROSOS (Symlink Poisoning) ========================================" >&3
echo "Directorio: $DIRECTORIO" >&3
echo "Fecha: $FECHA" >&3

mapfile -t enlaces < <(find "$DIRECTORIO" -type l)
CANTIDAD_ENLACES="${#enlaces[@]}"
if (( CANTIDAD_ENLACES == 0 )); then
	echo "No existen enlaces symbolicos en este directorio" >&3
else
	if [[ "$ESTRICTO" == "NO ]]; then
		echo "No se activo la bandera de cuarentena, asi que solo habra un reporte" >&3
	else
		echo "Se activo la bandera de cuarentena, asi que si haremos la eliminacion" >&3
	fi
	RUTAS_SENSIBLES=("/etc/passwd" "/etc/shadow" "/etc/sudoers" "/root/.ssh" "/proc/" "/sys/")
	for enlace in "${enlaces[@]}"; do
		Ruta_objetivo="$(readlink -f "$enlace")"
		for ruta in "${RUTAS_SENSIBLES[@]}"; do
			if [[ "$Ruta_objetivo" =~ ^"$ruta" ]]; then
				echo "----------------------------------------------------------------------------------------------------" >&3
				echo "[ALERTA] Amenaza de riesgo alto" >&3
				echo "El enlace es: $enlace con usuario dueño $(stat -c '%U' "$enlace") y apunta a la ruta: $Ruta_objetivo" >&3
				if [[ "$ESTRICTO" == "SI" ]]; then
					if rm -fv "$enlace" 2>/dev/null; then
						echo "Enlace peligroso eliminado correctamente" >&3
					else
						echo "No se puedo eliminar correctamente ese enlace" >&3
					fi
					echo "----------------------------------------------------------------------------------------------------" >&3
				fi
			fi
		done
	done
fi

## --------------------------------------------------------------------------------------------------------------------
##		Auditoria de Hard Links Sospechosos en Binarios/Archivos SUID
## --------------------------------------------------------------------------------------------------------------------

ARCHIVOS_CRITICOS=("/bin" "/usr/bin" "/sbin")
mapfile -t files_peligrosos < <(find "$DIRECTORIO" -type f \( -perm -4000 -o -perm -2000 \) -exec test -x {} \; -print)
CANTIDAD="${#files_peligrosos[@]}"

if (( CANTIDAD == 0 )); then
	echo "No existen archivos ejecutables con permisos SUID o SGID" >&3
else
	echo "Se encontraron $CANTIDAD archivos con permisos SUID/SGID. Analizando enlaces duros..." >&3
	# Arreglo asociativo para recordar inodos procesados y evitar reportes duplicados
	declare -A inodos_procesados
	for archivo in "${files_peligrosos[@]}"; do
		read -r num_enlaces inodo < <(stat -c '%h %i' "$archivo" 2>/dev/null)
		# Si ya auditamos este inodo en un archivo anterior, lo omitimos
		if [[ -n "${inodos_procesados[$inodo]}" ]]; then
			continue
		fi
		if (( num_enlaces > 1 )); then
			inodos_procesados["$inodo"]=1
			echo "[ALERTA] El ejecutable sensible $archivo tiene $num_enlaces enlaces duros (Inodo: $inodo)" >&3
			mapfile -t referencias_duplicadas < <(find "$DIRECTORIO" -samefile "$archivo" 2>/dev/null)
			for ref in "${referencias_duplicadas[@]}"; do
				if [[ "$ref" != "$archivo" ]]; then
					echo "  --> Enlace duro detectado en: $ref" >&3
					if [[ "$ref" =~ ^(/tmp/|/var/tmp/|/home/|tmp/|var/tmp/|home/) ]]; then
						echo "  [AMENAZA DE RIESGO ALTO] ¡Se encontró un Hard Link a un binario SUID en una ruta no autorizada!: $ref" >&3
					fi
				fi
			done
		fi
	done
fi

## ---------------------------------------------------------------------------------------------------------------------------
## 		Identificacion de Symlinks Cruzados entre Puntos de Montaje (Cross-Device Symlinks)
## ---------------------------------------------------------------------------------------------------------------------------

mapfile -t enlaces_simbolicos < <(find "$DIRECTORIO" -type l 2>/dev/null)
CANTIDAD_ENLACES="${#enlaces_simbolicos[@]}"

if (( CANTIDAD_ENLACES == 0 )); then
	echo "No hay enlaces simbolicos en ese directorio" >&3
else
	echo "Analizando $CANTIDAD_ENLACES enlaces simbolicos en busca de saltos entre particiones..." >&3
	for enlace in "${enlaces_simbolicos[@]}"; do
		dev_enlace=$(stat -c '%d' "$enlace")
		ruta="$(readlink -f "$enlace")"
		if [[ -z "$ruta" || ! -e "$ruta" ]]; then
			echo "La ruta del enlace $enlace ya no existe, entonces es un enlace roto, lo ignoramos" >&3
		else
			dev_destino=$(stat -c '%d' "$ruta")
			if [[ -n "$dev_enlace" && -n "$dev_destino" && "$dev_enlace" != "$dev_destino" ]]; then
				echo "[ALERTA - RIESGO MEDIO] Symlink Cruzado (Cross-Device) detectado:" >&3
				echo "  --> Enlace:  $enlace (Dispositivo ID: $dev_enlace)" >&3
				echo "  --> Destino: $destino_real (Dispositivo ID: $dev_destino)" >&3
			fi
		fi
	done
fi

exec 3>&-
echo "auditor_seguridad_symlinks.sh terminada con exito. Puede ver el reporte en $REPORTE"
