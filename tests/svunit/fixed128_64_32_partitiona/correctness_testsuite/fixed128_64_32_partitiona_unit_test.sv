`include "svunit_defines.svh"

`define NUM_BITS_128 128
`define NUM_BITS_64 64
`define NUM_BITS_32 32
`define ERROR_SIGNAL_NUM_BITS 32
`define DEBUG_SIGNAL_NUM_BITS 32

module fixed128_64_32_partitiona_unit_test;

  import svunit_pkg::svunit_testcase;

  import float_flag_pkg::*;
  import sp_mode_pkg::*;
  import float_metadata_pkg::*;
  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;


  string name = "fixed128_64_32_partitiona_ut";
  svunit_testcase svunit_ut;

  // DUT IO
  logic                                   s_i_clk;
  logic                                   s_i_rst_n;
  float_metadata_t                        s_i_metadata;
  float_metadata_t                        s_o_metadata;
  logic [10:0]                            s_i_lane_a;
  logic [10:0]                            s_i_lane_b;
  logic [10:0]                            s_i_lane_c;
  logic [10:0]                            s_i_lane_d;
  binary128_t                             s_o_exp_a128;
  binary64_t                              s_o_exp_a64a;
  binary64_t                              s_o_exp_a64b;
  binary32_t                              s_o_exp_a32a;
  binary32_t                              s_o_exp_a32b;
  binary32_t                              s_o_exp_a32c;
  binary32_t                              s_o_exp_a32d;
  logic                                   s_i_valid128;
  logic                                   s_i_valid64a;
  logic                                   s_i_valid64b;
  logic                                   s_i_valid32a;
  logic                                   s_i_valid32b;
  logic                                   s_i_valid32c;
  logic                                   s_i_valid32d;
  logic                                   s_o_valid128;
  logic                                   s_o_valid64a;
  logic                                   s_o_valid64b;
  logic                                   s_o_valid32a;
  logic                                   s_o_valid32b;
  logic                                   s_o_valid32c;
  logic                                   s_o_valid32d;
  logic [3:0]                             s_o_sanity_identifier;
  logic [`ERROR_SIGNAL_NUM_BITS-1:0]      s_o_error;
  logic [`DEBUG_SIGNAL_NUM_BITS-1:0]      s_o_debug;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  fixed128_64_32_partitiona #(
    .NUM_BITS_128(`NUM_BITS_128),
    .NUM_BITS_64(`NUM_BITS_64),
    .NUM_BITS_32(`NUM_BITS_32),
    .ERROR_SIGNAL_NUM_BITS(`ERROR_SIGNAL_NUM_BITS),
    .DEBUG_SIGNAL_NUM_BITS(`DEBUG_SIGNAL_NUM_BITS)
  ) my_fixed128_64_32_partitiona(
    .i_clk(s_i_clk),
    .i_rst_n(s_i_rst_n),
    .i_metadata(s_i_metadata),
    .o_metadata(s_o_metadata),
    .i_lane_a(s_i_lane_a),
    .i_lane_b(s_i_lane_b),
    .i_lane_c(s_i_lane_c),
    .i_lane_d(s_i_lane_d),
    .o_exp_a128(s_o_exp_a128),
    .o_exp_a64a(s_o_exp_a64a),
    .o_exp_a64b(s_o_exp_a64b),
    .o_exp_a32a(s_o_exp_a32a),
    .o_exp_a32b(s_o_exp_a32b),
    .o_exp_a32c(s_o_exp_a32c),
    .o_exp_a32d(s_o_exp_a32d),
    .i_valid128(s_i_valid128),
    .i_valid64a(s_i_valid64a),
    .i_valid64b(s_i_valid64b),
    .i_valid32a(s_i_valid32a),
    .i_valid32b(s_i_valid32b),
    .i_valid32c(s_i_valid32c),
    .i_valid32d(s_i_valid32d),
    .o_valid128(s_o_valid128),
    .o_valid64a(s_o_valid64a),
    .o_valid64b(s_o_valid64b),
    .o_valid32a(s_o_valid32a),
    .o_valid32b(s_o_valid32b),
    .o_valid32c(s_o_valid32c),
    .o_valid32d(s_o_valid32d),
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
    s_i_lane_a = '0;
    s_i_lane_b = '0;
    s_i_lane_c = '0;
    s_i_lane_d = '0;
    s_i_valid64a = '0;
    s_i_valid64b = '0;
    s_i_valid128 = '0;
    s_i_valid32a = '0;
    s_i_valid32b = '0;
    s_i_valid32c = '0;
    s_i_valid32d = '0;

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

  // Wait cycles
  task automatic wait_n_ticks(int n);
    repeat (n) @(posedge s_i_clk) @(negedge s_i_clk);
  endtask
  
  // Wait latency cycles and check o_error==0
  task automatic await_and_check_no_error();
    wait_n_ticks(LATENCY);
    `FAIL_UNLESS(s_o_error == '0)
  endtask

  // todo other helper, localparam, macros etc.
  localparam int LATENCY = 2;

  localparam string A128_POS_FILE = my_fixed128_64_32_partitiona.INIT_128a_POS_FILE;
  localparam string A128_NEG_FILE = my_fixed128_64_32_partitiona.INIT_128a_NEG_FILE;
  localparam string A64_POS_FILE  = "fixed64_0a_partition.hex";
  localparam string A64_NEG_FILE  = "fixed64_1a_partition.hex";
  localparam string A32_POS_FILE  = "fixed32_0a_partition.hex";
  localparam string A32_NEG_FILE  = "fixed32_1a_partition.hex";

  binary128_t gt_mempos128 [0:1023];
  binary128_t gt_memneg128 [0:1023];
  binary64_t  gt_mempos64  [0:1023];
  binary64_t  gt_memneg64  [0:1023];
  binary32_t  gt_mempos32  [0:1023];
  binary32_t  gt_memneg32  [0:1023];

  // Load hex file into TB
  initial begin
    $display(">>>>> TB: loading 128a_POS_FILE LUT file: %s", A128_POS_FILE);
    $display(">>>>> TB: loading 128a_NEG_FILE LUT file: %s", A128_NEG_FILE);
    $display(">>>>> TB: loading 64a_POS_FILE  LUT file: %s", A64_POS_FILE);
    $display(">>>>> TB: loading 64a_NEG_FILE  LUT file: %s", A64_NEG_FILE);
    $display(">>>>> TB: loading 32a_POS_FILE  LUT file: %s", A32_POS_FILE);
    $display(">>>>> TB: loading 32a_NEG_FILE  LUT file: %s", A32_NEG_FILE);
    $readmemh(A128_POS_FILE, gt_mempos128);
    $readmemh(A128_NEG_FILE, gt_memneg128);
    $readmemh(A64_POS_FILE,  gt_mempos64);
    $readmemh(A64_NEG_FILE,  gt_memneg64);
    $readmemh(A32_POS_FILE,  gt_mempos32);
    $readmemh(A32_NEG_FILE,  gt_memneg32);
  end

  function automatic binary128_t lookup128(input logic [10:0] lane);
    lookup128 = (lane[10] == 1'b0) ? gt_mempos128[lane[9:0]] : gt_memneg128[lane[9:0]];
  endfunction

  function automatic binary64_t lookup64(input logic [10:0] lane);
    lookup64 = (lane[10] == 1'b0) ? gt_mempos64[lane[9:0]] : gt_memneg64[lane[9:0]];
  endfunction

  function automatic binary32_t lookup32(input logic [10:0] lane);
    lookup32 = (lane[10] == 1'b0) ? gt_mempos32[lane[9:0]] : gt_memneg32[lane[9:0]];
  endfunction

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

  task automatic drive_lanes(input logic [10:0] lane_a,
                             input logic [10:0] lane_b,
                             input logic [10:0] lane_c,
                             input logic [10:0] lane_d
                             );
    s_i_lane_a = lane_a;
    s_i_lane_b = lane_b;
    s_i_lane_c = lane_c;
    s_i_lane_d = lane_d;
  endtask

  task automatic drive_valids(input bit v128,
                              input bit v64a,
                              input bit v64b,
                              input bit v32a,
                              input bit v32b,
                              input bit v32c,
                              input bit v32d
                              );
    s_i_valid128 = v128;
    s_i_valid64a = v64a;
    s_i_valid64b = v64b;
    s_i_valid32a = v32a;
    s_i_valid32b = v32b;
    s_i_valid32c = v32c;
    s_i_valid32d = v32d;
  endtask

  task automatic expect_metadata_passthrough(input float_metadata_t exp, input string tag = "");
    `FAIL_IF_LOG(s_o_metadata !== exp,
      $sformatf(">>>>> %s: metadata mismatch exp=%p got=%p", tag, exp, s_o_metadata))
  endtask

  task automatic expect_valids(input bit v128,
                               input bit v64a,
                               input bit v64b,
                               input bit v32a,
                               input bit v32b,
                               input bit v32c,
                               input bit v32d,
                               input string tag = ""
                               );
    `FAIL_IF_LOG(s_o_valid128 !== v128,
      $sformatf(">>>>> %s: o_valid128 exp=%0b got=%0b", tag, v128, s_o_valid128))
    `FAIL_IF_LOG(s_o_valid64a !== v64a,
      $sformatf(">>>>> %s: o_valid64a exp=%0b got=%0b", tag, v64a, s_o_valid64a))
    `FAIL_IF_LOG(s_o_valid64b !== v64b,
      $sformatf(">>>>> %s: o_valid64b exp=%0b got=%0b", tag, v64b, s_o_valid64b))
    `FAIL_IF_LOG(s_o_valid32a !== v32a,
      $sformatf(">>>>> %s: o_valid32a exp=%0b got=%0b", tag, v32a, s_o_valid32a))
    `FAIL_IF_LOG(s_o_valid32b !== v32b,
      $sformatf(">>>>> %s: o_valid32b exp=%0b got=%0b", tag, v32b, s_o_valid32b))
    `FAIL_IF_LOG(s_o_valid32c !== v32c,
      $sformatf(">>>>> %s: o_valid32c exp=%0b got=%0b", tag, v32c, s_o_valid32c))
    `FAIL_IF_LOG(s_o_valid32d !== v32d,
      $sformatf(">>>>> %s: o_valid32d exp=%0b got=%0b", tag, v32d, s_o_valid32d))
  endtask

  task automatic expect_exp128(input logic [10:0] lane, input string tag = "");
    binary128_t exp;
    exp = lookup128(lane);
    `FAIL_IF_LOG(s_o_exp_a128 !== exp,
      $sformatf(">>>>> %s: 128 LUT mismatch lane=%0d exp=0x%0h got=0x%0h",
        tag, lane[9:0], exp, s_o_exp_a128))
  endtask

  task automatic expect_exp64a(input logic [10:0] lane, input string tag = "");
    binary64_t exp;
    exp = lookup64(lane);
    `FAIL_IF_LOG(s_o_exp_a64a !== exp,
      $sformatf(">>>>> %s: 64a LUT mismatch lane=%0d exp=0x%0h got=0x%0h",
        tag, lane[9:0], exp, s_o_exp_a64a))
  endtask

  task automatic expect_exp64b(input logic [10:0] lane, input string tag = "");
    binary64_t exp;
    exp = lookup64(lane);
    `FAIL_IF_LOG(s_o_exp_a64b !== exp,
      $sformatf(">>>>> %s: 64b LUT mismatch lane=%0d exp=0x%0h got=0x%0h",
        tag, lane[9:0], exp, s_o_exp_a64b))
  endtask

  task automatic expect_exp32a(input logic [10:0] lane, input string tag = "");
    binary32_t exp;
    exp = lookup32(lane);
    `FAIL_IF_LOG(s_o_exp_a32a !== exp,
      $sformatf(">>>>> %s: 32a LUT mismatch lane=%0d exp=0x%0h got=0x%0h",
        tag, lane[9:0], exp, s_o_exp_a32a))
  endtask

  task automatic expect_exp32b(input logic [10:0] lane, input string tag = "");
    binary32_t exp;
    exp = lookup32(lane);
    `FAIL_IF_LOG(s_o_exp_a32b !== exp,
      $sformatf(">>>>> %s: 32b LUT mismatch lane=%0d exp=0x%0h got=0x%0h",
        tag, lane[9:0], exp, s_o_exp_a32b))
  endtask

  task automatic expect_exp32c(input logic [10:0] lane, input string tag = "");
    binary32_t exp;
    exp = lookup32(lane);
    `FAIL_IF_LOG(s_o_exp_a32c !== exp,
      $sformatf(">>>>> %s: 32c LUT mismatch lane=%0d exp=0x%0h got=0x%0h",
        tag, lane[9:0], exp, s_o_exp_a32c))
  endtask

  task automatic expect_exp32d(input logic [10:0] lane, input string tag = "");
    binary32_t exp;
    exp = lookup32(lane);
    `FAIL_IF_LOG(s_o_exp_a32d !== exp,
      $sformatf(">>>>> %s: 32d LUT mismatch lane=%0d exp=0x%0h got=0x%0h",
        tag, lane[9:0], exp, s_o_exp_a32d))
  endtask

  task automatic expect_all_zero_outputs(input string tag = "");
    `FAIL_IF_LOG(s_o_metadata !== '0,
      $sformatf(">>>>> %s: o_metadata not 0 when disabled", tag))
    `FAIL_IF_LOG(s_o_valid128 !== 1'b0 || s_o_valid64a !== 1'b0 || s_o_valid64b !== 1'b0 ||
                 s_o_valid32a !== 1'b0 || s_o_valid32b !== 1'b0 || s_o_valid32c !== 1'b0 ||
                 s_o_valid32d !== 1'b0,
      $sformatf(">>>>> %s: o_valid* not all 0 when disabled", tag))
    `FAIL_IF_LOG(s_o_exp_a128 !== '0 || s_o_exp_a64a !== '0 || s_o_exp_a64b !== '0 ||
                 s_o_exp_a32a !== '0 || s_o_exp_a32b !== '0 || s_o_exp_a32c !== '0 ||
                 s_o_exp_a32d !== '0,
      $sformatf(">>>>> %s: o_exp_* not all 0 when disabled", tag))
    `FAIL_IF_LOG(s_o_error !== '0,
      $sformatf(">>>>> %s: o_error not 0", tag))
  endtask

  task automatic expect_no_error(input string tag = "");
    `FAIL_IF_LOG(s_o_error !== '0,
      $sformatf(">>>>> %s: o_error not 0", tag))
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
