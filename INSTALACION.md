# Instalación

> Última actualización: 2026-10-13

Cómo montar todo el entorno con un solo script (esto es lo que hace cualquiera que clone el repositorio), y cómo reubicarlo si cambias de carpeta, usuario o máquina.

Ver también: [MANUAL-DE-USO.md](MANUAL-DE-USO.md) (día a día) · [INSTRUCCIONES-PENDIENTES.md](INSTRUCCIONES-PENDIENTES.md) (pasos que necesitan tus propios datos).

---

## 1. Instalación desde cero

El repositorio **no lleva los binarios** (VSCode, los 2 JDK, Tomcat, Maven pesan ~2.5 GB en total, incompatible con git). En su lugar trae **`setup.ps1`**, que los descarga de sus fuentes oficiales (Microsoft, Eclipse Adoptium, Apache), verifica su checksum, los coloca en la estructura de carpetas correcta, instala las extensiones de VSCode y genera `settings.json`/`setenv.bat` con las rutas absolutas de tu máquina.

```powershell
.\setup.ps1
```

- Todas las versiones están fijadas (no "latest") para que el resultado sea reproducible: VSCode 1.141.0, OpenJDK 11.0.32.1+1 y 17.0.20.1+1 (Temurin), Tomcat 9.0.123, Maven 3.10.0.
- Si un componente ya existe (por ejemplo, lo ejecutas una segunda vez), se omite. Usa `.\setup.ps1 -Force` para forzar que lo vuelva a descargar todo.
- Requiere conexión a internet la primera vez. Tarda varios minutos (descarga en total varios cientos de MB).
- Al terminar, ya tienes todo listo para el [manual de uso](MANUAL-DE-USO.md) y solo quedan los [pasos pendientes](INSTRUCCIONES-PENDIENTES.md) (los que necesitan tus propios datos: SVN, Oracle, etc.).

> Si mueves la carpeta del proyecto de sitio después de ejecutar el script, basta con volver a ejecutar `.\setup.ps1` en la nueva ubicación (verá que los componentes ya existen y solo regenerará `settings.json`/`setenv.bat` con las rutas nuevas) — no hace falta editar los ficheros a mano como se describe en la sección 2.

---

## 2. Cambiar las rutas a mano (otra carpeta, otro usuario u otra máquina)

> Si instalaste todo con `.\setup.ps1` (sección 1), lo normal es que **no necesites esta sección**: si mueves la carpeta, basta con volver a ejecutar el script en el sitio nuevo y regenera `settings.json`/`setenv.bat` solo. Esta sección sirve como referencia manual (por ejemplo, si prefieres editar los ficheros tú mismo, o usar JDK ya instalados en vez de los del script).

Este paquete usa **rutas absolutas** en varios ficheros de configuración, apuntando a la ubicación donde se instaló. Si mueves/clonas el paquete a otro sitio (otra unidad, otro usuario, otro PC) sin volver a ejecutar el script, o si prefieres usar unos JDK que ya tengas instalados en vez de los incluidos, hay que actualizar estas rutas a mano:

| Fichero | Qué contiene / qué cambiar |
|---|---|
| `VSCode-win32-x64-1.141.0\data\user-data\User\settings.json` | `java.configuration.runtimes[0].path` (JDK 11), `java.configuration.runtimes[1].path` (JDK 17), `java.jdt.ls.java.home` (JDK 17), `maven.executable.path` |
| `Complementos\apache-tomcat-9.0.123\bin\setenv.bat` | `JAVA_HOME` |
| `settings.json` (si ya configuraste el [cliente SVN](INSTRUCCIONES-PENDIENTES.md#1-cliente-svn-portable-máxima-portabilidad)) | `svn.path` |
| `settings.json` (si ya configuraste el [step into en las librerías](INSTRUCCIONES-PENDIENTES.md#3-que-el-debugger-pueda-hacer-step-into-en-el-código-de-esas-librerías)) | `java.debug.settings.sourcePaths` |
| `settings.json` | `java.format.settings.url` (ruta a `formatter/formatter.xml`) |

**Pasos**:

1. Copia/clona todo el paquete a la ubicación nueva.
2. Anota la ruta absoluta completa de la nueva ubicación (ej. `D:\Herramientas\MiProyecto`).
3. Abre cada fichero de la tabla y sustituye la ruta antigua por la nueva completa. Recuerda: en `settings.json` (JSON) las barras van dobles (`\\`); en los `.bat` van simples (`\`).
4. Si en vez de los JDK incluidos en `Complementos\` quieres usar unos ya instalados en tu sistema, simplemente pon ahí la ruta a esos JDK (p. ej. `C:\Program Files\Eclipse Adoptium\jdk-11.0.32.9-hotspot`) en lugar de `Complementos\openjdk-...`. Eso sí: para el Language Server (`java.jdt.ls.java.home`) sigue haciendo falta un JDK **17 o superior**, y para compilar/ejecutar el proyecto uno **11** (ver [ESTADO-SETUP.md](ESTADO-SETUP.md) para el porqué de usar dos JDK distintos).
5. Reinicia VSCode para que recargue la configuración.
