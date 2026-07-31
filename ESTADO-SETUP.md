# Estado del setup — VSCode portable + stack Java

> Última actualización: 2026-07-31
> Objetivo del proyecto: dejar la copia portable de VSCode (`VSCode-win32-x64-1.131.0/`) configurada para trabajar con el stack: **Java 11 + Tomcat 9 + Maven + Oracle SQL + frontend XHTML/PrimeFaces**, usando los componentes de `Complementos/`.

Este fichero existe para poder retomar el trabajo en otra sesión sin tener que re-analizar todo desde cero.

## Estructura del proyecto

```
Proyecto VsCode Java/
├── VSCode-win32-x64-1.131.0/     ← VSCode portable, YA en modo portable (carpeta data/ creada)
│   └── data/
│       ├── user-data/            ← settings, historial, etc. (queda dentro del proyecto)
│       └── extensions/           ← extensiones instaladas (ver lista abajo)
├── Complementos/
│   ├── openjdk-11.0.32+9/       ← JDK de COMPILACIÓN/EJECUCIÓN del proyecto (target Java 11)
│   ├── openjdk-17.0.20+8/       ← JDK para el Language Server de Java en VSCode (redhat.java necesita 17+)
│   ├── apache-maven-3.8.1/      ← estructura ya corregida (bin/, lib/, conf/ directamente dentro)
│   ├── apache-tomcat-9.0.120/   ← OK, estructura estándar completa
│   ├── lombok-1.18.26.jar
│   └── ojdbc7-12.1.0.2.jar      ← driver JDBC Oracle
└── ESTADO-SETUP.md              ← este fichero
```

## Qué se hizo en esta sesión (2026-07-31)

1. **Diagnóstico inicial**: se detectó que `Complementos/openjdk-11.0.23` y `openjdk-17.0.18` contenían el **tarball de CÓDIGO FUENTE** de OpenJDK (carpetas `src/`, `make/`, `configure`, `Makefile`), no un build binario ejecutable. No tenían `bin/java.exe`. También se detectó que `apache-maven-3.8.1/` estaba doblemente anidada (`apache-maven-3.8.1/apache-maven-3.8.1/...`), dejando `bin/` vacía en la ruta esperada.

2. **Descarga de binarios correctos (OpenJDK / Eclipse Temurin, Windows x64)**:
   - JDK 11: `OpenJDK11U-jdk_x64_windows_hotspot_11.0.32_9.zip` desde `github.com/adoptium/temurin11-binaries` — SHA-256 verificado (`c1a7c406b7...`).
   - JDK 17: `OpenJDK17U-jdk_x64_windows_hotspot_17.0.20_8.zip` desde `github.com/adoptium/temurin17-binaries` — SHA-256 verificado (`418497be5c...`).
   - Extraídos y aplanados en `Complementos/openjdk-11.0.32+9/` y `Complementos/openjdk-17.0.20+8/` (bin/ y lib/ quedan directamente dentro de esas carpetas).
   - Se borraron las carpetas antiguas incorrectas (`openjdk-11.0.23/`, `openjdk-17.0.18/` con sus `.tar` fuente).

3. **Maven arreglado**: se aplanó `apache-maven-3.8.1/`, eliminando el nivel de carpeta duplicado. Ahora `Complementos/apache-maven-3.8.1/bin/mvn.cmd` existe y funciona.

4. **Verificación**: `java -version` en ambos JDK y `mvn -version` (con `JAVA_HOME` apuntando al JDK 11) ejecutados correctamente:
   - `openjdk version "11.0.32" ... Temurin-11.0.32+9`
   - `openjdk version "17.0.20" ... Temurin-17.0.20+8`
   - `Apache Maven 3.8.1`, Java version 11.0.32, vendor Eclipse Adoptium.

5. **Limpieza**: borrados los `.zip`/temporales de descarga y las carpetas obsoletas mencionadas arriba. `Complementos/` solo contiene ya los elementos correctos.

