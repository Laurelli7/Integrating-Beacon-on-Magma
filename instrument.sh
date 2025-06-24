#!/bin/bash
set -e
set -x
export BEACON=$FUZZER/repo

export LIBS="$LIBS -L$OUT -l:driver.o -lstdc++"
"$MAGMA/build.sh"

(
export LLVM_COMPILER=clang
export LLVM_CONFIG=llvm-config
export LLVM_COMPILER_CXX=clang++
export CC=wllvm
export CXX=wllvm++
export PATH=/usr/bin/afl-clang-fast:$PATH
export CFLAGS="-g $CFLAGS"
export CXXFLAGS="-g $CXXFLAGS"



if [[ $TARGET = *sqlite3* ]]; then
		"$FUZZER/src/sqlite3_build.sh"
	else
		"$TARGET/build.sh"
	fi

)

pushd $BEACON

if [ ! -d $OUT ]; then
	mkdir $OUT; 
fi

(
	echo "## Get Target"

	if [[ $TARGET = *sqlite3* ]]; then
		pushd $TARGET/work
	else
		pushd $TARGET/repo
	fi

	echo "targets"
	grep -nr MAGMA_LOG | cut -f1,2 -d':' | grep -v ".orig:"  | grep -v "Binary file"
    if [[ $TARGET = *sqlite3* ]]; then
        grep -nr MAGMA_LOG \
        | cut -f1,2 -d':' \
        | grep -v '\.orig:' \
        | grep -v 'Binary file' \
        | grep '^sqlite3\.c:' \
        | head -n1 \
        > "$OUT/cstest.txt"

    else
        grep -nr MAGMA_LOG | cut -f1,2 -d':' | grep -v ".orig:" | grep -v "Binary file" | head -n1 > "$OUT/cstest.txt"
    fi

	cat $OUT/cstest.txt
)

(
pushd $OUT
source "$TARGET/configrc"
    for p in "${PROGRAMS[@]}"; do (
		folder=$OUT/output-$p
		if [ ! -d $folder ]; then
			mkdir $folder
		fi
		cd $folder
		mv ../$p .
		extract-bc "./$p"
		echo "[+] precondInfer"
		$BEACON/precondInfer/build/bin/precondInfer $p.bc --target-file=../cstest.txt --join-bound=5
		echo "[+] Ins"
        $BEACON/Ins/build/Ins -output="$folder/fuzz.bc" -blocks=bbreaches.txt -afl -byte -log=log.txt -load=range_res.txt ./transed.bc
		echo "[+] Compile"
		export CC=clang; export CXX=clang++;
		input_bc=$folder/fuzz.bc
		output_bin=$OUT/$p
		afl_llvm_rt=$BEACON/Fuzzer/afl-llvm-rt.o
		export BUILD_BC_LIBS="$LIBS -lrt" 
		pushd "$TARGET/repo"
		if [[ $TARGET = *libpng* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS .libs/libpng16.a -lz -lm
		elif [[ $TARGET = *libsndfile* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS -lmp3lame -lmpg123 -lFLAC -lvorbis -lvorbisenc -lopus -logg -lm
		elif [[ $TARGET = *libtiff* ]]; then
			WORK="$TARGET/work"
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS $WORK/lib/libtiffxx.a $WORK/lib/libtiff.a -lm -lz -ljpeg -Wl,-Bstatic -llzma -Wl,-Bdynamic
		elif [[ $TARGET = *libxml2* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS .libs/libxml2.a -lz -llzma -lm
		elif [[ $TARGET = *lua* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS $TARGET/repo/liblua.a -DLUA_USE_LINUX -DLUA_USE_READLINE -lreadline -lm -ldl  # -L/$OUT 
		elif [[ $TARGET = *openssl* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS -lpthread ./libcrypto.a ./libssl.a
		elif [[ $TARGET = *php* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS -lstdc++ -lpthread -lboost_fiber -lboost_context
		elif [[ $TARGET = *poppler* ]]; then
			WORK="$TARGET/work"
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS -I"$WORK/poppler/cpp" -I"$TARGET/repo/cpp" \
			"$WORK/poppler/cpp/libpoppler-cpp.a" "$WORK/poppler/libpoppler.a" "$WORK/lib/libfreetype.a" -lz -llzma -ljpeg -lz -lopenjp2 -lpng -ltiff -llcms2 -lm -lpthread -pthread
		elif [[ $TARGET = *sqlite3* ]]; then
            WORK="$TARGET/work"
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS $WORK/.libs/libsqlite3.a -lpthread -pthread -ldl -lm -lz 
		else 
			echo "Could not support this target $TARGET"
		fi
		popd
	)
	done

)
