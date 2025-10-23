# SPEX-128

# After cloning
1. This repo uses submodules, run this after cloning: `git submodule update --init --recursive`

# How to use?
1. Always, source the setup file before doing anything: `source setup.sh`

# Creating SVUnit Tests
```sh
# Setup environment:
# cd into your svunit folder
# export SVUNIT_INSTALL=`pwd`
# export PATH=$PATH:$SVUNIT_INSTALL"/bin"
# source Setup.bsh

# To create a test when you dont have the UUT (Unit Under Test) code yet
create_unit_test.pl -module_name name_of_module_you_wanna_test

# To create a test when you have the UUT code
create_unit_test.pl name_of_module_you_wanna_test.sv

# Generate filelist (for verilator to pick up which files to compile)
./gen_filelist.sh # Run this in project root

# Run the test using verilor simulator
runSVUnit -s verilator -f path/to/filelist.f
# e.g: jonathan@jonathan-msi:~/SPEX-128/tests/svunit/float_to_fixed_0 $ runSVUnit -s verilator -f ../filelist.f
```

# Installation of Tools
## SVUnit
Installation commands:
```sh
git clone git@github.com:svunit/svunit.git
cd svunit
git checkout v3.38.0

# Commands below are from the README.md of SVUnit:
export SVUNIT_INSTALL=`pwd`
export PATH=$PATH:$SVUNIT_INSTALL"/bin"
source Setup.bsh
```

## Verilator
```sh
git clone git@github.com:verilator/verilator.git
cd verilator
git checkout v5.040

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