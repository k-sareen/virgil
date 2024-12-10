#!/bin/bash

. ../common.bash lib

let PROGRESS_PIPE=1
if [[ "$1" =~ "-trace-calls=" ]]; then
    V3C_OPTS="$1 $V3C_OPTS"
    shift
    let PROGRESS_PIPE=0
fi

if [[ "$1" =~ "-fatal-calls=" ]]; then
    V3C_OPTS="$1 $V3C_OPTS"
    shift
    let PROGRESS_PIPE=0
fi

if [ $# -gt 0 ]; then
  TESTS=$*
else
  TESTS=*.v3
fi

LIB_FILES="$VIRGIL_LOC/lib/util/*.v3 $VIRGIL_LOC/lib/math/*.v3"

function do_v3i() {
    print_status Running v3i
    P=$OUT/run.out
    run_v3c "" $TESTS $LIB_FILES
    if [ "$?" != 0 ]; then
	printf "  %sfail%s: lib tests failed to compile\n" "$RED" "$NORM"
	exit 1
    fi

    if [ "$PROGRESS_PIPE" = 1 ]; then
	run_v3c "" -run $TESTS $LIB_FILES | tee $P | $PROGRESS
    else
	run_v3c "" -run $TESTS $LIB_FILES | tee $P
    fi
}

function do_compiled() {
    T=$OUT/$target
    mkdir -p $T

    C=$T/compile.out
    R=$OUT/$target/run.out

    print_compiling $target
    if [ -z "$target" ]; then
	$AENEAS_TEST $V3C_OPTS -output=$T $TESTS $LIB_FILES &> $C
    else
        local F=$VIRGIL_LOC/bin/dev/v3c-$target
        if [ ! -x "$F" ]; then
            F=$VIRGIL_LOC/bin/v3c-$target
        fi
	V3C=$AENEAS_TEST $F $V3C_OPTS -output=$T $TESTS $LIB_FILES &> $C
    fi

    # run_v3c $target -output=$T $TESTS $LIB_FILES &> $C
    check_no_red $? $C

    print_status Running $target
    if [ -x $CONFIG/run-$target ]; then
	$OUT/$target/main $TESTS | tee $R | $PROGRESS
    else
	printf "${YELLOW}skipped${NORM}\n"
    fi
}

for target in $(get_io_targets); do
    if [ "$target" = v3i ]; then
	do_v3i
    else
	do_compiled
    fi
done
