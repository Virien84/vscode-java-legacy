#Requires -Version 5.1
<#
.SYNOPSIS
    Descarga y monta desde cero el entorno portable: VSCode + OpenJDK 11 + OpenJDK 17 +
    Apache Tomcat 9 + Maven + extensiones de VSCode, todo dentro de esta misma carpeta.

.DESCRIPTION
    Pensado para poder tener este repositorio en Git sin llevar los binarios (serian
    varios GB). Cada componente se descarga de su fuente oficial, se verifica su
    checksum y se coloca en la ruta esperada por el resto de la configuracion
    (settings.json, setenv.bat), que se generan al final con las rutas absolutas
    reales de ESTA maquina.

.NOTES
    Todas las versiones estan fijadas (no "latest") para que el resultado sea
    reproducible. Si quieres actualizar alguna, cambia la variable correspondiente
    en la seccion "VERSIONES" y, si aplica, el checksum.

.EXAMPLE
    .\setup.ps1
#>

[CmdletBinding()]
param(
    # Vuelve a descargar y sobrescribe aunque el componente ya exista.
    [switch]$Force
)

$ErrorActionPreference = "Stop"
# Invoke-WebRequest en Windows PowerShell 5.1 renderiza una barra de progreso
# que ralentiza muchisimo (y a veces llega a abortar) las descargas grandes.
# Desactivarla es el workaround estandar.
$ProgressPreference = "SilentlyContinue"
$root = $PSScriptRoot
$complementos = Join-Path $root "Complementos"
$tmp = Join-Path $root "_setup_tmp"

# ---------------------------------------------------------------------------
# VERSIONES (fijadas para reproducibilidad; ver INSTRUCCIONES-PENDIENTES.md)
# ---------------------------------------------------------------------------
$vscodeVersion = "1.131.0"
$vscodeFolder  = "VSCode-win32-x64-$vscodeVersion"

$jdk11Release  = "jdk-11.0.32+9"
$jdk11Folder   = "openjdk-11.0.32+9"
$jdk11Sha256   = "c1a7c406b72fbbd30417d4b0fcf5cccd9318f15fd269f84fcece38d70b21e181"

$jdk17Release  = "jdk-17.0.20+8"
$jdk17Folder   = "openjdk-17.0.20+8"
$jdk17Sha256   = "418497be5cf585bdd2203d6486a565d66d3f5e992d5630d45104cb873fab8122"

$tomcatVersion = "9.0.120"
$tomcatFolder  = "apache-tomcat-$tomcatVersion"
$tomcatSha512  = "fca7cfbe8255b61fac0e474a9a7ac6fbaf2792c72061fda2666b26eb5ba60718adc4fc0cbd013f14a41f101bcd7f5b70b2d3eedc37554ff0db4bdb6e2e2898f6"

$mavenVersion  = "3.8.1"
$mavenFolder   = "apache-maven-$mavenVersion"
$mavenSha512   = "c585847bfbcf8647aeabfd3e8bf0ac3f67a037bd345545e274766f144c2b978b3457cbc3e31545e62c21ad69e732695de01ec96ea2580e5da67bd85df095c0f4"

# Extensiones validadas en la sesion original (mtxr.sqltools se probo y se
# descarto a proposito, no incluir).
$extensions = @(
    "vscjava.vscode-java-pack",
    "redhat.vscode-xml",
    "adashen.vscode-tomcat",
    "oracle.sql-developer",
    "alphabotsec.vscode-eclipse-keybindings",
    "johnstoncode.svn-scm"
)

# ---------------------------------------------------------------------------
# Funciones auxiliares
# ---------------------------------------------------------------------------
function Write-Step($msg) {
    Write-Host ""
    Write-Host "== $msg ==" -ForegroundColor Cyan
}

function Test-Hash($file, $expected, $algorithm) {
    $actual = (Get-FileHash -Path $file -Algorithm $algorithm).Hash
    if ($actual.ToLower() -ne $expected.ToLower()) {
        throw "Checksum $algorithm no coincide para $file`n  esperado: $expected`n  obtenido: $actual"
    }
    Write-Host "  checksum $algorithm OK"
}

function Get-FileFromUrl($url, $outFile) {
    Write-Host "  descargando $url"
    Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing
}

function Move-InnerFolderUp($extractedRoot, $innerName, $finalPath) {
    if (Test-Path $finalPath) { Remove-Item $finalPath -Recurse -Force }
    Move-Item (Join-Path $extractedRoot $innerName) $finalPath
}

# ---------------------------------------------------------------------------
# 0. Preparacion
# ---------------------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $complementos | Out-Null
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