## Qué se hizo en la sesión de continuación (modo portable + extensiones)

1. **Modo portable activado**: se creó la carpeta `VSCode-win32-x64-1.131.0/data/` (vacía) junto a `Code.exe`. Al ejecutar `bin/code.cmd --list-extensions` por primera vez, VSCode detectó la carpeta y generó dentro `data/user-data/` y `data/extensions/` automáticamente. A partir de ahora toda la configuración y extensiones quedan dentro del proyecto, no en `%APPDATA%`.

2. **Extensiones instaladas** (vía `bin/code.cmd --install-extension <id> --force`, requiere conexión a internet al Marketplace de VSCode):

   | ID | Nombre | Para qué |
   |---|---|---|
   | `vscjava.vscode-java-pack` | Extension Pack for Java | Meta-paquete: instala `redhat.java` (Language Support for Java), `vscjava.vscode-java-debug`, `vscjava.vscode-maven`, `vscjava.vscode-java-test`, `vscjava.vscode-java-dependency` |
   | `redhat.java` | Language Support for Java(TM) by Red Hat | Language Server — **usará el JDK 17** como runtime propio |
   | `vscjava.vscode-maven` | Maven for Java | Integración con `apache-maven-3.8.1` |
   | `vscjava.vscode-java-debug` | Debugger for Java | Depurar la app Java/Tomcat |
   | `vscjava.vscode-java-test` | Test Runner for Java | Tests unitarios |
   | `vscjava.vscode-java-dependency` | Project Manager for Java | Gestión de dependencias/proyecto |
   | `vscjava.vscode-gradle` | Gradle for Java | Viene incluida en el pack; no se usa (el proyecto es Maven), se deja porque no molesta |
   | `redhat.vscode-xml` | XML | Soporte XML/XHTML (autocompletado, validación) — cubre las vistas `.xhtml` de PrimeFaces |
   | `adashen.vscode-tomcat` | Tomcat for Java | Gestionar/arrancar `Complementos/apache-tomcat-9.0.120` y desplegar el `.war` desde VSCode |
   | `oracle.sql-developer` | Oracle SQL Developer for VSCode | Cliente oficial de Oracle para conectar y consultar la base de datos Oracle directamente desde VSCode |

   **Nota sobre IDs que fallaron y su sustituto**:
   - `vscjava.vscode-community-server-connectors` no existe → sustituido por `adashen.vscode-tomcat` (712k instalaciones, más consolidado).
   - `mtxr.sqltools-driver-oracle` no existe → en vez de montar SQLTools + driver community, se instaló la extensión **oficial** `oracle.sql-developer` (938k instalaciones, mantenida activamente por Oracle) y se desinstaló `mtxr.sqltools` (quedaba sin driver útil para Oracle, así que no aportaba nada).

3. **Limpieza adicional**: al desinstalar `mtxr.sqltools` quedó una carpeta residual vacía (`data/extensions/mtxr.sqltools-0.28.6/`, solo con `.vsixmanifest` y `LICENSE.md`) y una entrada en `data/extensions/.obsolete`. Se borró la carpeta a mano; `--list-extensions` ya no la mostraba de todas formas.

## Qué se hizo en la sesión de configuración de `settings.json`

