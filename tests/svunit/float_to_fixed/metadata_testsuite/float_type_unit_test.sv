`include "svunit_defines.svh"

module float_type_unit_test;

`define NUM_BITS_128 128
`define NUM_BITS_64 64
`define NUM_BITS_32 32
`define FIXED128_SHIFT_AMOUNT_INT_PORTION_OVERFLOW 9
`define FIXED64_SHIFT_AMOUNT_INT_PORTION_OVERFLOW 9
`define FIXED32_SHIFT_AMOUNT_INT_PORTION_OVERFLOW 9
`define ERROR_SIGNAL_NUM_BITS 32
`define DEBUG_SIGNAL_NUM_BITS 32

  import svunit_pkg::svunit_testcase;

  import float_flag_pkg::*;
  import sp_mode_pkg::*;
  import float_metadata_pkg::*;
  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;
  import unbiasing_pkg::*;


  string name = "float_to_fixed_ut";
  svunit_testcase svunit_ut;

  // DUT IO
  logic                                   s_i_clk;
  logic                                   s_i_rst_n; // Synchronous
  logic [`NUM_BITS_128-1:0]                s_i_float;
  logic [3:0]                             s_i_ctrl;
  logic [127:0]                           s_o_fixed;
  float_metadata_t                        s_o_metadata;
  logic [3:0]                             s_o_sanity_identifier;
  logic [`ERROR_SIGNAL_NUM_BITS-1:0]       s_o_error;
  logic [`DEBUG_SIGNAL_NUM_BITS-1:0]       s_o_debug;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  float_to_fixed #(
    .NUM_BITS_128(`NUM_BITS_128),
    .NUM_BITS_64(`NUM_BITS_64),
    .NUM_BITS_32(`NUM_BITS_32),
    .ERROR_SIGNAL_NUM_BITS(`ERROR_SIGNAL_NUM_BITS),
    .DEBUG_SIGNAL_NUM_BITS(`DEBUG_SIGNAL_NUM_BITS)
  ) my_float_to_fixed(
    .i_clk(s_i_clk),
    .i_rst_n(s_i_rst_n),
    .i_float(s_i_float),
    .i_ctrl(s_i_ctrl),
    .o_fixed(s_o_fixed),
    .o_metadata(s_o_metadata),
    .o_sanity_identifier(s_o_sanity_identifier),
    .o_error(s_o_error),
    .o_debug(s_o_debug)
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
    svunit_ut.setup();
    /* Place Setup Code Here */
    s_i_clk   = '0;
    s_i_float = '0;
    s_i_ctrl  = '0;

    s_i_rst_n   = 1'b0;                 // assert sync reset
    repeat (2) @(posedge s_i_clk);      // hold for > one posedge
    s_i_rst_n   = 1'b1;                 // deassert
    @(posedge s_i_clk);                 // let it stablize
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

  // ----------------------------------
  // Helpers
  // ----------------------------------
  `define LATENCY (my_float_to_fixed.MODULE_LATENCY)

  task automatic wait_n_ticks(int n);
    repeat (n) @(posedge s_i_clk) @(negedge s_i_clk);
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

    `include "cases/single_mode.svh"
    `include "cases/two_sp_mode.svh"
    `include "cases/four_sp_mode.svh"

  `SVUNIT_TESTS_END

endmodule
