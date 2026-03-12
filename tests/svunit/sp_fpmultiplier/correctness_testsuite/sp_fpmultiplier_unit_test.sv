`include "svunit_defines.svh"

`define NUM_BITS_128 128
`define NUM_BITS_64 64
`define NUM_BITS_32 32
`define ERROR_SIGNAL_NUM_BITS 32
`define DEBUG_SIGNAL_NUM_BITS 32

module sp_fpmultiplier_unit_test;

  import svunit_pkg::svunit_testcase;

  import float_flag_pkg::*;
  import sp_mode_pkg::*;
  import float_metadata_pkg::*;
  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;


  string name = "sp_fpmultiplier_ut";
  svunit_testcase svunit_ut;

  // DUT IO
  logic                                   s_i_clk;
  logic                                   s_i_rst_n;
  float_metadata_t                        s_i_metadata;
  float_metadata_t                        s_o_metadata;
  logic [`NUM_BITS_128-1:0]               s_i_in_anikin;
  logic [`NUM_BITS_128-1:0]               s_i_in_force;
  logic [`NUM_BITS_128-1:0]               s_o_out_jedi;
  logic                                   s_i_valid128_anikin;
  logic                                   s_i_valid128_force;
  logic                                   s_i_valid64a_anikin;
  logic                                   s_i_valid64a_force;
  logic                                   s_i_valid64b_anikin;
  logic                                   s_i_valid64b_force;
  logic                                   s_i_valid32a_anikin;
  logic                                   s_i_valid32a_force;
  logic                                   s_i_valid32b_anikin;
  logic                                   s_i_valid32b_force;
  logic                                   s_i_valid32c_anikin;
  logic                                   s_i_valid32c_force;
  logic                                   s_i_valid32d_anikin;
  logic                                   s_i_valid32d_force;
  logic                                   s_o_valid128_jedi;
  logic                                   s_o_valid64a_jedi;
  logic                                   s_o_valid64b_jedi;
  logic                                   s_o_valid32a_jedi;
  logic                                   s_o_valid32b_jedi;
  logic                                   s_o_valid32c_jedi;
  logic                                   s_o_valid32d_jedi;
  logic [3:0]                             s_o_sanity_identifier;
  logic [`ERROR_SIGNAL_NUM_BITS-1:0]      s_o_error;
  logic [`DEBUG_SIGNAL_NUM_BITS-1:0]      s_o_debug;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  sp_fpmultiplier #(
    .NUM_BITS_128(`NUM_BITS_128),
    .NUM_BITS_64(`NUM_BITS_64),
    .NUM_BITS_32(`NUM_BITS_32),
    .ERROR_SIGNAL_NUM_BITS(`ERROR_SIGNAL_NUM_BITS),
    .DEBUG_SIGNAL_NUM_BITS(`DEBUG_SIGNAL_NUM_BITS),

    .DEBUG_PRINT_EN(0)
  ) my_sp_fpmultiplier(
    .i_clk(s_i_clk),
    .i_rst_n(s_i_rst_n),
    .i_metadata(s_i_metadata),
    .o_metadata(s_o_metadata),
    .i_in_anikin(s_i_in_anikin),
    .i_in_force(s_i_in_force),
    .o_out_jedi(s_o_out_jedi),
    .i_valid128_anikin(s_i_valid128_anikin),
    .i_valid128_force(s_i_valid128_force),
    .i_valid64a_anikin(s_i_valid64a_anikin),
    .i_valid64a_force(s_i_valid64a_force),
    .i_valid64b_anikin(s_i_valid64b_anikin),
    .i_valid64b_force(s_i_valid64b_force),
    .i_valid32a_anikin(s_i_valid32a_anikin),
    .i_valid32a_force(s_i_valid32a_force),
    .i_valid32b_anikin(s_i_valid32b_anikin),
    .i_valid32b_force(s_i_valid32b_force),
    .i_valid32c_anikin(s_i_valid32c_anikin),
    .i_valid32c_force(s_i_valid32c_force),
    .i_valid32d_anikin(s_i_valid32d_anikin),
    .i_valid32d_force(s_i_valid32d_force),
    .o_valid128_jedi(s_o_valid128_jedi),
    .o_valid64a_jedi(s_o_valid64a_jedi),
    .o_valid64b_jedi(s_o_valid64b_jedi),
    .o_valid32a_jedi(s_o_valid32a_jedi),
    .o_valid32b_jedi(s_o_valid32b_jedi),
    .o_valid32c_jedi(s_o_valid32c_jedi),
    .o_valid32d_jedi(s_o_valid32d_jedi),
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
    s_i_in_anikin = '0;
    s_i_in_force = '0;
    s_i_valid128_anikin = '0;
    s_i_valid128_force = '0;
    s_i_valid64a_anikin = '0;
    s_i_valid64a_force = '0;
    s_i_valid64b_anikin = '0;
    s_i_valid64b_force = '0;
    s_i_valid32a_anikin = '0;
    s_i_valid32a_force = '0;
    s_i_valid32b_anikin = '0;
    s_i_valid32b_force = '0;
    s_i_valid32c_anikin = '0;
    s_i_valid32c_force = '0;
    s_i_valid32d_anikin = '0;
    s_i_valid32d_force = '0;

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

  // Hex file file names
  string HEX_A_128 = "anikin_128b.hex";
  string HEX_B_128 = "force_128b.hex";
  string HEX_C_128 = "jedi_128b.hex";

  `define LATENCY (my_sp_fpmultiplier.MODULE_LATENCY)

  // ----------------------------------
  // Helpers
  // ----------------------------------
  task automatic wait_n_ticks(int n);
    repeat (n) @(posedge s_i_clk) @(negedge s_i_clk);
  endtask

  task automatic clear_valids();
    s_i_valid128_anikin = 0;
    s_i_valid128_force  = 0;
    s_i_valid64a_anikin = 0;
    s_i_valid64a_force  = 0;
    s_i_valid64b_anikin = 0;
    s_i_valid64b_force  = 0;
    s_i_valid32a_anikin = 0;
    s_i_valid32a_force  = 0;
    s_i_valid32b_anikin = 0;
    s_i_valid32b_force  = 0;
    s_i_valid32c_anikin = 0;
    s_i_valid32c_force  = 0;
    s_i_valid32d_anikin = 0;
    s_i_valid32d_force  = 0;
  endtask

  task automatic drive_meta(sp_mode_t mode,
                            float_flag_t fa, float_flag_t fb,
                            float_flag_t fc, float_flag_t fd);
    s_i_metadata.sp_mode      = mode;
    s_i_metadata.float_type_a = fa;
    s_i_metadata.float_type_b = fb;
    s_i_metadata.float_type_c = fc;
    s_i_metadata.float_type_d = fd;
  endtask

  // 64-bit lane golden multiply (bit-exact to IEEE-754 double)
  function automatic logic [63:0] mul64_bits(logic [63:0] a_bits, logic [63:0] b_bits);
    real a = $bitstoreal(a_bits);
    real b = $bitstoreal(b_bits);
    real p = a * b;
    // $display(">>>>> a (%f) * b (%f) = p (%f)", a, b, p);
    return $realtobits(p);
  endfunction

  // 32-bit lane golden multiply (bit-exact to IEEE-754 single)
  function automatic logic [31:0] mul32_bits(logic [31:0] a_bits, logic [31:0] b_bits);
    shortreal a = $bitstoshortreal(a_bits);
    shortreal b = $bitstoshortreal(b_bits);
    shortreal p = a * b;
    return $shortrealtobits(p);
  endfunction

  // 64-bit helpers
  function automatic logic [63:0] r2b64(real r); return $realtobits(r); endfunction
  function automatic real         b2r64(logic [63:0] b); return $bitstoreal(b); endfunction
  function automatic logic [127:0] pack_2x64(real a_top, real a_bot);
    return { r2b64(a_top), r2b64(a_bot) };
  endfunction
  function automatic logic [63:0] top64(logic [127:0] v); return v[127:64]; endfunction
  function automatic logic [63:0] bot64(logic [127:0] v); return v[63:0];   endfunction

  // 32-bit helpers
  function automatic logic [31:0] sr2b32(shortreal s); return $shortrealtobits(s); endfunction
  function automatic shortreal     b2sr32(logic [31:0] b); return $bitstoshortreal(b); endfunction
  function automatic logic [127:0] pack_4x32(shortreal a, shortreal b, shortreal c, shortreal d);
    return { sr2b32(a), sr2b32(b), sr2b32(c), sr2b32(d) };
  endfunction
  function automatic logic [31:0] lane32_a(logic [127:0] v); return v[127:96]; endfunction
  function automatic logic [31:0] lane32_b(logic [127:0] v); return v[95:64];  endfunction
  function automatic logic [31:0] lane32_c(logic [127:0] v); return v[63:32];  endfunction
  function automatic logic [31:0] lane32_d(logic [127:0] v); return v[31:0];   endfunction

  // 128-bit special encodings for structural checks
  function automatic logic [127:0] pack128_bits(logic sign, logic [14:0] exp, logic [111:0] mant);
    return {sign, exp, mant};
  endfunction
  localparam logic [127:0] F128_POS_INF = pack128_bits(1'b0, {15{1'b1}}, '0);
  localparam logic [127:0] F128_NEG_INF = pack128_bits(1'b1, {15{1'b1}}, '0);
  localparam logic [127:0] F128_ZERO    = 128'b0;
  localparam logic [127:0] F128_QNAN    = pack128_bits(1'b0, {15{1'b1}}, 112'h8000_0000_0000_0000_0000_0000);

  // 32-bit canonical encodings for deterministic checks
  localparam logic [31:0] F32_POS_INF = 32'h7F80_0000;
  localparam logic [31:0] F32_NEG_INF = 32'hFF80_0000;
  localparam logic [31:0] F32_ZERO    = 32'h0000_0000;
  function automatic bit is_nan32(logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 0);
  endfunction

  // Read hex file (one 128-bit word per line) into a queue
  task automatic read_hex128_to_queue(string path, ref logic [127:0] q[$]);
    int fd; int rc; string line; logic [127:0] val;
    fd = $fopen(path, "r");
    `FAIL_UNLESS(fd) // must open
    while (!$feof(fd)) begin
      rc = $fgets(line, fd);
      if (line.len() == 0) continue;
      if ($sscanf(line, "%h", val) == 1) q.push_back(val);
    end
    $fclose(fd);
  endtask

  // ====== binary128 helpers/consts (add near your other helpers) ======
  localparam int unsigned F128_EXP_BIAS   = 16383;
  localparam logic [14:0] F128_EXP_ONE    = 15'h3FFF;
  localparam logic [14:0] F128_EXP_TWO    = 15'h4000;
  localparam logic [14:0] F128_EXP_HALF   = 15'h3FFE;
  localparam logic [14:0] F128_EXP_MIN_N  = 15'h0001; // min normal
  localparam logic [14:0] F128_EXP_MAX_F  = 15'h7FFE; // max finite exponent
  localparam logic [14:0] F128_EXP_INF    = 15'h7FFF;

  localparam logic [111:0] F128_MANT_ZERO = 112'd0;
  localparam logic [111:0] F128_MANT_ALL1 = {112{1'b1}};
  localparam logic [111:0] F128_MANT_LSB1 = 112'd1;

  // Common values
  localparam logic [127:0] F128_ONE            = pack128_bits(1'b0, F128_EXP_ONE,   F128_MANT_ZERO);
  localparam logic [127:0] F128_ONE_UP         = pack128_bits(1'b0, F128_EXP_ONE,   F128_MANT_LSB1);     // nextUp(1.0)
  localparam logic [127:0] F128_ONE_DOWN       = pack128_bits(1'b0, F128_EXP_HALF,  F128_MANT_ALL1);     // nextDown(1.0)
  localparam logic [127:0] F128_TWO            = pack128_bits(1'b0, F128_EXP_TWO,   F128_MANT_ZERO);
  localparam logic [127:0] F128_HALF           = pack128_bits(1'b0, F128_EXP_HALF,  F128_MANT_ZERO);
  localparam logic [127:0] F128_MIN_NORMAL     = pack128_bits(1'b0, F128_EXP_MIN_N, F128_MANT_ZERO);
  localparam logic [127:0] F128_MAX_FINITE_POS = pack128_bits(1'b0, F128_EXP_MAX_F, F128_MANT_ALL1);
  localparam logic [127:0] F128_MAX_FINITE_NEG = pack128_bits(1'b1, F128_EXP_MAX_F, F128_MANT_ALL1);
  // Tiny 2^-200 (exact power-of-two)
  localparam logic [127:0] F128_2_NEG_200      = pack128_bits(1'b0, 15'(F128_EXP_BIAS-200), F128_MANT_ZERO);
  // Smallest positive subnormal (used as a denormal operand example)
  localparam logic [127:0] F128_DENORM_MIN     = pack128_bits(1'b0, 15'd0, F128_MANT_LSB1);

  // Structural predicates
  function automatic bit is_inf128(logic [127:0] x);
    return (x[126 -: 15] == {15{1'b1}}) && (x[111:0] == '0);
  endfunction
  function automatic bit is_subnormal128(logic [127:0] x);
    return (x[126 -: 15] == 15'd0) && (x[111:0] != 0);
  endfunction

  `define MAKE_ALL_VALID_SINGLE   s_i_valid128_anikin = 1; s_i_valid128_force = 1;
  `define MAKE_ALL_VALID_TWO_SP   s_i_valid64a_anikin = 1; s_i_valid64a_force = 1; s_i_valid64b_anikin = 1; s_i_valid64b_force = 1;
  `define MAKE_ALL_VALID_FOUR_SP  s_i_valid32a_anikin = 1; s_i_valid32a_force = 1; s_i_valid32b_anikin = 1; s_i_valid32b_force = 1; s_i_valid32c_anikin = 1; s_i_valid32c_force = 1; s_i_valid32d_anikin = 1; s_i_valid32d_force = 1;

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
    // `include "cases/correctness.svh"
    `include "cases/handwritten_sanity.svh"
    `include "cases/pipeline_test.svh"
`else
    `include "cases/isolate.svh"
`endif

  `SVUNIT_TESTS_END

endmodule