1. **Creado `VSCode-win32-x64-1.131.0/data/user-data/User/settings.json`** (no existía) con:
   ```json
   {
       "java.configuration.runtimes": [
           { "name": "JavaSE-11", "path": ".../Complementos/openjdk-11.0.32+9", "default": true },
           { "name": "JavaSE-17", "path": ".../Complementos/openjdk-17.0.20+8" }
       ],
       "java.jdt.ls.java.home": ".../Complementos/openjdk-17.0.20+8",
       "maven.executable.path": ".../Complementos/apache-maven-3.8.1/bin/mvn.cmd",
       "maven.terminal.useJavaHome": true
   }
   ```
   (rutas absolutas completas en el fichero real, en `C:\Users\david\Documents\Proyecto VsCode Java\Complementos\...`).
   - `java.jdt.ls.java.home` → el Language Server de Java arranca con el **JDK 17**.
   - `java.configuration.runtimes` → el **JDK 11** queda como runtime por defecto del proyecto (compilación/ejecución); el 17 está disponible si algún módulo lo necesitase.
   - `maven.executable.path` → la extensión Maven usa el Maven de `Complementos/apache-maven-3.8.1` en vez de descargar/usar uno embebido.
   - `maven.terminal.useJavaHome: true` → evita duplicar la ruta del JDK a mano: la terminal de Maven usará automáticamente el runtime por defecto configurado arriba (JDK 11).
   - Validado el JSON (sintaxis correcta). **No se ha podido hacer una prueba "en caliente"** abriendo la UI de VSCode desde esta sesión (entorno sin sesión gráfica); recomendable abrir VSCode normalmente una vez y comprobar en la pestaña "Java Projects" / notificaciones que carga bien ambos runtimes.

2. **`adashen.vscode-tomcat` — NO configurable por `settings.json`**: revisado su `package.json`, la única propiedad de configuración es `tomcat.workspace` (carpeta interna de metadatos de la extensión, no la ruta del Tomcat en sí). Añadir un servidor Tomcat se hace con el comando **"Tomcat: Add Server"** desde la paleta de comandos (o el icono "+" en el panel Tomcat) y seleccionando la carpeta `Complementos/apache-tomcat-9.0.120` en el diálogo — es un paso interactivo, no hay fichero de config editable a mano de forma soportada. **Queda pendiente hacerlo dentro de la UI.**

3. **`oracle.sql-developer` — igual, requiere UI**: las conexiones se crean y guardan desde su propio panel (Database Explorer), no vía `settings.json`. Además faltan los datos reales de conexión (host, puerto, service name/SID, usuario) que el usuario aún no ha proporcionado. **Sigue pendiente.**

## Evaluación de nuevas tareas pedidas (2026-07-31, pendientes de ejecutar)

### 1. Extensión SVN + poder depurar (step-into) el código de 2 librerías que viven en SVN — VIABLE, con prerrequisito pendiente

- Proyecto principal en Git, pero 2 librerías dependencia viven en repos SVN aparte; se quiere poder hacer step-into en su código durante el debug, no solo gestionar el SVN como control de versiones.
- Extensión recomendada: **`johnstoncode.svn-scm`** ("SVN") — la opción de facto para SVN en VSCode.
- **Prerrequisito que falta**: esta extensión no trae cliente SVN propio, necesita el binario `svn.exe` en el sistema. Comprobado en esta máquina:
  - **TortoiseSVN está instalado** (`C:\Program Files\TortoiseSVN\bin`) pero **sin el componente "command line client tools"** — no hay `svn.exe` ahí, solo las herramientas gráficas (`TortoiseProc.exe`, etc.).
  - Dos formas de resolverlo (a decidir por el usuario, ninguna se ha hecho):
    - **(a)** Volver a ejecutar/modificar el instalador de TortoiseSVN y marcar "command line client tools" (rápido, ya está instalado, pero es un cambio a nivel de sistema fuera de este proyecto — hay que hacerlo manualmente, no es algo que se deba automatizar sin permiso).
    - **(b)** Instalar un cliente SVN portable aparte (p. ej. SlikSVN) sin tocar la instalación de sistema, y apuntar la extensión a él con el setting `svn.path`.
- **Para que el step-into funcione de verdad** (no solo tener el SCM), además hace falta:
  1. Hacer `svn checkout` de las dos librerías a alguna carpeta local (p. ej. dentro de `Complementos/` o en una carpeta `svn-libs/` aparte).
  2. Decirle al depurador de Java dónde están esos fuentes: setting `java.debug.settings.sourcePaths` (global) o `sourcePaths` dentro del `launch.json` del proyecto, apuntando a esas carpetas — así al hacer step-into en una llamada a la librería, resuelve el `.java` real en vez de solo bytecode.
