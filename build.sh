#!/bin/bash

set -e -x

echo "QT5_VERSION = $QT5_VERSION"
echo "INSTALL_PREFIX = $INSTALL_PREFIX"
echo "SUDO_CMD = $SUDO_CMD"
echo "CONFIGURE_EXTRAS = $CONFIGURE_EXTRAS"
echo "OS=$OS"
echo "PATH=$PATH"
which g++
g++ --version
# make qt dir
mkdir qt
cd qt

# download Qt5 sources to qt/qt5
git clone https://code.qt.io/qt/qt5.git
cd qt5
git checkout $QT5_VERSION
# only need qtbase submodule
git submodule update --init qtbase
cd ..

# make build dir in qt/build and run cmake
mkdir build
cd build
cmake ../qt5/qtbase -G "Ninja" -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DQT_USE_BUNDLED_BundledFreetype=ON -DQT_USE_BUNDLED_BundledHarfbuzz=ON -DQT_USE_BUNDLED_BundledLibpng=ON -DQT_USE_BUNDLED_BundledPcre2=ON -DFEATURE_system_doubleconversion=OFF -DFEATURE_system_freetype=OFF -DFEATURE_system_harfbuzz=OFF -DFEATURE_system_jpeg=OFF -DFEATURE_system_libb2=OFF -DFEATURE_system_pcre2=OFF -DFEATURE_system_png=OFF -DFEATURE_system_proxies=OFF -DFEATURE_system_sqlite=OFF -DFEATURE_system_textmarkdownreader=OFF -DFEATURE_system_zlib=OFF -DFEATURE_zstd=OFF -DFEATURE_openssl=OFF -DFEATURE_sql=OFF -DFEATURE_icu=OFF -DFEATURE_testlib=ON -DBUILD_WITH_PCH=OFF ${CONFIGURE_EXTRAS}

time ninja
$SUDO_CMD ninja install

cd ../..

$INSTALL_PREFIX/bin/qmake -v

# make tarball of installation
mkdir artefacts
cd artefacts
tar -zcvf sme_deps_qt5_${OS}.tgz ${INSTALL_PREFIX}/*
