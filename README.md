# After cloning
1. This repo uses submodules, run this after cloning: `git submodule update --init --recursive`
2. Install required tools, see section: [Installation of Tools](https://github.com/jona1115/SPEX-128?tab=readme-ov-file#installation-of-tools)
3. ⚠️ Source the setup file, every time, before doing anything: `source setup.sh`

# Shortcuts
Below are easy, copy-pastable commands to do stuff. They, in theory, should "just work".
1. Run the SVUnit test using ModelSim/QuestaSim:
    ```sh
    cd tests/svunit/float_to_fixed      # You can go into any test folders, important!
    ../svunit_run.sh -s modelsim --ci   # Run -h for more info, --ci flag is more cleaner imo
                                        # By default, the script will use the current test folder
                                        # name as the DUT module, so the folder name has to be the
                                        # same as module name!
    # Advanced:
    # To compile additional modules, use --also flag, you can "--also" more than once
    cd tests/svunit/float_to_fixed      # Again, where you run the script is very important
    ../svunit_run.sh -s modelsim --also fixed128_partitionm_ts --also xxx
    ```
2. Run the SVUnit test (QuestaSim or ModelSim) and open the Questa/ModelSim waveform viewer:
    ```sh
    cd tests/svunit/float_to_fixed      # You can go into any test folders
    ../sim_and_gen_waveform.sh          # Run -h flag for more info
    # You could also generate and open modelsim in one line:
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
# To create a test when you don't have the UUT (Unit Under Test) code yet
create_unit_test.pl -module_name name_of_module_you_wanna_test

# To create a test when you have the UUT code
create_unit_test.pl name_of_module_you_wanna_test.sv

# Generate filelist (for Verilator to pick up which files to compile)
./gen_filelist.sh # Run this in project root

# Run the test using the modelsim simulator
# cd to tests/svunit/float_to_fixed
runSVUnit -s modelsim -f path/to/filelist.f # If you want to run SVUnit manually
# --- OR ---
./svunit_run.sh -s <simulator> # This script is just cool, use it instead of manually 
                               # for <simulator>, use QuestaSim, or ModelSim, DO NOT use 
                               # verilator (at least v5.040), it doesn't work
```
(but honestly, it is faster to just copy and paste existing test code and modify them...)

### Test Driven Development (TDD)
I want to dedicate this section to describing my testing/developing philosophy. I use TDD, it works, and in my opinion, creates a positive feedback loop of self-documenting and self-testing code. Not to mention easier to CI. So when you are reading the code, maybe take time to look over the test as well. This is because the code is derived by the tests, not the other way around.

# Synthesis and Implementation
I use Vivado 2023.1 to synthesize for Xilinx UltraScale+ xczu19eg-ffve1924-3-e.
Common Vivado issues:
- Vivado tends to throw an error saying level 2's lookup tables are too big, run this command to make Vivado happy: `set_param synth.elaboration.rodinMoreOptions "rt::set_parameter var_size_limit 1048576"`

I use Cadence Genus v22.16-s078_1 for ASIC synthesis and Innovus v22.10 for place-and-route. I used the [TSMC 65nm node](https://www.tsmc.com/english/dedicatedFoundry/technology/logic/l_65nm). The final chip has a core area of about $1.8mm^2$ and looks like this:

<img width="600" alt="Screenshot 2026-04-30 at 5 46 47 PM" src="https://github.com/user-attachments/assets/bfa2f824-f2e9-4192-a832-9ae94ce3ee79" />



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

# Commands below are from the Verilator installation docs
# Prerequisites:
sudo apt-get install git help2man perl python3 make autoconf g++ flex bison ccache
sudo apt-get install libgoogle-perftools-dev numactl perl-doc
sudo apt-get install libfl2  # Ubuntu only (ignore if it gives an error)
sudo apt-get install libfl-dev  # Ubuntu only (ignore if it gives an error)
sudo apt-get install zlibc zlib1g zlib1g-dev  # Ubuntu only (ignore if it gives an error)

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

# Credit

[![DOI](https://zenodo.org/badge/1081601132.svg)](https://doi.org/10.5281/zenodo.20058685)

This repo is part of a published work (still in review), come back later for the BibTeX!
