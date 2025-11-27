// ---- 64-bit (double) bit patterns
localparam logic [63:0] DBL_MAX      = 64'h7FEF_FFFF_FFFF_FFFF;
localparam logic [63:0] DBL_MIN_N    = 64'h0010_0000_0000_0000; // min normal
localparam logic [63:0] DBL_TWO      = 64'h4000_0000_0000_0000;
localparam logic [63:0] DBL_HALF     = 64'h3FE0_0000_0000_0000;
localparam logic [63:0] DBL_ONE      = 64'h3FF0_0000_0000_0000;
localparam logic [63:0] DBL_ONE_UP   = 64'h3FF0_0000_0000_0001; // nextafter(1.0,+)
localparam logic [63:0] DBL_ONE_DOWN = 64'h3FEF_FFFF_FFFF_FFFF; // nextafter(1.0,-)

// ---- 32-bit (float) bit patterns
localparam logic [31:0] FLT_MAX      = 32'h7F7F_FFFF;
localparam logic [31:0] FLT_MIN_N    = 32'h0080_0000; // min normal
localparam logic [31:0] FLT_TWO      = 32'h4000_0000;
localparam logic [31:0] FLT_HALF     = 32'h3F00_0000;
localparam logic [31:0] FLT_ONE      = 32'h3F80_0000;
localparam logic [31:0] FLT_ONE_UP   = 32'h3F80_0001;
localparam logic [31:0] FLT_ONE_DOWN = 32'h3F7F_FFFF;

`SVTEST(two_sp_mode_edge_overflow_underflow_and_signs)
  // Lane A: DBL_MAX * 2 -> +INF (overflow)
  // Lane B: MIN_NORMAL * 0.5 -> subnormal (underflow to subnormal)
  logic [63:0] a_top = DBL_MAX;
  logic [63:0] b_top = DBL_TWO;
  logic [63:0] a_bot = DBL_MIN_N;
  logic [63:0] b_bot = DBL_HALF;

  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NA, NA);

  s_i_in_anikin = {a_top, a_bot};
  s_i_in_force  = {b_top, b_bot};

  s_i_valid64a_anikin = 1; s_i_valid64a_force = 1;
  s_i_valid64b_anikin = 1; s_i_valid64b_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid64a_jedi && s_o_valid64b_jedi)
  $display(">>>>> top64(s_o_out_jedi)=0x%x", top64(s_o_out_jedi));
  $display(">>>>> mul64_bits(a_top, b_top)=0x%x", mul64_bits(a_top, b_top));
  `FAIL_UNLESS(top64(s_o_out_jedi) == mul64_bits(a_top, b_top)) // expect +INF
  // `FAIL_UNLESS(bot64(s_o_out_jedi) == mul64_bits(a_bot, b_bot)) // expect subnormal
  // But because the module treats subnormal as zero, expect zero:
  `FAIL_UNLESS(bot64(s_o_out_jedi) == '0)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END