# ---------------------------------------------------------------------------
# 1. VSCode portable
# ---------------------------------------------------------------------------
$vscodePath = Join-Path $root $vscodeFolder
if ((Test-Path $vscodePath) -and -not $Force) {
    Write-Step "VSCode ya existe en '$vscodeFolder', se omite (usa -Force para rehacer)"
} else {
    Write-Step "Descargando VSCode $vscodeVersion (win32-x64)"
    $zip = Join-Path $tmp "vscode.zip"
    Get-FileFromUrl "https://update.code.visualstudio.com/$vscodeVersion/win32-x64-archive/stable" $zip
    if (Test-Path $vscodePath) { Remove-Item $vscodePath -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $vscodePath | Out-Null
    Expand-Archive -Path $zip -DestinationPath $vscodePath -Force
    Remove-Item $zip
}

# Modo portable: VSCode detecta la carpeta "data" junto a Code.exe.
$dataPath = Join-Path $vscodePath "data"
New-Item -ItemType Directory -Force -Path $dataPath | Out-Null

# ---------------------------------------------------------------------------
# 2. OpenJDK 11 y 17 (Eclipse Temurin)
# ---------------------------------------------------------------------------
function Install-Jdk($release, $folder, $sha256) {
    $finalPath = Join-Path $complementos $folder
    if ((Test-Path $finalPath) -and -not $Force) {
        Write-Step "$folder ya existe, se omite (usa -Force para rehacer)"
        return
    }
    Write-Step "Descargando OpenJDK $release (Eclipse Temurin, Windows x64)"
    $encodedRelease = $release -replace '\+', '%2B'
    $zip = Join-Path $tmp "$release.zip".Replace("+", "")
    Get-FileFromUrl "https://api.adoptium.net/v3/binary/version/$encodedRelease/windows/x64/jdk/hotspot/normal/eclipse?project=jdk" $zip
    Test-Hash $zip $sha256 "SHA256"
    $extractDir = Join-Path $tmp "extract_$($folder)"
    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $extractDir -Force
    Move-InnerFolderUp $extractDir $release $finalPath
    Remove-Item $zip
    Remove-Item $extractDir -Recurse -Force
}

Install-Jdk $jdk11Release $jdk11Folder $jdk11Sha256
Install-Jdk $jdk17Release $jdk17Folder $jdk17Sha256

# ---------------------------------------------------------------------------
# 3. Apache Tomcat 9
# ---------------------------------------------------------------------------
$tomcatPath = Join-Path $complementos $tomcatFolder
if ((Test-Path $tomcatPath) -and -not $Force) {
    Write-Step "$tomcatFolder ya existe, se omite (usa -Force para rehacer)"
} else {
    Write-Step "Descargando Apache Tomcat $tomcatVersion"
    $zip = Join-Path $tmp "tomcat.zip"
    Get-FileFromUrl "https://archive.apache.org/dist/tomcat/tomcat-9/v$tomcatVersion/bin/apache-tomcat-$tomcatVersion.zip" $zip
    Test-Hash $zip $tomcatSha512 "SHA512"
    if (Test-Path $tomcatPath) { Remove-Item $tomcatPath -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $complementos -Force
    Remove-Item $zip
}

# ---------------------------------------------------------------------------
# 4. Maven
# ---------------------------------------------------------------------------
$mavenPath = Join-Path $complementos $mavenFolder
if ((Test-Path $mavenPath) -and -not $Force) {
    Write-Step "$mavenFolder ya existe, se omite (usa -Force para rehacer)"
} else {
    Write-Step "Descargando Apache Maven $mavenVersion"
    $zip = Join-Path $tmp "maven.zip"
    Get-FileFromUrl "https://archive.apache.org/dist/maven/maven-3/$mavenVersion/binaries/apache-maven-$mavenVersion-bin.zip" $zip
    Test-Hash $zip $mavenSha512 "SHA512"
    if (Test-Path $mavenPath) { Remove-Item $mavenPath -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $complementos -Force
    Remove-Item $zip
}

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
# 5. Extensiones de VSCode
# ---------------------------------------------------------------------------
Write-Step "Instalando extensiones de VSCode"
$codeCmd = Join-Path $vscodePath "bin\code.cmd"
foreach ($ext in $extensions) {
    Write-Host "  $ext"
    & $codeCmd --install-extension $ext --force | Out-Null
}

# ---------------------------------------------------------------------------
# 6. settings.json y setenv.bat con las rutas reales de esta maquina
# ---------------------------------------------------------------------------
Write-Step "Generando settings.json y setenv.bat con las rutas de esta maquina"

$jdk11Abs = Join-Path $complementos $jdk11Folder
$jdk17Abs = Join-Path $complementos $jdk17Folder
$mavenExeAbs = Join-Path $mavenPath "bin\mvn.cmd"

$userDir = Join-Path $dataPath "user-data\User"
New-Item -ItemType Directory -Force -Path $userDir | Out-Null

$settings = [ordered]@{
    "java.configuration.runtimes" = @(
        [ordered]@{ name = "JavaSE-11"; path = $jdk11Abs; default = $true },
        [ordered]@{ name = "JavaSE-17"; path = $jdk17Abs }
    )
    "java.jdt.ls.java.home"      = $jdk17Abs
    "maven.executable.path"      = $mavenExeAbs
    "maven.terminal.useJavaHome" = $true
}
$settingsJson = $settings | ConvertTo-Json -Depth 5
# Set-Content -Encoding utf8 en Windows PowerShell 5.1 siempre añade BOM; lo
# evitamos escribiendo con .NET directamente para que quede un JSON limpio.
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $userDir "settings.json"), $settingsJson, $utf8NoBom)

$setenvContent = @"
@echo off
rem Generado por setup.ps1. Fuerza el JDK 11 de este paquete, evitando otros
rem JDK que pueda haber instalados en el sistema.
set "JAVA_HOME=$jdk11Abs"

rem --- VM Arguments: completar segun necesidades del proyecto ---
rem set "JAVA_OPTS=%JAVA_OPTS% -Xms256m -Xmx1024m"
rem set "JAVA_OPTS=%JAVA_OPTS% -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000"
"@
Set-Content -Path (Join-Path $tomcatPath "bin\setenv.bat") -Value $setenvContent -Encoding ascii

# ---------------------------------------------------------------------------
Write-Step "Listo"
Write-Host "VSCode:  $vscodePath"
Write-Host "JDK 11:  $jdk11Abs"
Write-Host "JDK 17:  $jdk17Abs"
Write-Host "Tomcat:  $tomcatPath"
Write-Host "Maven:   $mavenPath"
Write-Host ""
Write-Host "Siguiente paso: abre INSTRUCCIONES-PENDIENTES.md, seccion 3, para los pasos"
Write-Host "que quedan (SVN, Oracle, puerto/timeout de Tomcat, anadir el servidor en la UI)."
