#!/bin/bash

# Exit on error
set -ev

${CC} --version

${CXX} --version

cmake --version

# update and display enviroment variables
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
export LD_RUN_PATH=$LD_RUN_PATH:/usr/local/lib
echo "$LD_LIBRARY_PATH"
echo "$LD_RUN_PATH"

# clang failed b/c of a conflict between clang and gcc 4.9, downgrading gcc to 4.8 fixed the clang compiler error
# if [ "${TRAVIS_OS_NAME}" = "linux" ] && [ "${CC}" = "clang" ]; then
#   # https://github.com/m-a-d-n-e-s-s/madness/commit/65debe77e040af31d2f67d9b3befc4c0dec7ab8e
#   # should fix:
#   # /usr/lib/gcc/x86_64-linux-gnu/4.9/../../../../include/c++/4.9/cstddef:51:11: error: 
#   #    no member named 'max_align_t' in the global namespace
#   echo "cxxflags: $CXXFLAGS"
#   export CXXFLAGS="-stdlib=libc++"
# fi

# if [ "${TRAVIS_OS_NAME}" = "linux" ] && [ "${CC}" = "clang" ]; then
#   echo "deleting cache..."
#   rm -rf $TRAVIS_BUILD_DIR/deps/
#   mkdir $TRAVIS_BUILD_DIR/deps/
# fi

if [ -d "$TRAVIS_BUILD_DIR/deps/" ]; then
  echo "Deps exists and it contains:"
  cd $TRAVIS_BUILD_DIR/deps/
  ls
fi

mkdir $TRAVIS_BUILD_DIR/install-dist/
#mkdir $TRAVIS_BUILD_DIR/deps/

if [ "$(ls -A $TRAVIS_BUILD_DIR/deps/)" ]; then
  echo "Deps is not empty - skipping build"
else
  echo "Deps is empty, building now..."

  # build wxWidgtets
  cd $TRAVIS_BUILD_DIR
  mkdir wx3
  cd wx3
  wget https://github.com/wxWidgets/wxWidgets/archive/v3.1.0.tar.gz -O wx.tar.gz
  tar -xzf wx.tar.gz &> wxtar || cat wxtar
  cd wxWidgets-3.1.0
  mkdir gtk-build
  cd gtk-build
  CMAKEOSXARG=""
  if [ "$TRAVIS_OS_NAME" = "osx" ]; then
    CMAKEOSXARG="--with-osx_cocoa --with-macosx-version-min=10.11 --with-macosx-sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk"
  fi
  # since we intend to distribute this build, using shared libraries only complicates things, so we disable-shared libraries
  ../configure --prefix=$TRAVIS_BUILD_DIR/deps/ --disable-compat28 --disable-shared $CMAKEOSXARG
  make
  make install
  # wx-config --version

fi
