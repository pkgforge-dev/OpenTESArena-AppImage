#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
    cmake    \
    libdecor \
	openal	 \
    sdl2     \
    wildmidi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

# If the application needs to be manually built that has to be done down here
echo "Building OpenTESArena..."
echo "---------------------------------------------------------------"
REPO="https://github.com/afritz1/OpenTESArena"
if [ "${DEVEL_RELEASE-}" = 1 ]; then
    echo "Making nightly build of OpenTESArena..."
    echo "---------------------------------------------------------------"
    VERSION="$(git ls-remote "$REPO" HEAD | cut -c 1-9 | head -1)"
    git clone "$REPO" ./OpenTESArena
else
	echo "Making stable build of OpenTESArena..."
	VERSION="$(git ls-remote --tags --sort="v:refname" "$REPO" | tail -n1 | sed 's/.*\///; s/\^{}//')"
	git clone --branch "$VERSION" --single-branch "$REPO" ./OpenTESArena
fi
echo "$VERSION" > ~/version

mkdir -p ./AppDir/bin
cd ./OpenTESArena
wget https://github.com/afritz1/OpenTESArena/releases/download/opentesarena-0.1.0/eawpats.zip
bsdtar -xvf eawpats.zip -C data
mkdir build && cd build
if [ "$ARCH" = "x86_64" ]; then
	cmake .. -DCMAKE_BUILD_TYPE=ReleaseNative
else
	cmake .. \
    	-DCMAKE_BUILD_TYPE=ReleaseNative \
    	-DUSE_SSE4_1=OFF \
		-DUSE_SSE4_2=OFF \
    	-DUSE_AVX=OFF \
		-DUSE_AVX2=OFF \
    	-DUSE_AVX512=OFF \
		-DUSE_LZCNT=OFF \
    	-DUSE_TZCNT=OFF \
		-DUSE_F16C=OFF \
    	-DUSE_FMADD=OFF
fi
make -j$(nproc)
mv -v otesa ../../AppDir/bin
cd ..
mv -v options ../AppDir/bin
cd data
rm -f icon.bmp
cd ..
mv -v data ../AppDir/bin
