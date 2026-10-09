#!/bin/bash
### Nombre: project_jailor.sh
### Autor: kdefsys
### Descripcion: En la empresa CloudOps Solutions, se gestionan múltiples proyectos simultáneos donde colaboran desarrolladores y auditores. Han notado que cuando los desarrolladores
### crean archivos manualmente en carpetas compartidas, a menudo olvidan restringir los permisos predeterminados (umask), dejando archivos legibles o escribibles por cualquier otro
### usuario del sistema. Además, algunos usuarios eliminan por accidente archivos de configuración o logs históricos que deberían ser de solo lectura e inmodificables.
### Para resolver esto, el equipo de Ciberseguridad necesita una herramienta automatizada llamada project_jailor.sh que gestione el ciclo de vida de los proyectos seguros, aplique
### políticas de creación con atributos especiales y configure entornos compartidos aislados.
### Uso: sudo ./project_jailor.sh [-p <alpha>] [-g devops] [-i file.json] [-u file.json] [-a <directorio>] [-h]

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe de ejecutarse con permisos sudo" >&2
	exit 1
fi

function help {
	echo "El script se debe de ejecutar asi: sudo ./project_jailor.sh [-p <alpha>] [-g devops] [-i file.json] [-u file.json] [-a <directorio>] [-h]"
	echo "======================================== MODO CREACION DE PROYECTO ========================================================="
	echo "   -p : nombre del proyecto"
	echo "   -g : grupo indicado"
	echo "======================================== MODO PROTECCION CONTRA BORRADO/MODIFICACION ======================================="
	echo "   -i : ruta del archivo"
	echo "======================================== MODO DE DESCONGELAMIENTO / LIBERACION ============================================="
	echo "   -u : ruta del archivo"
	echo "======================================== MODO DE AUDITORIA DE ATRIBUTOS E INMUTABILIDAD ===================================="
	echo "   -a : directorio_proyecto"
	echo "============================================================================================================================"
	echo "   -h : Imprime esta guia"
}

MODO_CREACION=0
MODO_PROTECCION=0
MODO_DESCONGELAMIENTO=0
MODO_AUDITORIA=0

while getopts :p:g:i:u:a:h opt; do
	case "$opt" in
		p)
		  NAME_PROYECTO_CREACION="$OPTARG"
		  (( MODO_CREACION++ ))
		  ;;
		g)
		  GRUPO="$OPTARG"
		  if ! getent group "$GRUPO" &>/dev/null; then
			echo "El grupo especificado no existe. Saliendo del script" >&2
			exit 1
		  fi
		  (( MODO_CREACION++ ))
		  ;;
		i)
		  ARCHIVO_PROTECCION="$OPTARG"
		  if [[ ! -f "$ARCHIVO_PROTECCION" ]]; then
			echo "El archivo ingresado no existe. Saliendo del script" >&2
			exit 1
		  fi
		  MODO_PROTECCION=1
		  ;;
		u)
		  ARCHIVO_DESCONGELAMIENTO="$OPTARG"
		  if [[ ! -f "$ARCHIVO_DESCONGELAMIENTO" ]]; then
			echo "El archivo ingresado no existe. Saliendo del script." >&2
			exit 1
		  fi
		  MODO_DESCONGELAMIENTO=1
		 ;;
		a)
		  DIRECTORIO="$OPTARG"
		  if [[ ! -d "$DIRECTORIO" ]]; then
			echo "El directorio ingresado para la auditoria no existe. Saliendo del script" >&2
			exit 1
		  fi
		  MODO_AUDITORIA=1
		  ;;
		h)
		  help
		  exit 0
		  ;;
		*)
		  echo "Opcion ingresada no valida"
		  help
		  exit 1
		  ;;
	esac
done

