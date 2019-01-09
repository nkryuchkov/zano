#!/bin/bash

# Environment prerequisites:
# 1) QT_PREFIX_PATH should be set to Qt libs folder
# 2) BOOST_ROOT should be set to the root of Boost
#
# for example, place these lines to the end of your ~/.bashrc :
#
# export BOOST_ROOT=/home/user/boost_1_66_0
# export QT_PREFIX_PATH=/home/user/Qt5.10.1/5.10.1/gcc_64

: "${BOOST_ROOT:?BOOST_ROOT should be set to the root of Boost, ex.: /home/user/boost_1_66_0}"
: "${QT_PREFIX_PATH:?QT_PREFIX_PATH should be set to Qt libs folder, ex.: /home/user/Qt5.10.1/5.10.1/gcc_64}"

prj_root=$(pwd)

git pull
if [ $? -ne 0 ]; then
    echo "Failed to pull"
    exit $?
fi

echo "---------------- BUILDING PROJECT ----------------"
echo "--------------------------------------------------"

echo "Building...." 

rm -rf build; mkdir -p build/release; cd build/release; 
cmake -D STATIC=true -D ARCH=x86-64 -D BUILD_GUI=TRUE -D CMAKE_PREFIX_PATH="$QT_PREFIX_PATH" -D CMAKE_BUILD_TYPE=Release ../..
if [ $? -ne 0 ]; then
    echo "Failed to run cmake"
    exit 1
fi

make -j daemon Zano;
if [ $? -ne 0 ]; then
    echo "Failed to make!"
    exit 1
fi

make -j simplewallet;
if [ $? -ne 0 ]; then
    echo "Failed to make!"
    exit 1
fi

make -j connectivity_tool;
if [ $? -ne 0 ]; then
    echo "Failed to make!"
    exit 1
fi



read version_str <<< $(./src/zanod --version | awk '/^Zano / { print $2 }')
version_str=${version_str}
echo $version_str

rm -rf Zano;
mkdir -p Zano;

rsync -a ../../src/gui/qt-daemon/html ./Zano --exclude less --exclude package.json --exclude gulpfile.js
cp -Rv ../../utils/Zano.sh ./Zano
chmod 777 ./Zano/Zano.sh
mkdir ./Zano/lib
cp $QT_PREFIX_PATH/lib/libicudata.so.56 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libicui18n.so.56 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libicuuc.so.56 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5Core.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5DBus.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5Gui.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5Network.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5OpenGL.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5Positioning.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5PrintSupport.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5Qml.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5Quick.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5Sensors.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5Sql.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5Widgets.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5WebEngine.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5WebEngineCore.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5WebEngineWidgets.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5WebChannel.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5XcbQpa.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/lib/libQt5QuickWidgets.so.5 ./Zano/lib
cp $QT_PREFIX_PATH/libexec/QtWebEngineProcess ./Zano
cp $QT_PREFIX_PATH/resources/qtwebengine_resources.pak ./Zano
cp $QT_PREFIX_PATH/resources/qtwebengine_resources_100p.pak ./Zano
cp $QT_PREFIX_PATH/resources/qtwebengine_resources_200p.pak ./Zano
cp $QT_PREFIX_PATH/resources/icudtl.dat ./Zano


mkdir ./Zano/lib/platforms
cp $QT_PREFIX_PATH/plugins/platforms/libqxcb.so ./Zano/lib/platforms
mkdir ./Zano/xcbglintegrations
cp $QT_PREFIX_PATH/plugins/xcbglintegrations/libqxcb-glx-integration.so ./Zano/xcbglintegrations

cp -Rv src/Zanod src/Zano src/simplewallet  src/connectivity_tool ./Zano

cp -v ../../build_sm/release/src/Zanod ./Zano/Zanod_sm

package_filename=zano-linux-x64-$version_str.tar.bz2

rm ./$package_filename
tar -cjvf $package_filename Zano
if [ $? -ne 0 ]; then
    echo "Failed to pack"
    exit 1
fi

echo "Build success"


echo "Uploading..."

scp $package_filename zano_build_server:/var/www/html/builds
if [ $? -ne 0 ]; then
    echo "Failed to upload to remote server"
    exit $?
fi


mail_msg="New build for linux-x64 available at http://build.zano.org:8081/builds/$package_filename"

echo $mail_msg

echo $mail_msg | mail -s "Zano linux-x64 build $version_str" ${emails}

exit 0