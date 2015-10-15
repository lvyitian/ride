#!/bin/bash
set -ev

# what is the current compiler?
echo $CXX
echo $CC

#are commands even run?
ls

#from http://unix.stackexchange.com/questions/190571/sudo-in-non-interactive-script
## Detect the user who launched the script
usr=$(env | grep SUDO_USER | cut -d= -f 2)

## Exit if the script was not launched by root or through sudo
if [ -z $usr ] && [ $USER = "root" ]
then
    echo "The script needs to run as root" && exit 1
fi

#install ride dependencies
add-apt-repository -y ppa:chris-lea/protobuf
apt-get update -qq
apt-get install -qq --assume-yes libgtk2.0-dev libprotobuf-dev protobuf-compiler libwebkit-dev graphviz doxygen

# update cmake and compiler: copied from install part of https://github.com/skystrife/cpptoml/blob/toml-v0.4.0/.travis.yml
apt-get install libc6-i386
sudo -u $usr wget http://www.cmake.org/files/v3.3/cmake-3.3.2-Linux-i386.sh
sh cmake-3.3.2-Linux-i386.sh --prefix=/usr/local --exclude-subdir

# credit: https://github.com/beark/ftl/
# install g++ 4.8, if tests are run with g++
if [ "`echo $CXX`" == "g++" ]; then
	add-apt-repository -y ppa:ubuntu-toolchain-r/test;
	apt-get update;
	apt-get install -qq g++-4.8;
	update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 50
fi

# if [ "`echo $CXX`" == "clang++" ]; then
# 	cwd=$(pwd)
# 	svn co --quiet http://llvm.org/svn/llvm-project/libcxx/trunk libcxx
# 	git clone https://github.com/pathscale/libcxxrt.git libcxxrt
# 	cd libcxxrt
# 	mkdir build
# 	cd build
# 	cmake -DCMAKE_BUILD_TYPE=Release ../
# 	make
# 	cp lib/libcxxrt.so /usr/lib
# 	ln -sf /usr/lib/libcxxrt.so /usr/lib/libcxxrt.so.1
# 	ln -sf /usr/lib/libcxxrt.so /usr/lib/libcxxrt.so.1.0
# 	cd $cwd
# 	cd libcxx
# 	mkdir build
# 	cd build
# 	cmake -DLIBCXX_CXX_ABI=libcxxrt -DLIBCXX_LIBCXXRT_INCLUDE_PATHS="../../libcxxrt/src" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr ..
# 	make
# 	make install
# 	cd $cwd
# fi

# build wxWidgtets
sudo -u $usr mkdir wx3
sudo -u $usr cd wx3
sudo -u $usr wget https://github.com/wxWidgets/wxWidgets/archive/WX_3_0_2.tar.gz -O wx.tar.gz
sudo -u $usr tar -xzf wx.tar.gz
sudo -u $usr ls
sudo -u $usr cd wxWidgets-WX_3_0_2
sudo -u $usr mkdir gtk-build
sudo -u $usr cd gtk-build
sudo -u $usr ../configure --help
sudo -u $usr ../configure --enable-webview --disable-compat28
sudo -u $usr make
make install
sudo -u $usr wx-config --version
