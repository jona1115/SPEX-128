`include "svunit_defines.svh"

`define NUM_BITS_128 128
`define NUM_BITS_64 64
`define NUM_BITS_32 32
`define ERROR_SIGNAL_NUM_BITS 32
`define DEBUG_SIGNAL_NUM_BITS 32

module fixed128_64_partitionc_unit_test;

  import svunit_pkg::svunit_testcase;

  import float_flag_pkg::*;
  import sp_mode_pkg::*;
  import float_metadata_pkg::*;
  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;


  string name = "fixed128_64_partitionc_ut";
  svunit_testcase svunit_ut;

  // DUT IO
  logic                                   s_i_clk;
  logic                                   s_i_rst_n;
  float_metadata_t                        s_i_metadata;
  float_metadata_t                        s_o_metadata;
  logic [12:0]                            s_i_a;
  logic [12:0]                            s_i_a2;
  binary64_t                              s_o_exp_a64a;
  binary64_t                              s_o_exp_a64b;
  binary128_t                             s_o_exp_a128;
  logic                                   s_i_valid64a;
  logic                                   s_i_valid64b;
  logic                                   s_i_valid128;
  logic                                   s_o_valid64a;
  logic                                   s_o_valid64b;
  logic                                   s_o_valid128;
  logic [3:0]                             s_o_sanity_identifier;
  logic [`ERROR_SIGNAL_NUM_BITS-1:0]      s_o_error;
  logic [`DEBUG_SIGNAL_NUM_BITS-1:0]      s_o_debug;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  fixed128_64_partitionc #(
    .NUM_BITS_128(`NUM_BITS_128),
    .NUM_BITS_64(`NUM_BITS_64),
    .NUM_BITS_32(`NUM_BITS_32),
    .ERROR_SIGNAL_NUM_BITS(`ERROR_SIGNAL_NUM_BITS),
    .DEBUG_SIGNAL_NUM_BITS(`DEBUG_SIGNAL_NUM_BITS),
    .INIT_128_FILE("fixed128_c_partition.hex"),
    .INIT_64_FILE("fixed64_c_partition.hex")
  ) my_fixed128_64_partitionc(
    .i_clk(s_i_clk),
    .i_rst_n(s_i_rst_n),
    .i_metadata(s_i_metadata),
    .o_metadata(s_o_metadata),
    .i_a(s_i_a),
    .i_a2(s_i_a2),
    .o_exp_a64a(s_o_exp_a64a),
    .o_exp_a64b(s_o_exp_a64b),
    .o_exp_a128(s_o_exp_a128),
    .i_valid64a(s_i_valid64a),
    .i_valid64b(s_i_valid64b),
    .i_valid128(s_i_valid128),
    .o_valid64a(s_o_valid64a),
    .o_valid64b(s_o_valid64b),
    .o_valid128(s_o_valid128),
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
    s_i_clk = '0;
    s_i_metadata = '0;
    s_i_a = '0;
    s_i_a2 = '0;
    s_i_valid64a = '0;
    s_i_valid64b = '0;
    s_i_valid128 = '0;

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


  // ---------- Helpers & ground truth ----------
  // Below code is either partially written by, or written with the aid of ChatGPT
  localparam string A128_FILE = my_fixed128_64_partitionc.INIT_128_FILE;
  localparam string A64_FILE  = my_fixed128_64_partitionc.INIT_64_FILE;
  binary128_t gt_mem128  [0:8191];
  binary64_t gt_mem64    [0:8191];

  // Load hex file into TB
  initial begin
    $display(">>>>> TB: loading A128_FILE LUT file: %s", A128_FILE);
    $display(">>>>> TB: loading A64_FILE LUT file: %s", A64_FILE);
    $readmemh(A128_FILE, gt_mem128);
    $readmemh(A64_FILE, gt_mem64);
  end

  // Push new input into pipeline by setting valid bit
  task automatic drive128(input logic [12:0] a, input bit v);
    s_i_a         = a;
    s_i_valid128  = v;
  endtask
  task automatic drive64a(input logic [12:0] a, input bit v);
    s_i_a         = a;
    s_i_valid64a  = v;
  endtask
  task automatic drive64b(input logic [12:0] a, input bit v);
    s_i_a2        = a;
    s_i_valid64b  = v;
  endtask

  // Advance the clock by 1.5 cycles
  task automatic tick;
    @(posedge s_i_clk);
    @(negedge s_i_clk); // Wait a bit
  endtask

  /**
   * Does a couple of things (in order):
   * 1. Make sure valid bit register is working
   * 2. If a is positive, read from positive LUT and compare against output of DUT, else
   *    read form negative LUT
   * 3. Make sure identifier, error, and debug pins are as expected
   * 
   * Warning: Must be used after drive() and tick()
   */
  task automatic expect_now_valid_and_value128(input logic [12:0] a, input string tag = "");
    `FAIL_IF_LOG(s_o_valid128 !== 1'b1,
      $sformatf(">>>>> %s: expected o_valid128=1, got %0b @%0t", tag, s_o_valid128, $time))
    `FAIL_IF_LOG(s_o_exp_a128 !== gt_mem128[a],
      $sformatf(">>>>> %s: 128 LUT mismatch idx=%0d (0x%0h). exp=0x%0h got=0x%0h",
        tag, a, a, gt_mem128[a], s_o_exp_a128))
    `FAIL_IF_LOG(s_o_sanity_identifier !== 4'b0001, ">>>>> sanity identifier != 0")
  endtask
  task automatic expect_now_valid_and_value64a(input logic [12:0] a, input string tag = "");
    `FAIL_IF_LOG(s_o_valid64a !== 1'b1,
      $sformatf(">>>>> %s: expected o_valid64a=1, got %0b @%0t", tag, s_o_valid64a, $time))
    `FAIL_IF_LOG(s_o_exp_a64a !== gt_mem64[a],
      $sformatf(">>>>> %s: 64a LUT mismatch idx=%0d (0x%0h). exp=0x%0h got=0x%0h",
        tag, a, a, gt_mem64[a], s_o_exp_a64a))
  endtask
  task automatic expect_now_valid_and_value64b(input logic [12:0] a, input string tag = "");
    `FAIL_IF_LOG(s_o_valid64b !== 1'b1,
      $sformatf(">>>>> %s: expected o_valid64b=1, got %0b @%0t", tag, s_o_valid64b, $time))
    `FAIL_IF_LOG(s_o_exp_a64b !== gt_mem64[a],
      $sformatf(">>>>> %s: 64b LUT mismatch idx=%0d (0x%0h). exp=0x%0h got=0x%0h",
        tag, a, a, gt_mem64[a], s_o_exp_a64b))
  endtask

  /**
   * Does a couple of things (in order):
   * 1. Make sure valid bit register is working
   * 2. See if the output of DUT is the same as 
   * 
   * Warning: Must be used after drive(xxx, 0) and tick()
   */
  task automatic expect_hold128(input binary128_t exp, input string tag = "");
    `FAIL_IF_LOG(s_o_valid128 !== 1'b0,
      $sformatf(">>>>> %s: expected o_valid128=0 during bubble, got %0b", tag, s_o_valid128))
    `FAIL_IF_LOG(s_o_exp_a128 !== exp,
      $sformatf(">>>>> %s: 128 held value not preserved", tag))
  endtask
  task automatic expect_hold64a(input binary64_t exp, input string tag = "");
    `FAIL_IF_LOG(s_o_valid64a !== 1'b0,
      $sformatf(">>>>> %s: expected o_valid64a=0 during bubble, got %0b", tag, s_o_valid64a))
    `FAIL_IF_LOG(s_o_exp_a64a !== exp,
      $sformatf(">>>>> %s: 64a held value not preserved", tag))
  endtask
  task automatic expect_hold64b(input binary64_t exp, input string tag = "");
    `FAIL_IF_LOG(s_o_valid64b !== 1'b0,
      $sformatf(">>>>> %s: expected o_valid64b=0 during bubble, got %0b", tag, s_o_valid64b))
    `FAIL_IF_LOG(s_o_exp_a64b !== exp,
      $sformatf(">>>>> %s: 64b held value not preserved", tag))
  endtask

  function automatic float_metadata_t mk_meta(input sp_mode_t     mode,
                                              input float_flag_t  ta = NORMAL,
                                              input float_flag_t  tb = NORMAL,
                                              input float_flag_t  tc = NORMAL,
                                              input float_flag_t  td = NORMAL
                                              );
    mk_meta.sp_mode      = mode;
    mk_meta.float_type_a = ta;
    mk_meta.float_type_b = tb;
    mk_meta.float_type_c = tc;
    mk_meta.float_type_d = td;
  endfunction

  task automatic drive_meta(input sp_mode_t     mode,
                            input float_flag_t  ta = NORMAL,
                            input float_flag_t  tb = NORMAL,
                            input float_flag_t  tc = NORMAL,
                            input float_flag_t  td = NORMAL
                            );
    s_i_metadata = mk_meta(mode, ta, tb, tc, td);
  endtask

  task automatic expect_metadata_passthrough(input float_metadata_t exp, input string tag = "");
    `FAIL_IF_LOG(s_o_metadata !== exp,
      $sformatf(">>>>> %s: metadata mismatch exp=%p got=%p", tag, exp, s_o_metadata))
  endtask

  task automatic expect_valid128_passthrough(input bit v, input string tag = "");
    `FAIL_IF_LOG(s_o_valid128 !== v,
      $sformatf(">>>>> %s: expected o_valid128=%0b, got %0b", tag, v, s_o_valid128))
  endtask

  task automatic clear_all_valids();
    s_i_valid64a = 1'b0;
    s_i_valid64b = 1'b0;
    s_i_valid128 = 1'b0;
  endtask
  // --------------------------------------------


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
