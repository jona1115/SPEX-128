`include "svunit_defines.svh"

`define NUM_BITS_128 128
`define NUM_BITS_64 64
`define NUM_BITS_32 32
`define ERROR_SIGNAL_NUM_BITS 32
`define DEBUG_SIGNAL_NUM_BITS 32

module SPEX128_top_unit_test;

  import svunit_pkg::svunit_testcase;

  import float_flag_pkg::*;
  import sp_mode_pkg::*;
  import float_metadata_pkg::*;
  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;


  string name = "SPEX128_top_ut";
  svunit_testcase svunit_ut;

  // DUT IO
  logic                                   s_i_clk;
  logic                                   s_i_rst_n;
  logic [`NUM_BITS_128-1:0]               s_i_x;
  logic [3:0]                             s_i_ctrl;
  logic [127:0]                           s_o_exp_x;
  logic                                   s_i_valid;
  logic                                   s_o_ready;
  logic [3:0]                             s_o_sanity_identifier;
  logic [`ERROR_SIGNAL_NUM_BITS-1:0]      s_o_error;
  logic [`DEBUG_SIGNAL_NUM_BITS-1:0]      s_o_debug;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  SPEX128_top #(
    .NUM_BITS_128(`NUM_BITS_128),
    .NUM_BITS_64(`NUM_BITS_64),
    .NUM_BITS_32(`NUM_BITS_32),
    .ERROR_SIGNAL_NUM_BITS(`ERROR_SIGNAL_NUM_BITS),
    .DEBUG_SIGNAL_NUM_BITS(`DEBUG_SIGNAL_NUM_BITS)
  ) my_SPEX128_top(
    .i_clk(s_i_clk),
    .i_rst_n(s_i_rst_n),
    .i_x(s_i_x),
    .i_ctrl(s_i_ctrl),
    .o_exp_x(s_o_exp_x),
    .i_valid(s_i_valid),
    .o_ready(s_o_ready),
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
    s_i_x     <= '0;
    s_i_ctrl  <= '0;
    s_i_valid <= '0;

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

    `include "cases/correctness.svh"

  `SVUNIT_TESTS_END

endmodule
