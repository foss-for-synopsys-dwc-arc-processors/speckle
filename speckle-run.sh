#!/bin/bash

usage="$(basename "$0") [-h,--help] [--verbose]

where:
    -h or --help shows this help text
    -j or --jobs specifies amount of parallel executions of the same test
    -v or --verbose - prints complete execution command-lines"

for i in "$@"
do
case $i in
    -v|--verbose)
    verbose=yes
    shift # past argument=value
    ;;
    -j|--jobs=*)
    jobs="${i#*=}"
    shift # past argument=value
    ;;
    -h|--help)
    echo "$usage"
    exit
    ;;
    *)
    echo "$usage" >&2
    exit 1
    ;;
esac
done

jobs="${jobs:-1}"

# This way we may execute this script from any location
base_dir=$(dirname $(readlink -f $0))
mkdir -p ${base_dir}/output

for dir in ${base_dir}/benchmarks/*; do
    b="$(basename "${dir}")"
    echo -e "\nExecuting: ${b}"

    pushd ${base_dir}/benchmarks/${b} > /dev/null
    short_exe=${b##*.} # cut off the numbers ###.short_exe
    # There's one exception in a naming scheme though...
    if [ $b == "483.xalancbmk" ]; then
        short_exe=Xalan
    fi

    # read the command file
    IFS=$'\n' read -d '' -r -a commands < ${base_dir}/commands/${b}.cmd

    # run each workload
    count=0
    TOT=0
    for input in "${commands[@]}"; do

        # skip any comment out lines in the cmd files
        if [[ ${input:0:1} == '#' ]]; then
            continue
        fi

        # SPECKLE_CMD_PREFIX env var could be used for e.g. "perf stat"
        cmd="${SPECKLE_CMD_PREFIX} ./${short_exe} ${input} > ${base_dir}/output/${short_exe}.${count}.out"

        # Run multiple instances if requested
        if [ $jobs -eq 1 ]; then
            if [ "$verbose" == "yes" ]; then
                echo "workload=[${cmd}]"
            fi
            SECONDS=0
            eval ${cmd}
            TOT=$(($TOT + $SECONDS))
            echo "== $SECONDS seconds"
            ((count++))
        else
            for instance in $(seq 1 $jobs); do
                if [ "$verbose" == "yes" ]; then
                    echo "workload=[${cmd}], instance #${instance}"
                fi
                eval ${cmd} &
                ((count++))
            done
            wait # Wait until all started above instances are done
            TOT=$(($TOT + $SECONDS))
            echo "== $SECONDS seconds"
        fi
    done
    echo "==== ${b} all done in $TOT seconds"
    popd > /dev/null
done

echo "All done!"
