# Symlinks-Tools

Colección de scripts orientados a la auditoría, limpieza y reconstrucción de
enlaces simbólicos en sistemas Linux.
Estos scripts están pensados para escenarios reales de administración de
sistemas, donde los symlinks son usados para despliegues, rutas compartidas y
mantenimiento de servidores.

# Contenido

- [auditar_symlinks_rotos.sh](#auditar_symlinks_rotossh)
- [revinculacion_inteligente.sh](#revinculacion_inteligentesh)
- [verificar_y_reconstruir_symlinks.sh](#verificar_y_reconstruir_symlinkssh)
- [gestor_entornos.sh](#gestor_entornossh)
________________________________________________________________________________________________

## **auditar_symlinks_rotos.sh**
   Nivel Intermedio **Temas:** enlaces simbólicos,
   find, readlink, logs, validaciones

   Descripción Técnica:
   Este script es una herramienta de administración de sistemas diseñada para la detección 
   y limpieza proactiva de enlaces simbólicos huérfanos (broken symlinks). El programa recorre 
   de forma recursiva un directorio proporcionado por el usuario, identifica aquellos enlaces 
   cuyo destino ya no existe en el sistema de archivos y genera un reporte detallado (log) 
   utilizando descriptores de archivos personalizados.

   Además, ofrece una capa interactiva que permite al administrador decidir si desea eliminar 
   los enlaces detectados, garantizando que el sistema de archivos se mantenga limpio y libre de 
   referencias inválidas que puedan causar errores en aplicaciones o procesos de respaldo

   Uso Típico en las empresas:
   - Auditorías de integridad antes de backups
   - Verificación de despliegues fallidos
   - Revisión de rutas compartidas en servidores antiguos
   - Detección temprana de errores en aplicaciones que dependen de symlinks
   Este tipo de auditoría es común antes de migraciones, upgrades o mantenimientos
   programados

   Ejemplo de Ejecución:

   chmod u+x auditar_symlinks_rotos.sh

   ./auditar_symlinks_rotos.sh /var/www/html/assets

   Curiosidad Técnica:
   - 'find type l -not -exec test -e {} \;' para detectar symlinks rotos
   - 'readlink' para obtener el destino del enlace aunque el destino no exista
   Esto demuestra que un symlink siempre conserva la ruta destino como texto,
   independientemente de si el archivo real sigue presente 

_________________________________________________________________________________________________

## **revinculacion_inteligente.sh**
   Nivel Avanzado **temas:** symlink Management, Heuristic File Search, Namerefs (local -n),
   Forensic Recovery

   Descripción Técnica:
   Este script es una utilidad de autorrecuperación y mantenimiento proactivo para sistemas Linux. 
   Su objetivo principal no es solo auditar enlaces simbólicos rotos, sino actuar como un motor de reparación 
   heurística.
   El script identifica enlaces "huérfanos" (dangling symlinks), extrae el nombre del archivo original mediante 
   expansión de parámetros de shell y realiza una búsqueda exhaustiva en el sistema de archivos para localizar 
   posibles nuevas ubicaciones del archivo perdido. Mediante una interfaz interactiva, permite al administrador 
   re-vincular de forma atómica el enlace a su nueva ruta, eliminando la necesidad de intervención manual de 
   búsqueda y creación.

   Uso Típico en las empresas:
   En infraestructuras empresariales con servidores de larga trayectoria o entornos de desarrollo compartidos, 
   los archivos suelen moverse de particiones o directorios debido a políticas de ordenamiento o migraciones de 
   almacenamiento. Contextos específicos:
   - Post-Migración de Almacenamiento: Cuando se mueven carpetas de /opt a /mnt/data y cientos de scripts o 
   configuraciones quedan con rutas inválidas.
   - Soporte Técnico de Nivel 2: Para diagnosticar por qué un software falló tras una actualización que cambió 
   la estructura de librerías o binarios.
   - Limpieza de Servidores Legados: En máquinas antiguas donde se acumulan miles de enlaces y no se sabe con 
   certeza cuáles son prescindibles y cuáles simplemente están desorientados.

   Problemas que resuelve: Reduce el tiempo de inactividad (downtime) causado por errores de "File not found", 
   evita la pérdida de configuraciones críticas y automatiza la tarea tediosa de buscar archivos movidos manualmente.

   Ejemplo de Ejecución:

   ./revinculacion_inteligente.sh /home/usuario/proyectos

   Curiosidad Técnica:
   El script implementa varias técnicas de "Bash Moderno" que lo hacen destacar:
   - Paso por Referencia (local -n Lista=$1): Utiliza namerefs para trabajar directamente con el array definido 
   fuera de la función. Esto evita la "explosión de argumentos" y permite que la función sea mucho más eficiente y
   limpia al manipular estructuras de datos complejas.
   - Expansión Forense (${archivo_destino##*/}): En lugar de llamar al comando externo basename (lo cual crea un 
   proceso nuevo y consume recursos), utiliza la expansión de parámetros interna de Bash para obtener el nombre del 
   archivo instantáneamente.
   - Reparación Atómica con ln -sf: El uso de la bandera -f (force) es clave; permite sobrescribir el enlace simbólico 
   roto en una sola operación sin tener que ejecutar un rm previo, asegurando que el nombre del enlace se mantenga intacto.

__________________________________________________________________________________________________________________________

## **verificar_y_reconstruir_symlinks.sh**
   Nivel Avanzado **Temas:**
   enlaces simbólicos, automatización, validación, archivos de configuración

   Descripción Técnica:
   Este script verifica y reconstruye enlaces simbólicos según una fuente de
   verdad definida en un archivo de configuración
   Cada línea del archivo define: ENLACE:DESTINO_CORRECTO
   El script:
    - Valida la existencia del enlace simbólico
    - Compara el destino actual con el destino esperado
    - Elimina y recrea el enlace si no coincide
    - Registra todos los cambios realizados
   El script no adivina rutas ni destinos: actúa únicamente según lo definido.

   Uso Típico en las empresas:
   - Recuperación post-fallo de despliegues
   - Correción de enlaces tras actualizaciones fallidas
   - Mantenimiento de rutas estándares como 'current', 'latest', 'active'
   - Automatización en entornos CI/CD y staging
   Este patrón es ampliamente usado en infraestructura moderna.

   Curiosidad Técnica:
   El script destaca por:
    - Uso de archivos de configuración como fuente de verdad
    - Comparación de destinos con 'readlink'
    - Recreación segura de symlinks con 'ln -s'
   Este enfoque evita errores humanos y asegura consistencias en sistemas
   productivos

_____________________________________________________________________________

## **gestor_entornos.sh**
   Nivel Intermedio-Avanzado **Temas:** Automatización de Despliegues, Gestión de Parámetros(getopts), Integridad de Enlaces simbolicos,
   Logging Profesional

   Descripción Técnica:
   Este script es una herramienta de orquestación de infraestructura diseñada para alternar dinámicamente entre diferentes configuraciones o versiones de una aplicación. 
   Utiliza una lógica de "conmutación" mediante enlaces simbólicos, permitiendo que un punto de acceso único (target) apunte de forma segura a distintos directorios de entorno
   (source/env).
   El programa destaca por su robustez, ya que implementa validaciones de tres capas: verifica la existencia del origen, valida que el destino no sea un archivo/directorio real 
   para evitar pérdida de datos, y gestiona tanto la actualización de enlaces existentes como la creación de nuevos.

   Uso Típico en las empresas:
   En entornos de Integración y Despliegue Continuo (CI/CD), las empresas necesitan cambiar de versiones de software o de configuraciones de base de datos sin apagar los servicios.
   Contextos específicos:
   - Estrategias Blue-Green Deployment: Para activar la versión "Green" (nueva) simplemente moviendo el enlace simbólico que apunta al servidor web (Nginx/Apache), permitiendo un 
   retorno inmediato (rollback) si algo falla.
   - Gestión de Entornos Local/Dev/Prod: Para cambiar las variables de entorno o archivos de configuración de una aplicación según el servidor en el que se encuentre.
   - Actualizaciones de Aplicaciones: Permite instalar una nueva versión en una carpeta paralela y "activarla" en milisegundos mediante el cambio del enlace.

   Ejemplo de Ejecución:
   chmod +x gestor_entornos.sh

   ./gestor_entornos.sh -s /apps/releases -e v2.1.0 -t /var/www/html/current

   Curiosidad Técnica:
   - Procesamiento con getopts: Implementa un análisis de argumentos estándar de Linux, permitiendo que las opciones -s, -t y -e se pasen en cualquier orden de forma profesional.
   - Protección de Datos Atómica: Antes de operar, el script utiliza [[ -L "$ENLACE" ]] contra [[ -d "$ENLACE" ]]. Esto asegura que si por error el administrador intenta convertir 
   una carpeta con datos reales en un enlace, el script se detendrá y protegerá la integridad de los archivos.
   - Redirección de Auditoría (exec 3>>): Utiliza un descriptor de archivo personalizado para manejar el archivo de reporte. Esto permite separar los mensajes informativos de la 
   terminal de los registros permanentes de auditoría, manteniendo un flujo de salida limpio y eficiente.
______________________________________________________________________________________________________________________________________________________________

## NOTA FINAL
Estos scripts reflejan problemas reales que enfrenta un administrador de sistemas
Linux en el día a día, y demuestran un uso práctico y consciente de los enlaces
simbólicos en entornos empresariales.
