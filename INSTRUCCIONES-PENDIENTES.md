# Manual de uso e instrucciones pendientes

> Última actualización: 2026-07-31

Este documento tiene tres partes:

0. **Instalación desde cero** — cómo montar todo el entorno con un solo script (esto es lo que descarga cualquiera que clone el repositorio).
1. **Manual de uso** — cómo arrancar/parar el servidor, cómo depurar, cómo ejecutar los tests. Válido para cualquiera que use este paquete, no solo para quien lo montó.
2. **Instrucciones pendientes** — pasos de configuración que solo puede completar quien usa el paquete, porque necesitan datos propios (URLs de repositorios, credenciales, rutas de su máquina) o son acciones interactivas en la UI de VSCode.

---

## 0. Instalación desde cero

El repositorio **no lleva los binarios** (VSCode, los 2 JDK, Tomcat, Maven pesan ~2.5 GB en total, incompatible con git). En su lugar trae **`setup.ps1`**, que los descarga de sus fuentes oficiales (Microsoft, Eclipse Adoptium, Apache), verifica su checksum, los coloca en la estructura de carpetas correcta, instala las extensiones de VSCode y genera `settings.json`/`setenv.bat` con las rutas absolutas de tu máquina.

```powershell
.\setup.ps1
```

- Todas las versiones están fijadas (no "latest") para que el resultado sea reproducible: VSCode 1.131.0, OpenJDK 11.0.32+9 y 17.0.20+8 (Temurin), Tomcat 9.0.120, Maven 3.8.1.
- Si un componente ya existe (por ejemplo, lo ejecutas una segunda vez), se omite. Usa `.\setup.ps1 -Force` para forzar que lo vuelva a descargar todo.
- Requiere conexión a internet la primera vez. Tarda varios minutos (descarga en total varios cientos de MB).
- Al terminar, ya tienes todo listo para la sección 1 (Manual de uso) y solo quedan pendientes los pasos de la sección 2 (los que necesitan tus propios datos: SVN, Oracle, etc.).

> Si mueves la carpeta del proyecto de sitio después de ejecutar el script, basta con volver a ejecutar `.\setup.ps1` en la nueva ubicación (verá que los componentes ya existen y solo regenerará `settings.json`/`setenv.bat` con las rutas nuevas) — ya no hace falta editar los ficheros a mano como se describía antes en la sección 2.

---

## 1. Manual de uso

### 1.1 Arrancar el servidor Tomcat (modo normal)

