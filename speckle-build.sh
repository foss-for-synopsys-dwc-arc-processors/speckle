#!/bin/bash

if [ -z  "$SPEC_DIR" ]; then
    echo "  Please set the SPEC_DIR environment variable to point to your copy of SPEC CPU2006."
    exit 1
fi

usage="$(basename "$0") [-h,--help] [--size=(test|ref)] [--conf=(arc|arm|x86_64)]

where:
    -h or --help shows this help text
    --size=(test|ref) selects input data size: test or ref (default: test)
    --config=(arc|arm|x86_64) selects target system configuration: arc, arm or x86_64 (default: x86_64)

    Note, both --size & --config options have exactly the same meaning as for the original runspec"

for i in "$@"
do
case $i in
    --size=*)
    size="${i#*=}"
    shift # past argument=value
    ;;
    --config=*)
    config="${i#*=}"
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

config="${config:-x86_64}"
size="${size:-test}"

benchmarks=(400.perlbench 401.bzip2 403.gcc 429.mcf 445.gobmk 456.hmmer 458.sjeng 462.libquantum 464.h264ref 471.omnetpp 473.astar 483.xalancbmk)

echo "Building for config=${config} and size=${size}."

spec_logs=spec.log
base_dir=$(dirname $(readlink -f $0))
copy_dir=${base_dir}/${config}-spec-${size}

# Make sure target folder doesn't have reminders of previous builds
if [ -d "$copy_dir" ]; then rm -Rf $copy_dir; fi
# Make folder for commands and its needed parents
mkdir -p $copy_dir/commands

# Copy config file so that SPEC utilities may see it
cp ${config}.cfg $SPEC_DIR/config/

for b in ${benchmarks[@]}; do
    # Semi-hardcoded path assuming SPEC installation tree is clean, thus ".0000" in the end
    spec_run_dir=$SPEC_DIR/benchspec/CPU2006/$b/run/run_base_${size}_${config}.0000;
    spec_output_data_dir=$SPEC_DIR/benchspec/CPU2006/$b/data/${size}/output;
    short_exe=${b##*.} # cut off the numbers ###.short_exe
    echo "Working on: ${short_exe}"

    pushd $SPEC_DIR > /dev/null
    . ./shrc
    # Clean-up is required for above assumption to be valid
    runspec --config ${config} --size ${size} --action trash ${short_exe} > ${base_dir}/${spec_logs}
    if [ $? -ne 0 ]; then
        echo "runspec invication failed, see ${spec_logs} for more details"
        exit -1
    fi
    # Build benchmark & prepare execution environment for it
    runspec --config ${config} --size ${size} --action setup ${short_exe} >> ${base_dir}/${spec_logs}
    if [ $? -ne 0 ]; then
        echo "runspec invication failed, see ${SPEC_LOG} for more details"
        exit -1
    fi
    popd > /dev/null

    # Copy benchmark, command & input data
    # Create target folder for the benchmark
    mkdir -p $copy_dir/benchmarks/$b
    # Create target folder for the reference results
    mkdir -p $copy_dir/output-reference/$b
    # Copy file with commands for this benchmark, note we drop "size" part
    # This allows us to use universal script for execution later
    cp commands/$b.${size}.cmd $copy_dir/commands/$b.cmd
    # Copy contents of "run" folder: input data & benchmark binary
    for f in $spec_run_dir/*; do
        if [[ -d $f ]]; then
            cp -r $f $copy_dir/benchmarks/$b/$(basename "$f")
        else
            cp $f $copy_dir/benchmarks/$b/$(basename "$f")
        fi
    done
    # There's one exception in a naming scheme though...
    if [ $b == "483.xalancbmk" ]; then
        short_exe=Xalan
    fi
    # Get rid of meaningless "_base" in benchmark name, that simplifies execution script
    mv $copy_dir/benchmarks/$b/${short_exe}_base.${config} $copy_dir/benchmarks/$b/${short_exe}
    # Copy contents of "output" folder: reference output data
    for f in $spec_output_data_dir/*; do
        cp $f $copy_dir/output-reference/$b/$(basename "$f")
    done
done

echo "Copying over execution script"
cp speckle-run.sh ${copy_dir}

echo "Done!"