- **Falta para poder ejecutar esto**: las URLs de los 2 repos SVN, y elegir opción (a) o (b) para el cliente CLI.

### 2. Configurar parámetros del servidor Tomcat (puerto, timeouts, VM Arguments) — VIABLE, estándar de Tomcat

- **Puerto y timeouts** → `Complementos/apache-tomcat-9.0.120/conf/server.xml`, atributos `port` y `connectionTimeout` del `<Connector>` HTTP (y del `<Connector>` AJP si se usa).
- **VM Arguments** → la forma soportada oficialmente sin tocar `catalina.bat` es crear `Complementos/apache-tomcat-9.0.120/bin/setenv.bat` con `set JAVA_OPTS=...` (ahí van `-Xmx`, `-Xms`, flags de depuración remota JDWP, etc.). Catalina lo carga automáticamente si existe.
- Alternativa por UI: la extensión `adashen.vscode-tomcat` tiene el comando **"Customize JVM Options"** por servidor (una vez añadido el servidor en su panel, tarea aún pendiente de la sesión anterior).
- **Falta para poder ejecutar esto**: valores concretos — ¿puerto (mantener 8080 o cambiar), timeout deseado, memoria (`-Xmx`/`-Xms`), y si se quiere ya activar el puerto de debug remoto JDWP (enlaza directamente con la tarea 1: para depurar Tomcat + librerías SVN hace falta arrancarlo con algo como `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000` y luego "Attach" desde VSCode)?

### 3. Atajos de teclado estilo Eclipse "2026-06" — VIABLE, con matiz importante

- Extensión: **`alphabotsec.vscode-eclipse-keybindings`** ("Eclipse Keymap") — 906k instalaciones, 4.89/5, la opción claramente dominante frente a alternativas (`fengjx...`, `xunyss...`, mucho menos usadas).
- **Matiz**: no existe (ni aquí ni en ningún sitio) una "edición" del keymap específica para la build 2026-06 de Eclipse. Los atajos por defecto de Eclipse apenas han cambiado entre release trains en años; esta extensión (última actualización 2022) emula el esquema clásico de Eclipse (Ctrl+Shift+T, Ctrl+Shift+R, F3, Alt+Shift+R, etc.), no una versión puntual. Instalarla da "los atajos de Eclipse" en general, que en la práctica coinciden con los de 2026-06.
- **Sin bloqueos** — se puede instalar en cualquier momento sin más información.

## Qué se hizo tras la evaluación (extensiones confirmadas + setenv.bat + guía)

1. **Instaladas** las dos extensiones sin bloqueos: `alphabotsec.vscode-eclipse-keybindings` (Eclipse Keymap) y `johnstoncode.svn-scm` (SVN). Lista completa actualizada de extensiones: `adashen.vscode-tomcat`, `alphabotsec.vscode-eclipse-keybindings`, `johnstoncode.svn-scm`, `oracle.sql-developer`, `redhat.java`, `redhat.vscode-xml`, `vscjava.vscode-gradle`, `vscjava.vscode-java-debug`, `vscjava.vscode-java-dependency`, `vscjava.vscode-java-pack`, `vscjava.vscode-java-test`, `vscjava.vscode-maven`.

2. **Creado `Complementos/apache-tomcat-9.0.120/bin/setenv.bat`** (no existía). Fija `JAVA_HOME` al JDK 11 portable del proyecto — importante porque el PATH del sistema de esta máquina tiene **otros JDK instalados** (JDK 15, Liberica 17, etc.) que `catalina.bat` podría coger por error si no se fija explícitamente. Incluye además, comentadas con `rem` (a la espera de que el usuario decida los valores, ver `INSTRUCCIONES-PENDIENTES.md`), líneas de ejemplo para memoria (`-Xms`/`-Xmx`) y para activar el puerto de debug remoto JDWP.