if (( MODO_CREACION == 2 )); then
	echo "Se ingresaron los flags necesarios para activar el Modo Creacion de Proyecto"
	DIRECTORIO_BASE="/srv/projects/"
	DIRECTORIO_TOTAL="/srv/projects/${NAME_PROYECTO_CREACION}"
	if [[ ! -d "${DIRECTORIO_TOTAL}" ]]; then
		if mkdir -p "${DIRECTORIO_TOTAL}" 2>/dev/null; then
			echo "El directorio ${DIRECTORIO_TOTAL} se creo correctamente"
		else
			echo "El directorio ${DIRECTORIO_TOTAL} no se pudo crear correctamente" >&2
			exit 1
		fi
	fi
	if chown root:"$GRUPO" "$DIRECTORIO_TOTAL" 2>/dev/null; then
		echo "Se cambio los propietarios de $DIRECTORIO_TOTAL a: root:$GRUPO"
		if chmod 770 "$DIRECTORIO_TOTAL" 2>/dev/null; then
			echo "Se cambiaron los permisos, para que solo el usuario dueño y el grupo tengan acceso total y los otros 0"
			if chmod +t "$DIRECTORIO_TOTAL" 2>/dev/null; then
				echo "Ahora los miembros del grupo puden crear y editar sus archivos dentro de la carpeta, pero solo los suyos"
			else
				echo "No se pudo añadir el bit especial" >&2
			fi
		else
			echo "No se pudieron cambiar los permisos" >&2
		fi
	else
		echo "No se pudo cambiar los propietarios" >&2
	fi
elif (( MODO_CREACION > 0 )); then
	echo "No se ingresaron las flags necesarias. No se pudo activar el Modo creacion del Proyecto." >&2
fi

if (( MODO_PROTECCION == 1 )); then
	echo "Se activo el Modo de Proteccion contra Borrado/Modificacion"
	if chattr +i "$ARCHIVO_PROTECCION" 2>/dev/null; then
		echo "Ahora el archivo esta congelado completamente, frente a modificaciones, renombrados o eliminaciones"
	else
		echo "No se pudo aplicar el atributo inmutable"
	fi
fi

if (( MODO_DESCONGELAMIENTO == 1 )); then
	echo "Se activo el Modo de Descongelamiento / Liberacion"
	if chattr -i "$ARCHIVO_DESCONGELAMIENTO" 2>/dev/null; then
		echo "Ahora el archivo esta libre completamente, permite nuevamente su edicion o eliminacion por parte de usuarios autorizados"
	else
		echo "No se pudo liberar al archivo"
	fi
fi

if (( MODO_AUDITORIA == 1 )); then
	echo "Se activo el Modo de Auditoria para el proyecto"
	mapfile -t files_inmutables < <(find "$DIRECTORIO" -type f -exec lsattr {} + 2>/dev/null | gawk '$1 ~ /i/{print $2}')
	mapfile -t files_otros < <(find "$DIRECTORIO" -type f \( -perm -o=r -o -perm -o=w \))
	CANTIDAD_INMUTABLES="${#files_inmutables[@]}"
	CANTIDAD_OTROS="${#files_otros[@]}"
	echo "======================================= AUDITORIA DE ATRIBUTOS ==================================="
	echo "DIRECTORIO PROYECTO: $DIRECTORIO"
	echo "FECHA: $(date '+%Y-%m-%d %H-%M-%S')"
	echo "SCRIPT: project_jailor.sh"
	echo "HOSTNAME: $HOSTNAME"
	if [[ "$CANTIDAD_INMUTABLES" -eq 0 && -z "${files_inmutables[@]}" ]]; then
		echo "No se encontraron archivos con el bit inmutable"
	else
		echo "Archivos con el atributo inmutable: "
		printf "%s\n" "${files_inmutables[@]}"
	fi
	if [[ "$CANTIDAD_OTROS" -eq 0 && -z "${files_otros[@]}" ]]; then
		echo "No se encontraron archivos con permisos world-readable o world-writable"
	else
		echo "Archivos con permisos en otros: "
		printf "%s\n" "${files_otros[@]}"
	fi
	if [[ -k "$DIRECTORIO" ]]; then
		echo "El directorio tiene el sticky bit activado"
	else
		echo "El directorio no tiene el sticky bit activado"
	fi
fi

echo "project_jailor.sh terminado correctamente"
