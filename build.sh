#!/bin/bash

set -e -x

echo "QT_VERSION = $QT_VERSION"
echo "ZLIB_VERSION: ${ZLIB_VERSION}"
echo "INSTALL_PREFIX = $INSTALL_PREFIX"
echo "MACOSX_DEPLOYMENT_TARGET = $MACOSX_DEPLOYMENT_TARGET"
echo "SUDO_CMD = $SUDO_CMD"
echo "CONFIGURE_EXTRAS = $CONFIGURE_EXTRAS"
echo "OS=$OS"
echo "PATH=$PATH"
which g++
g++ --version
# make qt dir
mkdir qt
cd qt

# build static version of zlib to use instead of Qt bundled version
# to allow other libraries to link to the same zlib version
git clone -b $ZLIB_VERSION --depth 1 https://github.com/madler/zlib.git
cd zlib
mkdir build
cd build
cmake -G "Ninja" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
time ninja zlibstatic
# manual install to avoid shared libs being installed & issues with compiling example programs
# wildcard is used because on mingw it calls the library file libzlibstatic.a for some reason:
$SUDO_CMD mkdir -p $INSTALL_PREFIX
$SUDO_CMD mkdir -p $INSTALL_PREFIX/lib
$SUDO_CMD mkdir -p $INSTALL_PREFIX/include
$SUDO_CMD cp libz*.a $INSTALL_PREFIX/lib/libz.a
$SUDO_CMD cp zconf.h $INSTALL_PREFIX/include/.
$SUDO_CMD cp ../zlib.h $INSTALL_PREFIX/include/.
cd ../../


# download Qt sources to qt/qt5
git clone https://code.qt.io/qt/qt5.git
cd qt5
git checkout $QT_VERSION
# only need qtbase submodule
git submodule update --init qtbase
cd ..

# make build dir in qt/build and run cmake
mkdir build
cd build
cmake ../qt5/qtbase -G "Ninja" \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DCMAKE_MESSAGE_LOG_LEVEL=STATUS \
    -DFEATURE_system_doubleconversion=OFF \
    -DFEATURE_system_harfbuzz=OFF \
    -DFEATURE_system_jpeg=OFF \
    -DFEATURE_system_libb2=OFF \
    -DFEATURE_system_pcre2=OFF \
    -DFEATURE_system_png=OFF \
    -DFEATURE_system_proxies=OFF \
    -DFEATURE_system_textmarkdownreader=OFF \
    -DFEATURE_system_zlib=ON \
    -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX}/include \
    -DZLIB_LIBRARY_RELEASE=${INSTALL_PREFIX}/lib/libz.a \
    -DFEATURE_zstd=OFF \
    -DFEATURE_openssl=OFF \
    -DFEATURE_sql=OFF \
    -DFEATURE_icu=OFF \
    -DFEATURE_testlib=ON \
    -DBUILD_WITH_PCH=OFF \
    ${CONFIGURE_EXTRAS}

time ninja
$SUDO_CMD ninja install

cd ../..

$INSTALL_PREFIX/bin/qmake -v

# make tarball of installation
mkdir artefacts
cd artefacts
tar -zcvf sme_deps_qt_${OS}.tgz ${INSTALL_PREFIX}/*
