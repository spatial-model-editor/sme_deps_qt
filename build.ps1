Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($PSVersionTable.PSVersion.Major -ge 7) {
  $PSNativeCommandUseErrorActionPreference = $true
}

function New-Directory {
  param([Parameter(Mandatory)] [string]$Path)
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

$requiredEnvVars = @(
  "QT_VERSION",
  "ZLIB_VERSION",
  "INSTALL_PREFIX",
  "OS"
)

foreach ($name in $requiredEnvVars) {
  if (-not (Get-Item -Path "Env:$name" -ErrorAction SilentlyContinue)) {
    throw "$name is not set"
  }
}

$buildTag = if ($env:BUILD_TAG) { $env:BUILD_TAG } else { "" }
$installLibDir = Join-Path $env:INSTALL_PREFIX "lib"
$installIncludeDir = Join-Path $env:INSTALL_PREFIX "include"
$env:CMAKE_MSVC_RUNTIME_LIBRARY = if ($env:CMAKE_MSVC_RUNTIME_LIBRARY) {
  $env:CMAKE_MSVC_RUNTIME_LIBRARY
} else {
  'MultiThreaded$<$<CONFIG:Debug>:Debug>'
}
$configureExtras = @()
if ($env:CONFIGURE_EXTRAS) {
  $configureExtras = @($env:CONFIGURE_EXTRAS -split "\s+" | Where-Object { $_ })
}

Write-Host "QT_VERSION = $env:QT_VERSION"
Write-Host "ZLIB_VERSION = $env:ZLIB_VERSION"
Write-Host "INSTALL_PREFIX = $env:INSTALL_PREFIX"
Write-Host "MACOSX_DEPLOYMENT_TARGET = $env:MACOSX_DEPLOYMENT_TARGET"
Write-Host "SUDO_CMD = $env:SUDO_CMD"
Write-Host "CONFIGURE_EXTRAS = $env:CONFIGURE_EXTRAS"
Write-Host "BUILD_TAG = $buildTag"
Write-Host "OS = $env:OS"
Write-Host "CMAKE_MSVC_RUNTIME_LIBRARY = $env:CMAKE_MSVC_RUNTIME_LIBRARY"
Write-Host "PATH=$env:PATH"
Write-Host "git = $((Get-Command git -ErrorAction Stop).Source)"
git --version
Write-Host "cl = $((Get-Command cl -ErrorAction Stop).Source)"
Write-Host "ninja = $((Get-Command ninja -ErrorAction Stop).Source)"
ninja --version
Write-Host "cmake = $((Get-Command cmake -ErrorAction Stop).Source)"
cmake --version

# make qt dir
New-Directory "qt"
Push-Location "qt"

# build static version of zlib to use instead of Qt bundled version
# to allow other libraries to link to the same zlib version
git clone -b $env:ZLIB_VERSION --depth 1 https://github.com/madler/zlib.git
Push-Location "zlib"
New-Directory "build"
Push-Location "build"
$zlibArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_MSVC_RUNTIME_LIBRARY=$env:CMAKE_MSVC_RUNTIME_LIBRARY",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX"
)
if (Get-Command ccache -ErrorAction SilentlyContinue) {
  $zlibArgs += "-DCMAKE_C_COMPILER_LAUNCHER=ccache"
}
cmake @zlibArgs
ninja zlibstatic

# manual install to avoid shared libs being installed & issues with compiling example programs
New-Directory $env:INSTALL_PREFIX
New-Directory $installLibDir
New-Directory $installIncludeDir
Copy-Item ".\zlibstatic.lib" (Join-Path $installLibDir "zlibstatic.lib") -Force
Copy-Item ".\zconf.h" (Join-Path $installIncludeDir "zconf.h") -Force
Copy-Item "..\zlib.h" (Join-Path $installIncludeDir "zlib.h") -Force
$zlibLibrary = Join-Path $installLibDir "zlibstatic.lib"
Pop-Location
Pop-Location

# download Qt sources to qt/qt5
git clone https://code.qt.io/qt/qt5.git
Push-Location "qt5"
git checkout $env:QT_VERSION
# only need qtbase submodule
git submodule update --init qtbase
Pop-Location

# make build dir in qt/build and run cmake
New-Directory "build"
Push-Location "build"
$cmakeArgs = @(
  "..\qt5\qtbase",
  "-GNinja",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_MSVC_RUNTIME_LIBRARY=$env:CMAKE_MSVC_RUNTIME_LIBRARY",
  "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
  "-DCMAKE_CXX_VISIBILITY_PRESET=hidden",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_MESSAGE_LOG_LEVEL=STATUS",
  "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache",
  "-DFEATURE_system_doubleconversion=OFF",
  "-DFEATURE_system_harfbuzz=OFF",
  "-DFEATURE_system_jpeg=OFF",
  "-DFEATURE_system_libb2=OFF",
  "-DFEATURE_system_pcre2=OFF",
  "-DFEATURE_system_png=OFF",
  "-DFEATURE_system_proxies=OFF",
  "-DFEATURE_system_textmarkdownreader=OFF",
  "-DFEATURE_system_zlib=ON",
  "-DZLIB_INCLUDE_DIR=$installIncludeDir",
  "-DZLIB_LIBRARY_RELEASE=$zlibLibrary",
  "-DFEATURE_zstd=OFF",
  "-DFEATURE_openssl=OFF",
  "-DFEATURE_sql=OFF",
  "-DFEATURE_icu=OFF",
  "-DFEATURE_testlib=ON",
  "-DBUILD_WITH_PCH=OFF"
)

# Keep the historical bundled-library selections used by the MSVC build.
$cmakeArgs += @(
  "-DQT_USE_BUNDLED_BundledFreetype=ON",
  "-DQT_USE_BUNDLED_BundledHarfbuzz=ON",
  "-DQT_USE_BUNDLED_BundledLibpng=ON",
  "-DQT_USE_BUNDLED_BundledPcre2=ON"
)

$cmakeArgs += $configureExtras

cmake @cmakeArgs
ninja -v
if ($env:SUDO_CMD) {
  & $env:SUDO_CMD ninja install
} else {
  ninja install
}
Pop-Location
Pop-Location

if (Get-Command ccache -ErrorAction SilentlyContinue) {
  ccache --show-stats
}

& "$env:INSTALL_PREFIX\bin\qmake.exe" -v

# make tarball of installation
New-Directory "artefacts"
Push-Location "artefacts"
7z a "tmp.tar" $env:INSTALL_PREFIX
7z a "sme_deps_qt_$($env:OS)$buildTag.tgz" "tmp.tar"
Remove-Item "tmp.tar"
Pop-Location
