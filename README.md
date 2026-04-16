# After cloning
1. This repo uses submodules, run this after cloning: `git submodule update --init --recursive`
2. Install required tools, see section: [Installation of Tools](https://github.com/jona1115/SPEX-128?tab=readme-ov-file#installation-of-tools)
3. ⚠️ Source the setup file, everytime, before doing anything: `source setup.sh`

# Shortcuts
Below are easy, copy-pastable commands to do stuff. They, in theory, should "just work".
1. Run svunit test using Modelsim/Questasim:
    ```sh
    cd tests/svunit/float_to_fixed      # You can go into any test folders, important!
    ../svunit_run.sh -s modelsim --ci   # Run -h for more info, --ci flag is more cleaner imo
                                        # By default, the script will use the current test folder
                                        # name as the DUT module, so folder name has to be the
                                        # same as module name!
    # Advanced:
    # To compile additional module, use --also flag, you can "--also" more than once
    cd tests/svunit/float_to_fixed      # Again, where you run the script is very important
    ../svunit_run.sh -s modelsim --also fixed128_partitionm_ts --also xxx
    ```
2. Run svunit test (simulator questasim or modelsim) and open questa/modelsim waveform viewer:
    ```sh
    cd tests/svunit/float_to_fixed      # You can go into any test folders
    ../sim_and_gen_waveform.sh          # Run -h flag for more info
    # You could also generate and open modelsim in oneline:
    ../sim_and_gen_waveform.sh && vsim -view ./waves/svunit.wlf &
    # And even include the do file cli:
    ../sim_and_gen_waveform.sh && vsim -view ./waves/svunit.wlf -do "./dos/wave.do" &
    ```
3. Git log, this repo has some pretty stupid commits that are long, so use this for a nicer git log:
    ```sh
    git log --graph --decorate --all --format='%C(auto)%h %d %<(60,trunc)%s'
    ```

# Creating/running SVUnit Tests
Note: If you are just running tests, you don't need to care about this.
```sh
# To create a test when you dont have the UUT (Unit Under Test) code yet
create_unit_test.pl -module_name name_of_module_you_wanna_test

# To create a test when you have the UUT code
create_unit_test.pl name_of_module_you_wanna_test.sv

# Generate filelist (for verilator to pick up which files to compile)
./gen_filelist.sh # Run this in project root

# Run the test using modelsim simulator
# cd to tests/svunit/float_to_fixed
runSVUnit -s modelsim -f path/to/filelist.f # If you want to run svunit manually
# --- OR ---
./svunit_run.sh -s <simulator> # This script is just cool, use it instead of manually 
                               # for <simulator>, use questasim, or modelsim, DO NOT use 
                               # verilator (at least v5.040), it doesn't work
```
### Test Driven Development (TDD)
I want to dedicate this section to describing my testing/developing philosophy. I use TDD, it works, and in my opinion, creates a positive feedback loop of self-documenting, and self-testing code. Not to mention easier to CI. So when you are reading the code, maybe take time to also look over the test. This is because the code is derived by the tests, not the other way around.

# Vivado
I use Vivado to synthesize for FPGA.
Common Vivado issues:
- Vivado tends to throw an error saying level 2's lookup tables are too big, run this command to make Vivado happy: `set_param synth.elaboration.rodinMoreOptions "rt::set_parameter var_size_limit 1048576"`

# Installation of Tools
## SVUnit (no need to install, see ["After cloning"](https://github.com/jona1115/SPEX-128?tab=readme-ov-file#after-cloning))
Installation commands:
```sh
git clone git@github.com:svunit/svunit.git
cd svunit
git checkout v3.38.0 # this tag is tried and true

# Commands below are from the README.md of SVUnit:
export SVUNIT_INSTALL=`pwd`
export PATH=$PATH:$SVUNIT_INSTALL"/bin"
source Setup.bsh
```

<!-- ## Verilator (not used for this project)
```sh
git clone git@github.com:verilator/verilator.git
cd verilator
git checkout v5.040 # this tag is tried and true

# Commands below are from the verilator installation docs
# Prerequisites:
sudo apt-get install git help2man perl python3 make autoconf g++ flex bison ccache
sudo apt-get install libgoogle-perftools-dev numactl perl-doc
sudo apt-get install libfl2  # Ubuntu only (ignore if gives error)
sudo apt-get install libfl-dev  # Ubuntu only (ignore if gives error)
sudo apt-get install zlibc zlib1g zlib1g-dev  # Ubuntu only (ignore if gives error)

unsetenv VERILATOR_ROOT
autoconf         # Create ./configure script
./configure      # Configure and create Makefile
make -j `nproc`  # Build Verilator itself (if error, try just 'make')
sudo make install
``` -->

## Modelsim
Follow [this link](https://gist.github.com/Razer6/cafc172b5cffae189b4ecda06cf6c64f).

# A note on AI use
1. 99% of bash scripts are AI-generated. I don't bash like that, and I don't care (at least at this time) about learning to bash.
2. Some code is debugged with the help of AI, but only a super minority of the code is written by AI.
3. Code written by AI is cited in comments, using language like: "ChatGPT generated", "vibe coded", etc.
