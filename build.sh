#!/bin/bash
source source.sh

echo "INSTALL_PREFIX: ${INSTALL_PREFIX}"
echo "SUDOCMD: ${SUDOCMD}"
echo "CONFIGURE_EXTRAS: ${CONFIGURE_EXTRAS}"
which g++
g++ --version

mkdir build
cd build
../qt5/qtbase/configure -opensource -confirm-license ${CONFIGURE_EXTRAS} -prefix $INSTALL_PREFIX -release -static -silent -sql-sqlite -qt-zlib -qt-libjpeg -qt-libpng -qt-pcre -qt-harfbuzz -no-compile-examples -nomake tests -nomake examples -no-opengl -no-openssl -no-sql-odbc -no-icu -no-feature-concurrent -no-feature-xml -feature-testlib
cat config.log
make -j2
$SUDOCMD make install
cd ..
