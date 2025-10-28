`include "svunit_defines.svh"

// ChatGPT gave me this awesome macro
// It checks that float_to_fixed convert float to fix correctly in 2 cycles.
`define CHECK_CORRECT_CONVERT_LATENCY_2_CYCLES(in_float, in_ctrl, expected) \
  begin \
    logic [127:0] _prev = s_o_fixed;              \
    @(negedge s_i_clk);                           \
    s_i_ctrl       = in_ctrl;                     \
    s_i_float      = in_float;                    \
    @(posedge s_i_clk); /* +1 */                  \
    `FAIL_UNLESS_EQUAL(s_o_fixed, _prev)          \
    @(posedge s_i_clk); /* +2 */                  \
    `FAIL_UNLESS_EQUAL(s_o_fixed, expected)       \
  end

/**
 * 
 * This test checks for:
 * 1. Latency of the module (should be 2 cycles)
 * 2. Result of the module
 * 
 */
module float_to_fixed_correctness_unit_test;
  import svunit_pkg::svunit_testcase;

  import float_flag_pkg::*;
  import sp_mode_pkg::*;
  import float_metadata_pkg::*;
  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;


  string name = "float_to_fixed_ut";
  svunit_testcase svunit_ut;

  // DUT IO
  logic             s_i_clk;
  logic             s_i_reset;
  logic [127:0]     s_i_float;
  logic [3:0]       s_i_ctrl;
  logic [127:0]     s_o_fixed;
  float_metadata_t  s_o_metadata;
  logic [3:0]       s_o_sanity_identifier;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  float_to_fixed my_float_to_fixed(
    .i_clk(s_i_clk),
    .i_reset(s_i_reset),
    .i_float(s_i_float),
    .i_ctrl(s_i_ctrl),
    .o_fixed(s_o_fixed),
    .o_metadata(s_o_metadata),
    .o_sanity_identifier(s_o_sanity_identifier)
  );


  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);
  endfunction


  //===================================
  // Setup for running the Unit Tests
  //===================================
  task setup();
    // For testing latency
    logic [127:0] prev_out;
  
    svunit_ut.setup();
    /* Place Setup Code Here */
    s_i_float = '0;
    s_i_ctrl = '0;

    
  endtask

// Toggle clock
initial begin
  s_i_clk = 1'b0;
  forever #1 s_i_clk = ~s_i_clk; // 2 unit period
end

  //===================================
  // Here we deconstruct anything we 
  // need after running the Unit Tests
  //===================================
  task teardown();
    svunit_ut.teardown();
    /* Place Teardown Code Here */

  endtask

  //===================================
  // All tests are defined between the
  // SVUNIT_TESTS_BEGIN/END macros
  //
  // Each individual test must be
  // defined between `SVTEST(_NAME_)
  // `SVTEST_END
  //
  // i.e.
  //   `SVTEST(mytest)
  //     <test code>
  //   `SVTEST_END
  //===================================
  `SVUNIT_TESTS_BEGIN

    `include "cases/single_mode_basic_float_to_fixed_functionality.svh"
    `include "cases/two_sp_mode_basic_float_to_fixed_functionality.svh"
    `include "cases/four_sp_mode_basic_float_to_fixed_functionality.svh"
    // `include "cases/float_to_fixed_tests_from_file.svh"

  `SVUNIT_TESTS_END

endmodule
