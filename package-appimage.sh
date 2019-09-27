#! /bin/bash


APP=hdrmerge
APP_VERSION=0.5.0
LOWERAPP=${APP,,} 


# Get the helper scripts and load the helper functions
(mkdir -p /work && cd /work && rm -rf appimage-helper-scripts && \
git clone https://github.com/aferrero2707/appimage-helper-scripts.git) || exit 1
source /work/appimage-helper-scripts/functions.sh


# Create the root AppImage folder
export APPIMAGEBASE=/work/appimage
export APPDIR="${APPIMAGEBASE}/$APP.AppDir"
(rm -rf "${APPIMAGEBASE}" && mkdir -p "${APPIMAGEBASE}/$APP.AppDir/usr/bin") || exit 1
cp /work/appimage-helper-scripts/excludelist "${APPIMAGEBASE}"


cp -a "/usr/local/bin/$LOWERAPP" "$APPDIR/usr/bin/$LOWERAPP.bin"



mkdir -p "$APPDIR/usr/share/icons"
mkdir -p "$APPDIR/usr/share/applications"

#cp ./usr/share/applications/$LOWERAPP.desktop .
rm -rf ./usr/share/icons/48x48/apps || true
cp /work/hdrmerge/data/images/icon.png "$APPDIR/usr/share/icons/$LOWERAPP.png"
cp /work/hdrmerge/data/images/icon.png "$APPDIR/$LOWERAPP.png"

# The original desktop file is a bit strange, hence we provide our own
cat > "$APPDIR/usr/share/applications/$LOWERAPP.desktop" <<\EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=hdrmerge
GenericName=HDR raw image merge
GenericName[es]=Mezcla de imágenes HDR raw
Comment=Merge several raw images into a single DNG raw image with high dynamic range.
Comment[es]=Mezcla varias imágenes raw en una única imagen DNG raw de alto rango dinámico.
Exec=LOWERAPP %f
TryExec=LOWERAPP
Icon=ICON
Terminal=false
Categories=Graphics;
MimeType=image/x-dcraw;image/x-adobe-dng;
EOF
sed -i -e "s|LOWERAPP|$LOWERAPP|g" "$APPDIR/usr/share/applications/$LOWERAPP.desktop"
sed -i -e "s|ICON|$LOWERAPP|g" "$APPDIR/usr/share/applications/$LOWERAPP.desktop"
cat "$APPDIR/usr/share/applications/$LOWERAPP.desktop"
cp "$APPDIR/usr/share/applications/$LOWERAPP.desktop" "$APPDIR/$LOWERAPP.desktop"

#unset QTDIR; unset QT_PLUGIN_PATH ; unset LD_LIBRARY_PATH
export VERSION=$(git rev-parse --short HEAD) # linuxdeployqt uses this for naming the file
#mkdir -p /ai && cd /ai



#get_apprun
cp -a /sources/AppRun "$APPDIR/AppRun"

# Copy Qt5 plugins
QT5PLUGINDIR=$(pkg-config --variable=plugindir Qt5)
if [ x"$QT5PLUGINDIR" != "x" ]; then
  mkdir -p "$APPDIR/usr/lib/qt5/plugins"
  cp -a "$QT5PLUGINDIR"/* "$APPDIR/usr/lib/qt5/plugins"
fi


export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:$PKG_CONFIG_PATH
LIBRAW_LIBDIR=$(pkg-config --variable=libdir libraw_r)
export LD_LIBRARY_PATH=$LIBRAW_LIBDIR:$LD_LIBRARY_PATH

# Get into the AppImage
cd "$APPDIR"


# Copy in the indirect dependencies
copy_deps2 ; copy_deps2 ; copy_deps2 # Three runs to ensure we catch indirect ones

move_lib
echo ""
echo "ls usr/lib"
ls usr/lib


delete_blacklisted2
# Put the gcc libraries in optional folders
copy_gcc_libs


# patch_usr
# Patching only the executable files seems not to be enough for darktable
#find usr/ -type f -exec sed -i -e "s|$PREFIX|././|g" {} \;
#find usr/ -type f -exec sed -i -e "s|/usr|././|g" {} \;


# Workaround for:
# GLib-GIO-ERROR **: Settings schema 'org.gtk.Settings.FileChooser' is not installed
# when trying to use the file open dialog
# AppRun exports usr/share/glib-2.0/schemas/ which might be hurting us here
( mkdir -p usr/share/glib-2.0/schemas/ ; cd usr/share/glib-2.0/schemas/ ; ln -s /usr/share/glib-2.0/schemas/gschemas.compiled . )

# Workaround for:
# ImportError: /usr/lib/x86_64-linux-gnu/libgdk-x11-2.0.so.0: undefined symbol: XRRGetMonitors
cp $(ldconfig -p | grep libgdk-x11-2.0.so.0 | cut -d ">" -f 2 | xargs) ./usr/lib/
cp $(ldconfig -p | grep libgtk-x11-2.0.so.0 | cut -d ">" -f 2 | xargs) ./usr/lib/

GLIBC_NEEDED=$(glibc_needed)
#export VERSION=$(git rev-parse --short HEAD)-$(date +%Y%m%d).glibc$GLIBC_NEEDED
#export VERSION=git-$(date +%Y%m%d)
if [ x"${BUILD_BRANCH}" = "xreleases" ]; then
	export VERSION="$(git describe --tags --always)-$(date +%Y%m%d)"
else
	export VERSION="${BUILD_BRANCH}-$(git describe --tags --always)-$(date +%Y%m%d)"
fi
echo $VERSION

cd "$APPDIR"

get_desktopintegration $LOWERAPP
#cp -a ../../desktopintegration ./usr/bin/$LOWERAPP.wrapper
#chmod a+x ./usr/bin/$LOWERAPP.wrapper
#sed -i -e "s|Exec=$LOWERAPP|Exec=$LOWERAPP.wrapper|g" $LOWERAPP.desktop

# Go out of AppImage
cd ..

mkdir -p ../out/
ARCH="x86_64"
export NO_GLIBC_VERSION=true
export DOCKER_BUILD=true
generate_type2_appimage

pwd
ls ../out/*
mkdir -p /sources/out
cp ../out/*.AppImage /sources/out

########################################################################
# Upload the AppDir
########################################################################

transfer ../out/*
echo ""
echo "AppImage has been uploaded to the URL above; use something like GitHub Releases for permanent storage"
