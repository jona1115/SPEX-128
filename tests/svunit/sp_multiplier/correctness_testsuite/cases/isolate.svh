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

`SVTEST(two_sp_mode_edge_partial_valids_independent)
  logic [127:0] prev = s_o_out_jedi;
  // Only lane B valid; lane A overflow vector held back
  logic [63:0] a_top = DBL_MAX, b_top = DBL_TWO;   // would overflow
  logic [63:0] a_bot = DBL_MIN_N, b_bot = DBL_HALF; // underflow to subnormal

  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NA, NA);

  s_i_in_anikin = {a_top, a_bot};
  s_i_in_force  = {b_top, b_bot};

  s_i_valid64a_anikin = 0; s_i_valid64a_force = 0; // A not valid
  s_i_valid64b_anikin = 1; s_i_valid64b_force = 1; // B valid
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(!s_o_valid64a_jedi && !s_o_valid64b_jedi) // Both invalid
  `FAIL_UNLESS(s_o_out_jedi === prev)                    // Nothing happens
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

