`include "svunit_defines.svh"

module fixed_partition_sp_pipeline_unit_test;

`define ERROR_SIGNAL_NUM_BITS 32
`define DEBUG_SIGNAL_NUM_BITS 32

  import svunit_pkg::svunit_testcase;

  import float_flag_pkg::*;
  import sp_mode_pkg::*;
  import float_metadata_pkg::*;
  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;
  import binary128_convert_pkg::*;

  localparam int ADDR_BITS_128 = 4;
  localparam int ADDR_BITS_64  = 4;
  localparam int ADDR_BITS_32  = 4;
  localparam int LANE_BITS_128 = ADDR_BITS_128;
  localparam int LANE_BITS_64  = ADDR_BITS_64;
  localparam int LANE_BITS_32  = ADDR_BITS_32;
  localparam int LUT_DEPTH     = (1 << ADDR_BITS_128);
  localparam int CONVERT_LATENCY      = 4;
  localparam int SINGLE_MODE_LATENCY  = 2;
  localparam int TWO_SP_MODE_LATENCY  = 1 + CONVERT_LATENCY; // USE_128_FOR_64=1
  localparam int FOUR_SP_MODE_LATENCY = 2 + CONVERT_LATENCY; // USE_128_FOR_32=1

  string name = "fixed_partition_sp_pipeline_ut";
  svunit_testcase svunit_ut;

  logic                                   s_i_clk;
  logic                                   s_i_rst_n;
  float_metadata_t                        s_i_metadata;
  float_metadata_t                        s_o_metadata;
  logic [LANE_BITS_128-1:0]               s_i_lane_128;
  logic [LANE_BITS_64-1:0]                s_i_lane_64a;
  logic [LANE_BITS_64-1:0]                s_i_lane_64b;
  logic [LANE_BITS_32-1:0]                s_i_lane_32a;
  logic [LANE_BITS_32-1:0]                s_i_lane_32b;
  logic [LANE_BITS_32-1:0]                s_i_lane_32c;
  logic [LANE_BITS_32-1:0]                s_i_lane_32d;
  binary128_t                             s_o_exp_a128;
  binary64_t                              s_o_exp_64a;
  binary64_t                              s_o_exp_64b;
  binary32_t                              s_o_exp_32a;
  binary32_t                              s_o_exp_32b;
  binary32_t                              s_o_exp_32c;
  binary32_t                              s_o_exp_32d;
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

  logic [127:0] s_tb_lut [0:LUT_DEPTH-1];

  initial begin
    $readmemh("fixed_partition_sp_test_mem.hex", s_tb_lut);
  end

  fixed_partition_sp #(
    .MODULE_LATENCY_128(SINGLE_MODE_LATENCY),
    .MODULE_LATENCY_64(TWO_SP_MODE_LATENCY),
    .MODULE_LATENCY_32(FOUR_SP_MODE_LATENCY),
    .HAS_SIGN(1'b0),
    .USE_128_FOR_64(1'b1),
    .USE_128_FOR_32(1'b1),
    .ENABLE_64(1'b1),
    .ENABLE_32(1'b1),
    .ADDR_BITS_128(ADDR_BITS_128),
    .ADDR_BITS_64(ADDR_BITS_64),
    .ADDR_BITS_32(ADDR_BITS_32),
    .INIT_128_FILE("fixed_partition_sp_test_mem.hex"),
    .ERROR_SIGNAL_NUM_BITS(`ERROR_SIGNAL_NUM_BITS),
    .DEBUG_SIGNAL_NUM_BITS(`DEBUG_SIGNAL_NUM_BITS)
  ) my_fixed_partition_sp (
    .i_clk(s_i_clk),
    .i_rst_n(s_i_rst_n),
    .i_metadata(s_i_metadata),
    .o_metadata(s_o_metadata),
    .i_lane_128(s_i_lane_128),
    .i_lane_64a(s_i_lane_64a),
    .i_lane_64b(s_i_lane_64b),
    .i_lane_32a(s_i_lane_32a),
    .i_lane_32b(s_i_lane_32b),
    .i_lane_32c(s_i_lane_32c),
    .i_lane_32d(s_i_lane_32d),
    .o_exp_a128(s_o_exp_a128),
    .o_exp_64a(s_o_exp_64a),
    .o_exp_64b(s_o_exp_64b),
    .o_exp_32a(s_o_exp_32a),
    .o_exp_32b(s_o_exp_32b),
    .o_exp_32c(s_o_exp_32c),
    .o_exp_32d(s_o_exp_32d),
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

  function void build();
    svunit_ut = new(name);
  endfunction

  task setup();
    svunit_ut.setup();

    s_i_lane_128 = '0;
    s_i_lane_64a = '0;
    s_i_lane_64b = '0;
    s_i_lane_32a = '0;
    s_i_lane_32b = '0;
    s_i_lane_32c = '0;
    s_i_lane_32d = '0;
    s_i_valid128 = 1'b0;
    s_i_valid64a = 1'b0;
    s_i_valid64b = 1'b0;
    s_i_valid32a = 1'b0;
    s_i_valid32b = 1'b0;
    s_i_valid32c = 1'b0;
    s_i_valid32d = 1'b0;
    s_i_metadata = '0;
    s_i_metadata.sp_mode = SINGLE_MODE;
    s_i_metadata.float_type_a = NA;
    s_i_metadata.float_type_b = NA;
    s_i_metadata.float_type_c = NA;
    s_i_metadata.float_type_d = NA;

    s_i_rst_n = 1'b0;
    repeat (2) @(posedge s_i_clk);
    s_i_rst_n = 1'b1;
    @(posedge s_i_clk);
    @(negedge s_i_clk);
  endtask

  initial begin
    s_i_clk = 1'b0;
    forever #1 s_i_clk = ~s_i_clk;
  end

  task teardown();
    svunit_ut.teardown();
  endtask

  task automatic wait_n_ticks(input int n);
    repeat (n) @(posedge s_i_clk) @(negedge s_i_clk);
  endtask

  task automatic set_mode(input sp_mode_t mode);
    s_i_metadata.sp_mode = mode;
    s_i_metadata.float_type_a = NA;
    s_i_metadata.float_type_b = NA;
    s_i_metadata.float_type_c = NA;
    s_i_metadata.float_type_d = NA;
  endtask

  task automatic step_single(
    input logic valid128,
    input logic [LANE_BITS_128-1:0] lane128
  );
    set_mode(SINGLE_MODE);
    s_i_lane_128 = lane128;
    s_i_lane_64a = '0;
    s_i_lane_64b = '0;
    s_i_lane_32a = '0;
    s_i_lane_32b = '0;
    s_i_lane_32c = '0;
    s_i_lane_32d = '0;
    s_i_valid128 = valid128;
    s_i_valid64a = 1'b0;
    s_i_valid64b = 1'b0;
    s_i_valid32a = 1'b0;
    s_i_valid32b = 1'b0;
    s_i_valid32c = 1'b0;
    s_i_valid32d = 1'b0;
    wait_n_ticks(1);
  endtask

  task automatic step_two(
    input logic valid_pair,
    input logic [LANE_BITS_64-1:0] lane64a,
    input logic [LANE_BITS_64-1:0] lane64b
  );
    set_mode(TWO_SP_MODE);
    s_i_lane_128 = '0;
    s_i_lane_64a = lane64a;
    s_i_lane_64b = lane64b;
    s_i_lane_32a = '0;
    s_i_lane_32b = '0;
    s_i_lane_32c = '0;
    s_i_lane_32d = '0;
    s_i_valid128 = 1'b0;
    s_i_valid64a = valid_pair;
    s_i_valid64b = valid_pair;
    s_i_valid32a = 1'b0;
    s_i_valid32b = 1'b0;
    s_i_valid32c = 1'b0;
    s_i_valid32d = 1'b0;
    wait_n_ticks(1);
  endtask

  task automatic step_four(
    input logic valid_quad,
    input logic [LANE_BITS_32-1:0] lane32a,
    input logic [LANE_BITS_32-1:0] lane32b,
    input logic [LANE_BITS_32-1:0] lane32c,
    input logic [LANE_BITS_32-1:0] lane32d
  );
    set_mode(FOUR_SP_MODE);
    s_i_lane_128 = '0;
    s_i_lane_64a = '0;
    s_i_lane_64b = '0;
    s_i_lane_32a = lane32a;
    s_i_lane_32b = lane32b;
    s_i_lane_32c = lane32c;
    s_i_lane_32d = lane32d;
    s_i_valid128 = 1'b0;
    s_i_valid64a = 1'b0;
    s_i_valid64b = 1'b0;
    s_i_valid32a = valid_quad;
    s_i_valid32b = valid_quad;
    s_i_valid32c = valid_quad;
    s_i_valid32d = valid_quad;
    wait_n_ticks(1);
  endtask

  task automatic check_no_error();
    `FAIL_UNLESS(s_o_error == '0)
  endtask

  task automatic check_single_output(
    input logic expected_valid,
    input logic [LANE_BITS_128-1:0] expected_idx
  );
    logic [127:0] got128;
    logic [127:0] exp128;

    got128 = s_o_exp_a128;
    exp128 = s_tb_lut[expected_idx];

    `FAIL_UNLESS(s_o_valid128 == expected_valid)
    if (expected_valid) begin
      `FAIL_UNLESS(got128 == exp128)
    end
    check_no_error();
  endtask

  task automatic check_two_output(
    input logic expected_valid,
    input logic [LANE_BITS_64-1:0] expected_idx_a,
    input logic [LANE_BITS_64-1:0] expected_idx_b
  );
    logic [63:0] got64a;
    logic [63:0] got64b;
    logic [63:0] exp64a;
    logic [63:0] exp64b;

    got64a = s_o_exp_64a;
    got64b = s_o_exp_64b;
    exp64a = binary128_to_binary64_rne(s_tb_lut[expected_idx_a]);
    exp64b = binary128_to_binary64_rne(s_tb_lut[expected_idx_b]);

    `FAIL_UNLESS(s_o_valid64a == expected_valid)
    `FAIL_UNLESS(s_o_valid64b == expected_valid)
    if (expected_valid) begin
      `FAIL_UNLESS(got64a == exp64a)
      `FAIL_UNLESS(got64b == exp64b)
    end
    check_no_error();
  endtask

  task automatic check_four_output(
    input logic expected_valid,
    input logic [LANE_BITS_32-1:0] expected_idx_a,
    input logic [LANE_BITS_32-1:0] expected_idx_b,
    input logic [LANE_BITS_32-1:0] expected_idx_c,
    input logic [LANE_BITS_32-1:0] expected_idx_d
  );
    logic [31:0] got32a;
    logic [31:0] got32b;
    logic [31:0] got32c;
    logic [31:0] got32d;
    logic [31:0] exp32a;
    logic [31:0] exp32b;
    logic [31:0] exp32c;
    logic [31:0] exp32d;

    got32a = s_o_exp_32a;
    got32b = s_o_exp_32b;
    got32c = s_o_exp_32c;
    got32d = s_o_exp_32d;
    exp32a = binary128_to_binary32_rne(s_tb_lut[expected_idx_a]);
    exp32b = binary128_to_binary32_rne(s_tb_lut[expected_idx_b]);
    exp32c = binary128_to_binary32_rne(s_tb_lut[expected_idx_c]);
    exp32d = binary128_to_binary32_rne(s_tb_lut[expected_idx_d]);

    `FAIL_UNLESS(s_o_valid32a == expected_valid)
    `FAIL_UNLESS(s_o_valid32b == expected_valid)
    `FAIL_UNLESS(s_o_valid32c == expected_valid)
    `FAIL_UNLESS(s_o_valid32d == expected_valid)
    if (expected_valid) begin
      `FAIL_UNLESS(got32a == exp32a)
      `FAIL_UNLESS(got32b == exp32b)
      `FAIL_UNLESS(got32c == exp32c)
      `FAIL_UNLESS(got32d == exp32d)
    end
    check_no_error();
  endtask

  `SVUNIT_TESTS_BEGIN

    `include "cases/pipeline.svh"

  `SVUNIT_TESTS_END

endmodule
