#!/bin/bash
### Nombre: mapeo_jerarquico.sh
### Autor: kdefsys
### Este script agrupa los procesos por su proceso Padre (PPID), identifique servicios con "hijos excesivos"
### y detecte procesos que han quedado huerfanos o que pertenecen a usuarios inactivos

if [[ "$#" -ne 1 ]]; then
	echo -e "El script no recibio argumento\nSaliendo del script"
	sleep 2
	exit 1
fi

UMBRAL="$1"
declare -A procesos_padre
declare -A numero_hijos
declare -A estado_padre
declare -A nombres_procesos

while read -r padre hijo cmd; do
	procesos_padre["$padre"]="${hijo} ${procesos_padre[$padre]}"
	(( numero_hijos["$padre"] += 1))
	nombres_procesos["$hijo"]="$cmd"
done < <(ps -eo ppid,pid,cmd --no-headers)

for padre in "${!numero_hijos[@]}"; do
	if [[ "${numero_hijos[$padre]}" -gt "$UMBRAL" ]]; then
		estado_padre["$padre"]="POTENCIAL FUGA DE RECURSOS ALERTA EXCESO: (${numero_hijos[$padre]})"
	else
		estado_padre["$padre"]="OK"
	fi
done

function imprimir_arbol {
    local padre="$1"
    local nivel="$2"
    local prefijo=""
    local indent_hijo=""

    for (( i=0; i<nivel; ++i )); do prefijo+="    "; done
    local info_padre=""
    if [[ -n "${numero_hijos[$padre]}" ]]; then
            info_padre=" - ${estado_padre[$padre]}"
    fi
    echo -e "${prefijo}[+] PID: $padre (${nombres_procesos[$padre]})$info_padre"
    indent_hijo="${prefijo}    "

    for hijo in ${procesos_padre[$padre]}; do
        if [[ -z "${procesos_padre[$hijo]}" ]]; then
            echo -e "${indent_hijo}|-- PID: $hijo (${nombres_procesos[$hijo]})"
        else
            imprimir_arbol "$hijo" $((nivel + 1))
        fi
    done
}

echo -e "=======================================REPORTE JERARQUICO=============================="
imprimir_arbol "0" 0
