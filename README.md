**Purpose**

   The goal of this repository is to help you compile and run SPEC.
   This is especially useful in case of targets with limited resources
   be it available memory, CPU performance or even local storage
   not large enough to accommodate entire SPEC source tree & tools.

   Note this approach makes obtained results "non-reportable", see
   https://www.spec.org/cpu2006/Docs/runrules.html for much more details.

**Requirements**

   - You must have your own copy of SPEC CPU2006 v1.2.
   - You must have SPEC tools built and entire test-suite installed,
     see https://www.spec.org/cpu2006/Docs/install-guide-unix.html.


**Details**

   We will compile the binaries "in vivo", calling into the actual SPEC CPU2006
   directory. Once completed, the binaries are copied into staging folder,
   for example "x86_64-spec-test" which might be copied on the target as it is.

   The reasoning is that compiling the benchmarks is complicated and difficult (so
   why redo that effort?), but we want better control over executing the binaries.
   Of course, we are forgoing the validation and results building infrastructure of
   SPEC.


**Setup**

   - Set the $SPEC_DIR variable in your environment to point to CPU2006-1.2
     instrallation location, not just extracted .iso contents.
   - Modify or add your target configuration of choice (.cfg-file),
     see https://www.spec.org/cpu2006/Docs/config.html for detailed explanaton for
     all items set in the configuration file. Then it will get copied over to
     $SPEC_DIR/configs when compiling the benchmarks.
   - Modify the BENCHMARKS variable in speckle-build.sh as required to set which
     benchmarks you would like to compile and run.
   - Copy over entire folder with build tests (for example "x86_64-spec-test") to
     the target's filesystem and there execute speckle-run.sh script. See reported
     duration of each benchmark execution in seconds.


**To compile binaries**

        ./speckle-build.sh

**To run binaries**

        ./speckle-run.sh
