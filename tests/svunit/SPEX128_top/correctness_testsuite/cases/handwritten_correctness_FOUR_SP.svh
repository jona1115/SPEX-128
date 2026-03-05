`SVTEST(FOUR_SP_handwritten_sanity_correctness_test_0_exact)
  logic [127:0] expected = {32'h3fd3094c, 32'h3fd3094c, 32'h3fd3094c, 32'h3fd3094c};

  s_i_x     = {32'h3f000000, 32'h3f000000, 32'h3f000000, 32'h3f000000}; // 0.5, 0.5, 0.5, 0.5
  s_i_ctrl  = 4'b0010; // four sp mode

  s_i_valid = '1;

  wait_n_ticks(`LATENCY);

  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);

  `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END

// `SVTEST(FOUR_SP_handwritten_sanity_correctness_test_0)
//   logic [127:0] expected = {32'h3fd3094c, 32'h3fbbbc1b, 32'h3f1b4598, 32'h3fa2ef51};

//   s_i_x     = {32'h3f000000, 32'h3ec41893, 32'hbf000000, 32'h3e771c97}; // 0.5, 0.383, -0.5, 0.24132
//   s_i_ctrl  = 4'b0010; // four sp mode

//   s_i_valid = '1;

//   wait_n_ticks(`LATENCY);

//   // `PRINT_INTERMEDIATE_RESULTS
//   // `PRINT_INTERMEDIATE_VALID_BITS

//   // $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
//   // $display(">>>>> expected  = 0x%x", expected);
//   // $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);

//   `FAIL_UNLESS(lsb_error(expected, s_o_exp_x, `LSB_WINDOW) <= `ERR_TOL_LSB_32)
// `SVTEST_END