3. **Creado [INSTRUCCIONES-PENDIENTES.md](INSTRUCCIONES-PENDIENTES.md)**: nuevo documento (separado de este) que reúne todos los pasos que **solo el usuario puede completar** — porque necesitan datos confidenciales (URLs de los 2 repos SVN, valores de servidor, credenciales Oracle — todo por LOPD) o son acciones interactivas en la UI de VSCode. Cubre: dónde poner el `svn.exe` portable y el setting `svn.path`, dónde hacer el `svn checkout` de las 2 librerías (`Complementos/svn-libs/...`), el setting `java.debug.settings.sourcePaths` para el step-into en su código, edición de puerto/timeout en `server.xml`, activar las líneas de `setenv.bat`, y los dos pasos de UI ya pendientes (añadir servidor Tomcat, crear conexión Oracle). Tiene un checklist al final. **A partir de ahora, cualquier paso que requiera datos que el usuario no puede compartir se documenta ahí, no aquí.**

## Ampliación del documento de uso + aviso de tamaño para GitHub (2026-07-31)

1. **`INSTRUCCIONES-PENDIENTES.md` ampliado** con un manual de uso completo (pensado para cualquiera que use el paquete, no solo para configurarlo): arrancar Tomcat normal y en modo debug (JDWP, `launch.json` de attach), pararlo correctamente, ejecutar tests (UI y línea de comandos), y una sección nueva de "cambiar rutas si usas otra carpeta/usuario/máquina" con la tabla exacta de qué fichero/clave tocar para relocalizar los JDK y Maven. La antigua sección de pasos pendientes se mantiene dentro del mismo fichero, como sección 3.

2. **Aviso importante de cara a subir esto a GitHub**: el proyecto pesa **2.5 GB** en total (tras limpieza, ver abajo). Desglose:
   - `VSCode-win32-x64-1.131.0/Code.exe`: **222 MB** — por sí solo ya supera el límite duro de GitHub de 100 MB por fichero; un `git push` normal lo rechazaría.
   - `data/extensions/` (extensiones instaladas, incluye el Language Server de Java): ~915 MB.
   - `e4c7e7b1d6/` (motor Chromium/Electron de VSCode): ~743 MB.
   - `Complementos/openjdk-11.0.32+9` + `openjdk-17.0.20+8`: ~611 MB entre los dos.
   - Se ha borrado `data/user-data/CachedExtensionVSIXs/` (615 MB) — era solo una caché redundante de los instaladores de las extensiones, no afecta a que funcionen (verificado con `--list-extensions` tras borrarlo).
   - **Un repositorio git normal no es viable así** — ni siquiera con Git LFS de forma cómoda (la cuota gratuita de GitHub LFS es de 1 GB de almacenamiento/mes, muy por debajo de los ~2.5 GB, y cada clon de otra persona consumiría ancho de banda de esa misma cuota compartida).
   - **Alternativas razonables** (pendiente de que el usuario decida):
     a. Publicar el paquete como **asset de un GitHub Release** (permite ficheros de hasta ~2 GB cada uno, separado del repositorio git en sí) en vez de comitearlo en el árbol de git.
     b. Convertir esto en un **script de instalación** (similar a lo que se hizo esta sesión con la API de Adoptium) que, en la máquina de cada usuario, descargue VSCode portable + los 2 JDK + Tomcat + Maven directamente de sus fuentes oficiales — el repositorio en sí quedaría ligero (solo el script, `settings.json` de plantilla, `setenv.bat` de plantilla y estos documentos).
   - No se ha tomado ninguna decisión ni ejecutado ningún cambio de estructura todavía — está pendiente de que el usuario elija.

## Script de instalación automática — setup.ps1 (2026-07-31)

Tras el aviso de tamaño (2.5 GB, inviable en git), se eligió la opción de **script que descarga todo** en vez de subir los binarios o usar Git LFS.

