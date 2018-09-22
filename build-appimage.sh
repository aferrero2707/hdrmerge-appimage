
yum update -y && yum install -y epel-release && yum update -y 
yum group install -y "Development Tools"
(yum install -y autoconf automake libtool cmake3 qt5-qtbase-devel qt5-linguist git exiv2-devel alglib-devel zlib-devel wget cairo) || exit 1

mkdir -p /work

cd /work

#rm -rf hdrmerge
git clone https://github.com/jcelaya/hdrmerge.git
cd hdrmerge
mkdir -p build
cd build
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
git clone https://github.com/LibRaw/LibRaw.git
cd LibRaw
autoreconf --install || exit 1
./configure --prefix=/usr/local || exit 1
make -j2 install || exit 1
cd ..
pwd
cmake3 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. || exit 1
make -j2 install || exit 1
cd ..


exit

mkdir -p appimage
cp /sources/appimage.sh appimage
bash appimage/appimage.sh
