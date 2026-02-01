#!/bin/bash
# auditoria_disk_partitions.sh
### Audita los discos del sistema y genera un reporte claro de:
### Que discos existen, que tipo de tabla de particiones usan (MBR o GPT)
### Que particiones tiene cada disco y detectar discos sin particionar

### El script debe de ejecutarse con privilegios de superusuario

if [[ "$EUID" -ne 0 ]]; then
	echo "El script debe ejecutarse con privilegios de superusuario"
	echo "Saliendo del script"
	exit 1
fi

### El script debe tener si o si un parámetro de entrada

if [[ "$#" -ne 1 ]]; then
	echo "El script no posee un parámetro de entrada"
	echo "Saliendo del script"
	exit 1
fi

### Recogiendo parámetros de entrada y declarando variables

DIR="$1"
FECHA=$(date +'%Y%m%d_%H%M')

if [[ ! -d "$DIR" ]]; then
	echo "El directorio ingresado no existe"
	echo "Desea crearlo? (Y/N)"
	read -n1 op
	case "$op" in
		Y|y)
		   mkdir "$DIR"
		   echo "Directorio creado con éxito" ;;
		N|n)
		   echo "Entonces salimos del script"
		   exit 1 ;;
		*)
		   echo "Opcion incorrecta"
		   exit 1 ;;
	esac
fi

SALIDA="${DIR}/partition-audit-${FECHA}.log"

## Redirigimos la salida STDOUT a nuestro archiv de salida"

exec 1>& "$SALIDA"

echo -e "\n\n======================================"
echo "Disk Partition Audit Report"
echo "Hostname: $(hostname)"
echo "Date: $FECHA"
echo "======================================"

declare -A discos

### Contamos cuantas particiones hay por discos

while read nombre tipo padre ;do
	if [[ "$tipo" == "part" ]]; then
		((++discos["$padre"]))
	fi
done < <(lsblk -nro name,type,pkname)

cuenta=0
errores=0
total_discos=0
discos_part=0
discos_no_part=0

while read nombre tipo tama tabla padre tipopart montado; do
	if [[ "$tipo" == "disk" ]]; then
		echo -e "\n-----------------------------------------------------------------------------------\n\n"
		echo -e "[DISK] $nombre"
		echo -e "\tSize\t\t:${tama}"
		echo -e "\tTipo de Tabla\t:${tabla}"
		((++total_discos))
		if [[ -n "${discos[$nombre]}" ]]; then
			((cuenta=0))
			((++discos_part))
		else
			echo -e "\n\tWARNING:\n\tEl disco no tiene particiones"
			echo -e "\n\tposible disco nuevo"
			((++errores))
			((cuenta=1))
			((++discos_no_part))
		fi
		if [[ -z "$montado" ]]; then
			echo -e "\n\tWARNING:\n\tEl disco no esta montado\n"
			((++errores))
		fi
	elif [[ "$tipo" == "part" ]]; then
		if [[ "$cuenta" -eq 0 ]]; then
			echo -e "\tPartitions:\n"
			((cuenta=1))
		fi
		echo -e "\t- ${nombre}\n\t\t   size\t  :${tama}\n\t\t   type\t  :${tipopart}"
		if [[ -z "$montado" ]]; then
			echo -e "\t\tWARNING: La particion no esta montada CUIDADO\n\n"
			((++errores))
		fi
	fi
done < <(lsblk -nro name,type,size,pttype,pkname,parttypename,mountpoint)

echo -e "\n--------------------------------------------------------------------------------------------------------\n\n"

echo "[SUMARY]"
echo "  Total de discos detectados: $total_discos"
echo "  Total de discos particionados: $discos_part"
echo "  Total de discos no particionados: $discos_no_part"
echo "  Cantidad de errores generados: $errores"

echo -e "\n--------------------------------------------------------------------------------------------------------\n"
echo "   END OF REPORT"
echo -e "\n--------------------------------------------------------------------------------------------------------\n"
