
if [ x"$DEPINST" = "x1" ]; then

sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:adrozdoff/cmake
sudo add-apt-repository -y ppa:beineri/opt-qt58-trusty
sudo apt-get update
sudo apt-get install -y git wget g++ gettext intltool qt58base libtool autoconf automake cmake make libexiv2-dev mesa-common-dev libalglib-dev libboost-all-dev curl bsdtar

fi

source /opt/qt58/bin/qt58-env.sh

export TRAVIS_BUILD_DIR=/sources

if [ x"$BUILD" = "x1" ]; then

cd "$TRAVIS_BUILD_DIR"
rm -rf hdrmerge
git clone https://github.com/jcelaya/hdrmerge.git
cd hdrmerge
mkdir -p build
cd build
export PKG_CONFIG_PATH=/zyx/lib/pkgconfig:${PKG_CONFIG_PATH}
export LD_LIBRARY_PATH=/zyx/lib:${LD_LIBRARY_PATH}
git clone https://github.com/LibRaw/LibRaw.git
cd LibRaw
autoreconf --install
./configure --prefix=/usr
make -j2 && sudo make install
cd ..
pwd
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/zyx ..
make -j2 && sudo make install
cd ..

fi


#exit
mkdir -p appimage
cp /sources/appimage.sh appimage
bash appimage/appimage.sh
