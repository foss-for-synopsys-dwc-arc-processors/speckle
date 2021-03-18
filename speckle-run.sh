#!/bin/bash

usage="$(basename "$0") [-h,--help] [--verbose]

where:
    -h or --help shows this help text
    -v or --verbose - prints complete execution command-lines"

for i in "$@"
do
case $i in
    -v|--verbose)
    verbose=yes
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

# This way we may execute this script from any location
base_dir=$(dirname $(readlink -f $0))
mkdir -p ${base_dir}/output

for dir in ${base_dir}/benchmarks/*; do
    b="$(basename "${dir}")"
    echo -e "\nExecuting: ${b}"

    # Reset timer
    SECONDS=0
    pushd ${base_dir}/benchmarks/${b} > /dev/null
    short_exe=${b##*.} # cut off the numbers ###.short_exe
    # There's one exception in a naming scheme though...
    if [ $b == "483.xalancbmk" ]; then
        short_exe=Xalan
    fi

    # Read the command file
    IFS=$'\n' read -d '' -r -a commands < ${base_dir}/commands/${b}.cmd

    # Run each workload
    count=0
    for input in "${commands[@]}"; do

        # skip any comment out lines in the cmd files
        if [[ ${input:0:1} == '#' ]]; then
            continue
        fi

        # SPECKLE_CMD_PREFIX env var could be used for e.g. "perf stat"
        cmd="${SPECKLE_CMD_PREFIX} ./${short_exe} ${input} > ${base_dir}/output/${short_exe}.${count}.out"

        # Print full command-line we're going to execute if in verbose mode
        if [ "$verbose" == "yes" ]; then
            echo "workload=[${cmd}], instance #${instance}"
        fi

        # Really execute full command
        eval ${cmd}

        ((count++))
    done
    popd > /dev/null
    echo "${b} done in $SECONDS seconds"
done

echo "All done!"
