# Directory Organization

The way SVUnit read stuff is interesting. Tests are grouped into "test suites". See more [here](https://docs.svunit.org/en/latest/structure_and_workflow.html).

The way I set my project up:
1. From this location, each module has its own folder.
2. Inside each module folder are test suites.
3. There is a main "template" (language used in SVUnit docs) in each test suite. The name of the main template MUST end with "_unit_test". Same thing goes to the name of the `module` defined in each template.
4. The main template will `include` `.svh` files in the `cases` folder in its body.
5. The actual test code are located in the `.svh` files.

# Scripts
I have set up scripts that you can run to make your life much easier. Two main ones are:
1. [`svunit_run.sh`](https://github.com/jona1115/SPEX-128/blob/13-write-level-2-module/tests/svunit/svunit_run.sh) - For running svunit tests, it also does a lot with generating filelist, use the `-h` flag to se more
2. [`sim_and_gen_waveform.sh`](https://github.com/jona1115/SPEX-128/blob/13-write-level-2-module/tests/svunit/sim_and_gen_waveform.sh) - For running svunit_run.sh + generating waveforms that can be viewed in modelsim/questasim.
3. [`./run_all_test.sh -s modelsim`](https://youtu.be/txp2Tdiaw34?si=fuYJVkKCDHxA17Ul) - For running regression tests, this is the final boss, pass this and we are good.

# SVUnit Tips:
Macros you can use to do tests
```sv
`define FAIL_IF(exp)
`define FAIL_UNLESS(exp)

`define FAIL_IF_EQUAL(a,b)
`define FAIL_UNLESS_EQUAL(a,b)

`define FAIL_IF_STR_EQUAL(a,b)
`define FAIL_UNLESS_STR_EQUAL(a,b)
```
For more see: [https://docs.svunit.org/en/latest/](https://docs.svunit.org/en/latest/)
