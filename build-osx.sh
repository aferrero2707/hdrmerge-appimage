#! /bin/bash

# Install some Dependencies

brew install libomp
brew install zlib
brew install qt
brew reinstall little-cms2 fftw curl exiv2 || exit 1

# Prepare the Environment

export PATH="/usr/local/opt/qt/bin:/usr/local/opt/curl/bin:/usr/local/opt/zlib/bin:/usr/local/opt/${QTPREFIX}/bin:$PATH"
export PKG_CONFIG_PATH="/usr/local/opt/zlib/lib/pkgconfig:/usr/local/opt/curl/lib/pkgconfig:/usr/local/opt/zlib/lib/pkgconfig:/usr/local/opt/${QTPREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="/usr/local/opt/curl/lib:/usr/local/opt/zlib/lib:/usr/local/opt/${QTPREFIX}/lib:$LD_LIBRARY_PATH"

mkdir -p hdrmerge/build || exit 1
cd hdrmerge/build || exit 1

# build LibRaw 0.18
	git clone https://github.com/LibRaw/LibRaw.git || exit 1
	cd LibRaw || exit 1
	git checkout 0.18.13 || exit 1
	autoreconf --install || exit 1
	./configure --prefix=/usr/local || exit 1
	make -j2 install || exit 1
	cd ..
pwd

# Get alglib

curl -L http://www.alglib.net/translator/re/alglib-3.14.0.cpp.gpl.tgz -O || exit 1
tar xf alglib-3.14.0.cpp.gpl.tgz || exit 1
export ALGLIB_ROOT=$(pwd)/cpp

# Build HDRMerge

cmake -DQt5_DIR=/usr/local/opt/qt/lib/cmake/Qt5 -DCMAKE_C_FLAGS=-mmacosx-version-min=10.11 -DCMAKE_CXX_FLAGS=-mmacosx-version-min=10.11 -DCMAKE_EXE_LINKER_FLAGS="/usr/local/opt/libomp/lib/libomp.dylib -headerpad_max_install_names" -DOpenMP_CXX_FLAGS="-Xpreprocessor -fopenmp -I/usr/local/opt/libomp/include" -DOpenMP_C_FLAGS=-fopenmp -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk" -DCMAKE_INSTALL_PREFIX=/usr/local -DALGLIB_ROOT=$ALGLIB_ROOT -DALGLIB_INCLUDES=$ALGLIB_ROOT/src -DALGLIB_LIBRARIES=$ALGLIB_ROOT/src -DCMAKE_INSTALL_BINDIR=$(pwd)/install .. || exit 1
make -j2 install || exit 1

# Bundle the .app and make the .dmg

mkdir install/hdrmerge.app/Contents/Frameworks
cp /usr/local/lib/libexiv2.26.dylib install/hdrmerge.app/Contents/Frameworks
macdeployqt $(pwd)/install/hdrmerge.app -no-strip -verbose=3
install_name_tool -add_rpath "@executable_path/../Frameworks" install/hdrmerge.app/Contents/MacOS/hdrmerge
mkdir -p $TRAVIS_BUILD_DIR/out
hdiutil create -ov -srcfolder $(pwd)/install/hdrmerge.app $TRAVIS_BUILD_DIR/out/HDRMerge.dmg
