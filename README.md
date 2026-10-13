# VSCode Portable — Stack Java 11 + Tomcat 9 + Maven + Oracle + PrimeFaces

Entorno de desarrollo **portable y autocontenido** para trabajar con un stack legacy: **Java 11 · Apache Tomcat 9 · Maven · Oracle SQL · JSF/XHTML + PrimeFaces**, montado sobre una copia portable de Visual Studio Code.

Todo vive dentro de esta misma carpeta (modo portable de VSCode: configuración y extensiones incluidas) — no toca el registro de Windows ni ninguna instalación de VSCode que ya tengas en el sistema.

## Instalación rápida

```powershell
git clone https://github.com/Virien84/vscode-java-legacy.git
cd vscode-java-legacy
.\setup.ps1
```

`setup.ps1` descarga, de sus fuentes oficiales y con checksum verificado:

- VSCode 1.141.0 portable (win32-x64)
- OpenJDK 11.0.32.1+1 y OpenJDK 17.0.20.1+1 (Eclipse Temurin)
- Apache Tomcat 9.0.123
- Apache Maven 3.10.0

E instala las extensiones de VSCode necesarias (ver tabla más abajo). Al terminar, genera `settings.json` y `setenv.bat` con las rutas absolutas de tu propia máquina.

**Por qué un script y no los binarios directamente**: el conjunto completo pesa unos 2.5 GB, incompatible con un repositorio git normal. El repo en sí pesa unos pocos MB; `setup.ps1` monta el resto en tu equipo.

**Requisitos**: Windows, PowerShell 5.1 o superior, conexión a internet (solo hace falta la primera vez que se ejecuta el script).

Si ya lo tenías instalado y quieres rehacerlo desde cero: `.\setup.ps1 -Force`.

## Qué hay en el repositorio

```
├── setup.ps1                     # instala/reinstala todo el entorno
├── Complementos/
│   ├── lombok-1.18.48.jar
│   └── ojdbc7-12.1.0.2.jar        # driver JDBC de Oracle
├── ESTADO-SETUP.md                # historial y decisiones de la configuración
├── INSTALACION.md                 # instalación con setup.ps1 + reubicar rutas a mano
├── MANUAL-DE-USO.md               # día a día: Tomcat, debug, tests, formateo
└── INSTRUCCIONES-PENDIENTES.md    # pasos pendientes de cada usuario (con sus propios datos)
```

Tras ejecutar `setup.ps1` aparecen además `VSCode-win32-x64-.../` y el resto de `Complementos/` (los JDK, Tomcat, Maven) — están en `.gitignore`, no se versionan.

## Uso

- **[MANUAL-DE-USO.md](MANUAL-DE-USO.md)** — el día a día: arrancar y parar Tomcat, modo debug (adjuntar VSCode por JDWP), ejecutar los tests, formateo al guardar.
- **[INSTALACION.md](INSTALACION.md)** — detalles de `setup.ps1` y qué tocar si mueves la carpeta a otra máquina o usuario.
- **[INSTRUCCIONES-PENDIENTES.md](INSTRUCCIONES-PENDIENTES.md)** — los pasos que cada usuario debe completar con sus propios datos (no vienen preconfigurados a propósito): cliente SVN portable + las librerías de tus repos SVN, conexión a tu Oracle, puerto/timeout del servidor, alta del servidor Tomcat en la UI de la extensión.

Para el porqué de cada decisión de la configuración (por ejemplo, por qué hay dos JDK distintos) — **[ESTADO-SETUP.md](ESTADO-SETUP.md)**.

## Stack

| Componente | Versión |
|---|---|
| VSCode | 1.141.0 (portable) |
| OpenJDK — proyecto (compilación/ejecución) | 11.0.32.1+1 (Eclipse Temurin) |
| OpenJDK — Language Server de Java | 17.0.20.1+1 (Eclipse Temurin) |
| Apache Tomcat | 9.0.123 |
| Maven | 3.10.0 |
| Lombok | 1.18.48 |
| Driver JDBC Oracle | ojdbc7 12.1.0.2 |

## Extensiones de VSCode instaladas

| Extensión | Para qué |
|---|---|
| `vscjava.vscode-java-pack` | Extension Pack for Java (Language Support, Debugger, Maven, Test Runner, Project Manager) |
| `redhat.vscode-xml` | Soporte XML/XHTML (vistas de PrimeFaces) |
| `adashen.vscode-tomcat` | Gestionar/arrancar/depurar Tomcat desde VSCode |
| `oracle.sql-developer` | Cliente oficial de Oracle para consultar la base de datos |
| `johnstoncode.svn-scm` | Control de versiones SVN (para las librerías que viven fuera de Git) |
| `alphabotsec.vscode-eclipse-keybindings` | Atajos de teclado estilo Eclipse |
