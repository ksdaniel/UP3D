#!/bin/bash

set -e
set -x

if [ -z $TRAVIS_OS_NAME ]; then
	echo "This file is for automated builds only. Please use the respective make.sh files for local builds."
	exit -1
fi

if [ "_$TRAVIS_OS_NAME" = "_osx" ]; then
	#OSX DEPENDENCIES
	brew update
	brew upgrade pkg-config || true
    brew install $PACKAGES_INSTALL || true
else
	#DEBIAN DEPENDENCIES
    sudo rm /etc/apt/sources.list.d/google-chrome.list
    sudo apt-get update -qq
    sudo apt-get install -qq -y $PACKAGES_INSTALL
fi

if [ "_$OSTYPE" = "_msys" ]; then
	unset CC
	git clone https://github.com/libusb/libusb
	cd libusb
	sh autogen.sh --host=i686-w64-mingw32
	sh configure --target=i686-w64-mingw --host=i686-w64-mingw32 --prefix=/usr/i686-w64-mingw32 --disable-shared
	make
	sudo make install
	cd ..

	wget http://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz
	tar xzf ncurses-5.9.tar.gz
	cd ncurses-5.9
	sh configure --host=i686-w64-mingw32 --prefix=/usr/i686-w64-mingw32 --disable-shared --enable-term-driver --enable-sp-funcs --without-tests --without-cxx-binding
	make
	sudo make install
	cd ..

	export CC=i686-w64-mingw32-gcc
	export STRIP=i686-w64-mingw32-strip
fi

cd UP3DTOOLS
bash make.sh
cd ..

cd UP3DTRANSCODE
bash make.sh
cd ..


GIT=$(git describe --tags --always)
DATE=$(date +'%Y%m%d')
DESTDIR="build/UP3DTOOLS"
OS="LINUX"

mkdir -p $DESTDIR

if [ "$OSTYPE" == "msys" ]; then
    OS="WIN"
    cp UP3DTOOLS/up3dinfo.exe $DESTDIR
    cp UP3DTOOLS/up3dload.exe $DESTDIR
    cp UP3DTOOLS/up3dshell.exe $DESTDIR
    cp UP3DTRANSCODE/up3dtranscode.exe $DESTDIR
else
    if [[ $OSTYPE =~ darwin.* ]]; then
        OS="MAC"
    fi
    cp UP3DTOOLS/up3dinfo $DESTDIR
    cp UP3DTOOLS/up3dload $DESTDIR
    cp UP3DTOOLS/up3dshell $DESTDIR
    cp UP3DTRANSCODE/up3dtranscode $DESTDIR
fi

cd build
zip -r -9 "package.zip" "UP3DTOOLS"

curl -X PUT -T ./package.zip -H "x-ms-date: $(date -u)" -H "x-ms-blob-type: BlockBlob" "https://electiondatastaging.blob.core.windows.net/travis/package.zip?sv=2019-10-10&ss=bfqt&srt=sco&sp=rwdlacup&se=2020-05-02T23:53:45Z&st=2020-05-02T15:53:45Z&spr=https&sig=NfYmxiYd%2B6CjQEB7lRmHFhMy%2ByYte8Uj8qb6lSKd%2FnQ%3D"

cd ..
