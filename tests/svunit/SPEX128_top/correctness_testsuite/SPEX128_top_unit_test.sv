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
  logic                                   s_o_valid;
  logic                                   s_o_ready;
  logic [3:0]                             s_o_sanity_identifier;
  logic [`ERROR_SIGNAL_NUM_BITS-1:0]      s_o_error;
  logic [`DEBUG_SIGNAL_NUM_BITS-1:0]      s_o_debug;

  logic [127:0] s_my_float_to_fixed_fixed;
  logic [127:0] s_mux_0;
  logic [127:0] s_mux_1;
  logic [127:0] s_mux_2;
  logic [127:0] s_mux_3;
  logic [127:0] s_my_sp_multiplier_0_jedi;
  logic [127:0] s_my_sp_multiplier_1_jedi;
  logic [127:0] s_my_sp_multiplier_2_jedi;
  logic [127:0] s_mux_4;
  logic [127:0] s_my_sp_multiplier_3_jedi;
  logic [127:0] s_my_sp_multiplier_4_jedi;
  binary128_t s_my_fixed128_64_partitiona_exp_a128;
  binary128_t s_my_fixed128_64_partitionb_exp_a128;
  binary128_t s_my_fixed128_64_partitionc_exp_a128;
  binary128_t s_my_fixed128_partitiond_exp_d128;
  binary128_t s_my_fixed128_partitione_exp_d128;
  binary128_t s_my_fixed128_partitionf_ts_exp_f128;
  float_metadata_t s_my_float_to_fixed_metadata;

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
    .o_valid(s_o_valid),
    .o_ready(s_o_ready),
    .o_sanity_identifier(s_o_sanity_identifier),
    .o_error(s_o_error),
    .o_debug(s_o_debug),

    .os_my_float_to_fixed_fixed(s_my_float_to_fixed_fixed),
    .os_mux_0(s_mux_0),
    .os_mux_1(s_mux_1),
    .os_mux_2(s_mux_2),
    .os_mux_3(s_mux_3),
    .os_my_sp_multiplier_0_jedi(s_my_sp_multiplier_0_jedi),
    .os_my_sp_multiplier_1_jedi(s_my_sp_multiplier_1_jedi),
    .os_my_sp_multiplier_2_jedi(s_my_sp_multiplier_2_jedi),
    .os_mux_4(s_mux_4),
    .os_my_sp_multiplier_3_jedi(s_my_sp_multiplier_3_jedi),
    .os_my_sp_multiplier_4_jedi(s_my_sp_multiplier_4_jedi),
    .os_my_fixed128_64_partitiona_exp_a128(s_my_fixed128_64_partitiona_exp_a128),
    .os_my_fixed128_64_partitionb_exp_a128(s_my_fixed128_64_partitionb_exp_a128),
    .os_my_fixed128_64_partitionc_exp_a128(s_my_fixed128_64_partitionc_exp_a128),
    .os_my_fixed128_partitiond_exp_d128(s_my_fixed128_partitiond_exp_d128),
    .os_my_fixed128_partitione_exp_d128(s_my_fixed128_partitione_exp_d128),
    .os_my_fixed128_partitionf_ts_exp_f128(s_my_fixed128_partitionf_ts_exp_f128),
    .os_my_float_to_fixed_metadata(s_my_float_to_fixed_metadata)
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
  // Local constants (IEEE-754 patterns)
  // ----------------------------------
  // Quad (binary128)
  localparam logic [127:0] Q_PZERO  = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
  localparam logic [127:0] Q_NZERO  = 128'h8000_0000_0000_0000_0000_0000_0000_0000;
  localparam logic [127:0] Q_ONE    = 128'h3FFF_0000_0000_0000_0000_0000_0000_0000;
  localparam logic [127:0] Q_PINF   = 128'h7FFF_0000_0000_0000_0000_0000_0000_0000;
  localparam logic [127:0] Q_NINF   = 128'hFFFF_0000_0000_0000_0000_0000_0000_0000;
  localparam logic [127:0] Q_PDEN   = 128'h0000_0000_0000_0000_0000_0000_0000_0001; // smallest +denorm
  localparam logic [127:0] Q_NDEN   = 128'h8000_0000_0000_0000_0000_0000_0000_0001; // smallest -denorm
  localparam logic [127:0] Q_QNAN_P = 128'h7FFF_8000_0000_0000_0000_0000_0000_0001; // quiet NaN payload
  localparam logic [127:0] Q_QNAN_N = 128'hFFFF_8000_0000_0000_0000_0000_0000_0001;

  // Double (binary64)
  localparam logic [63:0]  D_PZERO  = 64'h0000_0000_0000_0000;
  localparam logic [63:0]  D_NZERO  = 64'h8000_0000_0000_0000;
  localparam logic [63:0]  D_ONE    = 64'h3FF0_0000_0000_0000;
  localparam logic [63:0]  D_PINF   = 64'h7FF0_0000_0000_0000;
  localparam logic [63:0]  D_NINF   = 64'hFFF0_0000_0000_0000;
  localparam logic [63:0]  D_PDEN   = 64'h0000_0000_0000_0001;
  localparam logic [63:0]  D_NDEN   = 64'h8000_0000_0000_0001;
  localparam logic [63:0]  D_QNAN_P = 64'h7FF8_0000_0000_0001;
  localparam logic [63:0]  D_QNAN_N = 64'hFFF8_0000_0000_0001;

  // Float (binary32)
  localparam logic [31:0]  F_PZERO  = 32'h0000_0000;
  localparam logic [31:0]  F_NZERO  = 32'h8000_0000;
  localparam logic [31:0]  F_ONE    = 32'h3F80_0000;
  localparam logic [31:0]  F_PINF   = 32'h7F80_0000;
  localparam logic [31:0]  F_NINF   = 32'hFF80_0000;
  localparam logic [31:0]  F_PDEN   = 32'h0000_0001;
  localparam logic [31:0]  F_NDEN   = 32'h8000_0001;
  localparam logic [31:0]  F_QNAN_P = 32'h7FC0_0001;
  localparam logic [31:0]  F_QNAN_N = 32'hFFC0_0001;

  // ctrl encodings (per spec)
  localparam logic [3:0] CTRL_SINGLE   = 4'b0000;
  localparam logic [3:0] CTRL_TWO_SP   = 4'b0001;
  localparam logic [3:0] CTRL_FOUR_SP  = 4'b0010;

  // ----------------------------------
  // Helpers
  // ----------------------------------
  task automatic wait_n_ticks(int n);
    repeat (n) @(posedge s_i_clk) @(negedge s_i_clk);
  endtask

  `define PRINT_INTERMEDIATE_RESULTS                                                                            \
    $display("<<<<< =================== Intermediate results: ===================");                            \
    $display("<<<<< ------------------------ Level 1 ------------------------");                                \
    $display("<<<<< s_my_float_to_fixed_fixed = 0x%x", s_my_float_to_fixed_fixed);                              \
    $display("<<<<< s_my_float_to_fixed_metadata's float_type_a,b,c,d=%x,%x,%x,%x",                       \
                                            s_my_float_to_fixed_metadata.float_type_a,                          \
                                            s_my_float_to_fixed_metadata.float_type_b,                          \
                                            s_my_float_to_fixed_metadata.float_type_c,                          \
                                            s_my_float_to_fixed_metadata.float_type_d);                         \
    $display("<<<<< ------------------------ Level 2 ------------------------");                                \
    $display("<<<<< s_my_fixed128_64_partitiona_exp_a128 = 0x%x", s_my_fixed128_64_partitiona_exp_a128);        \
    $display("<<<<< s_my_fixed128_64_partitionb_exp_a128 = 0x%x", s_my_fixed128_64_partitionb_exp_a128);        \
    $display("<<<<< s_my_fixed128_64_partitionc_exp_a128 = 0x%x", s_my_fixed128_64_partitionc_exp_a128);        \
    $display("<<<<< s_my_fixed128_partitiond_exp_d128    = 0x%x", s_my_fixed128_partitiond_exp_d128);           \
    $display("<<<<< s_my_fixed128_partitione_exp_d128    = 0x%x", s_my_fixed128_partitione_exp_d128);           \
    $display("<<<<< s_my_fixed128_partitionf_ts_exp_f128 = 0x%x", s_my_fixed128_partitionf_ts_exp_f128);        \
    $display("<<<<< ------------------------ Level 3 ------------------------");                                \
    $display("<<<<< s_mux_0 = 0x%x", s_mux_0);                                                                  \
    $display("<<<<< s_mux_1 = 0x%x", s_mux_1);                                                                  \
    $display("<<<<< s_mux_2 = 0x%x", s_mux_2);                                                                  \
    $display("<<<<< s_mux_3 = 0x%x", s_mux_3);                                                                  \
    $display("<<<<< s_my_sp_multiplier_0_jedi = 0x%x", s_my_sp_multiplier_0_jedi);                              \
    $display("<<<<< s_my_sp_multiplier_1_jedi = 0x%x", s_my_sp_multiplier_1_jedi);                              \
    $display("<<<<< s_my_sp_multiplier_2_jedi = 0x%x", s_my_sp_multiplier_2_jedi);                              \
    $display("<<<<< s_mux_4 = 0x%x", s_mux_4);                                                                  \
    $display("<<<<< s_my_sp_multiplier_3_jedi = 0x%x", s_my_sp_multiplier_3_jedi);                              \
    $display("<<<<< s_my_sp_multiplier_4_jedi = 0x%x", s_my_sp_multiplier_4_jedi);                              \
    $display("<<<<< =================== End Intermediate Results ===================");

  // -------- Tunables --------------------------------------------------------
  `define LATENCY 2+1+5*3/*idk why the +3*/+3 // 21
  // LSB error tolerances (difference in integer value of the LSB slice)
  `define ERR_TOL_LSB_128 200
  `define ERR_TOL_LSB_64  2000
  `define ERR_TOL_LSB_32  2000
  // Width of the LSB window to compare
  `define LSB_WINDOW 16
  // --------------------------------------------------------------------------

  // Absolute value (int)
  function automatic int abs_int(int v);
    return (v < 0) ? -v : v;
  endfunction

  function automatic int lsb_error(logic [127:0] expct, logic [127:0] act, int w);
    int mask;
    int e, a;
    // Build a 32-bit mask with the lowest w bits set
    mask = (w >= 32) ? 32'hFFFF_FFFF : ((1 << w) - 1);
    // Take only the low 32 bits, then mask
    e = int'($unsigned(expct[31:0])) & mask;
    a = int'($unsigned(act[31:0])) & mask;
    return abs_int(e - a);
  endfunction

  function automatic int lsb_error_64_lane(logic [63:0] expct, logic [63:0] act, int w);
    int mask;
    int e, a;
    mask = (w >= 32) ? 32'hFFFF_FFFF : ((1 << w) - 1);
    e = int'($unsigned(expct[31:0])) & mask;
    a = int'($unsigned(act[31:0])) & mask;
    return abs_int(e - a);
  endfunction

  function automatic int lsb_error_32_lane(logic [31:0] expct, logic [31:0] act, int w);
    int mask;
    int e, a;
    mask = (w >= 32) ? 32'hFFFF_FFFF : ((1 << w) - 1);
    e = int'($unsigned(expct)) & mask;  // already 32-bit wide
    a = int'($unsigned(act))  & mask;
    return abs_int(e - a);
  endfunction

  // Classifiers
  function automatic bit is_nan128(logic [127:0] x);
    return (&x[126:112]) && (x[111:0] != '0);
  endfunction
  function automatic bit is_inf128(logic [127:0] x);
    return (&x[126:112]) && (x[111:0] == '0);
  endfunction
  function automatic bit is_zero128(logic [127:0] x);
    return (x[126:0] == '0);
  endfunction
  function automatic bit is_denorm128(logic [127:0] x);
    return (x[126:112] == '0) && (x[111:0] != '0);
  endfunction

  function automatic bit is_nan64(logic [63:0] x);
    return (&x[62:52]) && (x[51:0] != '0);
  endfunction
  function automatic bit is_inf64(logic [63:0] x);
    return (&x[62:52]) && (x[51:0] == '0);
  endfunction
  function automatic bit is_zero64(logic [63:0] x);
    return (x[62:0] == '0);
  endfunction
  function automatic bit is_denorm64(logic [63:0] x);
    return (x[62:52] == '0) && (x[51:0] != '0);
  endfunction

  function automatic bit is_nan32(logic [31:0] x);
    return (&x[30:23]) && (x[22:0] != '0);
  endfunction
  function automatic bit is_inf32(logic [31:0] x);
    return (&x[30:23]) && (x[22:0] == '0);
  endfunction
  function automatic bit is_zero32(logic [31:0] x);
    return (x[30:0] == '0);
  endfunction
  function automatic bit is_denorm32(logic [31:0] x);
    return (x[30:23] == '0) && (x[22:0] != '0);
  endfunction

  // One-beat ready/valid transaction. Accept happens when both i_valid & o_ready are 1 on a posedge.
  task automatic send_txn(input logic [127:0] x, input logic [3:0] ctrl);
    // wait until DUT says ready
    @(posedge s_i_clk);
    while (!s_o_ready) @(posedge s_i_clk);

    s_i_x     <= x;
    s_i_ctrl  <= ctrl;
    s_i_valid <= 1'b1;
    @(posedge s_i_clk);
    s_i_valid <= 1'b0;
  endtask

  // Wait latency cycles and check o_error==0
  task automatic await_and_check_no_error();
    wait_n_ticks(`LATENCY);
    `FAIL_UNLESS(s_o_error == '0)
  endtask

  // ------------- Golden expected for 64/32 using real math -------------
  // NOTE: uses $bitstoreal/$realtobits and $bitstoshortreal/$shortrealtobits.
  //       For +INF/-INF/NaN cases we bypass real math and check classification.
  function automatic logic [63:0] exp64_bits(logic [63:0] xin);
    real r = $bitstoreal(xin);
    real e = $exp(r);
    return $realtobits(e);
  endfunction

  function automatic logic [31:0] exp32_bits(logic [31:0] xin);
    shortreal s = $bitstoshortreal(xin);
    shortreal e = shortreal'($exp(s));
    return $shortrealtobits(e);
  endfunction
  // ---------------------------------------------------------------------

  // ----------------- Vector file loader for binary128 ------------------
  localparam string VEC128_IN_FILE  = "x_128b.hex";
  localparam string VEC128_EXP_FILE = "expx_128b.hex";
  localparam int    VEC128_MAX      = 4096;

  logic [127:0] vec128_in [0:VEC128_MAX-1];
  logic [127:0] vec128_gd [0:VEC128_MAX-1];
  int vec128_n;

  task automatic load_vec128_from_files(output int count);
    int fi, fe;
    int n_in = 0, n_exp = 0;
    logic [127:0] tmp;
    fi = $fopen(VEC128_IN_FILE, "r");
    fe = $fopen(VEC128_EXP_FILE, "r");
    if (fi == 0 || fe == 0) begin
      count = 0;
      if (fi) $fclose(fi);
      if (fe) $fclose(fe);
      return;
    end
    while (!$feof(fi) && (n_in < VEC128_MAX)) begin
      if ($fscanf(fi, "%h\n", tmp) == 1) begin
        vec128_in[n_in] = tmp;
        n_in++;
      end else void'($fgets(tmp, fi));
    end
    while (!$feof(fe) && (n_exp < VEC128_MAX)) begin
      if ($fscanf(fe, "%h\n", tmp) == 1) begin
        vec128_gd[n_exp] = tmp;
        n_exp++;
      end else void'($fgets(tmp, fe));
    end
    $fclose(fi);
    $fclose(fe);
    count = (n_in < n_exp) ? n_in : n_exp;
  endtask
  // ---------------------------------------------------------------------


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

// `define ISOLATE

`ifndef ISOLATE
    `include "cases/handwritten_correctness.svh"
    `include "cases/vibed_correctness.svh"
`else
    `include "cases/isolate.svh"
`endif

  `SVUNIT_TESTS_END

endmodule
