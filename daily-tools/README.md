# Daily Tools - Scripts de Uso Diario

Este directorio contiene scripts de Bash diseñados para tareas comunes que un
administrador de sistemas realiza en su dia a dia.
El objetivo de los scripts es **automatizar tareas repetitivas**, facilitar el
manejo de usuarios, archivos y sistemas, y servir como referencia para buenas
prácticas de scripting.

# Contenido

- [registro_diario.sh](#registro_diariosh)
- [usuarios_procesos.sh](#usuarios_procesossh)
- [limpieza_enlaces.sh](#limpieza_enlacessh)
- [limpieza_contenido_logs.sh](#limpieza_contenido_logssh)
- [control_usuarios_permisos.sh](#control_usuarios_permisossh)
- [mensajeria.sh](#mensajeriash)

_____________________________________________________________________________

## Estructura del directorio

## **registro_diario.sh**
   Nivel Básico **Tema:** fecha, redirección, archivos

  Descripción técnica:
  - Registra automáticamente la fecha y hora junto con un mensaje de actividad
  en un archivo de log ('actividad_diaria.log').
  - Utiliza 'date' para obtener timestamp y la redirección '>>' para añadir
  información al log sin sobreescribirlo.
  - Cada ejecución agrega una línea nueva, permitiendo mantener un historial
  completo de tareas realizadas.

  Uso típico en empresas:
  - Llevar un **registro rápid de acciones realziadas en servidores** o tareas
  de mantenimiento.
  - Puede ser usado en **scripting de cron** para automatizar el logging de
  tareas periódicas.

  Curiosidad Técnica:
  - El archivo de log se genera en el mismo directorio que el script, pero puede
  modificarse para rutas absolutas o directorios centralizados de logs.
 
_____________________________________________________________________________

## **usuarios_procesos.sh**
   Nivel Intermedio **Tema:** ps, gawk, sort, uniq,
   head, tuberias, arreglos asociativos

   Descripción Técninca:
   - Muestra los **10 usuarios con más procesos activos** en el sistema.
   - Genera un txt ('proc_user.txt') que registra el numero de procesos por 
   usuario
   - Utiliza tuberías para **procesar la salida de ps aux**, extraer el usuario
   ('gawk 'BF{FS=":"} {print $1}''), contar procesos con ('uniq -c'), y
   ordenarlos en forma descendente con ('sort -k 2nr').

   Uso Típico en empresas:
   - Monitorizar la carga de usuarios en servidores compartidos
   - Detectar posibles **sobreutilizaciones o procesos problemáticos** que
   afecten el rendimiento.
   - Sirve como base para alertas automatizadas en scripts de administración.

   Curiosidad Técnica:
   - La combinacion sort | uniq es un patrón muy común en Bash para contar y
   ordenar ocurrencias de cualquier dato en logs, txt o listas.
   - Usamos el comando mapfile para asi poder generar un arreglo inteligente que entienda
   que una linea representa un elemento del array, asi nos eviatmos el problema
   si un usuario tiene espacios en su nombre, el mapfile lo guarda como un unico
   elemento, asi en el for solo tendriamos que usar "${LIST_USER[@]}".

_____________________________________________________________________________

## **limpieza_enlaces.sh**
   Nivel Avanzado **Temas:** enlaces simbólicos, find,
   rm, tee, xargs, redirecciones

   Descripción Técnica:
   - Busca **enlaces simbólicos rotos** dentro de un directorio crítico
   - Los elimina automáticamente y genera un log ('enñaces_rotos.log') con los
   detalles de los archivos eliminados.
   - Combinación de comandos:
    - 'fin -type l ! -exec test -e {} \; -print' -> identifica enlaces rotos
    - 'tee -a "$LOG_FILE"' -> imprime en pantalla y regresa al log simultáneamente
    - 'xargs -r rm -v >> "$LOG_FILE" 2>&1' -> elimina los enlaces y agrega la
   salida detallada al log, incluyendo errores.

   Uso Típico en empresas:
   - Mantener **directorios compartidos o servidores limpios**, evitando
   errores por enlaces rotos en aplicaciones que dependen de ellos.
   - Automatizable con cron para mantenimiento periódico de servidores

   Curiosidad Técnica:
   - El uso de ! es equivalente a -not y en este caso junto con test -e, permite
   filtrar enlaces rotos de forma eficiente.
   - 'xargs -r' asegura que 'rm' solo se ejecute si 'find' realmente encuentra
   enlaces rotos, evitando errores innecesarios.

_____________________________________________________________________________

## **limpieza_contenido_logs.sh**
   Nivel Intermedio-Avanzado **Temas:** 
   Bash Scripting, manejo de archivos, logs, sort, uniqe, pipelines

   Descripción Técnica
   - Este srcipt se encarga de procesar archivos de log en un directorio
   especificado por el usuario.
   - Realiza una limpieza eliminando entradas duplicadas de cada archivo '.log',
   consolida los datos en un único archivo temporal y genera un resumen con las
   10 entradas más frecuentes
   - Utiliza herramientas estándar de Linux como 'find' para localizar los
   archivos, 'sort' y 'uniq' para eliminar duplicados y contar ocurrencias, y
   'head' para mostrar un resumen final.

   Uso Tipico en Empresas:
   - Análisis de logs de aplicaciones o servidores, identificando rápidamente
   patrones de errores o accesos frecuentes.
   - Auditorías de actividad en sistemas multiusuario.
   - Automatización de tareas de limpieza de logs para ahorrar espacio y mejorar
   la legibilidad de la información
   - Se utiliza típicamente en entornos donde los logs crecen continuamente y
   es necesario extraer información relevante sin duplicados.

   Curiosidad Técninca:
   - El script combina varias técnicas de Bash para trabajar con múltiples
   archivos de manera eficinete.
   - 'find' para localizar todos los .log en el directorio dado.
   - 'sort | uniq' para eliminar entradas duplicadas dentro de cada log.
   - 'sort -nr | head -n 10' para generar un top 10 entradas más frecuentes.

_____________________________________________________________________________

## **control_usuarios_permisos.sh**
   Nivel Avanzado **Temas:** Bash Scripting,
   usuarios del sistema, permisos, auditoría, find, gawk

   Descripción Técnica:
   - Este script realiza un control integral sobre usuarios y permisos en un
   sistema Linux.
   - Primero, identifica todos los usuarios cuyo shell sea '\bin\bash' leyendo
   '/etc/passwd' con 'gawk' y almancenando los resultados en un archivo temporal
   - Luego, analiza un directorio compartido ('ingresado como parámetro') para 
   detectar archivos que **no sean legibles por el grupo**, utilizando 'find' 
   con '-not -perm -g=r' y generando un registro temporal.
   - Al final, el script imprime en patanlla los resultados resumidos: usuarios
   bash, total de archivos no legibles y la fecha/hora de ejecución.

   Uso Típico en empresas:
   - Auditorías de seguridad en servidores multiusuario, verificando qué
   usuarios pueden iniciar sesión vía Bash.
   - Control de acceso en carpetas compartidas, detectando rápidamente archivos
   con permisos inadecuados.
   - Automatización de tareas de reporte y limpieza, ahorrando tiempo en la
   revision manual de permisos y usuarios.
   - Útil para administradores de sistemas que necesitan información inmediata
   y accesos en entornos colaborativas.

   Curiosidad Técnica
   - Combina lectura de archivos del sistema (/etc/passd) con gawk para separar
   campos de manera precisa, evitando errores con nombres de usuarios o shells
   - Maneja archivos temporales para consolidar información y luego los elimina,
   evitando saturar el sistema con logs innecesarios
   - Usa find -not -perm -g=s para identificar archivos que no cumplen con
   permisos de grupo, una técnica profesional común en auditorías de seguridad
   - La combinación de while IFS=" " read y arrays permite procesar datos de
   manera segura, incluso si los nombres de usuario o rutas contienen espacios.

_____________________________________________________________________________

## **mensajeria.sh**
   Nivel Intermedio **Temas:** Administración de Usuarios, Automatización Bash, I/O
   Redirection, Procesamiento de Texto con gawk.

   Descripción Técnica:
   Este script automatiza el proceso de comunicación interna entre administradores
   y usuarios en un entorno Linux multiusuario. Su objetivo principal es localizar
   de forma dinámica la terminal activa de un usuario específico y enviarle un mensaje
   directo. El script incluye una capa de seguridad que valida la existencia del usuario
   en la base de datos /etc/passwd mediante getent antes de intentar cualquier comunicación,
   evitando errores de ejecución y procesos huérfanos.

   Uso Típico en las empresas:
   - Mantenimiento Programado: Un administrador de sistemas necesita notificar a un usuario
   especifico que su sesión será cerrad para realizar actualizaciones de software sin afectar
   a todos los demás conectados
   - Seguridad: Alertar a un usuario que está ejecutando un proceso que consume demasiados
   recursos (CPU/RAM) antes de finalizar su tarea de forma forzada (kill) 
   - Resolución de Problemas: Permite al equipo de soporte técnico enviar instrucciones
   directas a la pantalla de un empleado mientras este realiza una tarea en la terminal,
   facilitando la asistencia remota en servidores locales.

   Ejemplo de Ejecución:
   1. Asegúrate de tener permisos de ejecución: chmod u+x mensajería.sh
   2. Ejecuta el script ./mensajeria.sh
   3. Ingresa el nombre del usuario y el mensaje cuando el script lo solicite

   Curiosidad Técnica:
   - getent passwd: A diferencia de leer el archivo /etc/passwd directamente, este comando
   es más robusto ya que puede consultar usuarios en base de datos externas como LDAP o AD si
   el servidor está integrado en una red empresarial.
   - grep -i -m 1 "^$nameUser ": El uso del ancla ^ y el espacio final garantiza que si buscas
   al usuario "Ana", no coincida por error con "Anabel" o "Anastasia".
   - gawk '{print $2}': Se utiliza para extraer específicamente la columna de la terminal
   (tty o pts) de la salida del comando who, permitiendo que el mensaje llegue al dispositivo
   correcto

____________________________________________________________________________________________
