#! /bin/bash

brew cask uninstall oclint
brew reinstall little-cms2 fftw curl zlib exiv2 libraw || exit 1

#HASH=9ba3d6ef8891e5c15dbdc9333f857b13711d4e97 #qt@5.5
#QTPREFIX="qt@5.5"
HASH=13d52537d1e0e5f913de46390123436d220035f6 #qt 5.9
QTPREFIX="qt"
(cd $( brew --prefix )/Homebrew/Library/Taps/homebrew/homebrew-core && \
  git pull --unshallow && git checkout $HASH -- Formula/${QTPREFIX}.rb && \
  cat Formula/${QTPREFIX}.rb | sed -e 's|depends_on :mysql|depends_on "mysql-client"|g' | sed -e 's|depends_on :postgresql|depends_on "postgresql"|g' > /tmp/${QTPREFIX}.rb && cp /tmp/${QTPREFIX}.rb Formula/${QTPREFIX}.rb &&
  brew install ${QTPREFIX} && brew link --force ${QTPREFIX}) || exit 1

export PATH="/usr/local/opt/curl/bin:/usr/local/opt/zlib/bin:/usr/local/opt/${QTPREFIX}/bin:$PATH"
export PKG_CONFIG_PATH="/usr/local/opt/curl/lib/pkgconfig:/usr/local/opt/zlib/lib/pkgconfig:/usr/local/opt/${QTPREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="/usr/local/opt/curl/lib:/usr/local/opt/zlib/lib:/usr/local/opt/${QTPREFIX}/lib:$LD_LIBRARY_PATH"

mkdir -p hdrmerge/build || exit 1
cd hdrmerge/build || exit 1

if [ "x" = "y" ]; then
	rm -rf LibRaw
	git clone https://github.com/LibRaw/LibRaw.git || exit 1
	cd LibRaw || exit 1
	autoreconf --install || exit 1
	./configure --prefix=/usr/local || exit 1
	make -j2 install || exit 1
	cd ..
fi
pwd
curl -L http://www.alglib.net/translator/re/alglib-3.14.0.cpp.gpl.tgz -O || exit 1
tar xf alglib-3.14.0.cpp.gpl.tgz || exit 1
export ALGLIB_ROOT=$(pwd)/cpp
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.9.sdk" -DCMAKE_INSTALL_PREFIX=/usr/local -DALGLIB_ROOT=$ALGLIB_ROOT -DALGLIB_INCLUDES=$ALGLIB_ROOT/src -DALGLIB_LIBRARIES=$ALGLIB_ROOT/src -DCMAKE_INSTALL_BINDIR=$(pwd)/install .. || exit 1
make -j2 install || exit 1

mkdir install/hdrmerge.app/Contents/Frameworks
#sudo cp /opt/local/lib/libomp/libiomp5.dylib ~/hdrmerge/build/install/hdrmerge.app/Contents/Frameworks/.
cp /usr/local/lib/libexiv2.26.dylib install/hdrmerge.app/Contents/Frameworks

macdeployqt $(pwd)/install/hdrmerge.app -no-strip -verbose=3
install_name_tool -add_rpath "@executable_path/../Frameworks" install/hdrmerge.app/Contents/MacOS/hdrmerge
mkdir -p $TRAVIS_BUILD_DIR/out
hdiutil create -ov -srcfolder $(pwd)/install/hdrmerge.app $TRAVIS_BUILD_DIR/out/HDRMerge.dmg