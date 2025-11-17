`include "svunit_defines.svh"

`define NUM_BITS_128 128
`define NUM_BITS_64 64
`define NUM_BITS_32 32
`define ERROR_SIGNAL_NUM_BITS 32
`define DEBUG_SIGNAL_NUM_BITS 32

module sp_multiplier_unit_test;

  import svunit_pkg::svunit_testcase;

  import float_flag_pkg::*;
  import sp_mode_pkg::*;
  import float_metadata_pkg::*;
  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;


  string name = "sp_multiplier_ut";
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
  sp_multiplier #(
    .NUM_BITS_128(`NUM_BITS_128),
    .NUM_BITS_64(`NUM_BITS_64),
    .NUM_BITS_32(`NUM_BITS_32),
    .ERROR_SIGNAL_NUM_BITS(`ERROR_SIGNAL_NUM_BITS),
    .DEBUG_SIGNAL_NUM_BITS(`DEBUG_SIGNAL_NUM_BITS)
  ) my_sp_multiplier(
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

  // ----------------------------------
  // Helpers
  // ----------------------------------
  task automatic wait_n_ticks(int n);
    repeat (n) @(posedge s_i_clk);
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

  // 64-bit helpers
  function automatic logic [63:0] r2b64(real r);      return $realtobits(r); endfunction
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
    int fd; string line; logic [127:0] val;
    fd = $fopen(path, "r");
    `FAIL_UNLESS(fd) // must open
    while (!$feof(fd)) begin
      void'($fgets(line, fd));
      if (line.len() == 0) continue;
      if ($sscanf(line, "%h", val) == 1) q.push_back(val);
    end
    void'($fclose(fd));
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
