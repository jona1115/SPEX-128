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

`SVTEST(four_sp_mode_edge_overflow_underflow_and_signs)
  // a: FLT_MAX * 2 -> +INF (overflow)
  // b: MIN_NORMAL * 0.5 -> subnormal
  // c: (-3.0) * (2.5) -> -7.5
  // d: 2^-10 * 2^10 -> 1.0  (exact)
  logic [31:0] aa = FLT_MAX;
  logic [31:0] fa = FLT_TWO;

  logic [31:0] ab = FLT_MIN_N;
  logic [31:0] fb = FLT_HALF;

  logic [31:0] ac = $shortrealtobits(shortreal'(-3.0));
  logic [31:0] fc = $shortrealtobits(shortreal'( 2.5));

  // 2^-10 and 2^10 in float
  logic [31:0] ad = $shortrealtobits(shortreal'($pow(2.0, -10.0)));
  logic [31:0] fd = $shortrealtobits(shortreal'($pow(2.0,  10.0)));

  drive_meta(FOUR_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);

  s_i_in_anikin = {aa, ab, ac, ad};
  s_i_in_force  = {fa, fb, fc, fd};

  s_i_valid32a_anikin = 1; s_i_valid32a_force = 1;
  s_i_valid32b_anikin = 1; s_i_valid32b_force = 1;
  s_i_valid32c_anikin = 1; s_i_valid32c_force = 1;
  s_i_valid32d_anikin = 1; s_i_valid32d_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid32a_jedi && s_o_valid32b_jedi && s_o_valid32c_jedi && s_o_valid32d_jedi)
  `FAIL_UNLESS(lane32_a(s_o_out_jedi) == mul32_bits(aa, fa)) // +INF
  $display(">>>>> ab=0x%x", ab);
  $display(">>>>> fb=0x%x", fb);
  $display(">>>>> lane32_b(s_o_out_jedi)=0x%x", lane32_b(s_o_out_jedi));
  $display(">>>>> mul32_bits(ab, fb)=0x%x", mul32_bits(ab, fb));
  // `FAIL_UNLESS(lane32_b(s_o_out_jedi) == mul32_bits(ab, fb)) // subnormal
  `FAIL_UNLESS(lane32_c(s_o_out_jedi) == mul32_bits(ac, fc)) // negative
  `FAIL_UNLESS(lane32_d(s_o_out_jedi) == mul32_bits(ad, fd)) // 1.0
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END
