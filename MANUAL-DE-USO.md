# Manual de uso

> Última actualización: 2026-10-13

Cómo arrancar/parar el servidor, cómo depurar, cómo ejecutar los tests y cómo funciona el formateo. Válido para cualquiera que use este paquete, no solo para quien lo montó.

Ver también: [INSTALACION.md](INSTALACION.md) (montar el entorno) · [INSTRUCCIONES-PENDIENTES.md](INSTRUCCIONES-PENDIENTES.md) (pasos que necesitan tus propios datos).

---

## 1. Arrancar el servidor Tomcat (modo normal)

**Opción A — recomendada, integrada en VSCode** (requiere haber añadido el servidor, ver [Añadir el servidor Tomcat en la extensión](INSTRUCCIONES-PENDIENTES.md#6-añadir-el-servidor-tomcat-en-la-extensión)):

1. Abre la carpeta del proyecto Maven en VSCode (la que tiene el `pom.xml`).
2. En el explorador de archivos, clic derecho sobre el proyecto → **"Run on Server"** (extensión `adashen.vscode-tomcat`).
3. Elige el servidor Tomcat que hayas añadido. La extensión empaqueta el proyecto (`mvn package`) y lo despliega automáticamente; al terminar abre el navegador.

**Opción B — manual, sin la extensión**:

1. Empaqueta el proyecto:
   ```
   Complementos\apache-maven-3.10.0\bin\mvn.cmd clean package
   ```
   (ejecutado desde la carpeta raíz del proyecto, donde está el `pom.xml`). Esto genera un `.war` en `target\`.
2. Copia ese `.war` a `Complementos\apache-tomcat-9.0.123\webapps\`.
3. Arranca Tomcat:
   ```
   Complementos\apache-tomcat-9.0.123\bin\startup.bat
   ```
4. Espera en la consola el mensaje `Server startup in [n] milliseconds`.
5. Abre `http://localhost:8080/<nombre-del-war>/` en el navegador (el puerto es el configurado en `server.xml`, ver [Parámetros del servidor Tomcat](INSTRUCCIONES-PENDIENTES.md#5-parámetros-del-servidor-tomcat-puerto-timeout-vm-arguments)).

## 2. Arrancar en modo debug (para poner breakpoints)

**Opción A — recomendada**: clic derecho sobre el proyecto → **"Debug on Server"**. La extensión arranca Tomcat con el puerto de depuración ya preparado y conecta VSCode automáticamente. Puedes poner breakpoints en tu propio código, y también en el de las librerías SVN si has configurado `java.debug.settings.sourcePaths` (ver [Step into en las librerías](INSTRUCCIONES-PENDIENTES.md#3-que-el-debugger-pueda-hacer-step-into-en-el-código-de-esas-librerías)).

**Opción B — manual**:

1. Abre `Complementos\apache-tomcat-9.0.123\bin\setenv.bat` y quita el `rem` de esta línea (ajusta el puerto si quieres otro):
   ```bat
   set "JAVA_OPTS=%JAVA_OPTS% -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000"
   ```
2. Arranca Tomcat normalmente (`startup.bat`, punto 1). Ahora queda escuchando conexiones de depuración en el puerto 8000.
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

## 3. Parar el servidor

Usa siempre:
```
Complementos\apache-tomcat-9.0.123\bin\shutdown.bat
```
(o el botón "Stop" del panel Tomcat de la extensión). Envía la señal de apagado limpio al puerto 8005. **No cierres la ventana de consola directamente** (con la X o `Ctrl+C` bruscamente) — puede dejar el proceso Java corriendo en segundo plano sin que se note.

## 4. Ejecutar las clases de test

**Opción A — recomendada, UI**: icono de "Testing" (matraz) en la barra lateral de VSCode (extensión `vscjava.vscode-java-test`). Lista automáticamente los tests JUnit/TestNG del proyecto:
- ▶ junto a un test o clase → lo ejecuta.
- icono de bug junto a un test → lo ejecuta en modo debug, con tus breakpoints activos.
- botón "Run All Tests" arriba del panel → ejecuta toda la suite.

**Opción B — línea de comandos**, desde la carpeta raíz del proyecto:
```
Complementos\apache-maven-3.10.0\bin\mvn.cmd test
```
Para un test concreto:
```
Complementos\apache-maven-3.10.0\bin\mvn.cmd test -Dtest=NombreDeLaClaseTest
```

> Si los tests son de integración (necesitan Tomcat y/o la base de datos Oracle arrancados), arráncalos primero (punto 1) antes de lanzar la suite.

## 5. Formateo de código al guardar

Cada vez que guardas un `.java` (`Ctrl+S`), VSCode automáticamente:
1. **Organiza los imports** (añade los que falten según el código, quita los que no se usan, los ordena).
2. **Aplica el formato** definido en `formatter/formatter.xml` (perfil `ProyectoDefault`) — el mismo fichero de reglas de formateo estilo Eclipse que usa el resto del equipo.

No hay que hacer nada manualmente ni ejecutar ningún comando — es automático al guardar. Si quieres formatear un fichero sin guardar: paleta de comandos → "Format Document" (`Shift+Alt+F`). Si quieres organizar imports sin guardar: paleta de comandos → "Organize Imports" (`Shift+Alt+O`).

> El XML de formateo que trae el repo (`formatter/formatter.xml`) es un **placeholder mínimo** (ver [Sustituir el XML de formateo](INSTRUCCIONES-PENDIENTES.md#4-sustituir-el-xml-de-formateo-por-el-real-del-proyecto)) — hasta que se sustituya por el real del proyecto, solo fija la tabulación (espacios, tamaño 4) y el resto de reglas usan los valores por defecto de Eclipse/JDT.
