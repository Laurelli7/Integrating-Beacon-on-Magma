#!/bin/bash
set -e
set -x

export BEACON=$FUZZER/repo
pushd $BEACON

# Building SVF
#(
#    git clone https://github.com/SVF-tools/SVF.git
#    pushd SVF
#    git reset --hard 3170e83b03eefc15e5a3707e5c52dc726ffcd60a
#    sed -i 's/LLVMRELEASE=\/home\/ysui\/llvm-4.0.0\/llvm-4.0.0.obj/LLVMRELEASE=\/usr\/llvm/' build.sh
#    ./build.sh
#    popd 
#)

# Building precondInfer
#(
#    pushd precondInfer
#    if [ -d build ]; then
#        rm -r build
#    fi
#    mkdir build 
#    pushd build 
#    cmake \
#        -DENABLE_KLEE_ASSERTS=ON \
#       -DCMAKE_BUILD_TYPE=Release \
#        -DLLVM_CONFIG_BINARY=/usr/bin/llvm-config \
#        -DSVF_ROOT_DIR=${BEACON}/SVF \
#        -DSVF_LIB_DIR=${BEACON}/SVF/Release-build/lib \
#        ..
#    make -j
#    popd 
#    popd 
#)

# Building Ins
#(
#    export LLVM_COMPILER=clang
#    pushd Ins
#    if [ -d build ]; then
#       rm -r build
#    fi
#    mkdir build
#    pushd build
#    CXXFLAGS="-fno-rtti" cmake \
#        -DLLVM_DIR=/usr/lib/cmake/llvm/ \
#        -DCMAKE_BUILD_TYPE=Release \
#        ..
#    make -j
#   popd
#    popd
#)

echo 'export LLVM_COMPILER=clang' >> "$HOME/.bashrc"
echo 'export PATH="/usr/local/bin:$PATH"' >> "$HOME/.bashrc"
source "$HOME/.bashrc"
export LLVM_COMPILER=clang
wllvm++ $CXXFLAGS -std=c++11 -c "$FUZZER/src/driver.cpp" -fPIC -o "$OUT/driver.o"

popd
