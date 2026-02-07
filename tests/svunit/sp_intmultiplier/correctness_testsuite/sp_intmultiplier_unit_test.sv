`include "svunit_defines.svh"

`define EX_MAN_BITS_128       6
`define EX_MAN_BITS_64        53
`define EX_MAN_BITS_32        23
`define RADIX4_ROWS           $ceil(`EX_MAN_BITS_128 / 2)
`define ERROR_SIGNAL_NUM_BITS 32
`define DEBUG_SIGNAL_NUM_BITS 32

module sp_intmultiplier_unit_test;

  import svunit_pkg::svunit_testcase;

  import float_flag_pkg::*;
  import sp_mode_pkg::*;
  import float_metadata_pkg::*;
  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;


  string name = "sp_intmultiplier_ut";
  svunit_testcase svunit_ut;

  // DUT IO
  logic                                   s_i_clk;
  logic                                   s_i_rst_n;
  var float_metadata_t                    s_i_metadata;
  logic [`EX_MAN_BITS_128-1 : 0]          s_i_anikin;
  logic [`EX_MAN_BITS_128-1 : 0]          s_i_force;
  logic [`EX_MAN_BITS_128*2-1 : 0]        s_o_jedi;
  logic                                   s_i_valid_anikin;
  logic                                   s_i_valid_force;
  logic                                   s_o_valid_jedi;
  logic [3 : 0]                           s_o_sanity_identifier;
  logic [`ERROR_SIGNAL_NUM_BITS-1 : 0]    s_o_error;
  logic [`DEBUG_SIGNAL_NUM_BITS-1 : 0]    s_o_debug;
  logic [`EX_MAN_BITS_128+2-1 : 0]        ds_S1_pp [0 : `RADIX4_ROWS-1];
  logic [5993 : 0]                        ds_S2_S;
  logic [5993 : 0]                        ds_S2_C;
  logic [225 : 0]                         ss_S3_z0;
  logic [225 : 0]                         ss_S3_z1;
  logic [`EX_MAN_BITS_128*2-1:0]          ds_S4_jedi;
  logic                                   ds_S4_valid;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  sp_intmultiplier #(
    .EX_MAN_BITS_128(`EX_MAN_BITS_128),
    .EX_MAN_BITS_64(`EX_MAN_BITS_64),
    .EX_MAN_BITS_32(`EX_MAN_BITS_32)
  ) my_sp_intmultiplier(
    .i_clk(s_i_clk),
    .i_rst_n(s_i_rst_n),
    .i_metadata(s_i_metadata),
    .i_anikin(s_i_anikin),
    .i_force(s_i_force),
    .o_jedi(s_o_jedi),
    .i_valid_anikin(s_i_valid_anikin),
    .i_valid_force(s_i_valid_force),
    .o_valid_jedi(s_o_valid_jedi),
    .o_sanity_identifier(s_o_sanity_identifier),
    .o_error(s_o_error),
    .o_debug(s_o_debug),
    .ds_S1_pp(ds_S1_pp),
    .ds_S2_S(ds_S2_S),
    .ds_S2_C(ds_S2_C),
    .ds_S3_z0(ss_S3_z0),
    .ds_S3_z1(ss_S3_z1),
    .ds_S4_jedi(ds_S4_jedi),
    .ds_S4_valid(ds_S4_valid)
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
    s_i_valid_anikin = '0;
    s_i_valid_force = '0;

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

  `define LATENCY (my_sp_intmultiplier.MODULE_LATENCY)

  // ----------------------------------
  // Helpers
  // ----------------------------------
  task automatic wait_n_ticks(int n);
    repeat (n) @(posedge s_i_clk) @(negedge s_i_clk);
  endtask

  task automatic clear_valids();
    s_i_valid_anikin = 0;
    s_i_valid_force  = 0;
  endtask

  int row, col;
  `define PRINT_INTERMEDIATE_RESULTS                                                    \
    $display("<<<<< =================== Intermediate Results: ===================");    \
    $display("<<<<< big endian: ds_S1_pp =");                                           \
    for (row = 0; row < `RADIX4_ROWS; row = row + 1) begin                              \
      $write("\t\t");                                                                   \
      for (col = `EX_MAN_BITS_128+2-1; col >= 0; col = col - 1) begin                   \
        $write("%x ", ds_S1_pp[row][col]);                                              \
      end /*for col*/                                                                   \
      $display(""); /*\n*/                                                              \
    end /*for row*/                                                                     \
    // $display("<<<<< ds_S2_S = %x", ds_S2_S);                                            \
    // $display("<<<<< ds_S2_C = %x", ds_S2_C);                                            \
    $display("<<<<< ss_S3_z0 = %x", ss_S3_z0);                                          \
    $display("<<<<< ss_S3_z1 = %x", ss_S3_z1);                                          \
    $display("<<<<< ds_S4_jedi = %x", ds_S4_jedi);                                      \
    $display("<<<<< ds_S4_valid = %x", ds_S4_valid);                                    \
    $display("<<<<< =================== End Intermediate Results ===================");

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
    `include "cases/correctness.svh"
    // `include "cases/handwritten_sanity.svh"
`else
    `include "cases/isolate.svh"
`endif

  `SVUNIT_TESTS_END

endmodule