**Opción A — recomendada, integrada en VSCode** (requiere haber añadido el servidor, ver [5](#5-añadir-el-servidor-tomcat-en-la-extensión-paso-interactivo)):

1. Abre la carpeta del proyecto Maven en VSCode (la que tiene el `pom.xml`).
2. En el explorador de archivos, clic derecho sobre el proyecto → **"Run on Server"** (extensión `adashen.vscode-tomcat`).
3. Elige el servidor Tomcat que hayas añadido. La extensión empaqueta el proyecto (`mvn package`) y lo despliega automáticamente; al terminar abre el navegador.

**Opción B — manual, sin la extensión**:

1. Empaqueta el proyecto:
   ```
   Complementos\apache-maven-3.8.1\bin\mvn.cmd clean package
   ```
   (ejecutado desde la carpeta raíz del proyecto, donde está el `pom.xml`). Esto genera un `.war` en `target\`.
2. Copia ese `.war` a `Complementos\apache-tomcat-9.0.120\webapps\`.
3. Arranca Tomcat:
   ```
   Complementos\apache-tomcat-9.0.120\bin\startup.bat
   ```
4. Espera en la consola el mensaje `Server startup in [n] milliseconds`.
5. Abre `http://localhost:8080/<nombre-del-war>/` en el navegador (el puerto es el configurado en `server.xml`, ver [4.1](#41-puerto-y-timeout)).

### 1.2 Arrancar en modo debug (para poner breakpoints)

**Opción A — recomendada**: clic derecho sobre el proyecto → **"Debug on Server"**. La extensión arranca Tomcat con el puerto de depuración ya preparado y conecta VSCode automáticamente. Puedes poner breakpoints en tu propio código, y también en el de las librerías SVN si has configurado `java.debug.settings.sourcePaths` (ver [2](#2-traer-las-2-librerías-desde-svn) más abajo).

**Opción B — manual**:

1. Abre `Complementos\apache-tomcat-9.0.120\bin\setenv.bat` y quita el `rem` de esta línea (ajusta el puerto si quieres otro):
   ```bat
   set "JAVA_OPTS=%JAVA_OPTS% -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000"
   ```
2. Arranca Tomcat normalmente (`startup.bat`, punto 1.1). Ahora queda escuchando conexiones de depuración en el puerto 8000.
3. En la carpeta del proyecto crea/edita `.vscode\launch.json`:
   ```json
   {
       "version": "0.2.0",
       "configurations": [
           {
               "type": "java",
               "name": "Attach a Tomcat (8000)",
               "request": "attach",
               "hostName": "localhost",
               "port": 8000
           }
       ]
   }
   ```
4. Pon tus breakpoints, abre "Run and Debug" (`Ctrl+Shift+D`), elige **"Attach a Tomcat (8000)"** y pulsa ▶.

### 1.3 Parar el servidor

Usa siempre:
```
Complementos\apache-tomcat-9.0.120\bin\shutdown.bat
```
(o el botón "Stop" del panel Tomcat de la extensión). Envía la señal de apagado limpio al puerto 8005. **No cierres la ventana de consola directamente** (con la X o `Ctrl+C` bruscamente) — puede dejar el proceso Java corriendo en segundo plano sin que se note.

### 1.4 Ejecutar las clases de test

**Opción A — recomendada, UI**: icono de "Testing" (matraz) en la barra lateral de VSCode (extensión `vscjava.vscode-java-test`). Lista automáticamente los tests JUnit/TestNG del proyecto:
- ▶ junto a un test o clase → lo ejecuta.
- icono de bug junto a un test → lo ejecuta en modo debug, con tus breakpoints activos.
- botón "Run All Tests" arriba del panel → ejecuta toda la suite.

**Opción B — línea de comandos**, desde la carpeta raíz del proyecto:
```
Complementos\apache-maven-3.8.1\bin\mvn.cmd test
```
Para un test concreto:
```
Complementos\apache-maven-3.8.1\bin\mvn.cmd test -Dtest=NombreDeLaClaseTest
```

> Si los tests son de integración (necesitan Tomcat y/o la base de datos Oracle arrancados), arráncalos primero (punto 1.1) antes de lanzar la suite.

### 1.5 Formateo de código al guardar

Cada vez que guardas un `.java` (`Ctrl+S`), VSCode automáticamente:
1. **Organiza los imports** (añade los que falten según el código, quita los que no se usan, los ordena).
2. **Aplica el formato** definido en `formatter/formatter.xml` (perfil `ProyectoDefault`) — el mismo fichero de reglas de formateo estilo Eclipse que usa el resto del equipo.

No hay que hacer nada manualmente ni ejecutar ningún comando — es automático al guardar. Si quieres formatear un fichero sin guardar: paleta de comandos → "Format Document" (`Shift+Alt+F`). Si quieres organizar imports sin guardar: paleta de comandos → "Organize Imports" (`Shift+Alt+O`).

> El XML de formateo que trae el repo (`formatter/formatter.xml`) es un **placeholder mínimo** (ver sección 3) — hasta que se sustituya por el real del proyecto, solo fija la tabulación (espacios, tamaño 4) y el resto de reglas usan los valores por defecto de Eclipse/JDT.

---

## 2. Cambiar las rutas si usas otra carpeta, otro usuario u otra máquina

> Si instalaste todo con `.\setup.ps1` (sección 0), lo normal es que **no necesites esta sección**: si mueves la carpeta, basta con volver a ejecutar el script en el sitio nuevo y regenera `settings.json`/`setenv.bat` solo. Esta sección sirve como referencia manual (por ejemplo, si prefieres editar los ficheros tú mismo, o usar JDK ya instalados en vez de los del script).

Este paquete usa **rutas absolutas** en varios ficheros de configuración, apuntando a la ubicación donde se instaló. Si mueves/clonas el paquete a otro sitio (otra unidad, otro usuario, otro PC) sin volver a ejecutar el script, o si prefieres usar unos JDK que ya tengas instalados en vez de los incluidos, hay que actualizar estas rutas a mano:

| Fichero | Qué contiene / qué cambiar |
|---|---|
| `VSCode-win32-x64-1.131.0\data\user-data\User\settings.json` | `java.configuration.runtimes[0].path` (JDK 11), `java.configuration.runtimes[1].path` (JDK 17), `java.jdt.ls.java.home` (JDK 17), `maven.executable.path` |
| `Complementos\apache-tomcat-9.0.120\bin\setenv.bat` | `JAVA_HOME` |
| `settings.json` (si ya configuraste el punto 1 de la sección siguiente) | `svn.path` |
| `settings.json` (si ya configuraste el punto 3 de la sección siguiente) | `java.debug.settings.sourcePaths` |
| `settings.json` | `java.format.settings.url` (ruta a `formatter/formatter.xml`) |

**Pasos**:

1. Copia/clona todo el paquete a la ubicación nueva.
2. Anota la ruta absoluta completa de la nueva ubicación (ej. `D:\Herramientas\MiProyecto`).
3. Abre cada fichero de la tabla y sustituye la ruta antigua por la nueva completa. Recuerda: en `settings.json` (JSON) las barras van dobles (`\\`); en los `.bat` van simples (`\`).
4. Si en vez de los JDK incluidos en `Complementos\` quieres usar unos ya instalados en tu sistema, simplemente pon ahí la ruta a esos JDK (p. ej. `C:\Program Files\Eclipse Adoptium\jdk-11.0.32.9-hotspot`) en lugar de `Complementos\openjdk-...`. Eso sí: para el Language Server (`java.jdt.ls.java.home`) sigue haciendo falta un JDK **17 o superior**, y para compilar/ejecutar el proyecto uno **11** (ver [ESTADO-SETUP.md](ESTADO-SETUP.md) para el porqué de usar dos JDK distintos).
5. Reinicia VSCode para que recargue la configuración.

---

## 3. Instrucciones pendientes — pasos que solo puede completar quien usa el paquete

Estos pasos necesitan datos que no pueden venir predefinidos en el paquete (URLs de repositorios, credenciales, valores específicos de cada despliegue) o son acciones interactivas dentro de la UI de VSCode.

### 3.1 Cliente SVN portable (máxima portabilidad)

Ya está instalada la extensión **`johnstoncode.svn-scm`**. Le falta el binario `svn.exe`: no viene incluido en el paquete porque implica elegir y ejecutar un instalador de terceros.

Si tienes TortoiseSVN instalado pero sin el componente "command line client tools" (el caso más común), para máxima portabilidad **no** actives ese componente a nivel de sistema — mejor trae un `svn.exe` autocontenido:

1. Descarga un cliente SVN para Windows x64 (tú eliges la fuente/versión, por ejemplo SlikSVN u otra que prefieras).
2. Copia únicamente el ejecutable `svn.exe` (y las DLLs que pida si las necesita) a:
   ```
   Complementos\svn\bin\svn.exe
   ```
3. Añade en `settings.json`:
   ```json
   "svn.path": "<<ruta-completa-a>>\\Complementos\\svn\\bin\\svn.exe"
   ```
4. Comprueba que funciona: `"Complementos\svn\bin\svn.exe" --version` desde una terminal.

**Alternativa** (menos portable, más rápida): completar la instalación de TortoiseSVN marcando "command line client tools", y apuntar `svn.path` a `C:\Program Files\TortoiseSVN\bin\svn.exe`.

### 3.2 Traer las 2 librerías desde SVN

1. Recomendado, para mantenerlo autocontenido:
   ```
   Complementos\svn-libs\<<nombre-libreria-1>>
   Complementos\svn-libs\<<nombre-libreria-2>>
   ```
2. Desde una terminal:
   ```
   svn checkout <<URL_REPO_LIBRERIA_1>> "Complementos\svn-libs\<<nombre-libreria-1>>"
   svn checkout <<URL_REPO_LIBRERIA_2>> "Complementos\svn-libs\<<nombre-libreria-2>>"
   ```
3. La extensión `svn-scm` detecta automáticamente cualquier subcarpeta con `.svn` dentro del workspace abierto — no hace falta configuración extra para que aparezca en el panel de control de código fuente.

### 3.3 Que el debugger pueda hacer "step into" en el código de esas librerías

1. Localiza, dentro de cada checkout, la carpeta raíz del código fuente Java (normalmente algo como `src/main/java`, puede variar según cómo esté organizada cada librería).
2. Añade en `settings.json`:
   ```json
   "java.debug.settings.sourcePaths": [
       "<<ruta-completa>>\\Complementos\\svn-libs\\<<nombre-libreria-1>>\\<<subcarpeta-src-real>>",
       "<<ruta-completa>>\\Complementos\\svn-libs\\<<nombre-libreria-2>>\\<<subcarpeta-src-real>>"
   ]
   ```
3. Si el proyecto usa las librerías como `.jar` compilado (vía Maven), comprueba que la versión del `.jar` en el repositorio Maven local coincide con la versión del código fuente bajado de SVN — si no coinciden, el step-into puede desalinearse (mostrar la línea equivocada).

### 3.4 Sustituir el XML de formateo por el real del proyecto

El repo trae `formatter/formatter.xml` como **placeholder mínimo** (solo tabulación). Para usar las reglas de formateo reales del proyecto/equipo:

1. Exporta el perfil desde Eclipse: **Preferences > Java > Code Style > Formatter > Export...** (o pide el XML a quien lo tenga).
2. Sustituye el contenido de `formatter/formatter.xml` por ese XML.
3. Abre el fichero exportado y comprueba el atributo `name` del `<profile>` — si no es exactamente `ProyectoDefault`, o bien renómbralo a `ProyectoDefault`, o bien actualiza `java.format.settings.profile` en `settings.json` para que coincida con el nombre real.
4. No hace falta reiniciar VSCode necesariamente, pero si el formateo no coge los cambios, reinícialo.

### 3.5 Parámetros del servidor Tomcat (puerto, timeout, VM Arguments)

**Puerto y timeout** — archivo `Complementos\apache-tomcat-9.0.120\conf\server.xml`, línea ~71:
```xml
<Connector port="8080" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443"
           maxParameterCount="1000"
           />
```
Cambia `port="8080"` y `connectionTimeout="20000"` (milisegundos) por los valores que necesites. El connector HTTPS equivalente está en la línea ~93.

**VM Arguments** — ya existe `Complementos\apache-tomcat-9.0.120\bin\setenv.bat` con `JAVA_HOME` fijado y ejemplos comentados de memoria y de debug remoto (usado en el punto 1.2). Descoméntalos y ajusta los valores según necesites.

**Alternativa por UI**: la extensión `adashen.vscode-tomcat` tiene el comando **"Customize JVM Options"** una vez añadido el servidor (punto 3.5). Con usar una de las dos formas basta, no hace falta duplicarlo.

### 3.6 Añadir el servidor Tomcat en la extensión

1. Abre VSCode.
2. Panel "Tomcat" en la barra lateral → botón "+" (o paleta de comandos → "Tomcat: Add Server").
3. Selecciona la carpeta `Complementos\apache-tomcat-9.0.120`.

### 3.7 Conexión Oracle en la extensión `oracle.sql-developer`

1. Abre el panel de la extensión (Database Explorer / icono de Oracle en la barra lateral).
2. Crea una nueva conexión con tus datos reales (host, puerto, service name/SID, usuario, contraseña) — quedan guardados localmente por la extensión.
3. El driver `Complementos\ojdbc7-12.1.0.2.jar` es para que lo use la aplicación Java (vía Maven); esta extensión trae su propio driver interno, no hace falta indicárselo.

### Checklist

- [ ] `svn.exe` copiado en `Complementos\svn\bin\svn.exe` y `svn.path` en `settings.json`
- [ ] 2 librerías descargadas en `Complementos\svn-libs\...`
- [ ] `java.debug.settings.sourcePaths` apuntando a los fuentes reales
- [ ] `formatter/formatter.xml` sustituido por el XML real del proyecto (y `java.format.settings.profile` ajustado si el nombre del perfil no es `ProyectoDefault`)
- [ ] Puerto/timeout ajustados en `server.xml`
- [ ] VM Arguments descomentados/ajustados en `setenv.bat`
- [ ] Servidor Tomcat añadido en el panel de la extensión
- [ ] Conexión Oracle creada en `oracle.sql-developer`
- [ ] (si se ha movido el paquete de sitio) rutas de JDK/Maven actualizadas — ver sección 2
