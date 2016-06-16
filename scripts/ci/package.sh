#!/usr/bin/env bash

set -e

# Requires packages:
# devscripts cmake ninja git

TOP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../" && pwd )"

if [ ! -d "tmp-cmake" ]; then
mkdir tmp-cmake
cd tmp-cmake
wget https://cmake.org/files/v3.5/cmake-3.5.2-Linux-x86_64.tar.gz
tar xf cmake-3.5.2-Linux-x86_64.tar.gz
cd cmake-3.5.2-Linux-x86_64/bin/
export PATH=`pwd`:$PATH
else
cd tmp-cmake/cmake-3.5.2-Linux-x86_64/bin
export PATH=`pwd`:$PATH
fi

#cd $TOP_DIR/projects
#if [ ! -d "libcxx" ]; then
#git clone -b release_36 https://github.com/llvm-mirror/libcxx.git
#fi


#cd $TOP_DIR/projects
#if [ ! -d "libcxxabi" ]; then
#git clone -b release_36 https://github.com/llvm-mirror/libcxxabi.git
#fi

mkdir -p $TOP_DIR/build

cd $TOP_DIR/build


# Uncomment to use libcxx
#LLVM_CFLAGS="-I$TOP_DIR/include -DLIBUNWIND_SUPPORT_DWARF_UNWIND -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -DNDEBUG -D__NO_CTYPE_INLINE -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -ggdb -O0"
#LLVM_CXXFLAGS="$LLVM_CFLAGS -stdlib=libc++ -std=c++11 -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS  -fvisibility-inlines-hidden -Woverloaded-virtual -fexceptions -Wcast-qual -ggdb -O0"
#LLVM_LDFLAGS="-L$TOP_DIR/lib -lc++abi -lc++"

# Uncomment to use stdlib
LLVM_CFLAGS="-I$TOP_DIR/include -DLIBUNWIND_SUPPORT_DWARF_UNWIND -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -DNDEBUG -D__NO_CTYPE_INLINE -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -ggdb -O0"
LLVM_CXXFLAGS="$LLVM_CFLAGS -stdlib=stdc++ -std=c++11 -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS  -fvisibility-inlines-hidden -Woverloaded-virtual -fexceptions -Wcast-qual -ggdb -O0"
LLVM_LDFLAGS="-L$TOP_DIR/lib" 

echo "BUILDING LLVM"

LDFLAGS="$LLVM_LDFLAGS" cmake -DLIBCXXABI_USE_LLVM_UNWINDER=yes -DCMAKE_C_FLAGS="$LLVM_CFLAGS" -DCMAKE_CXX_FLAGS="$LLVM_CXXFLAGS" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_FLAGS="-ggdb -O0" -DCMAKE_CXX_FLAGS="-ggdb -O0" ../

export LIBRARY_PATH=`pwd`:$LIBRARY_PATH

# Need -j 1 or it will try to allocate > 10GB ram when linking (without LTO)
cmake --build . -- -j 1

export PKG_DIR=$TOP_DIR/build/mono-llvm-3.6

mkdir -p $PKG_DIR/usr

echo "INSTALLING LLVM TO BUILD DIR"

cmake -DCMAKE_INSTALL_PREFIX=$PKG_DIR/usr -P cmake_install.cmake

cp -r $TOP_DIR/scripts/ci/debian $PKG_DIR/debian

cd $PKG_DIR

echo "MAKING DEB"

dpkg-buildpackage -d -us -uc

echo "DONE"

cd ../


