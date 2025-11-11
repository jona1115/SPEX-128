`include "svunit_defines.svh"

`define NUM_BITS_128 128
`define NUM_BITS_64 64
`define NUM_BITS_32 32
`define ERROR_SIGNAL_NUM_BITS 32
`define DEBUG_SIGNAL_NUM_BITS 32

module fixed32_partitiona_unit_test;

  import svunit_pkg::svunit_testcase;

  import float_flag_pkg::*;
  import sp_mode_pkg::*;
  import float_metadata_pkg::*;
  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;


  string name = "fixed32_partitiona_ut";
  svunit_testcase svunit_ut;

  // DUT IO
  logic                                   s_i_clk;
  logic                                   s_i_reset;
  logic [10:0]                            s_i_a;
  binary32_t                              s_o_exp_a;
  logic                                   s_i_valid;
  logic                                   s_o_valid;
  logic [3:0]                             s_o_sanity_identifier;
  logic [`ERROR_SIGNAL_NUM_BITS-1:0]      s_o_error;
  logic [`DEBUG_SIGNAL_NUM_BITS-1:0]      s_o_debug;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  fixed32_partitiona #(
    .NUM_BITS_128(`NUM_BITS_128),
    .NUM_BITS_64(`NUM_BITS_64),
    .NUM_BITS_32(`NUM_BITS_32),
    .ERROR_SIGNAL_NUM_BITS(`ERROR_SIGNAL_NUM_BITS),
    .DEBUG_SIGNAL_NUM_BITS(`DEBUG_SIGNAL_NUM_BITS)
  ) my_fixed32_partitiona(
    .i_clk(s_i_clk),
    .i_reset(s_i_reset),
    .i_a(s_i_a),
    .o_exp_a(s_o_exp_a),
    .i_valid(s_i_valid),
    .o_valid(s_o_valid),
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
    s_i_a = '0;
    s_i_valid = '0;

    s_i_reset   = 1'b0;                 // assert sync reset
    repeat (2) @(posedge s_i_clk);      // hold for > one posedge
    s_i_reset   = 1'b1;                 // deassert
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
  localparam string POS_LUT_FILE = my_fixed32_partitiona.INIT_POS_FILE;
  localparam string NEG_LUT_FILE = my_fixed32_partitiona.INIT_NEG_FILE;
  binary32_t gt_mempos [0:1023];
  binary32_t gt_memneg [0:1023];

  // Load hex file into TB
  initial begin
    $display(">>>>> TB: loading POS LUT file: %s", POS_LUT_FILE);
    $display(">>>>> TB: loading NEG LUT file: %s", NEG_LUT_FILE);
    $readmemh(POS_LUT_FILE, gt_mempos);
    $readmemh(NEG_LUT_FILE, gt_memneg);
  end

  // Push new input into pipeline by setting valid bit
  task automatic drive(input logic [10:0] a, input bit v);
    s_i_a     = a;
    s_i_valid = v;
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
  task automatic expect_now_valid_and_value(input logic [10:0] a, input string tag = "");
    `FAIL_IF_LOG(s_o_valid !== 1'b1,
                $sformatf(">>>>> %s: expected o_valid=1, got %0b @%0t", tag, s_o_valid, $time))
    `FAIL_IF_LOG(s_o_exp_a !== ((a[10]===1'b0)?gt_mempos[a[9:0]]:gt_memneg[a[9:0]]),
                $sformatf(">>>>> %s: LUT mismatch for %s a=%0d (0x%0h), expected:0x%0h, got:0x%0h", 
                  tag, (a[10]===1'b0)?"positive":"negative", a[9:0], a[9:0], ((a[10]===1'b0)?gt_mempos[a[9:0]]:gt_memneg[a[9:0]]), s_o_exp_a))
    `FAIL_IF_LOG(s_o_sanity_identifier !== 4'b0000, ">>>>> sanity identifier != 0")
    `FAIL_IF_LOG(s_o_error !== '0,                  ">>>>> o_error non-zero")
    `FAIL_IF_LOG(s_o_debug !== '0,                  ">>>>> o_debug non-zero")
  endtask

  /**
   * Does a couple of things (in order):
   * 1. Make sure valid bit register is working
   * 2. See if the output of DUT is the same as 
   * 
   * Warning: Must be used after drive(xxx, 0) and tick()
   */
  task automatic expect_hold(input binary32_t exp, input string tag = "");
    `FAIL_IF_LOG(s_o_valid !== 1'b0,
                $sformatf(">>>>> %s: expected o_valid=0 during bubble, got %0b", tag, s_o_valid))
    `FAIL_IF_LOG(s_o_exp_a !== exp,
                $sformatf(">>>>> %s: expected held value not preserved", tag))
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
