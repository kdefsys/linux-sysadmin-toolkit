# Symlinks-Tools

Colección de scripts orientados a la auditoría, limpieza y reconstrucción de
enlaces simbólicos en sistemas Linux.
Estos scripts están pensados para escenarios reales de administración de
sistemas, donde los symlinks son usados para despliegues, rutas compartidas y
mantenimiento de servidores.

# Contenido

- [auditar_symlinks_rotos.sh](#auditar_symlinks_rotossh)
- [limpieza_symlinks_huerfanos.sh](#limpieza_symlinks_huerfanossh)
- [verificar_y_reconstruir_symlinks.sh](#verificar_y_reconstruir_symlinkssh)
_____________________________________________________________________________

## **auditar_symlinks_rotos.sh**
   Nivel Intermedio **Temas:** enlaces simbólicos,
   find, readlink, logs, validaciones

   Descripción Técnica:
   Este script audita un directorio dado y detecta **enlaces simbólicos rotos**,
   es decir, symlinks cuyo destino ya no existe en el sistema
   Para cada enlace roto encontrado, el script registra:
    - La ruta del enlace simbólico
    - El destino esperado almacenado en el symlink
   Los resultados se guardan en un archivo de log con marca de tiempo,
   permitiendo revisar posteriormente el estado del sistema.

   Uso Típico en las empresas:
   - Auditorías de integridad antes de backups
   - Verificación de despliegues fallidos
   - Revisión de rutas compartidas en servidores antiguos
   - Detección temprana de errores en aplicaciones que dependen de symlinks
   Este tipo de auditoría es común antes de migraciones, upgrades o mantenimientos
   programados

   Curiosidad Técnica:
   - 'find type l -not -exec test -e {} \;' para detectar symlinks rotos
   - 'readlink' para obtener el destino del enlace aunque el destino no exista
   Esto demuestra que un symlink siempre conserva la ruta destino como texto,
   independientemente de si el archivo real sigue presente 

_____________________________________________________________________________

## **limpieza_symlinks_huerfanos.sh**
   Nivel Intermedio/Avanzado **temas:**
   enlaces simbólicos, interacción con usuario, logging, control de flujo

   Descripción Técnica:
   Este script identifica enlaces simbólicos huérfanos dentro de un directorio
   y permite realizar una **limpieza controlada**
   Para cada enlace roto encontrado, el script:
   - Muestra la ruta del enlace y su destino inexistente
   - Solicita confirmación al usuario para eliminar o ignorar el enlace
   - Registra la acción tomada en un archivo de log
   No se elimina ningún enlace sin confirmación explicíta del administrador

   Uso Típico en las empresas:
   - Limpieza segura en servidores legacy
   - Mantenimiento de carpetas compartidas
   - Reducción de errores en scripts y aplicaciones
   - Prevención de referencias inválidas en sistemas productivos
   Este enfoque interactivo es habitual cuando se trabaja en sistemas críticos
   donde no se permite eliminación automática

   Curiosidad Técnica:
   - Detección de symlinks rotos con 'find'
   - Lectura de entrada del usuario con 'read -n1'
   - bucles 'while' + 'case¿ para control interactivo
   Este patrón es muy común en scripts administrativos que requieren decisiones
   humanas.

_____________________________________________________________________________

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

## NOTA FINA
Estos scripts reflejan problemas reales que enfrenta un administrador de sistemas
Linux en el día a día, y demuestran un uso práctico y consciente de los enlaces
simbólicos en entornos empresariales.
