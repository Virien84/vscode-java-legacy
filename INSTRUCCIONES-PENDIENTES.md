# Instrucciones pendientes

> Última actualización: 2026-10-13

Pasos que solo puede completar quien usa el paquete: necesitan datos que no pueden venir predefinidos (URLs de repositorios, credenciales, valores específicos de cada despliegue) o son acciones interactivas dentro de la UI de VSCode.

Ver también: [INSTALACION.md](INSTALACION.md) (montar el entorno) · [MANUAL-DE-USO.md](MANUAL-DE-USO.md) (día a día).

---

## 1. Cliente SVN portable (máxima portabilidad)

Ya está instalada la extensión **`johnstoncode.svn-scm`**. Le falta el binario `svn.exe`: no viene incluido en el paquete porque implica elegir y ejecutar un instalador de terceros.

### Si ya tienes TortoiseSVN instalado con "command line client tools"

No hace falta descargar nada: la extensión puede usar el `svn.exe` que trae TortoiseSVN.

1. Comprueba que el `svn.exe` está ahí. Desde una terminal:
   ```
   "C:\Program Files\TortoiseSVN\bin\svn.exe" --version --quiet
   ```
   Debe mostrar un número de versión (p. ej. `1.14.x`). Si TortoiseSVN está instalado en otra ruta, usa esa ruta aquí y en el paso siguiente.
2. Añade en `settings.json` (`VSCode-win32-x64-1.141.0\data\user-data\User\settings.json`):
   ```json
   "svn.path": "C:\\Program Files\\TortoiseSVN\\bin\\svn.exe"
   ```
   La extensión también lo encontraría sola a través del `PATH` (el instalador de TortoiseSVN añade su carpeta `bin`), pero fijar `svn.path` evita que coja otro `svn.exe` distinto que pueda haber en el sistema.
3. Reinicia VSCode. Las carpetas con checkout SVN deberían aparecer en el panel de control de código fuente.

**Ten en cuenta**:
- Esta opción **no es portable**: depende de que TortoiseSVN esté instalado en esa máquina. En un PC sin él, usa el cliente portable de abajo.
- TortoiseSVN y la extensión trabajan sobre las mismas copias de trabajo (`.svn`), así que puedes usar indistintamente el menú contextual de TortoiseSVN en el Explorador de Windows o la extensión de VSCode.

### Si no tienes un `svn.exe` disponible: cliente SVN portable

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

**Alternativa** (menos portable, más rápida): completar la instalación de TortoiseSVN marcando "command line client tools" y seguir el apartado anterior.

## 2. Traer las 2 librerías desde SVN

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

## 3. Que el debugger pueda hacer "step into" en el código de esas librerías

1. Localiza, dentro de cada checkout, la carpeta raíz del código fuente Java (normalmente algo como `src/main/java`, puede variar según cómo esté organizada cada librería).
2. Añade en `settings.json`:
   ```json
   "java.debug.settings.sourcePaths": [
       "<<ruta-completa>>\\Complementos\\svn-libs\\<<nombre-libreria-1>>\\<<subcarpeta-src-real>>",
       "<<ruta-completa>>\\Complementos\\svn-libs\\<<nombre-libreria-2>>\\<<subcarpeta-src-real>>"
   ]
   ```
3. Si el proyecto usa las librerías como `.jar` compilado (vía Maven), comprueba que la versión del `.jar` en el repositorio Maven local coincide con la versión del código fuente bajado de SVN — si no coinciden, el step-into puede desalinearse (mostrar la línea equivocada).

## 4. Sustituir el XML de formateo por el real del proyecto

El repo trae `formatter/formatter.xml` como **placeholder mínimo** (solo tabulación). Para usar las reglas de formateo reales del proyecto/equipo:

1. Exporta el perfil desde Eclipse: **Preferences > Java > Code Style > Formatter > Export...** (o pide el XML a quien lo tenga).
2. Sustituye el contenido de `formatter/formatter.xml` por ese XML.
3. Abre el fichero exportado y comprueba el atributo `name` del `<profile>` — si no es exactamente `ProyectoDefault`, o bien renómbralo a `ProyectoDefault`, o bien actualiza `java.format.settings.profile` en `settings.json` para que coincida con el nombre real.
4. No hace falta reiniciar VSCode necesariamente, pero si el formateo no coge los cambios, reinícialo.

## 5. Parámetros del servidor Tomcat (puerto, timeout, VM Arguments)

**Puerto y timeout** — archivo `Complementos\apache-tomcat-9.0.123\conf\server.xml`, línea ~71:
```xml
<Connector port="8080" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443"
           maxParameterCount="1000"
           />
```
Cambia `port="8080"` y `connectionTimeout="20000"` (milisegundos) por los valores que necesites. El connector HTTPS equivalente está en la línea ~93.

**VM Arguments** — ya existe `Complementos\apache-tomcat-9.0.123\bin\setenv.bat` con `JAVA_HOME` fijado y ejemplos comentados de memoria y de debug remoto (usado en el punto 2 de [MANUAL-DE-USO.md](MANUAL-DE-USO.md)). Descoméntalos y ajusta los valores según necesites.

**Alternativa por UI**: la extensión `adashen.vscode-tomcat` tiene el comando **"Customize JVM Options"** una vez añadido el servidor (punto 6). Con usar una de las dos formas basta, no hace falta duplicarlo.

## 6. Añadir el servidor Tomcat en la extensión

1. Abre VSCode.
2. Panel "Tomcat" en la barra lateral → botón "+" (o paleta de comandos → "Tomcat: Add Server").
3. Selecciona la carpeta `Complementos\apache-tomcat-9.0.123`.

## 7. Conexión Oracle en la extensión `oracle.sql-developer`

1. Abre el panel de la extensión (Database Explorer / icono de Oracle en la barra lateral).
2. Crea una nueva conexión con tus datos reales (host, puerto, service name/SID, usuario, contraseña) — quedan guardados localmente por la extensión.
3. El driver `Complementos\ojdbc7-12.1.0.2.jar` es para que lo use la aplicación Java (vía Maven); esta extensión trae su propio driver interno, no hace falta indicárselo.

## Checklist

- [ ] `svn.path` en `settings.json` apuntando al `svn.exe` de TortoiseSVN o al copiado en `Complementos\svn\bin\svn.exe`
- [ ] 2 librerías descargadas en `Complementos\svn-libs\...`
- [ ] `java.debug.settings.sourcePaths` apuntando a los fuentes reales
- [ ] `formatter/formatter.xml` sustituido por el XML real del proyecto (y `java.format.settings.profile` ajustado si el nombre del perfil no es `ProyectoDefault`)
- [ ] Puerto/timeout ajustados en `server.xml`
- [ ] VM Arguments descomentados/ajustados en `setenv.bat`
- [ ] Servidor Tomcat añadido en el panel de la extensión
- [ ] Conexión Oracle creada en `oracle.sql-developer`
- [ ] (si se ha movido el paquete de sitio) rutas de JDK/Maven actualizadas — ver [INSTALACION.md](INSTALACION.md), sección 2