1. **Creado [setup.ps1](setup.ps1)** en la raíz del proyecto. Descarga de las fuentes oficiales, con versión y checksum fijados (reproducible, no depende de "latest"):
   - VSCode 1.131.0 win32-x64 — `update.code.visualstudio.com/1.131.0/win32-x64-archive/stable` (mismo build ya usado, mismo hash de commit `e4c7e7b1d6...`).
   - OpenJDK 11.0.32+9 y 17.0.20+8 (Temurin) — API de versión fija de Adoptium, con verificación SHA-256 (los mismos hashes ya validados manualmente esta sesión).
   - Apache Tomcat 9.0.120 — `archive.apache.org` (versión archivada, no el mirror `dlcdn` que rota), con verificación SHA-512.
   - Apache Maven 3.8.1 — `archive.apache.org`, con verificación SHA-512.
   - Instala las 6 extensiones validadas (Java Pack, XML, Tomcat, Oracle SQL Developer, Eclipse Keymap, SVN) — **no** incluye `mtxr.sqltools`, que se probó y se descartó a propósito.
   - Genera `settings.json` y `setenv.bat` calculando las rutas absolutas reales de la máquina donde se ejecute (`$PSScriptRoot`) — esto resuelve de raíz el problema de portabilidad entre usuarios/máquinas descrito en la sección 2 de `INSTRUCCIONES-PENDIENTES.md`.
   - Es idempotente: si un componente ya existe, lo omite (salvo que se use `-Force`).

2. **Creado `.gitignore`**: excluye las carpetas que el script descarga (`VSCode-win32-x64-*`, `Complementos/openjdk-*`, `Complementos/apache-tomcat-*`, `Complementos/apache-maven-*`) y la temporal `_setup_tmp/`. **No** excluye `lombok-1.18.26.jar` ni `ojdbc7-12.1.0.2.jar` (pesan poco, 1.9 MB y 3.6 MB, se quedan versionados normal — además `ojdbc7` tiene licencia de descarga de Oracle que no se puede automatizar sin credenciales, así que no tiene sentido intentar descargarlo por script).

3. **`INSTRUCCIONES-PENDIENTES.md` reestructurado**: nueva sección 0 "Instalación desde cero" explicando `setup.ps1`; la sección 2 (cambiar rutas a mano) se mantiene como referencia/fallback pero ahora deja claro que normalmente no hace falta si se usa el script.

4. **Validación end-to-end completada** (en una carpeta aislada, no la del proyecto real):
   - Primer intento: falló la descarga de VSCode (`Invoke-WebRequest` en Windows PowerShell 5.1 aborta la conexión en archivos grandes por culpa de su barra de progreso — bug conocido). Arreglado añadiendo `$ProgressPreference = "SilentlyContinue"` al principio del script.
   - Segundo intento: **completado sin errores**. Verificado tras la ejecución:
     - Las 4 descargas con checksum OK (SHA-256 para los JDK, SHA-512 para Tomcat y Maven).
     - Estructura de carpetas correcta (sin el doble-anidado que tuvo Maven la primera vez).
     - `java -version` funciona en ambos JDK.
     - `mvn -version` funciona y detecta el JDK 11 correctamente (con `JAVA_HOME` puesto).
     - Las 12 extensiones esperadas instaladas (6 explícitas + las que arrastra el Java Pack), sin `mtxr.sqltools`.
     - `settings.json` y `setenv.bat` generados con las rutas absolutas reales de la carpeta de prueba (confirma que la resolución dinámica de rutas funciona).
   - Pulido menor tras la prueba: el `settings.json` generado llevaba BOM UTF-8 (por `Set-Content -Encoding utf8` en PowerShell 5.1) y el orden de claves salía desordenado (hashtables no ordenadas). Corregido escribiendo el fichero con `[System.IO.File]::WriteAllText` + `UTF8Encoding($false)` y usando `[ordered]@{}` en los objetos de runtime — revalidado con un JSON de prueba (sin BOM, orden correcto, `json.load` sin errores).
   - Carpeta de prueba eliminada tras la validación.

