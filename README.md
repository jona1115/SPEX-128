# After cloning
1. This repo uses submodules, run this after cloning: `git submodule update --init --recursive`
2. Install required tools, see section: [Installation of Tools](https://github.com/jona1115/SPEX-128?tab=readme-ov-file#installation-of-tools)
3. Source the setup file, everytime, before doing anything: `source setup.sh`

# Creating/running SVUnit Tests
```sh
# To create a test when you dont have the UUT (Unit Under Test) code yet
create_unit_test.pl -module_name name_of_module_you_wanna_test

# To create a test when you have the UUT code
create_unit_test.pl name_of_module_you_wanna_test.sv

# Generate filelist (for verilator to pick up which files to compile)
./gen_filelist.sh # Run this in project root

# Run the test using verilor simulator
# cd to tests/svunit/float_to_fixed
runSVUnit -s verilator -f path/to/filelist.f # If you want to run svunit manually
# --- OR ---
./svunit_run.sh -s <simulator> # This script is just cool, use it instead of manually 
                               # for <simulator>, use questasim, verilator doesn't work
```
### Test Driven Development (TDD)
I want to dedicate this section to describing my testing/developing philosophy. I use TDD, it works, and in my opinion, creates a positive feedback loop of self-documenting, and self-testing code. Not to mention easier to CI. So when you are reading the code, maybe take time to also look over the test. This is because the code is derived by the tests, not the other way around.


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

## Verilator (not used for this project)
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
```