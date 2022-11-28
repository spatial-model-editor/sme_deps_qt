echo "QT_VERSION = $env:QT_VERSION"
echo "INSTALL_PREFIX = $env:INSTALL_PREFIX"
echo "CONFIGURE_EXTRAS = $env:CONFIGURE_EXTRAS"
echo "PATH=$env:PATH"
echo "OS=$env:OS"

# make qt dir
mkdir qt
cd qt

# download Qt sources to qt/qt5
git clone https://code.qt.io/qt/qt5.git
cd qt5
git checkout $env:QT_VERSION
# only need qtbase submodule
git submodule update --init qtbase
cd ..

# make build dir in qt/build and run cmake
mkdir build
cd build
cmake ..\qt5\qtbase `
  -G "Ninja" `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_BUILD_TYPE=Release `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX" `
  -DCMAKE_MESSAGE_LOG_LEVEL=STATUS `
  -DQT_USE_BUNDLED_BundledFreetype=ON `
  -DQT_USE_BUNDLED_BundledHarfbuzz=ON `
  -DQT_USE_BUNDLED_BundledLibpng=ON `
  -DQT_USE_BUNDLED_BundledPcre2=ON `
  -DFEATURE_system_doubleconversion=OFF `
  -DFEATURE_system_harfbuzz=OFF `
  -DFEATURE_system_jpeg=OFF `
  -DFEATURE_system_libb2=OFF `
  -DFEATURE_system_pcre2=OFF `
  -DFEATURE_system_png=OFF `
  -DFEATURE_system_proxies=OFF `
  -DFEATURE_system_textmarkdownreader=OFF `
  -DFEATURE_system_zlib=OFF `
  -DFEATURE_zstd=OFF `
  -DFEATURE_openssl=OFF `
  -DFEATURE_sql=OFF `
  -DFEATURE_icu=OFF `
  -DFEATURE_testlib=ON `
  -DBUILD_WITH_PCH=OFF `
  $env:CONFIGURE_EXTRAS

cmake --build . --parallel

cmake --install .

& "$env:INSTALL_PREFIX\bin\qmake.exe" -v

cd ..\..
mkdir artefacts
cd artefacts
7z a tmp.tar $env:INSTALL_PREFIX
7z a sme_deps_qt_$env:OS.tgz tmp.tar
rm tmp.tar
