# Daily Tools - Scripts de Uso Diario

Este directorio contiene scripts de Bash diseñados para tareas comunes que un
administrador de sistemas realiza en su dia a dia.
El objetivo de los scripts es **automatizar tareas repetitivas**, facilitar el
manejo de usuarios, archivos y sistemas, y servir como referencia para buenas
prácticas de scripting.

# Contenido

- [registro_diario.sh](#registro_diariosh)
- [usuarios_procesos_top10.sh](#usuarios_procesos_top10sh)
- [limpieza_enlaces.sh](#limpieza_enlacessh)
- [limpieza_contenido_logs.sh](#limpieza_contenido_logssh)
- [control_usuarios_permisos.sh](#control_usuarios_permisossh)
- [mensajeria.sh](#mensajeriash)
- [monitor_recursos_umbral.sh](#monitor_recursos_umbralsh)
- [auditoria_integridad_archivos.sh](#auditoria_integridad_archivossh)
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

## **usuarios_procesos_top10.sh**
   Nivel Intermedio **Tema:** ps, gawk, sort, uniq,
   head, tuberias, arreglos asociativos

   Descripción Técninca:
   - Muestra los **10 usuarios con más procesos activos** en el sistema.
   - Genera un txt ('proc_user.txt') que registra el numero de procesos por 
   usuario
   - Utiliza tuberías para **procesar la salida de ps aux**, extraer el usuario
   ('gawk -F : '{print $1}'), contar procesos (wc -l), y
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
   elemento, asi en el for solo tendriamos que usar "${uids[@]}".
   - El uso de ps -U uidlist para listar todos los procesos que tiene por UID al especificado en esa lista.

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
   - Usamos el wc -l < "$SALIDA" el redireccionamiento de entrada para que así
   en el printf aparezca solo el numero y no el nombre del archivo

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

## **monitor_recursos_umbral.sh**
   Nivel Intermedio **Temas:** Monitoreo de Recursos, Descriptores de Archivo, Automatización, Parsing
   de Texto

   Descripción Técnica:
   Este script actúa como un sistema de alerta temprana para servidores Linux. Se objetivo
   es automatizar la vigilancia de los dos recursos más críticos del sistema: la CPU y la
   memoria RAM. El script lee umbrales de seguridad desde un archivo de configuración externo
   y los compara con el estado global del sistema en tiempo real. Si detecta que el servidor
   está bajo un estrés superior al permitido, realiza un volcado de los procesos "culpables"
   (los 5 que más consumen) hacia un log histórico para un análisis forense posterior.

   Uso Típico en las empresas:
   Se utiliza para evitar el **"Down-time"** (caída del servicio). Las empresas lo programan
   para que se ejecute cada minuto mediante un Cronjob
   - Ideal para servidores web o de bases de datos donde un proceso "zombie" o una fuga de memoria
   podría ralentizar el servicio a los clientes
   - Evita que el administrador tenga que estar mirando el comando top manualmente. Permite
   identificar que usuario o programa saturó el servidor en el pasado (por ejemplo, durante la
   madrugada) consultando el archivo de logs.

   Ejemplo de Ejecución:
   Primero, asegúrate de tener el archivo de configuración (ej. monitor.conf) con los valores deseados
   (CPU y RAM) en una sola línea: 80 70
   Luego, ejecuta el script pasando el archivo como parámetro:
   ./monitor_recursos.sh monitor.conf

   Curiosidad Técnica:
   - Descriptores de Archivo (exec 3>> ): En lugar de abrir y cerrar el log en cada linea de código
   el script abre un "canal" dedicado(el número 3) que permanece abierto hasta el final, optimizando
   el rendimiento de entrada/salida (I/O).
   - Tubería de Filtrado Aritmético: Combina top en modo batch (-bn1) con gawk para realizar
   una suma aritmética de estados user y system, obteniendo así la carga real de trabajo en CPU sin
   contar el tiempo de espera.

   Salida de Ejemplo:
   ==========REPORTE: '2026-04-19 19:30:05'==========
   [ALERTA RAM] Uso actual: 85% (Limite: 70%)
   root      1245  15.2  35.5  Ss   /usr/bin/python3_app
   mysql     950   5.5   20.1  Sl   /usr/sbin/mysqld
   apache2   2241  2.1   10.2  S    /usr/sbin/apache2
   usuario1  5560  1.0   5.0   R    ./proceso_pesado.sh
   root      1     0.0   0.1   Ss   /sbin/init

_____________________________________________________________________________________________________________

## **auditoria_integridad_archivos.sh**
   Nivel: Avanzado **Temas:** Seguridad Ofensiva/Defensiva, integridad de Datos, Criptografía (Hashing), Manipulación
   de Descriptores de archivo, Procesamiento de Texto con comm y gawk

   Descripción Técnica:
   Este script implementa un sistema ligero de detección de intrusos basado en el host (HIDS). Su objetivo principal es 
   garantizar la inmutabilidad y la integridad de los archivos dentro de un directorio crítico del sistema. El script opera 
   en dos fases controladas mediante opciones de línea de comandos (getopts):

   - Fase de Captura (Snapshot): Registra de forma recursiva el estado actual del directorio objetivo generando una firma 
   criptográfica SHA-256 única para cada archivo. Esta base de datos de "huellas dactilares" se almacena en un archivo plano estructurado (snapshot.db).
   - Fase de Auditoría (Verificación): Genera un segundo snapshot temporal del estado en vivo del directorio y realiza un análisis diferencial optimizado en memoria contra el
   registro original. Mediante operaciones de conjuntos binarios (comm) y parsing con gawk, el script aísla y clasifica con precisión quirúrgica qué elementos  han sufrido 
   alteraciones estructurales, cuáles han sido inyectados (creados) y cuáles han sido removidos (eliminados), volcando los resultados en reportes analíticos independientes.

   Uso Típico en las empresas:
   En entornos corporativos y de producción, este script se utiliza en el despliegue de políticas de Hardening de Servidores y cumplimiento de normativas de seguridad (como PCI-DSS o ISO 27001).
   - Contexto de uso: Se programa mediante tareas cronificadas (cron) para ejecutarse en la madrugada sobre directorios críticos que nunca deberían cambiar sin un control de cambios 
   previo (como /etc donde residen las configuraciones del sistema, /bin o /sbin que contienen los binarios esenciales, o el subdirectorio de producción de un servidor web 
   /var/www/html).
   - Problemas del día a día que resuelve: * Detección de Defacement: Identifica de inmediato si un atacante ha modificado el código fuente de la página web de la empresa para 
   alterar su aspecto o robar datos.
  	. Detección de Backdoors y Rootkits: Alerta al administrador si un intruso logra escalar privilegios e inyecta un script malicioso oculto o altera un binario del sistema 
  	para mantener acceso persistente.
   	. Auditoría de Cambios no Autorizados: Evita el "fuego amigo" en equipos de operaciones, detectando si un administrador modificó una configuración del sistema sin registrarla
  	 en el ticket de cambios, facilitando el rollback inmediato.

   Ejemplo de Uso:

   1. Generar la firma base de un directorio de desarrollo guardando el registro en una ruta personalizada: ./auditoria_integridad.sh -d /home/kdefsys/proyectos -g -f /home/kdefsys/firmas/auditoria.db

   2. Verificar el directorio tiempo después para auditar alteraciones: ./auditoria_integridad.sh -d /home/kdefsys/proyectos -v -f /home/kdefsys/firmas/auditoria.db

   Curiosidad Técnica:
   - Filtro de nombres con espacios (gawk '{ $1=""; print substr($0,2) }'): Por defecto, la salida de sha256sum entrega la estructura HASH  RUTA_DEL_ARCHIVO. Un awk '{print $2}' 
   convencional fallaría estrepitosamente si el nombre de la ruta contiene espacios (solo tomaría la primera palabra). Con $1="", el script vacía el primer campo (el hash) y 
   substr($0, 2) extrae la línea restante a partir del segundo carácter, conservando intacto el nombre completo del archivo con todos sus espacios.
   - Comparación limpia por conjuntos (comm -23 y comm -13): El comando comm requiere que los archivos estén previamente ordenados (sort). Al usar la bandera -23, compara el snapshot 
   nuevo contra el viejo e imprime únicamente las líneas presentes en el primero pero ausentes en el segundo (archivos nuevos o modificados). De forma inversa, -13 extrae los 
   archivos que existían en el viejo pero no en el nuevo (archivos eliminados).
   - Búsqueda literal en modo silencioso (grep -Fq "$file" ...): Para saber si un archivo en conflicto fue modificado o creado, el script busca la ruta en la base antigua. 
   La opción -F (Fixed Strings) le indica a grep que trate el nombre del archivo como una cadena de texto puro (evitando que puntos o caracteres especiales en las rutas se 
   interpreten como expresiones regulares). La opción -q (Quiet) suprime la impresión en pantalla y retorna inmediatamente un código de estado 0 (éxito) o 1 (fallo), optimizando al 
   máximo el rendimiento dentro de las condicionales if.
___________________________________________________________________________________________________________________________________________________________________________________