## Decisiones tomadas (y por qué)

- **Se mantienen los DOS JDK (11 y 17), no sobra el 17**: la extensión de Java de VSCode (Red Hat, `redhat.java` / Extension Pack for Java) requiere **JDK 17+ para ejecutar el propio Language Server**, independientemente de la versión con la que se compile el proyecto. Plan: JDK 17 → runtime del Language Server (`java.jdt.ls.java.home`); JDK 11 → JDK del proyecto (compilación/ejecución, `JAVA_HOME`, `maven-compiler-plugin` source/target=11).
- `ojdbc7-12.1.0.2.jar` se deja tal cual: funciona bien con Java 11 aunque esté pensado originalmente para JDK 7. Cambiar a `ojdbc8` es opcional, no bloqueante.

## Pendiente (próximos pasos, aún no hecho)

- [x] ~~Modo portable de VSCode~~ → hecho, ver arriba.
- [x] ~~Instalar extensiones de VSCode~~ → hecho, ver tabla arriba (`vscode-java-pack`, `vscode-xml`, `vscode-tomcat`, `oracle.sql-developer`).
- [x] ~~Configurar rutas de JDK/Maven en `settings.json`~~ → hecho, ver sección anterior.
- [ ] **Añadir el servidor Tomcat en la UI** (paso manual, no scriptable): abrir VSCode → panel "Tomcat" → botón "+" / comando "Tomcat: Add Server" → seleccionar `Complementos/apache-tomcat-9.0.120`.
- [ ] **Crear la conexión Oracle en la UI** de `oracle.sql-developer` (paso manual): faltan datos reales — host, puerto, service name/SID y usuario de la base de datos.
- [ ] **Probar en caliente** que VSCode arranca bien con el `settings.json` nuevo (abrir la app, comprobar que el Language Server de Java carga sin errores y que "Java Projects" ve los dos runtimes). No se pudo verificar en esta sesión por falta de entorno gráfico.
- [x] ~~Instalar Eclipse Keymap y SVN SCM~~ → hecho.
- [x] ~~Crear `setenv.bat` con `JAVA_HOME` fijo~~ → hecho.
- [ ] **Todo lo que requiere datos confidenciales del usuario o pasos de UI** (cliente SVN portable, checkout de las 2 librerías, `sourcePaths` del debugger, puerto/timeout de `server.xml`, VM Arguments reales en `setenv.bat`, alta del servidor Tomcat, conexión Oracle) → ver **[INSTRUCCIONES-PENDIENTES.md](INSTRUCCIONES-PENDIENTES.md)**, que tiene el detalle paso a paso y un checklist.
- [ ] **Crear `pom.xml`** del proyecto con:
  - JSF (Mojarra o MyFaces) + PrimeFaces (elegir versión compatible con Java 11 / Servlet 4.0 de Tomcat 9).
  - `javax.servlet-api` con `scope=provided` (la da Tomcat 9).
  - Lombok como dependencia + procesador de anotaciones.
  - `ojdbc7` como dependencia — **no está en Maven Central**, hay que instalarlo en el repo local (`mvn install:install-file ...`) o en un repositorio interno.
- [ ] **Decidir** si `ojdbc7.jar` va también en `Complementos/apache-tomcat-9.0.120/lib/` (si se usará un DataSource JNDI gestionado por el contenedor) o solo como dependencia empaquetada en el WAR (si la conexión la gestiona la propia app).
- [ ] Definir cómo se compilará y desplegará el `.war` generado por Maven hacia el Tomcat de `Complementos/`.

## Rutas clave (para copiar/pegar en configuración)

- `JAVA_HOME` (proyecto, Java 11): `Complementos/openjdk-11.0.32+9`
- JDK para Language Server (17): `Complementos/openjdk-17.0.20+8`
- `M2_HOME` / Maven: `Complementos/apache-maven-3.8.1`
- `CATALINA_HOME` / Tomcat: `Complementos/apache-tomcat-9.0.120`
