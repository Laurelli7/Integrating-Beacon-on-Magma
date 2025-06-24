#!/bin/bash
set -e
export BEACON=$FUZZER/repo
mkdir -p "$SHARED/findings"


export AFL_SKIP_CPUFREQ=1
export AFL_NO_AFFINITY=1

# cp -r $OUT/output-$PROGRAM $SHARED

if [[ $TARGET = *openssl* || $TARGET = *lua* || $TARGET = *libpng* ]]; then
    echo "set timeout -t 1000+"
	FUZZ_TIMEOUT="-t 1000+"
fi

"$BEACON/Fuzzer/afl-fuzz" -m 100M $FUZZ_TIMEOUT -i "$TARGET/corpus/$PROGRAM" -o "$SHARED/findings" -d -- "$OUT/$PROGRAM" $ARGS 2>&1
