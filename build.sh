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
which make
make --version

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

# make build dir in qt/build and run configure
mkdir build
cd build
../qt5/qtbase/configure -opensource -confirm-license ${CONFIGURE_EXTRAS} -prefix ${INSTALL_PREFIX} -release -static -silent -sql-sqlite -qt-zlib -qt-libjpeg -qt-libpng -qt-pcre -qt-harfbuzz -no-compile-examples -nomake tests -nomake examples -no-opengl -no-openssl -no-sql-odbc -no-icu -no-feature-concurrent -no-feature-xml -feature-testlib
cat config.log

time make -j2
$SUDO_CMD make install

cd ../..

$INSTALL_PREFIX/bin/qmake -v

# make tarball of installation
mkdir artefacts
cd artefacts
tar -zcvf sme_deps_qt5_${OS}.tgz ${INSTALL_PREFIX}/*
